#!/usr/bin/perl

print "1..$tests\n";

require PAB3::DB::Driver::Postgres;
print "ok 1\n";

import PAB3::DB::Driver::Postgres;
print "ok 2\n";

$_res = pg_connect();
if( ! $_res ) {
	$_res = pg_error();
	print STDERR "skipped:\n", $_res if $_res;
}
print "ok 3\n";

BEGIN {
	$tests = 3;
}
