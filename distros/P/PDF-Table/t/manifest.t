#!perl -T
use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;

my $min_tcm = 0.9;
# Windows: SET AUTHOR_TESTING=1

BEGIN {
  unless ($ENV{'AUTHOR_TESTING'}) {
    print qq{1..0 # SKIP Test::CheckManifest, for testing by the author\n};
    exit
  }
}

eval "use Test::CheckManifest $min_tcm";
plan skip_all => "Test::CheckManifest $min_tcm required" if $@;
ok_manifest();

1;
