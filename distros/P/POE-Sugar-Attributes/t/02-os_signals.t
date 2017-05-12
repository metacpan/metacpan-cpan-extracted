#!/usr/bin/perl
use strict;
use warnings;
use POE qw(Session Kernel);
use base qw(POE::Sugar::Attributes);
use Test::More;

my %EventRegistry = (
    _start  => 0,
    _stop   => 0,
    reaper  => 0,
    main_screens  => 0,
    zigs_moved => 0,
    
);

my $do_stop = 0;

sub hello :Start {
    $EventRegistry{$_[STATE]}++;
    
    if(fork() == 0) {
        POE::Kernel->stop();
        note "I am $$";
        exit(42);
    } else {
        note "We are $$";
    }
    
    $_[KERNEL]->signal($_[SESSION], 'main screen turn on');
}

sub keepalive :Recurring(Interval => 0.01) {
    if($do_stop) {
        note "Stopping keepalive timer";
        $_[KERNEL]->state($_[STATE], undef);
        $_[KERNEL]->delay($_[STATE], undef);
    }
}

sub zigs_moved :Event {
    $EventRegistry{$_[STATE]}++;
    note "ZIGs moved!";
}

sub dfl :Event(_default) {
    warn "Unhandled event" . $_[ARG0];
}

sub main_screens :SigHandler('main screen turn on')
{
    note "we get signal: $_[ARG0]";
    $EventRegistry{$_[STATE]}++;
}

sub reaper :Reaper
{
    $EventRegistry{$_[STATE]}++;
    note "Reaped PID " . $_[ARG1] .
        " with exit status. For great justice". ($_[ARG2] >> 8);
    note "Moving every 'ZIG'!";
    $_[KERNEL]->sig_handled();
    $_[KERNEL]->yield('zigs_moved');
    $do_stop = 1;
}

sub bye :Stop {
    $EventRegistry{$_[STATE]}++;
}

POE::Sugar::Attributes::wire_new_session();

POE::Kernel->run();

while (my ($state,$called) = each %EventRegistry) {
    ok($called, "State '$state' invoked as expected");
}

done_testing();