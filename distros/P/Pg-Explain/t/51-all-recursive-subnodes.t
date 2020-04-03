#!perl

use Test::More;
use Test::Exception;
use Test::Deep;
use Pg::Explain;

plan 'tests' => 1;

my $explain  = Pg::Explain->new( 'source_file' => 't/plans/19-plan' );
my $top_node = $explain->top_node;

my $counts = {};
for my $type ( map { $_->type } ( $top_node, $top_node->all_recursive_subnodes ) ) {
    $counts->{ $type }++;
}

my $expect = {
    'Aggregate'             => 1,
    'Bitmap Heap Scan'      => 1,
    'Bitmap Index Scan'     => 1,
    'Function Scan'         => 1,
    'Hash'                  => 2,
    'Hash Join'             => 1,
    'Hash Left Join'        => 1,
    'Index Scan'            => 2,
    'Merge Join'            => 1,
    'Nested Loop'           => 1,
    'Nested Loop Left Join' => 1,
    'Seq Scan'              => 3,
    'Sort'                  => 3,
};

cmp_deeply( $counts, $expect, "Got all nodes" );
