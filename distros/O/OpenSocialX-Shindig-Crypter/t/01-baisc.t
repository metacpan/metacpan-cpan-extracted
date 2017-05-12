#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 9;
use URI::Escape;
use OpenSocialX::Shindig::Crypter;

my $crypter = OpenSocialX::Shindig::Crypter->new(
    {
        cipher => 'length16length16',
        hmac   => 'forhmac_sha1',
        iv     => 'anotherlength16k'
    }
);

my $hash = {
    a => 1,
    c => 3,
    o => 5
};

my $encrypted = $crypter->wrap($hash);
sleep 1;
my $decrypted = $crypter->unwrap( $encrypted, 3600 );

is $decrypted->{a}, $hash->{a};
is $decrypted->{c}, $hash->{c};
is $decrypted->{o}, $hash->{o};

# test create_token
my $token = $crypter->create_token(
    {
        owner     => 2,
        viewer    => 4,
        app       => 6,
        app_url   => 'http://blabla/bla',
        domain    => 'http://foobar/',
        module_id => 10
    }
);
sleep 1;
$token = uri_unescape($token);    ######## for URL
my $data = $crypter->unwrap( $token, 3600 );
is $data->{o}, 2;
is $data->{v}, 4;
is $data->{a}, 6;
is $data->{u}, 'http://blabla/bla';
is $data->{d}, 'http://foobar/';
is $data->{m}, 10;
