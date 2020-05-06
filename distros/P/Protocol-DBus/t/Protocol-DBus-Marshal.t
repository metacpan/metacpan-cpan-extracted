#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::FailWarnings;

use Data::Dumper;

use_ok('Protocol::DBus::Marshal');

#----------------------------------------------------------------------

my $can_64 = eval { !!pack 'q' };

my @marshal_le_tests = (
    {
        in => [ 'y', [ 0 ] ],
        out => chr 0,
    },
    {
        in => [ 'y', [ 123 ] ],
        out => chr 123,
    },
    {
        in => [ 'b', [ 0 ] ],
        out => "\0\0\0\0",
    },
    {
        in => [ 'b', [ 1 ] ],
        out => "\1\0\0\0",
    },
    {
        in => [ 'n', [ -8 ] ],
        out => pack( 's<', -8 ),
    },
    {
        in => [ 'q', [ 127 ] ],
        out => pack( 'S<', 127 ),
    },
    {
        in => [ 'i', [ -8 ] ],
        out => pack( 'l<', -8 ),
    },
    {
        in => [ 'u', [ 127 ] ],
        out => pack( 'L<', 127 ),
    },
    {
        in => [ 'd', [ 127.46 ] ],
        out => pack( 'd<', 127.46 ),
    },

    #----------------------------------------------------------------------

    {
        in => [ 'g', [ 'ybn' ] ],
        out => "\x03ybn\0",
    },

    {
        in => [ 's',[  'ybn' ] ],
        out => "\x03\0\0\0ybn\0",
    },

    {
        in => [ 's', [ do { use utf8; "é" } ] ],
        out => "\x02\0\0\0é\0",
    },

    {
        in => [ 's', [ "é" ] ],
        out => "\x04\0\0\0" . do { utf8::encode(my $v = 'é'); $v } . "\0",
    },

    {
        in => [ 'o',[  '/yb' ] ],
        out => "\x03\0\0\0/yb\0",
    },

    #----------------------------------------------------------------------

    ( $can_64
        ? (
            {
                in => [ 'at', [ [5] ] ],
                out => "\x08\0\0\0" . "\0\0\0\0" . "\x05\0\0\0\0\0\0\0",
            },
            {
                in => [ 't', [ 5 ] ],
                out => "\x05\0\0\0\0\0\0\0",
            },
            {
                in => [ '(t)', [ [5] ] ],
                out => "\x05\0\0\0\0\0\0\0",
            },
        )
        : ()
    ),

    {
        in => [ v => [ [ o => '/org/freedesktop/NetworkManager' ] ] ],
        out => "\1o\0\0\37\0\0\0/org/freedesktop/NetworkManager\0",
    },

    {
        in => [ '(s)', [ ['hello'] ] ],
        out => "\5\0\0\0hello\0",
    },

    {
        in => [ '(ss)', [ ['hello', 'there'] ] ],
        out => "\5\0\0\0hello\0" . "\0\0". "\5\0\0\0there\0",
    },

    {
        in => [
            'ua(yv)',
            [
                127,
                [
                    [ 1 => [ o => '/org/freedesktop/NetworkManager' ] ],
                    [ 3 => [ s => 'Introspect' ] ],
                    [ 2 => [ s => 'org.freedesktop.DBus.Introspectable' ] ],
                    [ 6 => [ s => 'org.freedesktop.NetworkManager' ] ],
                ],
            ],
        ],
        out => "\x7f\0\0\0\227\0\0\0\1\1o\0\37\0\0\0/org/freedesktop/NetworkManager\0\3\1s\0\n\0\0\0Introspect\0\0\0\0\0\0\2\1s\0#\0\0\0org.freedesktop.DBus.Introspectable\0\0\0\0\0\6\1s\0\36\0\0\0org.freedesktop.NetworkManager\0",
    },

    {
        in => [
            'uua(yv)',
            [
                2,
                127,
                [
                    [ 1 => [ o => '/org/freedesktop/NetworkManager' ] ],
                    [ 3 => [ s => 'Introspect' ] ],
                    [ 2 => [ s => 'org.freedesktop.DBus.Introspectable' ] ],
                    [ 6 => [ s => 'org.freedesktop.NetworkManager' ] ],
                ],
            ],
        ],
        out => "\2\0\0\0\x7f\0\0\0\227\0\0\0\0\0\0\0\1\1o\0\37\0\0\0/org/freedesktop/NetworkManager\0\3\1s\0\n\0\0\0Introspect\0\0\0\0\0\0\2\1s\0#\0\0\0org.freedesktop.DBus.Introspectable\0\0\0\0\0\6\1s\0\36\0\0\0org.freedesktop.NetworkManager\0",
    },

    {
        in => [
            'uua{yv}',
            [
                127,
                2,
                {
                    1 => [ o => '/org/freedesktop/NetworkManager' ],
                },
            ],
        ],
        out => "\x7f\0\0\0\2\0\0\0(\0\0\0\0\0\0\0\1\1o\0\37\0\0\0/org/freedesktop/NetworkManager\0",
    },

    # Note the reuse of index 1 (STDOUT).
    {
        in => [
            'hhyh',
            [ \*STDERR, \*STDOUT, 2, \*STDOUT ],
        ],
        out => "\0\0\0\0\1\0\0\0\x02\0\0\0\1\0\0\0",
        out_fds => [ map { fileno $_ } (\*STDERR, \*STDOUT) ],
    },
);

