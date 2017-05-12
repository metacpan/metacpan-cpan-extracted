# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use Term::InKey;
$loaded = 1;
print "ok 1\n";

my $x,$y;
if ($^O !~ /Win32/i) 
	{
	local *STDIN;
	open STDIN, $0;
	$x = &ReadKey;
	$y = &ReadPassword($x);
	} 
	else 
	{ #No tests for Win32
	$x = '#';
	$y = ' Before ';
	}

if ($x eq '#') {
	print "ok 2\n";
	}
	else
	{
	print "not ok 2\n";
	}

if ($y =~ /Before/) {
	print "ok 3\n";
	}
	else
	{
	print "not ok 3\n";
	}

{
local *STDOUT;
open STDOUT, "> /dev/null";
&Clear;
}
print "ok 4\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

