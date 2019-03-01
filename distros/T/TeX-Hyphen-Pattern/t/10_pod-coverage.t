#!/usr/bin/env perl -w    # -*- cperl -*-
use strict;
use warnings;
use 5.014000;
use utf8;

use Test::More;

our $VERSION = v1.1.1;

if ( not $ENV{'AUTHOR_TESTING'} ) {
    my $msg =
q{Author test. Set the environment variable AUTHOR_TESTING to enable this test.};
    plan( 'skip_all' => $msg );
}

eval {
    require Test::Pod::Coverage;
    1;
} or do {
    my $msg = q{Test::Pod::Coverage 1.00 required to check spelling of POD};
    plan 'skip_all' => $msg;
};

Test::Pod::Coverage::all_pod_coverage_ok();
