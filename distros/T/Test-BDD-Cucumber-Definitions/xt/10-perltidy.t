#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

if ( !$ENV{RELEASE_TESTING} ) {
    my $msg = 'Author test.  Set $ENV{RELEASE_TESTING} to a true value to run.';
    plan( skip_all => $msg );
}

eval { use Test::PerlTidy; };

if ($@) {
    my $msg = 'Test::PerlTidy required to criticise code';
    plan( skip_all => $msg );
}

run_tests( path => 'lib' );
