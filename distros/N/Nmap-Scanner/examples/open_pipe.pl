#!/usr/bin/perl

#
#  Example of just using Nmap::Scanner::Scanner as a front end
#  option processor.
#

use lib 'lib';

use Nmap::Scanner;

use strict;

my $scanner = Nmap::Scanner->new();

$scanner->max_rtt_timeout(200);

my ($pid, $in, $out, $err) = $scanner->open_nmap("-P0 -sS -p 22,25,80 $ARGV[0]");

#  Now YOU decide what to do with the XML output :) here.

print "PID: $pid\n";

print while (<$out>);
print while (<$err>);

close($out, $in, $err);

exit 0;
