#!/usr/bin/perl

use strict;
use Test::More tests => 10;
use lib ('./lib', '../lib');
use String::Unique;

#BEGIN {
#	use_ok( 'String::Unique' );
#}

my $stringGen1 = String::Unique->new({characterCount => 15, salt => 'gu',date => 'May 19, 2008'});
ok (
    $stringGen1->getStringByIndex(7, "April 29 2025") 
    eq 'ZY3AXIDYZP6TQG9'
    );
#print STDERR "\n", $stringGen1->getStringByIndex(7, "April 29 2025"),"\n";
my $stringGen2 = String::Unique->new({characterCount => 8, salt => 'IO',date => 'May 19, 2008'});
ok (
    $stringGen2->getStringByIndex(6484, "November 9 1992") 
    eq 'UIZ73078'
    );
#print STDERR "\n", $stringGen2->getStringByIndex(6484, "November 9 1992") ,"\n";
my $stringGen3 = String::Unique->new({characterCount => 10, salt => 'w2',date => 'May 19, 2008'});
ok (
    $stringGen3->getStringByIndex(7058, "August 31 1987") 
    eq 'DQKXXN0VB6'
    );
#print STDERR "\n", $stringGen3->getStringByIndex(7058, "August 31 1987") ,"\n";
my $stringGen4 = String::Unique->new({characterCount => 12, salt => 'Xt',date => 'May 19, 2008'});
ok (
    $stringGen4->getStringByIndex(3013, "October 14 2024") 
    eq '02YTEQZ6N24X'
    );
#print STDERR "\n", $stringGen4->getStringByIndex(3013, "October 14 2024") ,"\n";
my $stringGen5 = String::Unique->new({characterCount => 14, salt => 'Ta',date => 'May 19, 2008'});
ok (
    $stringGen5->getStringByIndex(7246, "May 28 1989") 
    eq 'S7WOQ4LRX15NQG'
    );
#print STDERR "\n", $stringGen5->getStringByIndex(7246, "May 28 1989") ,"\n";
my $stringGen6 = String::Unique->new({characterCount => 13, salt => 'KA',date => 'May 19, 2008'});
ok (
    $stringGen6->getStringByIndex(10, "August 4 1994") 
    eq 'G25HN64LC5AEW'
    );
#print STDERR "\n", $stringGen6->getStringByIndex(10, "August 4 1994") ,"\n";
my $stringGen7 = String::Unique->new({characterCount => 16, salt => 'cM',date => 'May 19, 2008'});
ok (
    $stringGen7->getStringByIndex(23, "April 10 1995") 
    eq '8SP6QE3QUT2WAT5G'
    );
#print STDERR "\n", $stringGen7->getStringByIndex(23, "April 10 1995") ,"\n";
my $stringGen8 = String::Unique->new({characterCount => 11, salt => 'G8',date => 'May 19, 2008'});
ok (
    $stringGen8->getStringByIndex(1454, "February 29 2024") 
    eq 'TCFJ5SXIUS4'
    );
#print STDERR "\n", $stringGen8->getStringByIndex(1454, "February 29 2024") ,"\n";
my $stringGen9 = String::Unique->new({characterCount => 20, salt => 'CO',date => 'May 19, 2008'});
ok (
    $stringGen9->getStringByIndex(1276, "June 29 1991") 
    eq 'AZ1OYNS46KPWA275NUOI'
    );
#print STDERR "\n", $stringGen9->getStringByIndex(1276, "June 29 1991") ,"\n";

my $stringGen10 = String::Unique->new({characterCount => 9, salt => 'ch',date => 'May 19, 2008'});
ok (
    $stringGen10->getStringByIndex(4, "February 15 1992") 
    eq 'BBI0FG9GE'
    );
#print STDERR "\n", $stringGen10->getStringByIndex(4, "February 15 1992") ,"\n";
