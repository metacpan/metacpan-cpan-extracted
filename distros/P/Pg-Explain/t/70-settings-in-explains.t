#!perl

use strict;
use Test::More;
use Test::Deep;
use File::Basename;
use FindBin;
use Pg::Explain;

our $data_dir = sprintf '%s/%s.d', $FindBin::Bin, basename( $0, '.t' );

my @formats = qw( text json yaml xml );
plan 'tests' => 12;

# No settings plans
for my $format ( @formats ) {
    my $source_file = "$data_dir/no-settings-$format.plan";
    my $explain     = Pg::Explain->new( 'source_file' => $source_file );
    $explain->parse_source();
    ok( !defined $explain->settings, "No settings in $source_file" );
}

# Plans with single settings
for my $format ( @formats ) {
    my $source_file = "$data_dir/single-$format.plan";
    my $explain     = Pg::Explain->new( 'source_file' => $source_file );
    $explain->parse_source();
    cmp_deeply(
        $explain->settings,
        {
            'random_page_cost' => '13.666',
        },
        "Proper settings in $source_file"
    );
}

# Plans with multiple settings
for my $format ( @formats ) {
    my $source_file = "$data_dir/multi-$format.plan";
    my $explain     = Pg::Explain->new( 'source_file' => $source_file );
    $explain->parse_source();
    cmp_deeply(
        $explain->settings,
        {
            'random_page_cost' => '13.666',
            'search_path'      => 'public, test',
            'work_mem'         => '666MB',
        },
        "Proper settings in $source_file"
    );
}

exit;
