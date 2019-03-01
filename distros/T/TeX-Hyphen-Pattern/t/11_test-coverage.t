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
    plan 'skip_all' => $msg;
}

eval {
    require Test::TestCoverage;
    1;
} or do {
    my $msg = q{Test::TestCoverage 0.08 required to check spelling of POD};
    plan 'skip_all' => $msg;
};

plan 'tests' => 1;
Test::TestCoverage::test_coverage('TeX::Hyphen::Pattern');

my $thp = TeX::Hyphen::Pattern->new();
$thp->label(q{nl});
$thp->filename();
$thp->meta();
$thp->packaged();
$thp->DESTROY();

Test::TestCoverage::ok_test_coverage('TeX::Hyphen::Pattern');
