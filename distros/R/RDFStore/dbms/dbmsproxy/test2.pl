#!/usr/bin/perl

die "$0 <dbms-uri>"
	unless $#ARGV == 0;

my $URI = shift @ARGV;

use DBMS;
tie %a ,DBMS,$URI,&DBMS::XSMODE_RDONLY,0 or die $!;

while(my ($k,$v) = each %a) {
	print "$k\n\t$v\n";
};

