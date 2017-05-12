#!/usr/bin/env perl

package Demo;
use Time::HiRes 'usleep';
use Moose;

with 'MooseX::Role::Timer';

sub BUILD {
    shift->start_timer("build");
}

sub do_something {
    my $self = shift;
    $self->start_timer("something");
    usleep(20_000);
    $self->stop_timer("something");
}

sub do_someotherthing {
    my $self = shift;
    $self->start_timer("someotherthing");
    usleep(10_000);
    $self->stop_timer("someotherthing");
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

package main;

my $demo = Demo->new;

for (0..9) {
    $demo->do_something;
    $demo->do_someotherthing;
}

#$demo->stop_timer($_) for $demo->timer_names;

for my $timer ( $demo->timer_names ) {
    printf "timer %-20s %3.6fs\n", "'$timer'", $demo->elapsed_timer($timer);
}