#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Net::IPv6Addr 'in_network_of_size';
my $obj = in_network_of_size ('dead:beef:cafe:babe:dead:beef:cafe:babe', 42);
print $obj->to_string_compressed ();
