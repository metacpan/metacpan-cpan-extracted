#!perl
use strict;
use warnings;
use Test::More;

use Test::Pod::Coverage 1.08;
use Pod::Coverage 0.18;

# Sorry but...
my @files = @ARGV ? @ARGV : all_modules("lib");
die "No pod files!" unless grep { /::/ } @files;

foreach ( @files ) {
    pod_coverage_ok($_);
};

done_testing;
