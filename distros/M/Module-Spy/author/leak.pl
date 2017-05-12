#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use 5.010000;
use autodie;
use Module::Spy;

sub X::y { }

bench('X', 10);
bench(bless([], X::), 1000);

sub memory_usage { system("ps uw -p $$") }

sub bench {
    my $subject = shift;
    my $n = shift;

    &memory_usage;
    for (1..$n) {
        spy($subject, 'y');
    }
    &memory_usage;
    for (1..$n) {
        spy($subject, 'y');
    }
    &memory_usage;
}
