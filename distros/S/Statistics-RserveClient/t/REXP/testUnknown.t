use warnings;
use autodie;

use Statistics::RserveClient::REXP::Unknown;

use Test::More tests => 2;

my $unknown = new Statistics::RserveClient::REXP::Unknown('test');

isa_ok( $unknown, 'Statistics::RserveClient::REXP::Unknown', 'new returns an object that' );
is( $unknown->getUnknownType(), 'test', 'Unknown is an unknown "test"' );

done_testing();

