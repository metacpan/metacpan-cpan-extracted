#!perl
use Test::More tests => 2;

use Pg::Explain;

my $plan = 'Seq Scan on tenk1  (cost=0.00..333.00 rows=10000 width=148)';

my $expected_output = {
    'estimated_row_width'    => 148,
    'estimated_rows'         => 10000,
    'estimated_startup_cost' => 0,
    'estimated_total_cost'   => 333,
    'type'                   => 'Seq Scan',
    'scan_on'                => { 'table_name' => 'tenk1', },
    'is_analyzed'            => 0,
};

my $explain = Pg::Explain->new( 'source' => $plan );

isa_ok( $explain, 'Pg::Explain' );

is_deeply( $explain->top_node->get_struct(), $expected_output, 'Simple plan passed as string', );
