#!/usr/bin/perl

use Nagios::Plugin::DieNicely;

eval {
	die "died and Nagios can detect me";
};

print "OK";
exit 0;
