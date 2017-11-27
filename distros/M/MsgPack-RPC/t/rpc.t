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
    my $in = <$has>;
    $decoder->read($in);
    $has = $decoder->next;

    cmp_deeply $has => $expected, $comment
        or diag explain $has;
}

open my $input_fh,  '<', \my $input;
my $output;
open my $output_fh, '>>', \$output;

#my( $output );
#open my $input_fh,  '<', 'in';
#open my $output_fh, '>>', 'out';

my $rpc = MsgPack::RPC->new;

my @output;
$rpc->on( write => sub { push @output, $_[0]->payload } );

$rpc->send_request( 'method' => [ qw/ param1 param2 / ] );

cmp_deeply shift @output, [0,1,'method',[qw/ param1 param2/] ], "request encapsulated";

$rpc->send_request( 'method' => [ qw/ param1 param2 / ] );

cmp_deeply shift @output => [0,2,'method',[qw/ param1 param2/]], "id increments";

$rpc->send_notification( 'psst' => [ qw/ param3 param4 / ] );

cmp_deeply shift @output => [2,'psst',[qw/ param3 param4 /] ], "notification";

$rpc->read( MsgPack::Encoder->new( struct => [
    0, 10, 'myrequest', [ 1 ]
])->encoded );

pass "okay";

subtest 'request -> reply' => sub {
    my $i = 0;
    $rpc->subscribe( myrequest => sub ($msg) {
        if ( $msg->is_request ) {
            if ( $i++ == 0 ) {
                $msg->resp( scalar reverse $msg->params->[0] );
            }
            else {
                $msg->error( length $msg->params->[0] );
            }
        }
        else {
            $rpc->send_notification( 'sure' );
        }
    });

    $rpc->read( MsgPack::Encoder->new( struct => [
        0, 15, 'myrequest', [ 'banana' ]
    ])->encoded );

    cmp_deeply shift @output, [1,15,undef,"ananab"], "reply to request";

    $rpc->read( MsgPack::Encoder->new( struct => [
        0, 15, 'myrequest', [ 'banana' ]
    ])->encoded );

    cmp_deeply shift @output, [1,15,6,undef], "reply to request, error";

    $rpc->read( MsgPack::Encoder->new( struct => [
        2, 'myrequest', [ 'banana' ]
    ])->encoded );

    cmp_deeply shift @output, [2,'sure',[]], "reply to notification";

    $rpc->subscribe( foo => sub ($msg) { $msg->resp( $msg->params->[0] + 1 ) } );

    my $result;
    $rpc->send_request( 'foo', [1] )->then(sub { $result = 1 + shift });

    1 while $rpc->loop->loop_once(1);

    is $result => undef, "no answer yet";

    $rpc->read( MsgPack::Encoder->new( struct => shift @output ) );

    1 while $rpc->loop->loop_once(1);

    is $result => undef, "not yet";

    $rpc->read( MsgPack::Encoder->new( struct => shift @output ) );

    1 while $rpc->loop->loop_once(1);

    is $result => 3, "got it";


};


