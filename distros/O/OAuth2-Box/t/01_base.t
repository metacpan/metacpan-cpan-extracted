#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok 'OAuth2::Box';

throws_ok { OAuth2::Box->new }
    qr/Missing .* client_id, client_secret, redirect_uri/,
    'new obect without params dies';

throws_ok { OAuth2::Box->new( client_id => 123 ) }
    qr/Missing .* client_secret, redirect_uri/,
    'new obect with client_id only dies';
throws_ok {
    OAuth2::Box->new(
        client_id => 123,
        client_secret => 'abcdef123',
    );
    }
    qr/Missing .* redirect_uri/,
    'new obect with client_id and client_secret only dies';

my $ob = OAuth2::Box->new(
    client_id     => 123,
    client_secret => 'abcdef123',
    redirect_uri  => 'http://localhost/',
);

isa_ok $ob, 'OAuth2::Box', 'new obect created';

can_ok $ob, qw/authorization_uri authorize refresh_token/;

my ($before,$after) = (""," is a read-only accessor");
if ( $INC{"Class/XSAccessor.pm"} ) {
    $before = "Usage: OAuth2::Box::";
    $after  = '\(self\)';
}

is $ob->url, 'https://www.box.com/api/oauth2/authorize', 'check authorization url';
throws_ok { $ob->url('test' ) }
    qr/${before}url$after/,
    'url is "ro"';

is $ob->token_url, 'https://www.box.com/api/oauth2/token', 'check token url';
throws_ok { $ob->token_url('test' ) }
    qr/${before}token_url$after/,
    'token_url is "ro"';

is $ob->client_id, 123, 'check client_id';
throws_ok { $ob->client_id('test' ) }
    qr/${before}client_id$after/,
    'client_id is "ro"';

is $ob->client_secret, 'abcdef123', 'check client_secret';
throws_ok { $ob->client_secret('test' ) }
    qr/${before}client_secret$after/,
    'client_secret is "ro"';

is $ob->redirect_uri, 'http://localhost/', 'check redirect_uri';
throws_ok { $ob->redirect_uri('test' ) }
    qr/${before}redirect_uri$after/,
    'redirect_uri is "ro"';

done_testing();
