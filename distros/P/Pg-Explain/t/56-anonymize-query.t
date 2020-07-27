#!perl

use Test::More;
use Test::Deep;
use Test::Exception;
use autodie;
plan 'tests' => 15;

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

my $query = q{SELECT n.nspname as "Schema",
  c.relname as "Name",
  CASE c.relkind WHEN 'r' THEN 'table' WHEN 'v' THEN 'view' WHEN 'm' THEN 'materialized view' WHEN 'i' THEN 'index' WHEN 'S' THEN 'sequence' WHEN 's' THEN 'special' WHEN 'f' THEN 'foreign table' WHEN 'p' THEN 'partitioned table' WHEN 'I' THEN 'partitioned index' END as "Type",
  pg_catalog.pg_get_userbyid(c.relowner) as "Owner"
FROM pg_catalog.pg_class c
     LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind IN ('r','p','v','m','S','f','')
      AND n.nspname <> 'pg_catalog'
      AND n.nspname <> 'information_schema'
      AND n.nspname !~ '^pg_toast'
  AND pg_catalog.pg_table_is_visible(c.oid)
ORDER BY 1,2;};

my $explain = Pg::Explain->new( 'source' => $plan_source );
isa_ok( $explain,           'Pg::Explain' );
isa_ok( $explain->top_node, 'Pg::Explain::Node' );

my $anonymized_query;
lives_ok(
    sub {
        ( $anonymized_query ) = $explain->anonymize( $query );
    },
    'Anonymization works',
);

my $textual = $explain->as_text();

ok( $textual          =~ /::"char"\[\]/,       'anonymize() preserves type casting' );
ok( $textual          =~ /::name\b/,           'anonymize() preserves type casting' );
ok( $textual          =~ /::text\b/,           'anonymize() preserves type casting' );
ok( $textual          !~ /'pg_catalog'/,       'anonymize() hides string literals' );
ok( $textual          !~ /nspname/,            'anonymize() hides column names' );
ok( $textual          !~ /pg_class/,           'anonymize() hides relation names' );
ok( $textual          !~ /\{r,p,v,m,S,f,""\}/, 'anonymize() hides complex things' );
ok( $anonymized_query !~ /'pg_catalog'/,       'anonymize() hides string literals in query.' );
ok( $anonymized_query !~ /nspname/,            'anonymize() hides column names in query.' );
ok( $anonymized_query !~ /pg_class/,           'anonymize() hides relation names in query.' );
ok( $anonymized_query !~ /\{r,p,v,m,S,f,""\}/, 'anonymize() hides complex things in query.' );
ok( $anonymized_query !~ /WHERE[a-z]/,         'anonymize() preserves whitespace in query.' );

exit;

sub just_numbers {
    my $what = shift;
    return unless 'HASH' eq ref $what;
    delete $what->{ 'extra_info' };
    delete $what->{ 'scan_on' };
    delete $what->{ 'type' };

    for my $key ( grep { 'ARRAY' eq ref $what->{ $_ } } keys %{ $what } ) {
        for my $item ( @{ $what->{ $key } } ) {
            just_numbers( $item );
        }
    }
    return;
}
