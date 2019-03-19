use strict;
use warnings;

use Test::More tests => 12;
use Test::Deep;
use Test::Approx;

use MsgPack::Encoder;
use MsgPack::Decoder;
use MsgPack::Type::Boolean;
use MsgPack::Type::Ext;

use Config;

my $is_32bits = !$Config{use64bitint};

my $decoder = MsgPack::Decoder->new( log_to_stderr => 0, debug => 0 );

subtest simple_encoding => sub {
    my %structs = (
        fixint  => 0,
        fixint_2 => 15,
        fixmap => { 1..10 },
        fixarray => [ 1..10 ],
        fixstr => "hello",
        nil => undef,
        false => MsgPack::Type::Boolean->new(0),
        true  => MsgPack::Type::Boolean->new(1),
        negfixint => -5,
        ext1 => MsgPack::Type::Ext->new( type => 5, data => chr(13) ),
        'mix' => [0, 4, "vim_eval", ["call rpcrequest( nvimx_channel, \"foo\", \"dummy\" )"]],
        'some string' => 'call rpcrequest( nvimx_channel, "foo", "dummy" )',
        'int8' => -128,
        float64 => 1/3,
    );

    plan tests => scalar keys %structs;

    for ( sort keys %structs ) {
        my( $name, $struct ) = ( $_, $structs{$_} );
        subtest $name => sub {
            plan skip_all => '32bits architecture'
                if $name =~ /64/ and $is_32bits;

            $decoder->read( MsgPack::Encoder->new(  struct => $struct )->encoded );
            if ( $name eq 'float32' ) {
                is_approx( $decoder->next, $struct, $name );
            }
            else {
                cmp_deeply $decoder->next => $struct, $name;
            }
        }
    }
};


subtest bin => sub {
    $decoder->read( msgpack_bin8 "hello there" );
    is $decoder->next => "hello there", "bin8";

    $decoder->read( msgpack_bin16 "hello there" );
    is $decoder->next => "hello there", "bin16";

    $decoder->read( msgpack_bin32 "hello there" );
    is $decoder->next => "hello there", "bin32";
};


sub encode(@) {
    pack 'C*', @_;
}

subtest nil => sub {
    is msgpack_nil() => encode( 0xc0 );
    is msgpack( undef ) => encode( 0xc0 );
    is $decoder->read_next(msgpack_nil) => undef;
};


subtest booleans => sub {
    for ( 0..1 ) {
        $decoder->read( MsgPack::Encoder->new( struct => MsgPack::Type::Boolean->new($_) ) );
        my $next = $decoder->next;
        isa_ok $next => 'MsgPack::Type::Boolean';
        ok !!$next == $_;
    }

    for ( 0..1 ) {
        my $e = encode( 0xc2 + $_ );
        is msgpack_bool($_) => $e;
        is msgpack( MsgPack::Type::Boolean->new($_) ) => $e;

        my $v = $decoder->read_next(msgpack_bool($_));
        isa_ok $v => 'MsgPack::Type::Boolean';
        is !!$v => !!$_;
    }
};

subtest int => sub {
    subtest positive_fixnum => sub {
        my $value = 13;
        my $e = encode($value);
        is msgpack_positive_fixnum($value) => $e;
        is msgpack($value) => $e;

        is $decoder->read_next($e) => $value;
    };
    subtest negative_fixnum => sub {
        my $value = -13;
        my $e = encode( 0xe0 - $value);
        is msgpack_negative_fixnum($value) => $e;
        is msgpack($value) => $e;

        is $decoder->read_next($e) => $value;
    };
    subtest uint8 => sub {
        my $value = 255;
        my $e = encode( 0xcc, $value);
        is msgpack_uint8($value) => $e;
        is msgpack($value) => $e;

        is $decoder->read_next($e) => $value;
    };
    subtest uint16 => sub {
        my $value = 2**8;
        my $e = encode( 0xcd, 1, 0);
        is msgpack_uint16($value) => $e;
        is msgpack($value) => $e;

        is $decoder->read_next($e) => $value;
    };
    subtest uint32 => sub {
        my $value = 2**16;
        my $e = encode( 0xce, 0, 1, 0, 0);
        is msgpack_uint32($value) => $e;
        is msgpack($value) => $e;

        is $decoder->read_next($e) => $value;
    };
    subtest uint64 => sub {
        plan skip_all => '32bits architecture' if $is_32bits;

        my $value = 2**32;
        my $e = encode( 0xcf, 0, 0, 0, 1, 0, 0, 0, 0);
        my $x = msgpack_uint64($value);
        is msgpack_uint64($value) => $e;
        is msgpack($value) => $e;

        is $decoder->read_next($e) => $value;
    };
    subtest int8 => sub {
        my $value = -127;
        my $e = encode( 0xd0, 129);
        is msgpack_int8($value) => $e;
        is msgpack($value) => $e;

        is $decoder->read_next($e) => $value;
    };
    subtest int16 => sub {
        my $value = -255;
        my $e = encode( 0xd1, 1, 255 );

        is msgpack_int16($value) => $e;
        is msgpack($value) => $e;

        is $decoder->read_next($e) => $value;
    };
    subtest int32 => sub {
        my $value = -16777215;
        my $e = encode( 0xd2, 1,0,0,255 );

        is msgpack_int32($value) => $e;
        is msgpack($value) => $e;

        is $decoder->read_next($e) => $value;
    };
    subtest int64 => sub {
        plan skip_all => '32bits architecture' if $is_32bits;

        my $value = -72057594037927935;
        my $e = encode( 0xd3, 1,0,0,0,0,0,0,255 );

        is msgpack_int64($value) => $e;
        is msgpack($value) => $e;

        is $decoder->read_next($e) => $value;
    };
};

