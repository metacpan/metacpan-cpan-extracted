#!/usr/bin/perl
use strict;
use warnings;
use POE qw(Session Kernel);
use base qw(POE::Sugar::Attributes);
use Test::More;


my %EventRegistry = (
    _start => 0,
    _stop => 0,
    sub_timer => 0,
    named_timer => 0
);

sub hello :Start {
    $EventRegistry{$_[STATE]}++;
    $_[KERNEL]->yield('foo');
}

sub sub_timer :Recurring(Interval => 0.0001)
{
    my $state = $_[STATE];
    
    #Kill the timer
    if($EventRegistry{$state}++ > 5) {
        $_[KERNEL]->delay($state);
    }
}

sub __anon :Recurring(Interval => 0.00001, Name => 'named_timer')
{
    my $state = $_[STATE];
    $EventRegistry{$state}++;
    $_[KERNEL]->delay($state);
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