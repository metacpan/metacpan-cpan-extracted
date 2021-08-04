#!perl

use Test::More;
use Test::Deep;
use File::Basename;
use autodie;
use FindBin;

plan 'tests' => 6;

use Pg::Explain;

my $plan = join '', <DATA>;

my $explain = Pg::Explain->new( 'source' => $plan );
isa_ok( $explain, 'Pg::Explain' );
$explain->parse_source();

isa_ok( $explain->top_node, 'Pg::Explain::Node' );

# Check if node types are OK.
is( $explain->top_node->type,                                             'Hash Join', 'Correct type - top_node' );
is( $explain->top_node->sub_nodes->[ 0 ]->type,                           'Seq Scan',  'Properly got top->child(1) type' );
is( $explain->top_node->ctes->{ 'artist_count' }->type,                   'Limit',     'Properly got top->cte type' );
is( $explain->top_node->ctes->{ 'artist_count' }->sub_nodes->[ 0 ]->type, 'Sort',      'Properly got top->cte->child(1) type' );

exit;

__DATA__
Hash Join  (cost=17116.79..44169.26 rows=4827 width=25)
   Hash Cond: (artist.area = country.id)
   CTE artist_count
 	->  Limit  (cost=17111.20..17111.20 rows=1 width=12)
       	->  Sort  (cost=17111.20..17111.58 rows=152 width=12)
             	Sort Key: (count(*)) DESC
             	->  Finalize GroupAggregate  (cost=17071.93..17110.44 rows=152 width=12)
                   	Group Key: artist_1.area
                   	->  Gather Merge  (cost=17071.93..17107.40 rows=304 width=12)
                         	Workers Planned: 2
                         	->  Sort  (cost=16071.91..16072.29 rows=152 width=12)
                               	Sort Key: artist_1.area
                               	->  Partial HashAggregate  (cost=16064.88..16066.40 rows=152 width=12)
                                     	Group Key: artist_1.area
                                     	->  Parallel Seq Scan on artist artist_1  (cost=0.00..15146.88 rows=183599 width=4)
                                           	Filter: (area IS NOT NULL)
   ->  Seq Scan on artist  (cost=0.00..22383.32 rows=1240532 width=18)
   ->  Hash  (cost=5.58..5.58 rows=1 width=19)
     	->  Hash Join  (cost=0.03..5.58 rows=1 width=19)
           	Hash Cond: (country.id = artist_count.area)
           	->  Seq Scan on country  (cost=0.00..4.57 rows=257 width=15)
           	->  Hash  (cost=0.02..0.02 rows=1 width=4)
                 	->  CTE Scan on artist_count  (cost=0.00..0.02 rows=1 width=4)
