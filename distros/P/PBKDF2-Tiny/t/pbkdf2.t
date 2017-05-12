use strict;
use warnings;
use Test::More 0.88;

use utf8;
use PBKDF2::Tiny qw/derive derive_hex verify verify_hex/;
use Encode qw/encode_utf8/;

#--------------------------------------------------------------------------#
# custom test function
#--------------------------------------------------------------------------#

sub is_hex {
    my ( $got, $exp, $label ) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is( unpack( "H*", $got ), unpack( "H*", $exp ), $label );
}

sub exception(&) {
    my $code = shift;
    eval { $code->() };
    return $@;
}

#--------------------------------------------------------------------------#
# Test cases:
#--------------------------------------------------------------------------#

my @cases = (
    # PBKDF2 HMAC-SHA1 test cases from RFC 6070
    {
        n => 'SHA-1 1 iter',
        a => 'SHA-1',
        p => 'password',
        s => 'salt',
        c => 1,
        l => 20,
        o => "0c 60 c8 0f 96 1f 0e 71 f3 a9 b5 24 af 60 12 06 2f e0 37 a6",
    },
    {
        n => 'SHA-1 2 iters',
        a => 'SHA-1',
        p => 'password',
        s => 'salt',
        c => 2,
        l => 20,
        o => "ea 6c 01 4d c7 2d 6f 8c cd 1e d9 2a ce 1d 41 f0 d8 de 89 57"
    },
    {
        n => 'SHA-1 3 iters',
        a => 'SHA-1',
        p => 'password',
        s => 'salt',
        c => 3,
        l => 20,
        o => "6b4e26125c25cf21ae35ead955f479ea2e71f6ff",
    },
    {
        n => 'SHA-1 4096 iters',
        a => 'SHA-1',
        p => 'password',
        s => 'salt',
        c => 4096,
        l => 20,
        o => "4b 00 79 01 b7 65 48 9a be ad 49 d9 26 f7 21 d0 65 a4 29 c1"
    },
    {
        n => 'SHA-1 4096 iters, longer pw/salt/dk_length',
        a => 'SHA-1',
        p => 'passwordPASSWORDpassword',
        s => 'saltSALTsaltSALTsaltSALTsaltSALTsalt',
        c => 4096,
        l => 25,
        o => "3d 2e ec 4f e4 1c 84 9b 80 c8 d8 36 62 c0 e4 4a 8b 29 1a 96 4c f2 f0 70 38"
    },
    {
        n => 'SHA-1 4096 iters, embedded nulls, short dk',
        a => 'SHA-1',
        p => "pass\x00word",
        s => "sa\x00lt",
        c => 4096,
        l => 16,
        o => "56 fa 6a a7 55 48 09 9d cc 37 d7 f0 34 25 e0 c3"
    },

    # PBKDF2 HMAC-SHA2 test cases from Crypt::PBKDF2
    {
        n => 'SHA-224 1 iter',
        a => 'SHA-224',
        p => 'password',
        s => 'salt',
        c => 1,
        l => 28,
        o => "3c198cbdb9464b7857966bd05b7bc92bc1cc4e6e63155d4e490557fd"
    },
    {
        n => 'SHA-224 1000 iter',
        a => 'SHA-224',
        p => 'password',
        s => 'salt',
        c => 1000,
        l => 28,
        o => "d3bcf320fd918908eafcaa460faf40e201f6508d4e6f3d9c1c0abd30"
    },
    {
        n => 'SHA-256 1 iter',
        a => 'SHA-256',
        p => 'password',
        s => 'salt',
        c => 1,
        l => 32,
        o => "120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b"
    },
    {
        n => 'SHA-256 1000 iter',
        a => 'SHA-256',
        p => 'password',
        s => 'salt',
        c => 1000,
        l => 32,
        o => "632c2812e46d4604102ba7618e9d6d7d2f8128f6266b4a03264d2a0460b7dcb3"
    },
    {
        n => 'SHA-384 1 iter',
        a => 'SHA-384',
        p => 'password',
        s => 'salt',
        c => 1,
        l => 48,
        o => "c0e14f06e49e32d73f9f52ddf1d0c5c7191609233631dadd76a567db42b7867"
          . "6b38fc800cc53ddb642f5c74442e62be4"
    },
    {
        n => 'SHA-384 1000 iter',
        a => 'SHA-384',
        p => 'password',
        s => 'salt',
        c => 1000,
        l => 48,
        o => "3bd37e2236941d4a77b1b5b714c6f913fabb6b0841a6d7d8656b99d611e900"
          . "fe06edb93b5b809efaa9678b635ce513e0"
    },
    {
        n => 'SHA-512 1 iter',
        a => 'SHA-512',
        p => 'password',
        s => 'salt',
        c => 1,
        l => 64,
        o => "867f70cf1ade02cff3752599a3a53dc4af34c7a669815ae5d513554e1c8cf"
          . "252c02d470a285a0501bad999bfe943c08f050235d7d68b1da55e63f73b60a57fce"
    },
    {
        n => 'SHA-512 1000 iter',
        a => 'SHA-512',
        p => 'password',
        s => 'salt',
        c => 1000,
        l => 64,
        o => "afe6c5530785b6cc6b1c6453384731bd5ee432ee549fd42fb6695779ad8a1"
          . "c5bf59de69c48f774efc4007d5298f9033c0241d5ab69305e7b64eceeb8d834cfec"
    },

);

