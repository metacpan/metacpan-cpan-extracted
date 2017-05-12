#!perl

use strict;
use warnings;
use Test::More tests => 2;

use Net::OAuth::ProtectedResourceRequest;

sub slurp {
    my $file = shift;
    my $text = do { local( @ARGV, $/ ) = $file ; <> } ;
    return $text;
}

SKIP: {

    skip "Crypt::OpenSSL::RSA not installed", 2 unless eval 'require Crypt::OpenSSL::RSA';

    my $publickey;
    my $privkey;

    eval {
    $privkey = Crypt::OpenSSL::RSA->new_private_key(slurp('t/rsakey'));
    } or die "unable to read private key";
    eval {
    $publickey = Crypt::OpenSSL::RSA->new_public_key(slurp("t/rsakey.pub"));
    } or die "unable to read public key";

    my $request = Net::OAuth::ProtectedResourceRequest->new(
            consumer_key => 'dpf43f3p2l4k3l03',
            consumer_secret => 'kd94hf93k423kf44',
            request_url => 'http://photos.example.net/photos',
            request_method => 'GET',
            signature_method => 'RSA-SHA1',
            timestamp => '1191242096',
            nonce => 'kllo9940pd9333jh',
            token => 'nnch734d00sl2jdk',
            token_secret => 'pfkkdhi9sl3r4s00',
            extra_params => {
                file => 'vacation.jpg',
                size => 'original',
            },
            signature_key => $privkey,
    );

    $request->sign;
    is($request->signature, "mkZ/wOq5cS7UOyKKdo5Khd4fYpYVhs20K0E8k/DyumO74rjo7s1y+Y+mZ/hBvy2gu6ip/U4XqTRdT0QObAUvrKf+fH/Yfdc6kQsQ9kP3/IgRF1K5Po284UIy8p7DcJGC5udR01aTkNkpqo3XAw+8ljULguhwVC1l+EWHrzKKuZ6li7EOx1It5JxWqCRVn+1+NA8vGlIjcaPb+aIoUmyM2/ytu1041cnvdDGzuiibRgIv770cuXsfkFNtaK5rgjlmhZhDwqULHfWEN9oxcHxY+6EB/HOvwWkYE1CeUoo9Dgm6mn6+DsfkTjfRh4mJRTIyi6jEYaIgY5RaWwSHaXw44A==");
    ok($request->verify($publickey));

}
