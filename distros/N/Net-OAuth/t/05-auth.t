#!perl

use strict;
use warnings;
use Test::More tests => 6;

BEGIN {
    use Net::OAuth;
    $Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0;
    use_ok( 'Net::OAuth::Request' );
    use_ok( 'Net::OAuth::Response' );
    use_ok( 'Net::OAuth::UserAuthRequest' );
    use_ok( 'Net::OAuth::UserAuthResponse' );
}

my $request = Net::OAuth::UserAuthRequest->new(
    token => 'abcdef',
    callback => 'http://example.com/callback',
    extra_params => {
            foo => 'bar',
    },
);

is($request->to_post_body, 'foo=bar&oauth_callback=http%3A%2F%2Fexample.com%2Fcallback&oauth_token=abcdef');

my $response = Net::OAuth::UserAuthResponse->new(
    token => 'abcdef',
    extra_params => {
            foo => 'bar',
    },
);

is($response->to_post_body, 'foo=bar&oauth_token=abcdef');