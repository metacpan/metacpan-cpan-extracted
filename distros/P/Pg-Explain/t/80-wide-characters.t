#!perl

use strict;
use Test::More;
use File::Basename;
use Test::Exception;
use FindBin;
use Pg::Explain;
use Encode qw( encode );

our $data_dir = sprintf '%s/%s.d', $FindBin::Bin, basename( $0, '.t' );
my $expect_struct = [ { 'name' => '1', 'returns' => '$0,$1', }, ];

# 3 tests for 4 formats;
plan 'tests' => 2 * 4;

for my $test ( qw( text json yaml xml ) ) {
    my $plan = Pg::Explain->new( 'source_file' => $data_dir . '/wide-characters-explain.' . $test );
    lives_ok( sub { $plan->parse_source(); }, "Parsing ${test} plan worked" );
    my $has_turtle = 0;    # żółw in Polish means turtle
    for my $info ( @{ $plan->top_node->extra_info } ) {
        $has_turtle = 1 if encode( 'UTF-8', $info ) =~ m{żółw};
    }
    is( $has_turtle, 1, "There is turtle in ${test}" );
}

exit;
