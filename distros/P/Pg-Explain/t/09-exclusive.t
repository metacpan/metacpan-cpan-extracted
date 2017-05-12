#!perl

use Test::More;
use Test::Deep;
use Data::Dumper;
use autodie;

use Pg::Explain;

plan 'tests' => 4;

my $explain = Pg::Explain->new( 'source_file' => 't/plans/10-plan', );

my $top = $explain->top_node;
ok(
    abs( $top->total_exclusive_time - 0.029 ) < 0.001,    # it's float so i have to use < instead of = 0
    'total exclusive time (0.029) - calculated exclusive time of node'
  );
my $sub = $top->sub_nodes->[ 0 ];
$sub = $sub->sub_nodes->[ 1 ];
is( $sub->total_exclusive_time, 0.007 * 588, 'same as total_inclusive_time since there are no subnodes/initplans/subplans' );

$explain = Pg::Explain->new( 'source_file' => 't/plans/13-plan', );
$top = $explain->top_node;
ok( abs($top->total_exclusive_time - 1.694 ) < 0.001, 'total exclusive time (1.694)');

my $plan = 'Seq Scan on tenk1  (cost=0.00..333.00 rows=10000 width=148)';
$explain = Pg::Explain->new( 'source' => $plan );
is( $explain->top_node->total_exclusive_time, undef, 'time cannot be defined as this is explain output, and not explain analyze' );

