#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

plan tests => 1;

pod_coverage_ok(
        "POE::Wheel::Sendfile",
        { also_private => [ qw( EVENT_ERROR EVENT_FLUSHED STATE_SENDFILE 
                                HANDLE_OUTPUT SENDFILE STATE_WRITE UNIQUE_ID
                                DEBUG AUTOFLUSH DRIVER_BOTH) ], 
        },
        "POE::Wheel::Sendfile, ignoring private functions",
);

