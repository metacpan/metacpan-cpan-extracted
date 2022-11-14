#!perl

use Test::More;
use Test::Deep;
use Test::Exception;
use autodie;
plan 'tests' => 3;

use Pg::Explain;

my $plan_source = q{                                                                  QUERY PLAN
──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
 Sort  (cost=32.93..33.01 rows=32 width=224) (actual time=0.621..0.626 rows=8 loops=1)
   Sort Key: n.nspname, c.relname
   Sort Method: quicksort  Memory: 27kB
   ->  Hash Join  (cost=1.09..32.13 rows=32 width=224) (actual time=0.137..0.597 rows=8 loops=1)
         Hash Cond: (c.relnamespace = n.oid)
         ->  Seq Scan on pg_class c  (cost=0.00..29.89 rows=65 width=73) (actual time=0.032..0.445 rows=137 loops=1)
               Filter: ((relkind = ANY ('{r,p,v,m,S,f,""}'::"char"[])) AND pg_table_is_visible(oid))
               Rows Removed by Filter: 258
         ->  Hash  (cost=1.07..1.07 rows=2 width=68) (actual time=0.065..0.066 rows=1 loops=1)
               Buckets: 1024  Batches: 1  Memory Usage: 9kB
               ->  Seq Scan on pg_namespace n  (cost=0.00..1.07 rows=2 width=68) (actual time=0.039..0.041 rows=1 loops=1)
                     Filter: ((nspname <> 'pg_catalog'::name) AND (nspname <> 'information_schema'::name) AND (nspname !~ '^pg_toast'::text))
                     Rows Removed by Filter: 3
 Planning Time: 0.626 ms
 Execution Time: 0.713 ms
(15 rows)
};
my $text_1  = 'Something about pg_class';
my $text_2  = 'Something about other stuff';
my $explain = Pg::Explain->new( 'source' => $plan_source );
$explain->parse_source;
$explain->anonymize;
my $first = $explain->as_text;

my $anon_t1 = $explain->anonymize( $text_1 );
my $anon_t2 = $explain->anonymize( $text_2 );
my $second  = $explain->as_text;

is( $first, $second, 'Two anonymized texts of plans are the same' );
isnt( $anon_t1, $text_1, 'Text 1 properly anonymized' );
is( $anon_t2, $text_2, 'Text 2 not anonymized, as it has no "bad" words' );

exit;