subtest float => sub {
    for ( 32, 64 ) {
        subtest "float$_", sub {
            plan skip_all => '32bits architecture' if $_ == 64 and $is_32bits;
            my $e = eval qq{ msgpack_float$_ 1/3 };
            is length $e => 1 + ($_ / 8), "right number of characters";
            my $val = $decoder->read_next($e);
            cmp_deeply [ $val ] => [ num(1/3,3) ], "float$_";
        }
    }
    cmp_deeply [ msgpack 1/3 ] => [ num(1/3,3) ], 'msgpack';
};

subtest 'str' => sub {
    my $str = 'hello';

    for my $size ( 0..3 ) {
        my $function = 'msgpack_' . ( $size == 0 ? 'fixstr' : 'str' . (2**($size+2) ) );
        subtest $function => sub {
            my $l = length $str;
            my $e = pack 'C*', ( $size == 0
                            ? ( 0xa0 + $l )
                            : ( 0xd8 + $size, (0)x((2**($size-1)) - 1), $l) ), map { ord } split '', $str;
            is eval qq{ $function '$str' } => $e;
            is $decoder->read_next($e) => $str;
        }
    }

    is $decoder->read_next( msgpack $str ) => $str, 'msgpack';
};

subtest 'bin' => sub {
    my $str = 'hello';

    for my $size ( 1..3 ) {
        my $function = 'msgpack_' . 'bin' . (2**($size+2) );
        subtest $function => sub {
            my $l = length $str;
            my $e = pack 'C*',
                            ( 0xc3 + $size, (0)x((2**($size-1)) - 1), $l), map { ord } split '', $str;
            is eval qq{ $function '$str' } => $e;
            is $decoder->read_next($e) => $str;
        }
    }
};

sub show_binary($) {
    diag join ' : ', map { sprintf "%x", ord } split '', shift;
}

subtest array => sub {
    my @array = (1);

    subtest fixarray => sub {
        my $e = encode( 0x90+1, 1);

        is msgpack_fixarray(\@array) => $e;
        is msgpack(\@array) => $e;

        cmp_deeply $decoder->read_next($e) => \@array;
    };

    for my $size ( 16, 32 ) {
        my $function = "msgpack_array$size";
        subtest $function => sub {
            my $e = pack 'C*', ( 0xdb + $size/16,
                ( 0 ) x ( (2**($size/16)) - 1 ), 1,
                1
            );

            my $r =eval qq{$function(\\\@array)};
            is $r => $e or diag show_binary $r;

            cmp_deeply $decoder->read_next($e) => \@array;
        };
    }
};

subtest map => sub {
    my %hash = (1 => 2);

    subtest fixmap => sub {
        my $e = encode( 0x80+1, 1, 2);

        is msgpack_fixmap(\%hash) => $e;
        is msgpack(\%hash) => $e;

        cmp_deeply $decoder->read_next($e) => \%hash;
    };

    for my $size ( 16, 32 ) {
        my $function = "msgpack_map$size";
        subtest $function => sub {
            my $e = pack 'C*', ( 0xdd + $size/16,
                ( 0 ) x ( (2**($size/16)) - 1 ), 1,
                1,2
            );

            my $r =eval qq{$function(\\\%hash)};
            is $r => $e or diag show_binary $r;

            cmp_deeply $decoder->read_next($e) => \%hash;
        };
    }
};

subtest 'fixext' => sub {
    for my $i ( map { 2**$_ } 0..4 ) {
        my $func = "msgpack_fixext$i";
        subtest $func => sub {
            my $payload = 'x' x $i;
            my $data = eval "$func( 3 => '$payload' )";
            is $decoder->read_next($data)->data => $payload;
        };
    }
};

subtest 'ext' => sub {
    for my $i ( map { 2**$_ } 3..5 ) {
        my $func = "msgpack_ext$i";
        subtest $func => sub {
            my $payload = 'x' x $i;
            is eval { $decoder->read_next(eval "$func( 3 => '$payload' )")->data } => $payload;
        };
    }
};
