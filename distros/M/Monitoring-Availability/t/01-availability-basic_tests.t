#!/usr/bin/env perl

#########################

use strict;
use Test::More tests => 2;
use Data::Dumper;

use_ok('Monitoring::Availability');
my $ma = Monitoring::Availability->new();
isa_ok($ma, 'Monitoring::Availability', 'create new Monitoring::Availability object');

#########################
