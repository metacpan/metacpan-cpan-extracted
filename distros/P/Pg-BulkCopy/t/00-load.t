#!perl 

use Cwd ;
use Carp::Always ;
use Test::More tests => 1;
#use Test::More 'no_plan' ;

BEGIN {
  use_ok( 'Pg::BulkCopy' ) || print "Bail out!";
}

diag( "Testing Pg::BulkCopy $Pg::BulkCopy::VERSION, Perl $], $^X" );

