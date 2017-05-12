#!/usr/bin/perl

use strict;
use warnings;

use lib './lib';

use Data::Dumper;
use Net::NationalRail::LiveDepartureBoards;

my $ldb = Net::NationalRail::LiveDepartureBoards->new();

print Dumper($ldb->departures(rows => 10, crs => 'RUG'));

