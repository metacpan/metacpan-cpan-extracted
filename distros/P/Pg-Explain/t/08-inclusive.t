#!perl

use Test::More;
use Test::Deep;
use Data::Dumper;
use autodie;

use Pg::Explain;

plan 'tests' => 7;

my $explain = Pg::Explain->new( 'source_file' => 't/plans/10-plan', );

my $top = $explain->top_node;
is( $top->actual_loops, 1, '1 loop' );
is( $top->actual_time_last, 126.517, '126.517 - time of getting last record from single loop' );
is( $top->total_inclusive_time, 126.517, 'total inclusive time (126.517 - because only single loop)');

my $sub = $top->sub_nodes->[0];
$sub = $sub->sub_nodes->[1];

is( $sub->actual_loops, 588, '588 loops' );
is( $sub->actual_time_last, 0.007, '0.007 - time of getting last record from single loop' );
is( $sub->total_inclusive_time, 0.007 * 588, 'total inclusive time (0.007ms * 588 loops)');


my $plan = 'Seq Scan on tenk1  (cost=0.00..333.00 rows=10000 width=148)';
$explain = Pg::Explain->new( 'source' => $plan );
is( $explain->top_node->total_inclusive_time, undef, 'time cannot be defined as this is explain output, and not explain analyze' );

