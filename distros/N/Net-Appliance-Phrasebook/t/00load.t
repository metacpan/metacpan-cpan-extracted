#!/usr/bin/perl

use strict;
use Test::More tests => 1;

my $class;
BEGIN {
    $class = 'Net::Appliance::Phrasebook';
    use_ok($class);
}
