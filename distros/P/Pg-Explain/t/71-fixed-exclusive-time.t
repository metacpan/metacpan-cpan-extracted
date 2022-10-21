#!perl

use strict;
use Test::More;
use File::Basename;
use FindBin;
use Pg::Explain;
use List::Util qw( sum );

our $data_dir = sprintf '%s/%s.d', $FindBin::Bin, basename( $0, '.t' );

opendir my $dir, $data_dir;
my @tests = sort { $a <=> $b } grep { s/^(\d+)\.plan$/$1/ } readdir $dir;
closedir $dir;

# tests * formats * tests
plan 'tests' => 2 * scalar @tests;

for my $test ( @tests ) {
    my $plan = Pg::Explain->new( 'source_file' => $data_dir . '/' . $test . '.plan' );
    $plan->parse_source();

    my $sum_exclusive = sum( map { $_->total_exclusive_time // 0 } ( $plan->top_node, $plan->top_node->all_recursive_subnodes ) );

    # These are floats, and there are some roundings, so I accept values in range
    my $real_time_last = $plan->top_node->actual_time_last;
    my $expected_min   = $real_time_last * 0.99;
    $expected_min = $real_time_last - 0.002 if $real_time_last - 0.002 < $expected_min;
    my $expected_max = $real_time_last * 1.01;
    $expected_max = $real_time_last + 0.002 if $real_time_last + 0.002 > $expected_max;

    ok(
        ( $sum_exclusive >= $expected_min ) && ( $sum_exclusive <= $expected_max ),
        "($test) Sum of exclusive times ($sum_exclusive) is withing expected range [ $expected_min, $expected_max ]"
      );
    ok(
        $plan->top_node->total_exclusive_time > 0,
        "($test) top node has non-zero exclusive time (" . $plan->top_node->total_exclusive_time . ")"
      );

}

exit;
