#!perl

use Test::More;
use autodie;

use Pg::Explain;

my $plan = q{
 Sort  (cost=146.63..148.65 rows=808 width=138) (actual time=55.009..55.012 rows=71 loops=1)
   Sort Key: n.nspname, p.proname, (pg_get_function_arguments(p.oid))
   Sort Method: quicksort  Memory: 43kB
   ->  Hash Join  (cost=1.14..107.61 rows=808 width=138) (actual time=42.495..54.854 rows=71 loops=1)
         Hash Cond: (p.pronamespace = n.oid)
         ->  Seq Scan on pg_proc p  (cost=0.00..89.30 rows=808 width=78) (actual time=0.052..53.465 rows=2402 loops=1)
               Filter: pg_function_is_visible(oid)
         ->  Hash  (cost=1.09..1.09 rows=4 width=68) (actual time=0.011..0.011 rows=4 loops=1)
               Buckets: 1024  Batches: 1  Memory Usage: 1kB
               ->  Seq Scan on pg_namespace n  (cost=0.00..1.09 rows=4 width=68) (actual time=0.005..0.007 rows=4 loops=1)
                     Filter: ((nspname <> 'pg_catalog'::name) AND (nspname <> 'information_schema'::name))"></textarea>
};

plan 'tests' => 9;

my $explain = Pg::Explain->new( 'source' => $plan );
$explain->parse_source;

my @all_nodes = ( $explain->top_node, $explain->top_node->all_recursive_subnodes );

my %seen = ();
for my $node ( @all_nodes ) {
    $seen{ $node->id }++;
}
my @numerical  = grep { $_ =~ m{\A[1-9]\d*\z} } keys %seen;
my @duplicated = grep { $seen{ $_ } > 1 } keys %seen;

is( scalar @all_nodes,  5, 'Five nodes' );
is( scalar keys %seen,  5, 'Five unique ids' );
is( scalar @numerical,  5, 'Five numerical ids' );
is( scalar @duplicated, 0, 'No duplicated ids' );

for my $node ( @all_nodes ) {
    my $id                = $node->id;
    my $node_from_explain = $explain->node( $id );
    is( $node_from_explain, $node, "Node ${id} fetched successfully from explain." );
}

exit;
