#!perl -T

use strict;
use warnings;

use Test::FailWarnings;
use Test::More tests => 3;


BEGIN
{
	use_ok( 'DBI' );
	use_ok( 'Queue::DBI' );
	use_ok( 'Queue::DBI::Element' );
}

diag( "Testing Queue::DBI $Queue::DBI::VERSION, Perl $], $^X" );
