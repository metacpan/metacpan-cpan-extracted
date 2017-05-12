use warnings;
use autodie;

use Statistics::RserveClient::REXP::Raw;

use Test::More tests => 3;

my $raw = new Statistics::RserveClient::REXP::Raw;

isa_ok( $raw, 'Statistics::RserveClient::REXP::Raw', 'new returns an object that' );
ok( !$raw->isExpression(), 'Raw is not an expression' );
ok( $raw->isRaw(),         'Raw is a raw' );

done_testing();
