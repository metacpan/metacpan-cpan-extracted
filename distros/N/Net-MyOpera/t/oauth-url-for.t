#!perl -T

use strict;
use warnings;
use Test::More tests => 6;
use URI;

use_ok('Net::MyOpera');

my $my = Net::MyOpera->new(
    consumer_key => 'fake',
    consumer_secret => 'fake-too',
);

my $oauth_url = $my->oauth_url_for('request_token', arg1=>'val1', arg2=>'val2');
my $uri = URI->new($oauth_url);

is(
    $uri->scheme, 'https',
    "Make sure we're using HTTPS for OAuth APIs",
);

like(
    $uri->path, qr{/request_token},
    "Path should be the OAuth 'step'",
);

is(
    $uri->path, '/service/oauth/request_token',
    "Path should contain the OAuth API root path",
);

like(
    $uri->query(), qr{arg1=val1},
    'Arguments should be filled in correctly',
);

like(
    $uri->query(), qr{arg2=val2},
    'Arguments should be filled in correctly',
);

