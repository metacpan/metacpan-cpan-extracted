#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use lib '../lib';

package MyEnum;

sub new {
    my ($class, @x) = @_;
    return bless [ @x ], $class;
}

sub each {
    my ($self, $cb) = @_;

    my $i = 0;
    for my $x (@$self) {
        local $_ = $x;
        $cb->($i++);
    }
}

sub map {
    my ($self, $cb) = @_;

    my @r = ();
    my $i = 0;
    for my $x (@$self) {
        local $_ = $x;
        push @r, $cb->($i++);
    }
    return __PACKAGE__->new(@r);
}

package main;
use PerlX::MethodCallWithBlock;

my $x = MyEnum->new(0..10);

$x->each {
    say 2 * $_ + 1;
};

say "----";
$x->map {
    2 * $_ + 1
}->each {
    say;
};
