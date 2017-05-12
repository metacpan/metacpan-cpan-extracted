#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Task::BeLike::MPERRY' ) || print "Bail out!\n";
}

diag( "Testing Task::BeLike::MPERRY $Task::BeLike::MPERRY::VERSION, Perl $], $^X" );
