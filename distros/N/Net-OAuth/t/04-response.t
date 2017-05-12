#!perl

use strict;
use warnings;
use Test::More tests => 5;

BEGIN {
    use Net::OAuth;
    $Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0;
    use_ok( 'Net::OAuth::Response' );
    use_ok( 'Net::OAuth::RequestTokenResponse' );
    use_ok( 'Net::OAuth::AccessTokenResponse' );
}

my $response = Net::OAuth::RequestTokenResponse->new(
	token => 'abcdef',
	token_secret => '0123456',
	extra_params => {
		foo => 'bar',
	},
);

is($response->to_post_body, 'foo=bar&oauth_token=abcdef&oauth_token_secret=0123456');

$response = Net::OAuth::AccessTokenResponse->new(
	token => 'abcdef',
	token_secret => '0123456',
	extra_params => {
		foo => 'bar',
	},
);

is($response->to_post_body, 'foo=bar&oauth_token=abcdef&oauth_token_secret=0123456');