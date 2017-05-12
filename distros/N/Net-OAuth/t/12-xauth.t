#!perl

use strict;
use warnings;
use Test::More tests => 5;

use Net::OAuth;

my $request = Net::OAuth->request('xauth access token')->new(
        consumer_key => 'dpf43f3p2l4k3l03',
        consumer_secret => 'kd94hf93k423kf44',
        request_url => 'https://photos.example.net/access_token',
        request_method => 'POST',
        signature_method => 'PLAINTEXT',
        timestamp => '1191242092',
        nonce => 'dji430splmx33448',
        token => 'hh5s93j4hdidpola',
        token_secret => 'hdhd0244k9j7ao03',
        x_auth_username => 'keeth',
        x_auth_password => 'foobar',
        x_auth_mode => 'client_auth',
);

$request->sign;

ok($request->verify);

is($request->to_post_body, 'oauth_consumer_key=dpf43f3p2l4k3l03&oauth_nonce=dji430splmx33448&oauth_signature=kd94hf93k423kf44%26hdhd0244k9j7ao03&oauth_signature_method=PLAINTEXT&oauth_timestamp=1191242092&oauth_version=1.0&x_auth_mode=client_auth&x_auth_password=foobar&x_auth_username=keeth');

eval {
    $request = Net::OAuth->request('xauth access token')->new(
            consumer_key => 'dpf43f3p2l4k3l03',
            consumer_secret => 'kd94hf93k423kf44',
            request_url => 'https://photos.example.net/access_token',
            request_method => 'POST',
            signature_method => 'PLAINTEXT',
            timestamp => '1191242092',
            nonce => 'dji430splmx33448',
            token => 'hh5s93j4hdidpola',
            token_secret => 'hdhd0244k9j7ao03',
    );
};

ok($@);

$request = Net::OAuth->request('yahoo access token refresh')->new(
        consumer_key => 'dpf43f3p2l4k3l03',
        consumer_secret => 'kd94hf93k423kf44',
        request_url => 'https://photos.example.net/access_token',
        request_method => 'POST',
        signature_method => 'HMAC-SHA1',
        timestamp => '1191242092',
        nonce => 'dji430splmx33448',
        token => 'hh5s93j4hdidpola',
        token_secret => 'hdhd0244k9j7ao03',
        session_handle => 'this is my session handle',
);

$request->sign;

ok($request->verify);

is($request->to_post_body, 'oauth_consumer_key=dpf43f3p2l4k3l03&oauth_nonce=dji430splmx33448&oauth_session_handle=this%20is%20my%20session%20handle&oauth_signature=cIkNa1a40fmnGuuWVYHWFOrTE3M%3D&oauth_signature_method=HMAC-SHA1&oauth_timestamp=1191242092&oauth_token=hh5s93j4hdidpola&oauth_version=1.0');
