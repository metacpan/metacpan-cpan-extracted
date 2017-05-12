#!/usr/bin/perl

print "1..$tests\n";

require PAB3::DB::Driver::Mysql;
print "ok 1\n";

import PAB3::DB::Driver::Mysql;
print "ok 2\n";

$_res = mysql_connect();
if( ! $_res ) {
	$_res = mysql_error();
	print STDERR "skipped: ", $_res, "\n" if $_res;
}
print "ok 3\n";

BEGIN {
	$tests = 3;
}
