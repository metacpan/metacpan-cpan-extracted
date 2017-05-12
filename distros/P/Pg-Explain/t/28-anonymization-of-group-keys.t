#!perl

use Test::More;
use Test::Deep;
use Test::Exception;
use Data::Dumper;
use autodie;

use Pg::Explain;

my @plans = (
    q{ HashAggregate  (cost=15.46..15.58 rows=12 width=5) (actual time=0.107..0.108 rows=7 loops=1)
   Group Key: relkind, relnamespace
   ->  Seq Scan on pg_class  (cost=0.00..13.12 rows=312 width=5) (actual time=0.003..0.023 rows=312 loops=1)
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

    ok( $textual !~ /relkind/, 'anonymize() hides group keys' );
    ok( $textual !~ /relnamespace/, 'anonymize() hides group keys' );

}

exit;
