#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use Test::UseAllModules;

BEGIN {
	if ( $^O ne 'MSWin32' ) {
		plan skip_all => 'Not on Win32';
	}
}

all_uses_ok();
diag( "Testing Perl::Dist::WiX $Perl::Dist::WiX::VERSION" );


