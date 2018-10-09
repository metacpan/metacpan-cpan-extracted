#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Net::IPv6Addr 'from_bigint';
print from_bigint ('12345678901234567890')->to_string_compressed ();

