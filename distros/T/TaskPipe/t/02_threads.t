#!/usr/bin/perl

use strict;
use warnings;
use TaskPipe::TaskUtils::Settings;
use File::Basename;
use Proc::ProcessTable;
use Test::More;
use Time::HiRes qw(gettimeofday tv_interval);
use Cwd 'abs_path';
use lib 't/lib';
use TaskPipe::TestUtils::Basic;
use TaskPipe::TestUtils::Threaded;


my $root_dir = File::Spec->catdir(
    dirname(abs_path(__FILE__)),'..','t','threaded'
);

my $threaded = TaskPipe::TestUtils::Threaded->new(
    root_dir => $root_dir
);

$threaded->skip_if_no_config;
my $basic = TaskPipe::TestUtils::Basic->new(
    root_dir => $root_dir
);
$basic->deploy_tables_unless_exist;
$basic->clear_tables;
my $sm = $basic->cmdh->handler->schema_manager;
my $gm = $basic->cmdh->handler->job_manager->gm;

my $utils_settings = TaskPipe::TaskUtils::Settings->new;
my $timeout = 10;
my $init_threads = 4;
my $max_threads = 44;
my $inc_threads = 8;
my $i = int( ($max_threads - $init_threads ) / $inc_threads );
my $fin_threads = $init_threads + $i * $inc_threads;

plan tests => $i * ( 2 + ( $fin_threads - $init_threads ) / 2 );

warn "Testing thread system. Please be patient - this will take some time\n";

for ( my $n_threads = $init_threads; $n_threads < $max_threads; $n_threads += $inc_threads ){

    my $pid = fork();

    if ( $pid ){

        my $t0 = [gettimeofday];
        my $elapsed;
        my $job;
        do {
            $job = $gm->table('job')->find({
               pid => $pid
            });
            $elapsed = tv_interval( $t0 );
        } while ( ! $job && $elapsed < $timeout );

        die "Timed out waiting for job to appear on job table" unless $job;

        $t0 = [gettimeofday];
        my $n_thread_rows;
        do {
            $n_thread_rows = $sm->table('thread')->search({})->count;
            $elapsed = tv_interval( $t0 );
        } while ( $n_thread_rows < $n_threads && $elapsed < $timeout );

        die "Timed out waiting for thread rows to appear on thread table" if $elapsed > $timeout;

        my $proc_regex = $utils_settings->xtask_script." ".$job->id;

        my @active_threads = ();
        $t0 = [gettimeofday];
        do {
            my $t = Proc::ProcessTable->new;
            @active_threads = ();

            foreach my $p ( @{$t->table} ){
                next unless $p->cmndline && $p->cmndline =~ /$proc_regex/;
                my $pid = $p->pid;
                push @active_threads,$pid;
            }
        } while ( @active_threads < $n_threads && $elapsed < $timeout );

        die "Timed out waiting for threads to become active" if $elapsed > $timeout;

        foreach my $pid (@active_threads){
            my $exists = $sm->table('thread')->search({
                pid => $pid
            })->count;
            is( $exists, 1, "pid $pid is active and exists on table");
        }

        # wait a couple seconds to make sure no additional processes appear,
        # then count totals
        sleep 2;

        my $t = Proc::ProcessTable->new;
        my $tot_active_threads = 0;
        foreach my $p ( @{$t->table} ){
            next unless $p->cmndline && $p->cmndline =~ /$proc_regex/;
            $tot_active_threads++;
        }

        is( $tot_active_threads, $n_threads, "$n_threads active threads in total" );
        my $n_threads_db = $sm->table('thread')->search({})->count;
        is( $n_threads_db, $n_threads, "$n_threads_db threads on threads table" );

        $basic->stop_job( $pid );

        sleep 2;

        $basic->clear_tables;

    } else {
        $basic->run_plan({ threads => $n_threads, plan => 'sleep.yml' });
        exit;
    }
}



done_testing();
