#!/usr/bin/env perl

use strict;
use Test::More tests => 9;

use_ok('Number::Phone::CountryCode') or exit 1;

# make sure api works like it should
my $pc = Number::Phone::CountryCode->new('AF');
isa_ok $pc, 'Number::Phone::CountryCode';
is $pc->country, 'AF';
is $pc->country_code, '93';
is $pc->ndd_prefix, '0';
is $pc->idd_prefix, '00';

# test class methods
ok Number::Phone::CountryCode->is_supported('US');
ok !Number::Phone::CountryCode->is_supported('XX');

my @codes = Number::Phone::CountryCode->countries;
ok @codes > 0;
