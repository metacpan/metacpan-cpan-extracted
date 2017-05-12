#!/usr/bin/env perl

use Test::More tests => 4;
use warnings;
use strict;

package Demo;
use Time::HiRes 'usleep';
use Moo;

with 'MooseX::Role::Timer';

sub BUILD {
    shift->start_timer("build");
}

sub a {
    my $self = shift;
    $self->start_timer("a");
    usleep(3_000);
    $self->stop_timer("a");
}

sub b {
    my $self = shift;
    $self->start_timer("b");
    usleep(15_000);
    $self->stop_timer("b");
}

package main;

my $demo = Demo->new;

for (0..4) {
    $demo->a;
    $demo->b;
}

my $a = $demo->elapsed_timer("a");
my $b = $demo->elapsed_timer("b");
my $c = $demo->elapsed_timer("build");

ok( $a > 0, "a>0; (a=$a)" );

ok( $b > 0, "b>0; (b=$b)" );

ok( $b > $a, "b>a; ($b>$a)" );

ok( $c >= ($a + $b), "all>=(a+b); ($c>=($a+$b)");
