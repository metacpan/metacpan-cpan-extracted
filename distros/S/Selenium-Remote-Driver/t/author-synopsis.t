#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print "1..0 # SKIP these tests are for testing by the author\n";
    exit
  }
}


use Test::Synopsis;

all_synopsis_ok();
