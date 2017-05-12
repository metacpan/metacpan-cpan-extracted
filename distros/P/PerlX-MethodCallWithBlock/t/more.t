#!/usr/bin/env perl
use strict;

package Ping::Pong;
sub ping {
    my $cb = pop;
    $cb->(@_);
}

package main;
use Test::More;
use PerlX::MethodCallWithBlock;

Ping::Pong->ping {
    pass "pong";
    my $caller = caller ;
    is $caller, "Ping::Pong", "called from Ping::Pong";
};

Ping::Pong->ping(42) {
    pass "pong";
    my $caller = caller ;
    is $caller, "Ping::Pong", "called from Ping::Pong";
};

my $pp = bless{}, "Ping::Pong";

$pp->ping(42) {
    pass "pong";
    my $caller = caller ;
    is $caller, "Ping::Pong", "called from Ping::Pong";
};

done_testing;
