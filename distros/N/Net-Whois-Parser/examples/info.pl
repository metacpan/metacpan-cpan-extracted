#!/usr/bin/perl

use strict;
use utf8;

use FindBin '$Bin';
use Data::Dumper;

use lib "$Bin/../lib";
use Net::Whois::Parser;
$Net::Whois::Raw::CHECK_FAIL = 1;
$Net::Whois::Raw::TIMEOUT = 10;
$Net::Whois::Parser::GET_ALL_VALUES = 1;

my $info = parse_whois( domain => $ARGV[0] || 'reg.ru' );

print $info ? Dumper($info) : "failed\n";


