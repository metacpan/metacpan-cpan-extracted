#!/usr/bin/env perl -w
use strict;

package Cow;
use Perl6ish;

sub new {
    bless {}, shift 
}

sub sound { "moooo" }

sub speak {
    my $self = shift;
    "a Cow goes " . $self->sound;
}

package main;

use Test::More tests => 1;

my $animal = new Cow;

is $animal.sound(), "moooo"