#--------------------------------------------------------------------------#
# test runner
#--------------------------------------------------------------------------#

subtest "Test cases" => sub {
    for my $c (@cases) {
        ( my $exp_hex = $c->{o} ) =~ s{ }{}g; # strip spaces
        my $exp = pack( "H*", $exp_hex );

        my $got = derive( @{$c}{qw/a p s c l/} );
        is_hex( $got, $exp, "$c->{n} (derive)" );

        my $got_hex = derive_hex( @{$c}{qw/a p s c l/} );
        is( $got_hex, $exp_hex, "$c->{n} (derive hex)" );

        ok( verify( $exp, @{$c}{qw/a p s c l/} ), "$c->{n} (verify)" );
        ok( verify_hex( $exp_hex, @{$c}{qw/a p s c l/} ), "$c->{n} (verify hex)" );

        ok( !verify( $exp, $c->{a}, 'qwerty', @{$c}{qw/s c l/} ),
            "$c->{n} (verify bad pass)" );
        ok( !verify_hex( $exp_hex, $c->{a}, 'qwerty', @{$c}{qw/s c l/} ),
            "$c->{n} (verify hex bad pas)" );
    }
};

subtest "Unicode" => sub {
    my $latin1 = "büller";
    utf8::upgrade($latin1);
    my $wide = "☺♥☺•♥♥☺";

    # password

    like(
        exception { derive( 'SHA-1', $latin1, 'salt', 1000 ) },
        qr/password must be an octet string/,
        "password: UTF8-on latin-1 is fatal"
    );

    is( exception { derive( 'SHA-1', encode_utf8($latin1), 'salt', 1000 ) },
        '', "password: UTF-8 encoded latin-1 is OK" );

    utf8::downgrade($latin1);
    is( exception { derive( 'SHA-1', $latin1, 'salt', 1000 ) },
        '', "password: UTF8-off latin-1 is OK" );

    like(
        exception { derive( 'SHA-1', $wide, 'salt', 1000 ) },
        qr/password must be an octet string/,
        "password: UTF8-on wide is fatal"
    );

    is( exception { derive( 'SHA-1', encode_utf8($wide), 'salt', 1000 ) },
        '', "password: UTF-8 encoded wide is OK" );

    # salt

    utf8::upgrade($latin1);

    like(
        exception { derive( 'SHA-1', 'pass', $latin1, 1000 ) },
        qr/salt must be an octet string/,
        "salt: UTF8-on latin-1 is fatal"
    );

    is( exception { derive( 'SHA-1', 'pass', encode_utf8($latin1), 1000 ) },
        '', "salt: UTF-8 encoded latin-1 is OK" );

    utf8::downgrade($latin1);
    is( exception { derive( 'SHA-1', 'pass', $latin1, 1000 ) },
        '', "salt: UTF8-off latin-1 is OK" );

    $wide = "☺♥☺•♥♥☺";
    like(
        exception { derive( 'SHA-1', 'pass', $wide, 1000 ) },
        qr/salt must be an octet string/,
        "salt: UTF8-on wide is fatal"
    );

    is( exception { derive( 'SHA-1', 'pass', encode_utf8($wide), 1000 ) },
        '', "salt: UTF-8 encoded wide is OK" );

};

subtest "missing dk length" => sub {
    my @gdargs = ( 'SHA-1', 'pass',       'salt', 1000 );
    my @bdargs = ( 'SHA-1', 'notthepass', 'salt', 1000 );
    my $key1   = derive_hex(@gdargs);
    my $key2 = derive_hex( @gdargs, 0 );

    is( $key1, $key2, "0 as dk length ignored" );
    ok( !verify_hex( $key1, @gdargs, length($key1) ),
        "verify w/length true (good pass)" );
    ok( !verify_hex( $key1, @bdargs, length($key1) ),
        "verify w/length false (bad pass)" );

    ok( verify_hex( $key1, @gdargs ), "verify w/o length true (good pass)" );
    ok( !verify_hex( $key1, @bdargs ), "verify w/o length false (bad pass)" );

    ok( verify_hex( $key1, @gdargs, 0 ), "verify with 0 length true (good pass)" );
    ok( !verify_hex( $key1, @bdargs, 0 ), "verify with 0 length false (bad pass)" );
};

done_testing;

#
# This file is part of PBKDF2-Tiny
#
# This software is Copyright (c) 2014 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
# vim: ts=4 sts=4 sw=4 et:
