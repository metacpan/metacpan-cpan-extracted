#!/usr/bin/perl -w
use lib '../lib';
use strict;
use SAP::BC;
use Data::Dumper;

my $bc = SAP::BC->new(server => 'http://kogut.local.net:5555',
                      user   => 'Administrator',
		      password => 'manage');

print Dumper $bc->SAP_systems();
print Dumper $bc->services();

