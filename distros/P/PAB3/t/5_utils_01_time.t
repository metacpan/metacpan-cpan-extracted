#!/usr/bin/perl

print "1..$tests\n";

require PAB3::Utils;
import PAB3::Utils;

$time = time;
@lt = &PAB3::Utils::localtime( $time );
print '', ( @lt == 9 ? "ok" : "failed" ), " 1\n";

use Cwd;

$dir = getcwd() . '/blib/arch/auto/PAB3/Utils/';
if( -f $dir . 'zoneinfo/Europe/Berlin.ics' ) {
	&PAB3::Utils::_set_module_path( $dir );
	
	&PAB3::Utils::set_timezone( 'Europe/Berlin' );
	if( int( &PAB3::Utils::strftime( '%z' ) >= 100 ) ) {
		print "ok ";
	}
	else {
		print "failed ";
	}
}
else {
	print STDERR "skipped, zoneinfo path not found\n";
	print "ok ";
}
print "2\n";

BEGIN {
	$tests = 2;
}
