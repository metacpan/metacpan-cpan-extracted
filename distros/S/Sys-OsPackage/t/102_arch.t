#!/usr/bin/perl
#===============================================================================
#         FILE: 102_arch.t
#  DESCRIPTION: container test with Arch
#       AUTHOR: Ian Kluft (IKLUFT),
#      CREATED: 05/05/2022 13:37:00 PM
#===============================================================================

# container tests are expensive and only for release candidate tests, or for advanced users who want to run them
BEGIN {
    unless ( $ENV{RELEASE_TESTING} ) {
        print qq{1..0 # SKIP container tests are for release candidate testing\n};
        exit;
    }
}

# Test Anything Protocol (TAP) output will come from the container
use strict;
use warnings;
exec "perl", "t/testcon.pl", "--arch";
