#!perl

use Test::More;
use Test::Deep;
use Test::Exception;
use Data::Dumper;
use autodie;

use Pg::Explain;

my @plans = (

    q{
"Index Only Scan using object_pkey on object  (cost=0.00..8.27 rows=1 width=4) (actual time=0.016..0.016 rows=0 loops=1)"
"  Index Cond: (id = 7)"
"  Heap Fetches: 0"
"Total runtime: 0.049 ms"
},

);

plan 'tests' => 5 * scalar @plans;

for my $plan_source ( @plans ) {

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

    ok( $textual !~ /object_pkey/, 'anonymize() hides column name' );
    ok( $textual !~ /\bobject\b/,  'anonymize() hides table name' );

}

exit;
