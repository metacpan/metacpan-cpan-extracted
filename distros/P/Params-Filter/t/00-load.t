#!/usr/bin/env perl

use strict;
use warnings;
use Test2::V0;

use Params::Filter;

ok(1, 'Module loaded successfully');

# Test that filter function is available for explicit import
use Params::Filter qw/filter/;
can_ok('main', 'filter');

# Test that new_filter method exists
can_ok('Params::Filter', 'new_filter');

# Test that apply method exists
my $filter = Params::Filter->new_filter({});
can_ok($filter, 'apply');

done_testing();
