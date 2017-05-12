#!perl

use Test::More;
use Test::Deep;
use Test::Exception;
use Data::Dumper;
use autodie;
plan 'tests' => 12;

use Pg::Explain;

my $plan_source = q{                                                                  QUERY PLAN
----------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=17.05..17.17 rows=45 width=133) (actual time=1.633..1.633 rows=0 loops=1)
   Sort Key: n.nspname, c.relname
   Sort Method: quicksort  Memory: 25kB
   ->  Hash Join  (cost=1.14..15.82 rows=45 width=133) (actual time=1.599..1.599 rows=0 loops=1)
         Hash Cond: (c.relnamespace = n.oid)
         ->  Seq Scan on pg_class c  (cost=0.00..13.27 rows=45 width=73) (actual time=0.036..1.419 rows=93 loops=1)
               Filter: (pg_table_is_visible(oid) AND (relkind = ANY ('{r,v,S,f,""}'::"char"[])) AND relname = 'timestamp with time zone')
         ->  Hash  (cost=1.10..1.10 rows=3 width=68) (actual time=0.120..0.120 rows=2 loops=1)
               Buckets: 1024  Batches: 1  Memory Usage: 1kB
               ->  Seq Scan on pg_namespace n  (cost=0.00..1.10 rows=3 width=68) (actual time=0.109..0.118 rows=2 loops=1)
                     Filter: ((nspname <> 'pg_catalog'::name) AND (nspname <> 'information_schema'::name) AND (nspname !~ '^pg_toast'::text))
 Total runtime: 1.777 ms
};

my $explain = Pg::Explain->new( 'source' => $plan_source );
isa_ok( $explain,           'Pg::Explain' );
isa_ok( $explain->top_node, 'Pg::Explain::Node' );

lives_ok(
    sub {
        $explain->anonymize();
    },
    'Anonymization works',
);

my $textual = $explain->as_text();

ok( $textual =~ /::"char"\[\]/, 'anonymize() preserves type casting' );
ok( $textual =~ /::name\b/, 'anonymize() preserves type casting' );
ok( $textual =~ /::text\b/, 'anonymize() preserves type casting' );
ok( $textual !~ /timestamp with time zone/, 'anonymize() hides string literals' );
ok( $textual !~ /nspname/, 'anonymize() hides column names' );
ok( $textual !~ /pg_class/, 'anonymize() hides relation names' );

my $reparsed = Pg::Explain->new( 'source' => $textual );
isa_ok( $reparsed,           'Pg::Explain' );
isa_ok( $reparsed->top_node, 'Pg::Explain::Node' );

my $expected = $explain->top_node->get_struct();
my $got      = $reparsed->top_node->get_struct();

just_numbers( $expected );
just_numbers( $got );

cmp_deeply( $got, $expected, 'Plan numbers are the same' );

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
