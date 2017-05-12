#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

plan tests => 2;
pod_coverage_ok(
        "POEx::URI",
        { also_private => [ qw( DEBUG query query_form fragment abs rel ) ], 
        },
        "POE::URI, ignoring private functions",
);

pod_coverage_ok(
        "URI::poe",
        { also_private => [ qw( DEBUG ) ], 
        },
        "URI::poe, ignoring private functions",
);
