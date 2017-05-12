#!perl
use strict;
use warnings FATAL => 'all';
use 5.014;

BEGIN { chdir 't' if -d 't'; }
use lib '../lib';

use Test::More; END { done_testing; }

use NetObj::IPv4Address;

my %ip_list = (
    "\x00\x00\x00\x00" => '0.0.0.0',
    "\xff\xff\xff\xff" => '255.255.255.255',
    "\x01\x02\x03\x04" => '1.2.3.4',
    "\x7f\x00\x00\x01" => '127.0.0.1',
);
for my $ipaddr (keys %ip_list) {
    my $ip = NetObj::IPv4Address->new($ipaddr);
    is($ip->to_string(), $ip_list{$ipaddr}, "convert to string for $ip");
    is("$ip", $ip_list{$ipaddr}, "implicit stringification for $ip");
}
