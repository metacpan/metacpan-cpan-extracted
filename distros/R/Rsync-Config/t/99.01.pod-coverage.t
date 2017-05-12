#!/usr/bin/perl
# $Id: 99.01.pod-coverage.t,v 1.1 2006/12/21 23:05:24 altblue Exp $
use strict;
use warnings;
our $VERSION = sprintf '0.%d.%d', '\$Revision: 1.1 $' =~ /(\d+)\.(\d+)/xm;
use Test::More;
use English qw( -no_match_vars );

if ( $ENV{TEST_FAST} ) {
    plan skip_all => 'Fast tests only';
}

if ( getpwuid($UID) ne 'diablo' ) {
    plan skip_all => q{It's author's job to check POD coverage'};
}

eval { require Test::Pod::Coverage };
if ($EVAL_ERROR) {
    plan skip_all =>
        'Test::Pod::Coverage is required for testing POD coverage';
}
Test::Pod::Coverage->import;

all_pod_coverage_ok();
