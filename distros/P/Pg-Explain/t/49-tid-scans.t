#!perl

use Test::More;
use Test::Exception;

use Pg::Explain;

plan 'tests' => 8;

my $plan = q{
 Tid Scan on pg_class c  (cost=0.00..4.01 rows=1 width=373) (actual time=0.014..0.016 rows=1 loops=1)
   TID Cond: (ctid = '(1,33)'::tid)
};

my $explain = Pg::Explain->new( 'source' => $plan );
isa_ok( $explain,           'Pg::Explain' );
isa_ok( $explain->top_node, 'Pg::Explain::Node' );
ok( defined $explain->top_node->scan_on,                    "Scan on parsed for top node" );
ok( defined $explain->top_node->scan_on->{ 'table_name' },  "Scan on table name parsed for top node" );
ok( defined $explain->top_node->scan_on->{ 'table_alias' }, "Scan on table alias parsed for top node" );
my $table_name  = $explain->top_node->scan_on->{ 'table_name' };
my $table_alias = $explain->top_node->scan_on->{ 'table_alias' };

lives_ok(
    sub {
        $explain->anonymize();
    },
    'Anonymization works',
);
ok( $table_name ne $explain->top_node->scan_on->{ 'table_name' },   "Table name anonymized" );
ok( $table_alias ne $explain->top_node->scan_on->{ 'table_alias' }, "Table alias anonymized" );

exit;
