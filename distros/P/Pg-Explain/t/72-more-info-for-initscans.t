#!perl

use strict;
use Test::More;
use File::Basename;
use FindBin;
use Pg::Explain;

our $data_dir = sprintf '%s/%s.d', $FindBin::Bin, basename( $0, '.t' );
my $expect_struct = [ { 'name' => '1', 'returns' => '$0,$1', }, ];

# 3 tests for 4 formats;
plan 'tests' => 3 * 4;

for my $test ( qw( text json yaml xml ) ) {
    my $plan = Pg::Explain->new( 'source_file' => $data_dir . '/plan.' . $test );
    $plan->parse_source();

    is_deeply( $plan->top_node->initplans_metainfo,                   $expect_struct, "($test) Correct node->initplans_metainfo" );
    is_deeply( $plan->top_node->get_struct->{ 'initplans_metainfo' }, $expect_struct, "($test) Correct node->get_struct->initplans_metainfo" );

    my $replan = Pg::Explain->new( 'source' => $plan->as_text );
    $replan->parse_source;
    is_deeply( $replan->get_struct, $plan->get_struct, "($test) Replan has correct struct" );
}

exit;
