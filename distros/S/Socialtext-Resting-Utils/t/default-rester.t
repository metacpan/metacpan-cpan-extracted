#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;

BEGIN {
    use_ok 'Socialtext::Resting::DefaultRester';
}

my $rester = Socialtext::Resting::DefaultRester->new;
isa_ok $rester, 'Socialtext::Resting';
