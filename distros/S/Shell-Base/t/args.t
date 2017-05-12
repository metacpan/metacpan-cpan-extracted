#!/usr/bin/perl -w
# vim: set ft=perl:

use strict;

use Test::More;
use Shell::Base;

my %args = (
    ONE => 1,
    TWO => 2,
    THREE => 3,
    FOUR => 4,
    FIVE => 5,
    SIX => 6,
    SEVEN => 7,
    EIGHT => 8,
    NINE => 9,
    TEN => 10,
);
my $args = \%args;

my $sh = Shell::Base->new(\%args);

plan tests => scalar(keys(%args)) * 2 + 1;

is($args, sprintf("%s", $sh->args), '$self->args returns original hash');

for my $key (keys %args) {
    my $lckey = lc $key;
    is($sh->args($key), $args{$key}, "Got correct data for $key");
    is($sh->args($lckey), $args{$key}, "Got correct data for $lckey");
}
