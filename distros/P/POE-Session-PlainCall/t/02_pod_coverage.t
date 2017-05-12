#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

plan tests => 1;
pod_coverage_ok(
        "POE::Session::PlainCall",
        { also_private => [ 
                    qr/^(SE|EN|OPT)_.+$/,
                    qr/^(instantiate)$/
                ], 
        },
        "POE::Session::PlainCall, ignoring private functions",
);
