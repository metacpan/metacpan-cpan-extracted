#!perl
use strict;
use warnings;
use lib './lib';
use Test::More;
plan tests => 1;
our $i;
use Nice::Try;
try { $i++ } catch { }
is( $i, 1, 'try-catch immediately after use' );
