#!/usr/bin/perl

use strict;
use warnings;
use POE::Session;
use POE::Kernel;
use POE;
use base qw(POE::Sugar::Attributes);
use Test::More;


my %EventRegistry = (
    _start => 0,
    _stop => 0,
    foo  => 0,
    bar  => 0,
);

sub hello :Start {
    $EventRegistry{$_[STATE]}++;
    $_[KERNEL]->yield('foo');
}

sub _anon_event :Event(foo, bar) {
    $EventRegistry{$_[STATE]}++;
    $_[KERNEL]->yield('bar') unless $_[STATE] eq 'bar';
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