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

sub _replace {
    my ( $string, $index, $value ) = @_;
    my @parts = split qr/~/, $string;
    $parts[$index] = $value;
    return join "~", @parts;
}

subtest "defaults" => sub {
    my $store = _gen_store;

    my $encoded = $store->encode($data);
    like( $encoded, qr/^\d+~~/, "no expiration set" );

    my $decoded = $store->decode($encoded);
    cmp_deeply( $decoded, $data, "roundtrip" );

    my $store2 = _gen_store(
        {
            secret_key  => "second secret",
            old_secrets => [$secret],
        }
    );
    my $decoded2 = $store2->decode($encoded);
    cmp_deeply( $decoded2, $data, "roundtrip with old secret" );

    my $store3 = _gen_store(
        {
            secret_key  => "second secret",
            old_secrets => [ "another secret", $secret ],
        }
    );
    my $decoded3 = $store3->decode($encoded);
    cmp_deeply( $decoded3, $data, "roundtrip with old secret" );

    my $store4 = _gen_store(
        {
            secret_key  => "second secret",
            old_secrets => [ $secret, "another secret" ],
        }
    );
    my $decoded4 = $store4->decode($encoded);
    cmp_deeply( $decoded4, $data, "roundtrip with old secret" );
};

subtest "no data" => sub {
    my $store = _gen_store;

    my $encoded = $store->encode();
    like( $encoded, qr/^\d+~~/, "no expiration set" );

    my $decoded = $store->decode($encoded);
    cmp_deeply( $decoded, {}, "undefined data treated as empty hashref" );
};

subtest "future expiration" => sub {
    my $store   = _gen_store;
    my $expires = time + 3600;

    my $encoded = $store->encode( $data, $expires );
    my ($got) = $encoded =~ m/~(\d+)~/;
    is( $got, $expires, "expiration timestamp correct" );

    my $decoded = $store->decode($encoded);
    cmp_deeply( $decoded, $data, "roundtrip" );
};

subtest "past expiration" => sub {
    my $store   = _gen_store;
    my $expires = time - 3600;

    my $encoded = $store->encode( $data, $expires );
    my ($got) = $encoded =~ m/~(\d+)~/;
    is( $got, $expires, "expiration timestamp correct" );

    my $decoded = $store->decode($encoded);
    is( $decoded, undef, "expired data decodes to undef" );
};

subtest "future default duration" => sub {
    my $store = _gen_store( { default_duration => 3600 } );

    my $encoded = $store->encode($data);
    my ($got) = $encoded =~ m/~(\d+)~/;
    is_tol( $got - time, [qw/3550 to 3605/], "expiration in correct range" );

    my $decoded = $store->decode($encoded);
    cmp_deeply( $decoded, $data, "roundtrip" );
};

subtest "past default duration" => sub {
    my $store = _gen_store( { default_duration => -3600 } );

    my $encoded = $store->encode($data);
    my ($got) = $encoded =~ m/~(\d+)~/;
    is_tol( $got - time, [qw/-3605 to -3550/], "expiration in correct range" );

    my $decoded = $store->decode($encoded);
    is( $decoded, undef, "expired data decodes to undef" );
};

subtest "changed secret key" => sub {
    my $store = _gen_store;

    my $encoded = $store->encode($data);

    my $store2 = _gen_store( { secret_key => "unpopular deface inflamed belay" } );
    my $decoded = $store2->decode($encoded);
    is( $decoded, undef, "changed key decodes to undef" );

    my $store3 = _gen_store(
        {
            secret_key  => "second secret key",
            old_secrets => [ "something else", "another secret" ],
        }
    );
    is( $store3->decode($encoded), undef, "No matching keys decodes to undef" );
};

subtest "modified salt" => sub {
    my $store = _gen_store( { default_duration => 3600 } );

    my $encoded = _replace( $store->encode($data), 0, int( rand() * 2**31 ) );

    my $decoded = $store->decode($encoded);
    is( $decoded, undef, "changed salt decodes to undef" );
};

subtest "modified expiration" => sub {
    my $store = _gen_store( { default_duration => 3600 } );

    my $encoded = _replace( $store->encode($data), 1, time + 86400 );

    my $decoded = $store->decode($encoded);
    is( $decoded, undef, "changed expiration decodes to undef" );
};

subtest "modified ciphertext" => sub {
    my $store = _gen_store( { default_duration => 3600 } );

    my $encoded = _replace( $store->encode($data),
        2, encode_base64url( pack( "l*", rand, rand, rand, rand ) ) );

    my $decoded = $store->decode($encoded);
    is( $decoded, undef, "changed ciphertext decodes to undef" );
};

subtest "modified mac" => sub {
    my $store = _gen_store( { default_duration => 3600 } );

    my $encoded = _replace( $store->encode($data),
        3, encode_base64url( pack( "l*", rand, rand, rand, rand ) ) );

    my $decoded = $store->decode($encoded);
    is( $decoded, undef, "changed mac decodes to undef" );
};

subtest "truncated mac" => sub {
    my $store = _gen_store( { default_duration => 3600 } );

    my $encoded = _replace( $store->encode($data), 3, "" );

    my $decoded = $store->decode($encoded);
    is( $decoded, undef, "truncated mac decodes to undef" );
};

subtest "garbage encoded" => sub {
    my $store = _gen_store( { default_duration => 3600 } );

    my $encoded = encode_base64url( pack( "l*", rand, rand, rand, rand ) );

    my $decoded = $store->decode($encoded);
    is( $decoded, undef, "garbage decodes to undef" );
};

subtest "empty encoded" => sub {
    my $store = _gen_store( { default_duration => 3600 } );

    my $decoded = $store->decode('');
    is( $decoded, undef, "empty string decodes to undef" );
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
