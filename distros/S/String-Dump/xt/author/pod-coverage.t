use strict;
use warnings;
use Test::More;

eval 'use Test::Pod::Coverage 1.00';
plan skip_all => 'Test::Pod::Coverage 1.00 not installed; skipping' if $@;

# TODO: remove trustme when we ditch dumpstr dump_string
all_pod_coverage_ok({ trustme => [qw< dumpstr dump_string >] });
