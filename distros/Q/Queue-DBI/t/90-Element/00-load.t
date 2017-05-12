#!perl -T

use strict;
use warnings;

use Test::FailWarnings;
use Test::More tests => 1;


BEGIN
{
	use_ok( 'Queue::DBI::Element' );
}

diag( "Testing Queue::DBI::Element $Queue::DBI::Element::VERSION, Perl $], $^X" );
