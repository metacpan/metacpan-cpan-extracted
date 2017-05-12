#!perl

use Test::More;
use Test::Deep;
use Test::Exception;
use Data::Dumper;
use autodie;

use Pg::Explain;

my @plans = (

    q{Subquery Scan on ns_common_target  (cost=81182.54..81237.41 rows=62 width=243)},

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

    ok( $textual !~ /ns_common_target/, 'anonymize() hides subqueries names' );

}

exit;
