#!/usr/bin/perl

# Compile-testing for File::HomeDir

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;

use_ok( 'SMS::Send'           );
use_ok( 'SMS::Send::Driver'   );
use_ok( 'SMS::Send::Test'     );
use_ok( 'SMS::Send::AU::Test' );
