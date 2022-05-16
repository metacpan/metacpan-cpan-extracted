#!/usr/bin/perl
#===============================================================================
#         FILE: 104_fedora.t
#  DESCRIPTION: container test with Fedora
#       AUTHOR: Ian Kluft (IKLUFT), 
#      CREATED: 05/03/2022 08:15:00 PM
#===============================================================================

# container tests are expensive and only for release candidate tests, or for advanced users who want to run them
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP container tests are for release candidate testing\n};
    exit;
  }
}

# Test Anything Protocol (TAP) output will come from the container
use strict;
use warnings;
exec "perl", "t/testcon.pl", "--fedora";
