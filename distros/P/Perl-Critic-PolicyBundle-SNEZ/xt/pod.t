#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

BEGIN { plan skip_all => 'TEST_AUTHOR not enabled' if not $ENV{TEST_AUTHOR}; }

use Test::Pod::Coverage;

all_pod_coverage_ok({
    trustme        => [qr/\Asupported_parameters\z/],  # documented indirectly
    coverage_class => 'Pod::Coverage::CountParents',
});
