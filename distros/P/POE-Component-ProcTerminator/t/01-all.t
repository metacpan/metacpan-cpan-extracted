#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use POE;
use POE::Session;
use POE::Kernel;
use POE::Component::ProcTerminator;
use POE::Sugar::Attributes;
use POSIX qw(:sys_wait_h :errno_h :signal_h);
use Time::HiRes qw(sleep time);

use base qw(POE::Sugar::Attributes);
my $poe_kernel = "POE::Kernel";

my $CALL_NEXT;
my $BEGIN_TIME;
my $LAST_EXIT;

sub child_dead :Reaper {
    my ($pid,$status) = @_[ARG1,ARG2];
    diag "Child $pid reaped. Signal: ". WTERMSIG($status);
    $LAST_EXIT = WTERMSIG($status);
    if ($CALL_NEXT) {
        $CALL_NEXT->();
    } else {
        die("Couldn't find 'next' function!");
    }
}


sub got_signit :SigHandler(INT) {
    warn("Stopping...");
    $_[KERNEL]->signal($_[KERNEL], 'UIDESTROY');
}

sub fork_and_schedule {
    my ($sigs_to_send, $sigs_to_ignore,$grace) = @_;
    $grace ||= 0.5;
    local %SIG = %SIG;
    foreach my $sig (@$sigs_to_ignore) {
        $SIG{$sig} = 'IGNORE';
    }
    
    my $pid = fork();
    
    alarm(10);
    if ($pid == 0){
        POSIX::pause() while 1;
    } else {
        alarm(0);
        diag "Forked $pid";
        $poe_kernel->call(proc_terminator =>
                         terminate => $pid,
                         {
                            siglist => $sigs_to_send,
                            grace_period => $grace,
                         });
    }
}

sub poe_start :Start {
    POE::Component::ProcTerminator->spawn(Alias => "proc_terminator");
    fork_and_schedule([SIGINT, SIGUSR1, SIGKILL], [qw(INT USR1)], 0.5);
    $BEGIN_TIME = time();
    $CALL_NEXT = sub {
        my $duration = time - $BEGIN_TIME;
        ok($duration < 2, "Slept a bit");
        is($LAST_EXIT, SIGKILL, "Child died with SIGKILL");
        fork_many();
    }
}

sub fork_many {
    $BEGIN_TIME = time();
    foreach (1..10) {
        fork_and_schedule([SIGQUIT], [], 0.1);
    }
    my $count_total = 0;
    $CALL_NEXT = sub {
        $count_total++;
        is($LAST_EXIT, SIGQUIT, "Exited with SIGQUIT");
        if ($count_total == 10) {
            ok(time - $BEGIN_TIME < 1, "Took less than a second!");
        }
    }
}

POE::Sugar::Attributes->wire_new_session("main_session");
POE::Kernel->run();

done_testing();