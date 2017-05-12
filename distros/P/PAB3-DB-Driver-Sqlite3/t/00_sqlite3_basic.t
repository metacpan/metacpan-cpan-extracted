#!/usr/bin/perl

print "1..$tests\n";

require PAB3::DB::Driver::Sqlite3;
print "ok 1\n";

import PAB3::DB::Driver::Sqlite3;
print "ok 2\n";

$_res = sqlite3_connect( 'test.db' );
if( ! $_res ) {
	$_res = sqlite3_error();
}
print "ok 3\n";

BEGIN {
	$tests = 3;
}
