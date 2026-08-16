#!perl

use strict;
use warnings;
use Test::More tests => 3;

use Net::OAuth::ProtectedResourceRequest;

sub slurp {
    my $file = shift;
    my $text = do { local( @ARGV, $/ ) = $file ; <> } ;
    return $text;
}

SKIP: {

    skip "Crypt::OpenSSL::RSA not installed", 3 unless eval 'require Crypt::OpenSSL::RSA';

    my $publickey;
    my $privkey;

    eval {
    $privkey = Crypt::OpenSSL::RSA->new_private_key(slurp('t/rsakey'));
    } or die "unable to read private key";
    eval {
    $publickey = Crypt::OpenSSL::RSA->new_public_key(slurp("t/rsakey.pub"));
    } or die "unable to read public key";

    # Crypt::OpenSSL::RSA 0.35 through 0.37 disabled PKCS#1 v1.5 padding over
    # the Marvin attack; 0.38 re-enabled it (PR #103). RFC 5849 3.4.3 requires
    # it, so RSA-SHA1 simply cannot be done on those releases.
    skip "Crypt::OpenSSL::RSA $Crypt::OpenSSL::RSA::VERSION cannot do PKCS#1 "
       . "v1.5 padding, which OAuth RSA-SHA1 requires; upgrade to 0.38+", 3
        unless eval { Crypt::OpenSSL::RSA->new_private_key(slurp('t/rsakey'))
                          ->use_pkcs1_padding; 1 };

    # Deliberately left un-tuned: Net::OAuth::SignatureMethod::RSA_SHA1 must
    # pin the hash and padding itself, since callers in the wild don't.

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

    # Assert the base string before the signature. It is pure Perl (sorting,
    # percent-encoding, no crypto), so checking it first splits a failure into
    # "we built the wrong string" vs "OpenSSL signed it differently" instead of
    # leaving you to diff two opaque base64 blobs.
    is($request->signature_base_string,
        'GET&http%3A%2F%2Fphotos.example.net%2Fphotos&file%3Dvacation.jpg'
      . '%26oauth_consumer_key%3Ddpf43f3p2l4k3l03%26oauth_nonce%3Dkllo9940pd9333jh'
      . '%26oauth_signature_method%3DRSA-SHA1%26oauth_timestamp%3D1191242096'
      . '%26oauth_token%3Dnnch734d00sl2jdk%26oauth_version%3D1.0%26size%3Doriginal',
        'signature base string (RFC 5849 3.4.1)');

    $request->sign;
    is($request->signature, "mkZ/wOq5cS7UOyKKdo5Khd4fYpYVhs20K0E8k/DyumO74rjo7s1y+Y+mZ/hBvy2gu6ip/U4XqTRdT0QObAUvrKf+fH/Yfdc6kQsQ9kP3/IgRF1K5Po284UIy8p7DcJGC5udR01aTkNkpqo3XAw+8ljULguhwVC1l+EWHrzKKuZ6li7EOx1It5JxWqCRVn+1+NA8vGlIjcaPb+aIoUmyM2/ytu1041cnvdDGzuiibRgIv770cuXsfkFNtaK5rgjlmhZhDwqULHfWEN9oxcHxY+6EB/HOvwWkYE1CeUoo9Dgm6mn6+DsfkTjfRh4mJRTIyi6jEYaIgY5RaWwSHaXw44A==");
    ok($request->verify($publickey));

}
