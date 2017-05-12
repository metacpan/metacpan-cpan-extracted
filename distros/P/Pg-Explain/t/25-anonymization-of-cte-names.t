#!perl

use Test::More;
use Test::Deep;
use Test::Exception;
use Data::Dumper;
use autodie;

use Pg::Explain;

my @plans = (

    q{
 CTE Scan on some_name  (cost=0.01..0.03 rows=1 width=8) (actual time=0.006..0.006 rows=1 loops=1)
   CTE some_name
     ->  Result  (cost=0.00..0.01 rows=1 width=0) (actual time=0.003..0.003 rows=1 loops=1)
 Planning time: 0.032 ms
 Execution time: 0.030 ms
},

);

plan 'tests' => 4 * scalar @plans;

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

    ok( $textual !~ /some_name/, 'anonymize() hides cte names' );

}

exit;
