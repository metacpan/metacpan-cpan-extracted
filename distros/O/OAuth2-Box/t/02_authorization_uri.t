#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use OAuth2::Box;

my $ob = OAuth2::Box->new(
    client_id     => 123,
    client_secret => 'abcdef123',
    redirect_uri  => 'http://localhost/',
);

throws_ok { $ob->authorization_uri }
    qr/Assertion \(need state\)/,
    'state is needed - die when it is missing';

my $uri = $ob->authorization_uri( state => 'authenticated' );

is $uri, 'https://www.box.com/api/oauth2/authorize?client_id=123&response_type=code&redirect_uri=http%3A%2F%2Flocalhost%2F&state=authenticated';

my $ob2 = OAuth2::Box->new(
    client_id     => 123,
    client_secret => 'abcdef123',
    redirect_uri  => 'http://localhost/',
    url           => 'http://localhost:3000/authorize',
);

my $uri2 = $ob2->authorization_uri( state => 'auth' );

is $uri2, 'http://localhost:3000/authorize?client_id=123&response_type=code&redirect_uri=http%3A%2F%2Flocalhost%2F&state=auth';

done_testing();
