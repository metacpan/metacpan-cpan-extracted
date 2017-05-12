#!/usr/bin/env perl
use strict;
use warnings;
use if -d 'lib', lib => 'lib'; # include libraries from ./lib
use Net::ISC::DHCPd::Config;

# This example script is mostly to see what is wrong with
# Net::ISC::DHCPd::Config, and not very usable...
# Check out t/*t instead

my $config = Net::ISC::DHCPd::Config->new(file => shift @ARGV);

#no warnings 'net_isc_dhcpd_config_parse'; # <-- turn off parse() warnings
printf "Parsed %s lines, and got these objects:\n\n", $config->parse;
print map { "$_\n" } @{ $config->_children }; # not public api, and may change
