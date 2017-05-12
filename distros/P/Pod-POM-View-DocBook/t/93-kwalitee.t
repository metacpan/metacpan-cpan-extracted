#!/usr/bin/perl
# $Id: 93-kwalitee.t 4105 2009-03-03 09:50:27Z andrew $

use Test::More;

eval {
    require Test::Kwalitee;

    # Skip Pod tests - they are tested by other unit tests anyway
    Test::Kwalitee->import( tests => [ qw( -no_pod_errors -has_test_pod -has_test_pod_coverage ) ] ) };

plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;
