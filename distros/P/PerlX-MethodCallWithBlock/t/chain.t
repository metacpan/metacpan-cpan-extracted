#!/usr/bin/env perl -w
use strict;
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
    return $self;
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
use Test::More;
use PerlX::MethodCallWithBlock;

my $array = MyEnum->new(1..10);

$array->map {
    2 * $_
}->each {
    is($_ % 2, 0, "Chained each");
};

done_testing;
