#!/usr/bin/perl -w
# Copyright Troels Liebe Bentsen 2001.
# License:GPL
# 

use strict;
use RPM::Header::PurePerl;

my $filename = "test-1.0-1.i686.rpm";

tie my %rpm, "RPM::Header::PurePerl", $filename 
    or die "Problem, could not open $filename"; 

print "1..2\n";

if ($rpm{'NAME'} eq 'test') {
	print "ok 1\n";
}
if ($rpm{'PACKAGE_OFFSET'} == 1464) {
	print "ok 2\n";
}

untie(%rpm);
