#!perl

use Test::More;
use Test::Deep;
use Pg::Explain;

plan 'tests' => 2;

my $explain = Pg::Explain->new( 'source_file' => 't/plans/19-plan' );

$explain->parse_source();
my $top_node = $explain->top_node;

my $counts = {};

for my $node ( $top_node, $top_node->all_recursive_subnodes ) {
    my @path = map { $_->type } $node->all_parents();
    push @path, $node->type;
    my $path_str = join ' -> ', @path;
    $counts->{ $path_str }++;
}

my $expect = {
    'Sort'                                                                                                                  => 1,
    'Sort -> Nested Loop Left Join'                                                                                         => 1,
    'Sort -> Nested Loop Left Join -> Hash Left Join'                                                                       => 1,
    'Sort -> Nested Loop Left Join -> Hash Left Join -> Hash'                                                               => 1,
    'Sort -> Nested Loop Left Join -> Hash Left Join -> Aggregate'                                                          => 1,
    'Sort -> Nested Loop Left Join -> Hash Left Join -> Aggregate -> Bitmap Heap Scan'                                      => 1,
    'Sort -> Nested Loop Left Join -> Hash Left Join -> Aggregate -> Bitmap Heap Scan -> Bitmap Index Scan'                 => 1,
    'Sort -> Nested Loop Left Join -> Hash Left Join -> Hash -> Seq Scan'                                                   => 1,
    'Sort -> Nested Loop Left Join -> Hash Left Join -> Merge Join'                                                         => 1,
    'Sort -> Nested Loop Left Join -> Hash Left Join -> Merge Join -> Sort'                                                 => 2,
    'Sort -> Nested Loop Left Join -> Hash Left Join -> Merge Join -> Sort -> Function Scan'                                => 1,
    'Sort -> Nested Loop Left Join -> Hash Left Join -> Merge Join -> Sort -> Nested Loop'                                  => 1,
    'Sort -> Nested Loop Left Join -> Hash Left Join -> Merge Join -> Sort -> Nested Loop -> Hash Join'                     => 1,
    'Sort -> Nested Loop Left Join -> Hash Left Join -> Merge Join -> Sort -> Nested Loop -> Hash Join -> Hash'             => 1,
    'Sort -> Nested Loop Left Join -> Hash Left Join -> Merge Join -> Sort -> Nested Loop -> Hash Join -> Hash -> Seq Scan' => 1,
    'Sort -> Nested Loop Left Join -> Hash Left Join -> Merge Join -> Sort -> Nested Loop -> Hash Join -> Seq Scan'         => 1,
    'Sort -> Nested Loop Left Join -> Hash Left Join -> Merge Join -> Sort -> Nested Loop -> Index Scan'                    => 1,
    'Sort -> Nested Loop Left Join -> Index Scan'                                                                           => 1,
};

cmp_deeply( $counts,                    $expect, "Got all nodes" );
cmp_deeply( [ $top_node->all_parents ], [],      "Parents of top node" );

