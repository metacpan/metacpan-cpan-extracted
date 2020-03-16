
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

use strict;
use warnings;
use Test::More;
use FASTX::Reader;
my $raw_version = $FASTX::Reader::VERSION;
my ($version) = $raw_version=~/^(\d+.\d+)/;
ok($version > 0.5, "FASTX::Reader is updated (version: $raw_version)");
done_testing(); 
