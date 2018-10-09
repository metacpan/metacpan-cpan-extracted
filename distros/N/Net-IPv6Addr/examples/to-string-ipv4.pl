#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Net::IPv6Addr ':all';
print to_string_ipv4_compressed ('dead:beef:0:3:2:1:cafe:babe');
