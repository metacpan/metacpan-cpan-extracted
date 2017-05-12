#!perl -T
# $Id: 00-load.t,v 1.1 2007/01/02 21:15:54 tans Exp $

use Test::More tests => 2;

BEGIN {
	use_ok( 'Net::OICQ' );
	use_ok( 'Net::OICQ::ServerEvent' );
}

diag( "Testing Net::OICQ $Net::OICQ::VERSION, Perl $], $^X" );
