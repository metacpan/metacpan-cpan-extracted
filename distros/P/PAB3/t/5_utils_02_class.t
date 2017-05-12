#!/usr/bin/perl

print "1..$tests\n";

require PAB3::Utils;
import PAB3::Utils;

$util = PAB3::Utils->new();
print $util ? 'ok' : 'failed', " 1\n";

if( int( $util->strftime( '%z' ) == 0 ) ) {
	print "ok 2\n";
}
else {
	print "failed 2\n";
}

use Cwd;

$dir = getcwd() . '/blib/arch/auto/PAB3/Utils/';
if( -f $dir . 'zoneinfo/Europe/Berlin.ics' ) {
	&PAB3::Utils::_set_module_path( $dir );
	
	$util->set_timezone( 'Europe/Berlin' );
	if( int( $util->strftime( '%z' ) >= 100 ) ) {
		print "ok 3\n";
	}
	else {
		print "failed 3\n";
	}
	if( int( &PAB3::Utils::strftime( '%z' ) == 0 ) ) {
		print "ok 4\n";
	}
	else {
		print "failed 4\n";
	}	
}
else {
	print STDERR "skipped, zoneinfo path not found\n";
	print "ok 3\n";
	print "ok 4\n";
}

#undef $util;

BEGIN {
	$tests = 4;
	unshift @INC, 'blib/lib', 'blib/arch';
}
