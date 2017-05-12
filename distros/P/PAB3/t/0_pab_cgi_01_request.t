#!/usr/bin/perl

print "1..$tests\n";

require PAB3::CGI;
import PAB3::CGI qw(:default);

$ENV{'REQUEST_METHOD'} = 'GET';
$ENV{'QUERY_STRING'} = 'var1=val1&var2=val2';
&PAB3::CGI::_parse_request();
print "ok 1\n";

print $_GET{'var1'} eq 'val1' ? "ok 2\n" : "failed 2\n";

print $_GET{'var2'} eq 'val2' ? "ok 3\n" : "failed 3\n";

$ENV{'QUERY_STRING'} = 'var[]=val1&var[]=val%202';
&PAB3::CGI::_parse_request();

print ref( $_GET{'var'} ) eq 'ARRAY' ? "ok 4\n" : "failed 4\n";

print $_GET{'var'}->[0] eq 'val1' ? "ok 5\n" : "failed 5\n";

print $_GET{'var'}->[1] eq 'val 2' ? "ok 6\n" : "failed 6\n";

BEGIN {
	$tests = 6;
}
