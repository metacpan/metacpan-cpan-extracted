use strict;
use warnings;
use Test::More;

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all =>
    "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

my @drivers;
my @modules
    = grep { $_ ne 'Test::Database' }
    grep { !/Driver::/ or push @drivers, $_ and 0 } all_modules();

plan tests => @modules + @drivers + 1;

# Test::Database exports are not documented
pod_coverage_ok( 'Test::Database', { trustme => [qr/^test_db_\w+$/] } );

# no exception for those modules
pod_coverage_ok($_) for @modules;

# the drivers methods are documented Test::Database::Driver
pod_coverage_ok(
    $_,
    {   trustme => [
            qr/^(?:(?:create|drop)_database|databases|dsn|is_filebased|cleanup|essentials)$/
        ]
    }
) for @drivers;

