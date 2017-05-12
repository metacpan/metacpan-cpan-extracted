#!/usr/bin/env perl

use Test::More tests => 2;
use lib::abs '../lib';

BEGIN {
	use_ok( 'Socket::AcceptFilter' );
	ok defined &accept_filter, 'export ok';
}

diag( "Testing Socket::AcceptFilter $Socket::AcceptFilter::VERSION, Perl $], $^O, $^X" );
