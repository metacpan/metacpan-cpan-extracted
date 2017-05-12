#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

my $has_xs = eval "require Package::Stash::XS; 1";

require Package::Stash;

no warnings 'once';

my $expected = $has_xs ? 'XS' : 'PP';
is($Package::Stash::IMPLEMENTATION, $expected,
   "autodetected properly: $expected");
can_ok('Package::Stash', 'new');

done_testing;
