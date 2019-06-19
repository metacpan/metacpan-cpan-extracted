#!perl

use Test::More;
use Test::Deep;
use Test::Exception;
use Data::Dumper;
use autodie;

use Pg::Explain;

my $plan = q{
 CTE Scan on foo  (cost=4.03..6.05 rows=101 width=4)
   CTE foo
     ->  Recursive Union  (cost=0.00..4.03 rows=101 width=4)
           ->  Result  (cost=0.00..0.01 rows=1 width=4)
           ->  WorkTable Scan on foo foo_1  (cost=0.00..0.20 rows=10 width=4)
};
my $expected_struct = {
    'estimated_rows'         => '10',
    'estimated_row_width'    => '4',
    'estimated_startup_cost' => '0',
    'estimated_total_cost'   => '0.2',
    'is_analyzed'            => 0,
    'type'                   => 'WorkTable Scan',
    'scan_on'                => {
        'worktable_alias' => 'foo_1',
        'worktable_name'  => 'foo'
    }
};

plan 'tests' => 7;

my $explain = Pg::Explain->new( 'source' => $plan );
isa_ok( $explain,           'Pg::Explain' );
isa_ok( $explain->top_node, 'Pg::Explain::Node' );
is( $explain->top_node->type,                                    'CTE Scan',        'Properly got top node type' );
is( $explain->top_node->ctes->{ 'foo' }->type,                   'Recursive Union', 'Properly got top->cte type' );
is( $explain->top_node->ctes->{ 'foo' }->sub_nodes->[ 0 ]->type, 'Result',          'Properly got top->cte->child(1) type' );

my $work_table = $explain->top_node->ctes->{ 'foo' }->sub_nodes->[ 1 ];
is( $work_table->type, 'WorkTable Scan', 'Properly got WorkTable type' );

cmp_deeply( $work_table->get_struct, $expected_struct, 'Structure of WorkTable is OK');

exit;
