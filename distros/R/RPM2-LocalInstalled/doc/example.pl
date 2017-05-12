#!/usr/bin/perl

use strict;
use warnings;

use RPM2::LocalInstalled;
use Data::Dumper;

my $rpms = RPM2::LocalInstalled->new({ tags => [ qw/packager/ ] });

print Dumper($rpms->list_newest());
