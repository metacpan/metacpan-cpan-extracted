#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Test::More;
use Test::FailWarnings;
use Test::Deep;
use Test::Exception;

use File::Spec;
use File::Temp;

use Protocol::DBus::Authn::Mechanism::DBUS_COOKIE_SHA1::Pieces ();

for my $sha1mod ( qw( Digest::SHA1 Digest::SHA ) ) {
    ok(
        !$sha1mod->can('sha1_hex'),
        "$sha1mod isn’t compiled in",
    );
}

my $pieces_ns = 'Protocol::DBus::Authn::Mechanism::DBUS_COOKIE_SHA1::Pieces';

like(
    $pieces_ns->create_challenge(),
    qr<\A[0-9a-f]{40,}\z>,
    'create_challenge()',
);

is(
    $pieces_ns->can('sha1_hex')->("1\x0a"),
    'e5fa44f2b31c1fb553b6021e7360d07d5d91ff5e',
    'sha1_hex()',
);

#----------------------------------------------------------------------

my $dir = File::Temp::tempdir( CLEANUP => 1 );

my $keyrings_dir = File::Spec->catfile( $dir, Protocol::DBus::Authn::Mechanism::DBUS_COOKIE_SHA1::Pieces::KEYRINGS_DIR() );

mkdir $keyrings_dir;

my $file = File::Spec->catfile( $keyrings_dir, 'my_cookie_ctx' );

{
    open my $wfh, '>', $file;
    print {$wfh} "12345 99999 deadbeef1234$/";
    print {$wfh} "23456 88888 deadbeef5678$/";
}

is(
    $pieces_ns->can('get_cookie')->( $dir, 'my_cookie_ctx', 12345 ),
    'deadbeef1234',
    'cookie on 1st line',
);

is(
    $pieces_ns->can('get_cookie')->( $dir, 'my_cookie_ctx', 23456 ),
    'deadbeef5678',
    'cookie on 2nd line',
);

dies_ok(
    sub {
        $pieces_ns->can('get_cookie')->( $dir, 'bad_cookie_ctx', 12345  )
    },
    'nonexistent cookie context prompts an exception',
);
my $err = $@;

cmp_deeply(
    $err,
    all(
        re( qr<\Q$keyrings_dir\E> ),
        re( qr<bad_cookie_ctx> ),
    ),
    '… and the error looks as expected',
);

dies_ok(
    sub {
        $pieces_ns->can('get_cookie')->( $dir, 'my_cookie_ctx', 34567  )
    },
    'nonexistent cookie ID prompts an exception',
);
$err = $@;

cmp_deeply(
    $err,
    all(
        re( qr<34567> ),
        re( qr<\Q$keyrings_dir\E> ),
        re( qr<my_cookie_ctx> ),
    ),
    '… and the error looks as expected',
);

#----------------------------------------------------------------------

done_testing();
