#!/usr/bin/perl
# this merges several nmap scans to one file
# cat 2*xml > all.xml
# $0 all.xml > new.xml
open (F,"$ARGV[0]");
while (<F>) { $dat.=$_; }
close (F);

$dat =~ s!</nmaprun>(.*?)<host>!<host>!gis;
print $dat;
