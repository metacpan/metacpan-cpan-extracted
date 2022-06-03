#!/usr/bin/perl
#===============================================================================
#         FILE: 106_kali.t
#  DESCRIPTION: container test with Kali Linux
#       AUTHOR: Ian Kluft (IKLUFT), 
#      CREATED: 06/02/2022 15:33:00 PM
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
exec "perl", "t/testcon.pl", "--kalilinux";
