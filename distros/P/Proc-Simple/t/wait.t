#!/usr/bin/perl -w
##################################################
# Check the exit status feature
##################################################

use Test::More tests => 4;
use Proc::Simple;

#Proc::Simple::debug(1);

my $proc = Proc::Simple->new();

my $start_rc = $proc->start("sleep 1");
ok($start_rc, 'start');

my $wait_rc = $proc->wait();
ok(! $proc->poll(), "process has exited");
ok(defined $wait_rc, "wait_rc defined");

my $exit_rc = $proc->exit_status();
ok(defined $exit_rc, "exit_rc defined");
