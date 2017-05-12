use warnings;
use autodie;

use Statistics::RserveClient::REXP::List;

use Test::More tests => 3;

my $lst = new Statistics::RserveClient::REXP::List;

isa_ok( $lst, 'Statistics::RserveClient::REXP::List', 'new returns an object that' );
ok( !$lst->isExpression(), 'List is not an expression' );
ok( $lst->isList(),        'List is an integer' );

done_testing();
