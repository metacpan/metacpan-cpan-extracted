#!/usr/bin/env perl
#
# $Id: 03pod-coverage.t,v 1.3 2007/05/04 07:33:34 hironori.yoshida Exp $
#
use strict;
use warnings;
use version; our $VERSION = qv('1.3.1');

use English qw(-no_match_vars);
use Test::More;

if ( $ENV{TEST_POD} || $ENV{TEST_ALL} || !$ENV{HARNESS_ACTIVE} ) {
    eval {
        require Test::Pod::Coverage;
        Test::Pod::Coverage->import;
    };
    if ($EVAL_ERROR) {
        plan skip_all =>
          'Test::Pod::Coverage required for testing POD coverage';
    }
}
else {
    plan skip_all => 'set TEST_POD for testing POD coverage';
}

all_pod_coverage_ok();
