#!perl

use Test::More;
use Test::Deep;
use Data::Dumper;
use autodie;

use Pg::Explain;

plan 'tests' => 18;

my $explain = Pg::Explain->new( 'source_file' => 't/plans/10-plan', );
isa_ok( $explain, 'Pg::Explain' );

my $top = $explain->top_node;
isa_ok( $top, 'Pg::Explain::Node' );
is( $top->type, 'Limit', 'Type of top node: Limit' );

is( $top->actual_loops, 1, '1 loop' );
is( $top->actual_time_last, 126.517, '126.517 - time of getting last record from single loop' );

is( ref($top->sub_nodes), 'ARRAY', 'sub_nodes exist' );
is( scalar @{ $top->sub_nodes }, 1, '1 sub_node exists' );

my $sub = $top->sub_nodes->[0];
isa_ok( $sub, 'Pg::Explain::Node' );
is( $sub->type, 'Nested Loop', 'Type of sub node: Nested Loop' );

is( ref($sub->sub_nodes), 'ARRAY', 'sub_nodes exist' );
is( scalar @{ $sub->sub_nodes }, 2, '2 sub_nodes exist' );

$sub = $sub->sub_nodes->[1];
isa_ok( $sub, 'Pg::Explain::Node' );
is( $sub->type, 'Index Scan', 'Type of sub node: Index Scan' );

is( ref($sub->sub_nodes), '', 'no subnodes' );

is( $sub->actual_loops, 588, '588 loops' );
is( $sub->actual_time_last, 0.007, '0.007 - time of getting last record from single loop' );


my $plan = 'Seq Scan on tenk1  (cost=0.00..333.00 rows=10000 width=148)';

$explain = Pg::Explain->new( 'source' => $plan );

isa_ok( $explain, 'Pg::Explain' );

is( $explain->top_node->type, 'Seq Scan', 'Type of top node: Seq Scan' );

exit;
