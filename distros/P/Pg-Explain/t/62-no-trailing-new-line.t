#!perl

use strict;
use Test::More;
use Test::Exception;
use autodie;
use Pg::Explain;

plan 'tests' => 4;

my $plan = '"Result  (cost=0.00..0.26 rows=1 width=8) (actual time=0.373..0.373 rows=1 loops=1)"' . "\r\n";
$plan .= '"Planning time: 0.034 ms"' . "\r\n";
$plan .= '"Execution time: 0.388 ms"';

my $explain = Pg::Explain->new( 'source' => $plan );
lives_ok( sub { $explain->parse_source(); }, 'Parsing lives' );
is( $explain->top_node->type, 'Result', 'Top node is Result' );
is( $explain->planning_time,  0.034,    'Planning time extracted' );
is( $explain->execution_time, 0.388,    'Execution time extracted' );

exit;
