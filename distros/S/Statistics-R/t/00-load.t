#! perl

use strict;
use warnings;
use Test::More;


BEGIN {
   use_ok 'Statistics::R';
}

diag( "Testing Statistics::R $Statistics::R::VERSION, Perl $], $^X" );

done_testing;
