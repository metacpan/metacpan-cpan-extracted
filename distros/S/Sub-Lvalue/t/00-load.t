#!/usr/bin/perl

use strict;
#use ex::lib '../lib';
use Test::More tests => 1;

BEGIN {
	use_ok( 'Sub::Lvalue' );
}

diag( "Testing Sub::Lvalue $Sub::Lvalue::VERSION, Perl $], $^X" );
