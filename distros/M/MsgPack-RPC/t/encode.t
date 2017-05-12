use strict;
use warnings;

use Test::More tests => 5;
use Test::Deep;

use MsgPack::Encoder;
use MsgPack::Type::Ext;

sub encode {
    [ map { ord } split '', MsgPack::Encoder->new(struct => shift) ]
};

sub cmp_encode(@){
    my( $struct, $wanna, $comment ) = @_;
    $struct = encode($struct);
    cmp_deeply( $struct => $wanna, $comment )
        or diag explain [ map { sprintf "%x", $_ } @$struct ];
}

cmp_encode 15 => [ 15 ], "number 15";

cmp_encode( MsgPack::Type::Ext->new( type => 5, data => chr(13) ) => [ 0xd4, 5, 13 ], "fixext1" );

cmp_encode [ (1)x18 ] => [
    0xdc, 0x00, 0x12, ( 0x01 ) x 18
], "array of 18 elements";

cmp_encode 'a' x 300 => [
    0xda, 1, 0x2c, ( ord 'a' ) x 300
], '300 char string';

cmp_encode '    25' => [ 0xa6, 0x20, 0x20, 0x20, 0x20, 0x32, 0x35 ],
    'string that looks like a number';

