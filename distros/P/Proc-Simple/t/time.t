#!/usr/bin/perl -w
##################################################
# Check the exit status feature
##################################################

use Test::More tests => 9;
use Proc::Simple;

#Proc::Simple::debug(1);

my $errortolerance = 2;	# this is necessary if the system under test is quite busy
my $proc = Proc::Simple->new();

my $t0 = time();
my $start_rc = $proc->start("sleep 5");
ok($start_rc, 'start');

my $wait_rc = $proc->wait();
my $t1 = time();
ok(! $proc->poll(), "process has exited");
ok(defined $wait_rc, "wait_rc defined");

my $exit_rc = $proc->exit_status();
ok(defined $exit_rc, "exit_rc defined");

ok(defined $proc->t0, "t0 defined");
ok(defined $proc->t1, "t1 defined");

my $t0diff = abs($proc->t0 - $t0);
ok($t0diff <= $errortolerance, "t0-proc->t0 <= $errortolerance");

my $t1diff = abs($proc->t1 - $t1);
ok($t1diff <= $errortolerance, "t1-proc->t1 <= $errortolerance");

my $actela = $t1 - $t0;
my $pmela = $proc->t1 - $proc->t0;
my $eladiff = abs($actela - $pmela);
ok($eladiff < $errortolerance, "eladiff <= $errortolerance");