for my $t (@marshal_le_tests) {
    my ($out_sr, $out_fds) = Protocol::DBus::Marshal::marshal_le( @{ $t->{'in'} } );

    is(
        $$out_sr,
        $t->{'out'},
        'marshal_le(): ' . _terse_dump($t->{'in'}),
    ) or diag _terse_dump( [ got => $out_sr, wanted => $t->{'out'} ] );

    if ($t->{'out_fds'}) {
        is_deeply(
            $out_fds,
            $t->{'out_fds'},
            '... and associated file handles',
        );
    }
}

#done_testing();
#exit;
#----------------------------------------------------------------------

my @positive_le_tests = (
    {
        in => ["\x0a\0\0\0", 0, 'u'],
        out => [ [10], 4 ],
    },

    {
        in => [ "\x02\0\0\0é\0", 0, 's'],
        out => [ [ do { use utf8; "é" } ], 7 ],
    },

    {
        in => [
            "\x04\0\0\0" . do { utf8::encode(my $v = 'é'); $v } . "\0",
            0,
            's',
        ],
        out => [ [ "é" ], 9 ],
    },

    {
        in => ["\0\0\0\0\x0a\0\0\0", 1, 'u'],
        out => [ [10], 7 ],
    },

    {
        in => ["\x02\0\0\0hi\0" . "\0" . "\x04\0". "\x02\0", 0, '(s(qq))'],
        out => [
            [ all(
                noclass( [ 'hi', all(
                    noclass( [ 4, 2 ] ),
                    Isa('Protocol::DBus::Type::Struct'),
                ) ] ),
                Isa('Protocol::DBus::Type::Struct'),
            ) ],
            12,
        ],
    },

    {
        in => [ "\x08\0\0\0" . "\0\0\0\0" . "\x05\0\0\0\0\0\0\0", 0, 'at' ],
        out => [
            [ all(
                noclass([ 5 ]),
                Isa('Protocol::DBus::Type::Array'),
            ) ],
            16,
        ],
    },

    {
        in => [ "\0\0\0\0" . "\x08\0\0\0" . "\x05\0\0\0\0\0\0\0", 4, 'at' ],
        out => [
            [ all(
                noclass([ 5 ]),
                Isa('Protocol::DBus::Type::Array'),
            ) ],
            12,
        ],
    },

    {
        in => ["\0\0\0\0" . "\x08\0\0\0" . "\x0a\0\0\0" . "\0\1\0\0", 2, 'au'],
        out => [
            [ all(
                noclass([ 10, 256 ]),
                Isa('Protocol::DBus::Type::Array'),
            ) ],
            14,
        ],
    },

    {
        in => ["\0\0\0\0" . "\x10\0\0\0" . "\x0a\0\0\0" . "\0\1\0\0" . "\x02\0\0\0" . "\x10\0\0\0", 2, 'a{uu}'],
        out => [
            [ all(
                Isa('Protocol::DBus::Type::Dict'),
                noclass( { 10 => 256, 2 => 16 } ),
            ) ],
            22,
        ],
    },
    {
        in => ["\0\0\0\0\237\0\0\0\1\1o\0.\0\0\0/org/freedesktop/systemd1/unit/spamd_2eservice\0\0\3\1s\0\6\0\0\0GetAll\0\0\2\1s\0\37\0\0\0org.freedesktop.DBus.Properties\0\6\1s\0\30\0\0\0org.freedesktop.systemd1\0\0\0\0\0\0\0\0\10\1g\0\1s\0\0", 1, 'a(yv)'],
        out => [
            [ all(
                Isa('Protocol::DBus::Type::Array'),
                noclass( [
                    all(
                        Isa('Protocol::DBus::Type::Struct'),
                        noclass( [
                            1,
                            '/org/freedesktop/systemd1/unit/spamd_2eservice',
                        ] ),
                    ),
                    all(
                        Isa('Protocol::DBus::Type::Struct'),
                        noclass( [
                            3,
                            'GetAll',
                        ] ),
                    ),
                    all(
                        Isa('Protocol::DBus::Type::Struct'),
                        noclass( [
                            2,
                            'org.freedesktop.DBus.Properties',
                        ] ),
                    ),
                    all(
                        Isa('Protocol::DBus::Type::Struct'),
                        noclass( [
                            6,
                            'org.freedesktop.systemd1',
                        ] ),
                    ),
                    all(
                        Isa('Protocol::DBus::Type::Struct'),
                        noclass( [
                            8,
                            's',
                        ] ),
                    ),
                ] ),
            ) ],
            166,
        ],
    },
    {
        in => ["l\1\0\1\5\0\0\0\1\0\0\0\237\0\0\0\1\1o\0.\0\0\0/org/freedesktop/systemd1/unit/spamd_2eservice\0\0\3\1s\0\6\0\0\0GetAll\0\0\2\1s\0\37\0\0\0org.freedesktop.DBus.Properties\0\6\1s\0\30\0\0\0org.freedesktop.systemd1\0\0\0\0\0\0\0\0\10\1g\0\1s\0\0", 0, 'yyyyuua(yv)'],
        out => [
            [
                108,
                1,
                0,
                1,
                5,
                1,
                all(
                    Isa('Protocol::DBus::Type::Array'),
                    noclass( [
                        all(
                            Isa('Protocol::DBus::Type::Struct'),
                            noclass( [
                                1,
                                '/org/freedesktop/systemd1/unit/spamd_2eservice',
                            ] ),
                        ),
                        all(
                            Isa('Protocol::DBus::Type::Struct'),
                            noclass( [
                                3,
                                'GetAll',
                            ] ),
                        ),
                        all(
                            Isa('Protocol::DBus::Type::Struct'),
                            noclass( [
                                2,
                                'org.freedesktop.DBus.Properties',
                            ] ),
                        ),
                        all(
                            Isa('Protocol::DBus::Type::Struct'),
                            noclass( [
                                6,
                                'org.freedesktop.systemd1',
                            ] ),
                        ),
                        all(
                            Isa('Protocol::DBus::Type::Struct'),
                            noclass( [
                                8,
                                's',
                            ] ),
                        ),
                    ] ),
                ),
            ],
            175,
        ],
    },
);

for my $t (@positive_le_tests) {
    my ($buf, $buf_offset, $sig) = @{ $t->{'in'} };

    my $str = _str_for_buf_offset_sig( $buf, $buf_offset, $sig);

    #$str .= "] → [" . join(', ', map { Dumper($_) } @{ $t->{'out'} } ) . ']';

    my ($data, $offset_delta) = Protocol::DBus::Marshal::unmarshal_le(\$buf, $buf_offset, $sig);

    cmp_deeply(
        [$data, $offset_delta],
        $t->{'out'},
        "unmarshal_le: $str",
    ) or diag explain [$data, $offset_delta];
}

sub _str_for_buf_offset_sig {
    my ($buf, $buf_offset, $sig) = @_;

    return '[' . join(', ', _terse_dump($buf), $buf_offset, $sig) . ']';
}

sub _terse_dump {
    my ($thing) = @_;

    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Useqq = 1;

    return Dumper($thing);
}

#----------------------------------------------------------------------

done_testing();
