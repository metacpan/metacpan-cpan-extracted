# -*- perl -*-
use Test::More;
use ExtUtils::Manifest qw(manicheck);
plan tests => 1;

my @fails = manicheck();
is(@fails, 0, "manicheck");
