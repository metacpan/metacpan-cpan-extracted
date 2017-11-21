#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Statistics::Descriptive::LogScale;

my $stat = Statistics::Descriptive::LogScale->new;

$stat->add_data( 1 .. 5 );

is $stat->format( "%%" ), "%", "Format % escape";
is $stat->format( "%1.1a" ), "3.0", "Format w/o arg";
is $stat->format( "%1.0p(50)" ), "3", "Format with arg";
is $stat->format( "%p(0)" ), sprintf("%f", -9**9**9)
    , sprintf( "-infinity = %f", -9**9**9 );

like $stat->format( "%5s = %a +- %d", "foo" )
    , qr/^  foo = \d(\.\d+)? \+- \d(\.\d+)?/
    , "More than 1 value in format";

done_testing;
