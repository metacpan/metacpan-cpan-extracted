#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Syntax::Operator::Elem qw( elem_str elem_num );

# stringy
{
   ok( elem_str("c", "a".."e"), 'c is in a..e');
   ok(!elem_str("f", "a".."e"), 'f is not in a..e');
}

# numbery
{
   ok( elem_num(3, 1..5), '3 is in 1..5');
   ok(!elem_num(6, 1..5), '6 is not in 1..5');
}

# TODO unimport test makes the-above test fail

done_testing;
