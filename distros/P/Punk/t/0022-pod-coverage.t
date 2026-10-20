#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

# The AWAIT_* methods are the Future::AsyncAwait::Awaitable protocol, called
# by that module rather than by a user, and documented as a whole under
# Punk::Future's ASYNC/AWAIT section rather than one entry at a time.
#
# blib/arch/Punk/Install/Files.pm is ExtUtils::Depends' generated record of
# the headers, not a module of this distribution, and all_modules finds it
# as arch::Punk::Install::Files.
my @modules = grep { !/^arch::/ } all_modules();
plan tests => scalar @modules;
pod_coverage_ok($_, { also_private => [qr/^AWAIT_/] }) for @modules;
