use Test::More tests => 4;

use strict;
use warnings;

use MsgPack::RPC;

my $client = MsgPack::RPC->new( timeout => 1 );

my $got_timeout;
$client->send_request( 'yo' )->catch(sub { $got_timeout = $_[0] } );

is $got_timeout => undef, "didn't get it yet";
is scalar( keys %{$client->response_callbacks} ) => 1, "callback is there";

1 while $client->loop->loop_once(2);

is $got_timeout => 'timeout', "got it";

is scalar( keys %{$client->response_callbacks} ) => 0, "no more callbacks";
