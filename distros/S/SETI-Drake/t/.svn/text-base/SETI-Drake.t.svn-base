#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 7;
use_ok 'SETI::Drake';

my $d = eval { SETI::Drake->new() };
warn $@ if $@;
isa_ok $d, 'SETI::Drake';
is $d->N, 10_000, 'Frank Drake is an optimist';

my %args = (
    R  => 10,
    fp => 0.5,
    ne => 2,
    fl => 1,
    fi => 1,
    fc => 0.01,
    L  => 10,
);
$d = SETI::Drake->new(%args);
is $d->N, 1, 'Drake is a pessimist, according to wikipedia';

%args = (
    R  => 0,
    fp => 0,
    ne => 0,
    fl => 0,
    fi => 0,
    fc => 0,
    L  => 0,
);
$d = SETI::Drake->new(%args);
is $d->N, 0, 'What if there were no Universe?';

%args = (
    R  => 5,
    fp => 0.5,
    ne => 2,
    fl => 0.5,
    fi => 0.01,
    fc => 0.1,
    L  => 500,
);
$d = SETI::Drake->new(%args);
is $d->N, 1.25, 'Gene is a pessimist';

%args = (
    R  => 400_000_000_000,
    fp => 1/4,
    ne => 2,
    fl => 1/2,
    fi => 1/10,
    fc => 1/10,
    L  => 1/100_000_000,
);
$d = SETI::Drake->new(%args);
is $d->N, 10, 'Carl Sagan is not an optimist, either';
