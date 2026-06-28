#!/usr/bin/env perl
#
# t/02-primitives.t — Test PDF::Make primitive type constants
#
# Phase 02 implements C primitives; this test verifies the Perl-side
# constants match and the module loads correctly.

use strict;
use warnings;
use Test::More tests => 14;

BEGIN {
    use_ok('PDF::Make');
    use_ok('PDF::Make::Obj', qw(:kinds));
}

# Test kind constants
is(KIND_NULL,   0, 'KIND_NULL is 0');
is(KIND_BOOL,   1, 'KIND_BOOL is 1');
is(KIND_INT,    2, 'KIND_INT is 2');
is(KIND_REAL,   3, 'KIND_REAL is 3');
is(KIND_NAME,   4, 'KIND_NAME is 4');
is(KIND_STR,    5, 'KIND_STR is 5');
is(KIND_ARRAY,  6, 'KIND_ARRAY is 6');
is(KIND_DICT,   7, 'KIND_DICT is 7');
is(KIND_STREAM, 8, 'KIND_STREAM is 8');
is(KIND_REF,    9, 'KIND_REF is 9');

# Verify version string exists
my $version = PDF::Make::version();
ok(defined $version, 'PDF::Make::version() returns defined value');
like($version, qr/^\d+\.\d+/, 'version looks like a version number');

done_testing();
