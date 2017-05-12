use warnings;
use autodie;

use Statistics::RserveClient::REXP::Null;

use Test::More tests => 3;

my $null = new Statistics::RserveClient::REXP::Null;

isa_ok( $null, 'Statistics::RserveClient::REXP::Null', 'new returns an object that' );
ok( !$null->isExpression(), 'Null is not an expression' );
ok( $null->isNull(),        'Null is a null' );

done_testing();
