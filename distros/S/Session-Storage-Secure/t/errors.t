use 5.008001;
use strict;
use warnings;
use Test::More 0.96;
use Test::Fatal;

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

subtest "bad data" => sub {
    my $store = _gen_store;
    like(
        exception { $store->encode( { foo => bless {} } ) },
        qr/Encoding error/,
        "Invalid data throws encoding error",
    );
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
