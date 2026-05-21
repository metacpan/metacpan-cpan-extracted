
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

use Test::More;
use File::Spec;

my @scripts = sort glob 'examples/*.pl';

plan skip_all => 'no example scripts found in examples/' unless @scripts;
plan tests    => scalar @scripts;

my $devnull = File::Spec->devnull;

for my $script (@scripts) {
    my $status = system qq{"$^X" -Ilib "$script" > $devnull 2>&1};
    is( $status, 0, "$script runs to a clean exit" );
}
