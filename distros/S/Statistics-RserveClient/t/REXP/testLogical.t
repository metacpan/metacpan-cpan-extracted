use warnings;
use autodie;

use Statistics::RserveClient::REXP::Logical;

use Test::More tests => 3;

my $logical = new Statistics::RserveClient::REXP::Logical;

isa_ok( $logical, 'Statistics::RserveClient::REXP::Logical', 'new returns an object that' );
ok( !$logical->isExpression(), 'Logical is not an expression' );
ok( $logical->isLogical(),     'Logical is a logical' );

done_testing();
