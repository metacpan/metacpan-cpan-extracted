# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 17;
use strict;

use lib qw(lib);

use Net::Sieve::Script;

BEGIN { use_ok( 'Net::Sieve::Script::Condition' ); }

my $bad_string = 'header :contains :comparator "i;octet" "i;octet" "Subject" "MAKE MONEY FAST"';
isnt (Net::Sieve::Script::Condition->new($bad_string)->write,$bad_string,'bad string not RFC 5228');

my @strings = (
'header :value "ge" :comparator "i;ascii-numeric" ["X-Spam-score"] ["14"]',
'header :comparator "i;octet" :contains "Subject" "MAKE MONEY FAST"',
'header :contains "x-attached" [".exe",".bat",".js"]',
'not address :localpart :is "X-Delivered-To" ["address1", "address2", "address3"]',
'allof ( address :domain :is "X-Delivered-To" "mydomain.info", not address :localpart :is "X-Delivered-To" ["address1", "address2", "address3"] )',
'allof ( address :is "X-Delivered-To" "mydomain.info", not address :localpart :is "X-Delivered-To" ["address1", "address2", "address3"] )',
'header :matches ["from","cc"] "from-begin@begin.fr"',
'not header :matches ["Subject"," Keywords"] ["POSTMASTER-AUTO-FW:", "postmaster-auto-fw:"]',
'header :contains ["from","cc"] [ "from-begin@begin.fr", "sex.com newsletter"]',
'header :comparator "i;ascii-casemap" :matches "Subject" "^Output file listing from [a-z]*backup$"',
'size :over 1M',
'allof ( 
    address :is "X-Delivered-To" "mydomain.info", 
    not address :localpart :is "X-Delivered-To" ["address1", "address2", "address3"], 
    anyof ( 
        header :contains "Subject" "Test", 
        header :contains "Subject" "Test2" )
 )',
'allof ( 
    address :is "X-Delivered-To" "mydomain.info", 
    anyof ( 
        header :contains "Subject" "Test", 
        header :contains "Subject" "Test2" ),
    not address :localpart :is "X-Delivered-To" ["address1", "address2", "address3"] 
 )',
'allof (
    allof (
        address :is "X-Delivered-To" "mydomain.info", 
        not address :localpart :is "X-Delivered-To" ["address1", "address2", "address3"]), 
    anyof ( 
        header :contains "Subject" "Test", 
        header :contains "Subject" "Test2" )
 )',
'allof ( anyof ( 
  header :contains ["From","Sender","Resent-from","Resent-sender","Return-path"] "xxx.com",
  header :contains ["Return-path"] "xxx.com",
  header :contains ["Return-path"] "xxx.com"
  ),
allof (
  not header :matches ["Subject"," Keywords"] ["POSTMASTER-AUTO-FW:", "postmaster-auto-fw:"],
  header :matches ["Subject"," Keywords"] "*"
  ))'

);


foreach my $string (@strings) {
    my $cond = Net::Sieve::Script::Condition->new($string);
    is (_strip($string),_strip($cond->write),'test string');
};


my $s1 = 'allof (
    allof (
        address :is "X-Delivered-To" "mydomain.info", 
        not address :localpart :is "X-Delivered-To" ["address1", "address2", "address3"]), 
    anyof ( 
        header :contains "Subject" "Test", 
        header :contains "Subject" "Test2" )
 )';


my $test = $s1;
#print $test."\n=====\n";
#my $cond = Net::Sieve::Script::Condition->new($test);
#use Data::Dumper;
#print Dumper $cond;
#print $cond->write;
