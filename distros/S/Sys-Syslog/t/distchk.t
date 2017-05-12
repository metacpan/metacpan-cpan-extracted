#!perl -w
use strict;
use Test::More;

plan skip_all => "Test::Distribution required for checking distribution"
    unless eval "use Test::Distribution not => [qw(versions podcover use)]; 1";
