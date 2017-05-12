use warnings;
use autodie;

use Statistics::RserveClient::REXP::Expression;
use Statistics::RserveClient::REXP::Double;

use Test::More tests => 3;

my $expr = new Statistics::RserveClient::REXP::Expression;

isa_ok( $expr, 'Statistics::RserveClient::REXP::Expression', 'new returns an object that' );
ok( $expr->isExpression(), 'Expression is an expression' );

my $dbl = new Statistics::RserveClient::REXP::Double;
ok( !$dbl->isExpression(), 'Double is not an expression' );

done_testing();
