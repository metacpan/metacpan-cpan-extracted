#!/usr/bin/perl

die "$0 <dbms-uri>"
        unless $#ARGV == 0;

my $URI = shift @ARGV;

use DBMS;
tie %a ,DBMS,$URI,&DBMS::XSMODE_CREAT,0 or die $!;

$a{ foo } = bar;
for (1 .. 100) {
	$a{ 'key'.$_ } = "Some value ". ('x' x $_);
};

