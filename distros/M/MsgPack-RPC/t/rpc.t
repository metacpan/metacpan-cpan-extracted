use 5.20.0;

use strict;
use warnings;

use Test::More tests => 5;
use Test::Deep;

use MsgPack::RPC;

use experimental 'signatures';

sub cmp_msgpack(@) {
    state $decoder = MsgPack::Decoder->new;
    my( $has, $expected, $comment ) = @_;
    $decoder->read(<$has>);
    $has = $decoder->next;

    cmp_deeply $has => $expected, $comment
        or diag explain $has;
}

open my $input_fh,  '<', \my $input;
open my $output_fh, '>', \my $output;

my $rpc = MsgPack::RPC->new(
    io => [ $input_fh, $output_fh ],
);

$rpc->request( 'method' => [ qw/ param1 param2 / ] );

open my $io, '<', \$output;
open my $io_in, '>>', \$input;

cmp_msgpack $io => [0,1,'method',[qw/ param1 param2/]], "request encapsulated";

$rpc->request( 'method' => [ qw/ param1 param2 / ] );

cmp_msgpack $io => [0,2,'method',[qw/ param1 param2/]], "id increments";


$rpc->notify( 'psst' => [ qw/ param3 param4 / ] );

cmp_msgpack $io => [2,'psst',[qw/ param3 param4 /] ], "notification";

print $io_in MsgPack::Encoder->new( struct => [
    0, 10, 'myrequest', [ 1 ]
])->encoded;

$rpc->loop(1);

pass "okay";

subtest 'request -> reply' => sub {
    $rpc->subscribe( myrequest => sub ($msg) {
        $msg->resp( 'okay' );
    });

    print $io_in MsgPack::Encoder->new( struct => [
        0, 15, 'myrequest', [ 1 ]
    ])->encoded;

    $rpc->loop(1);

    cmp_msgpack $io => [1,15,undef,"okay"], "reply to request";
};


