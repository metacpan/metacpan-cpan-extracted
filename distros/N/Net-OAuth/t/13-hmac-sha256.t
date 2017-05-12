#!perl

use strict;
use warnings;
use Test::More tests => 3;

use Net::OAuth::ProtectedResourceRequest;

SKIP: {

    skip "Digest::SHA not installed", 3 unless eval 'require Digest::SHA; 1';

    my $request = Net::OAuth::ProtectedResourceRequest->new(
            consumer_key => 'dpf43f3p2l4k3l03',
            consumer_secret => 'kd94hf93k423kf44',
            request_url => 'http://photos.example.net/photos',
            request_method => 'GET',
            signature_method => 'HMAC-SHA256',
            timestamp => '1191242096',
            nonce => 'kllo9940pd9333jh',
            token => 'nnch734d00sl2jdk',
            token_secret => 'pfkkdhi9sl3r4s00',
            extra_params => {
                file => 'vacation.jpg',
                size => 'original',
            },
    );

    $request->sign;

    is(length($request->signature), 44);
    is($request->signature, "WVPzl1j6ZsnkIjWr7e3OZ3jkenL57KwaLFhYsroX1hg=");
    ok($request->verify());

}
