#!perl

use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok( 'Proc::Topus' );
}

diag( "Testing Proc::Topus $Proc::Topus::VERSION, Perl $], $^X" );

done_testing;
