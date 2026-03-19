#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use Syntax::Feature::With qw(with);

my %h1 = ( a => 1 );
my %h2 = ( b => 2 );

my ($a, $b);

my $result = with \%h1, sub {
    with \%h2, sub {
        return "$a|$b";
    };
};

is($result, "1|2", 'nested with() works');

done_testing();

