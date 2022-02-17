#!perl

use Test::More;
use autodie;

use Pg::Explain;
use Pg::Explain::Hinter;

my $plan = q{Result  (cost=0.00..0.01 rows=1 width=4)};

plan 'tests' => 1;

my $explain = Pg::Explain->new( 'source' => $plan );
$explain->parse_source;

my $hinter = Pg::Explain::Hinter->new( $explain );
ok( ! $hinter->any_hints, 'No hints for explain plans' );

exit;
