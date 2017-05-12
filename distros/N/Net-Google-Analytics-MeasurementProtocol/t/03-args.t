use strict;
use warnings;
use Test::More tests => 2;

use Furl;
use Net::Google::Analytics::MeasurementProtocol;

my $ga = Net::Google::Analytics::MeasurementProtocol->new(
    tid       => 'UA-1234-5',
    ua_object => Furl->new,
);

my $args = $ga->_build_request_args( 'transaction', { ti => 1 } );

ok( !exists $args->{ua_object},
    'ua_object is scrubbed from args before POST' );

ok( !exists $args->{debug},
    'debug param is scrubbed from args before POST' );
