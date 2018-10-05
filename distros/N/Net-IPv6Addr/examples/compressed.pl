#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Net::IPv6Addr 'to_string_compressed';
print to_string_compressed ('dead:beef:0000:0000:0000:0000:cafe:babe');
