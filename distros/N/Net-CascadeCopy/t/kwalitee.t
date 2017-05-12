#!/usr/bin/perl

# Test that the module passes perlcritic
use strict;
BEGIN {
    $|  = 1;
    $^W = 1;
}

# Don't run tests during end-user installs
use Test::More;
plan( skip_all => 'Author tests not required for installation' )
    unless ( $ENV{RELEASE_TESTING} );

eval "use Test::Kwalitee";
if ( $@ ) {
    $ENV{RELEASE_TESTING}
        ? die( "Failed to load required release-testing module Test::Kwalitee" )
            : plan( skip_all => "Test::Kwalitee not available for testing" );
}

1;
