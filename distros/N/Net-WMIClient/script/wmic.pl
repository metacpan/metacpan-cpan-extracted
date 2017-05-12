#!/usr/bin/perl -I blib/lib -I blib/arch
use Net::WMIClient qw(wmiclient);
my ($rc, $rv) = wmiclient(@ARGV);
print $rv;
exit !$rc;
