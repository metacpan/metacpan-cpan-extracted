use 5.008001;
use strict;
use warnings;
use Test::More 0.96;
use Test::Deep qw/!blessed/;
use Test::Tolerant;
use MIME::Base64 qw/encode_base64url decode_base64url/;

use Session::Storage::Secure;

my $data = {
    foo => 'bar',
    baz => 'bam',
};

my $secret = "serenade viscount secretary frail";

my $custom_enc = sub {
    return "~" . reverse encode_base64url( $_[0] );
};

my $custom_dec = sub {
    my $string = shift;
    substr( $string, 0, 1, '' );
    return decode_base64url( scalar reverse $string );
};

sub _gen_store {
    my ($config) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $store = Session::Storage::Secure->new(
        secret_key => $secret,
        %{ $config || {} },
    );
    ok( $store, "created a storage object" );
    return $store;
}

subtest "custom separator" => sub {
    my $store = _gen_store( { separator => ":", } );

    my $encoded = $store->encode($data);
    my $decoded = eval { $store->decode($encoded) };
    is( $@, '', "no error decoding custom separator" );
    cmp_deeply( $decoded, $data, "custom separator works" );
};

subtest "custom transfer encoding" => sub {
    my $store = _gen_store(
        {
            transport_encoder => $custom_enc,
            transport_decoder => sub { return "" }, # intentionally broken
            separator         => ':',
        }
    );

    my $encoded = $store->encode($data);

    my $decoded = eval { $store->decode($encoded) };
    is( $decoded, undef, "non-symmtric custom codec throws error" );

    $store = _gen_store(
        {
            transport_encoder => $custom_enc,
            transport_decoder => $custom_dec,
            separator         => ':',
        }
    );

    $decoded = eval { $store->decode($encoded) };
    is( $@, '', "no error decoding custom codec" );
    cmp_deeply( $decoded, $data, "custom codec works" );
};

subtest "custom sereal options" => sub {
    my $store = _gen_store(
        {
            sereal_encoder_options => {}, # i.e. allow objects
            sereal_decoder_options => {},
        }
    );

    my $object = bless { %$data }, "Fake::Class";

    my $encoded = $store->encode({ object => $object});

    my $decoded = eval { $store->decode($encoded) };
    isa_ok( $decoded->{object}, "Fake::Class", "decoded session element" );
    is_deeply( $decoded->{object}, $object, "object decoded correctly" );
};

done_testing;
#
# This file is part of Session-Storage-Secure
#
# This software is Copyright (c) 2013 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
