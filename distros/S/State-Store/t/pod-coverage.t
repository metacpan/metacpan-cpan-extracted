#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

# Over lib/, not blib/: all_pod_coverage_ok walks blib when it exists, and
# blib/arch carries the Install/Files.pm ExtUtils::Depends writes for
# consumers, which has no POD and is not this dist's to document.
my @modules = all_modules('lib');
plan tests => scalar @modules;

# Every method has its own =head2, so Pod::Coverage finds them itself and
# needs no trustme list. A method added without one fails this test.
pod_coverage_ok($_) for @modules;
