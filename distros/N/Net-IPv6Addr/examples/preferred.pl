#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Net::IPv6Addr 'to_string_preferred';
print to_string_preferred ('dead:beef:cafe:babe::f0ad');
