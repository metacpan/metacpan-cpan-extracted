use warnings;
use autodie;

use Statistics::RserveClient::REXP;
use Statistics::RserveClient::REXP::Integer;

use Test::More tests => 3;

my $int = new Statistics::RserveClient::REXP::Integer;

isa_ok( $int, 'Statistics::RserveClient::REXP::Integer', 'new returns an object that' );
ok( !$int->isExpression(), 'Integer is not an expression' );
ok( $int->isInteger(),     'Integer is an integer' );

done_testing();
