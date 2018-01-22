#!perl

use strict;
use warnings;

use lib '.';
use t::lib::Utils qw/base_tests/;
use Test::More 'tests' => 11;

# run base tests on actual system
my $hostip = Sys::HostIP->new;
base_tests($hostip);
