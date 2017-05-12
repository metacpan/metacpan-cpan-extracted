use strict;
use warnings;



package Fake::DBIC;
use Moo;

sub storage { return shift }
sub debug   { return shift }
sub debugcb { return shift }



package main;
use Test::More;

use lib "lib";
use Test::DBIC::ExpectedQueries;


# Doesn't blow up, good
expected_queries(
    Fake::DBIC->new,
    sub { },
    {}
);

done_testing();
