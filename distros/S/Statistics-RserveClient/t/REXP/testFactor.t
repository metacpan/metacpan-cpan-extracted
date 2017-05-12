use warnings;
use autodie;

use Statistics::RserveClient::REXP::Factor;

use Test::More tests => 4;

my $fact = new Statistics::RserveClient::REXP::Factor;

isa_ok( $fact, 'Statistics::RserveClient::REXP::Factor', 'new returns an object that' );
ok( !$fact->isExpression(), 'Factor is not an expression' );
ok( $fact->isFactor(),      'Factor is a facotr' );
ok( $fact->isInteger(),     'Factor is not an integer' );

done_testing();
