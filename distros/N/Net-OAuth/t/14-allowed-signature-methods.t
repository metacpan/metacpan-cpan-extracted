#!perl

# verify() has to be told which signature methods to accept. The method
# named in a message is chosen by whoever sent that message, so on the
# verifying side it is untrusted input, and dispatching on it lets the
# sender pick the algorithm - and therefore the key - we check their
# signature with.

use strict;
use warnings;
use Test::More tests => 12;

use Net::OAuth;
use Net::OAuth::ProtectedResourceRequest;

my %COMMON = (
    consumer_key    => 'dpf43f3p2l4k3l03',
    consumer_secret => 'kd94hf93k423kf44',
    request_url     => 'http://photos.example.net/photos',
    request_method  => 'GET',
    timestamp       => '1191242096',
    nonce           => 'kllo9940pd9333jh',
    token           => 'nnch734d00sl2jdk',
    token_secret    => 'pfkkdhi9sl3r4s00',
);

sub signed_request {
    my %args = @_;
    my $method = delete $args{signature_method} || 'HMAC-SHA1';
    my $request = Net::OAuth::ProtectedResourceRequest->new(
        %COMMON,
        signature_method => $method,
        %args,
    );
    $request->sign;
    return $request;
}

# Nothing stated: verify refuses rather than trust the message.

{
    local @Net::OAuth::ALLOWED_SIGNATURE_METHODS = ();
    my $request = signed_request();
    ok(!eval { $request->verify; 1 }, 'unpinned verify does not run');
    like($@, qr/no acceptable signature method/,
        '... and says what to do about it');
    ok(eval { $request->sign; 1 },
        'signing is unaffected - the sender chooses for itself');
}

# Stated process-wide.

{
    local @Net::OAuth::ALLOWED_SIGNATURE_METHODS = ('HMAC-SHA1');
    ok(signed_request()->verify, 'the stated method verifies');
}

{
    local @Net::OAuth::ALLOWED_SIGNATURE_METHODS = ('HMAC_SHA1');
    ok(signed_request()->verify,
        'the underscore spelling is the same method, not a second one');
}

{
    local @Net::OAuth::ALLOWED_SIGNATURE_METHODS = ('PLAINTEXT', 'HMAC-SHA1');
    ok(signed_request()->verify, 'any one of several stated methods verifies');
}

# The defect this guards: a Service Provider deployed with RSA-SHA1 holds
# only the Consumer's public key, and is asked to verify an HMAC-SHA1
# message - whose key it would derive from consumer_secret, a field
# RSA-SHA1 never uses and such a deployment has no reason to keep secret.

{
    local @Net::OAuth::ALLOWED_SIGNATURE_METHODS = ('RSA-SHA1');
    my $request = signed_request();
    ok(!eval { $request->verify; 1 },
        'a method outside the stated list is refused');
    like($@, qr/not an allowed signature method/, '... naming it');
}

# Stated per message.

{
    local @Net::OAuth::ALLOWED_SIGNATURE_METHODS = ();
    ok(signed_request(allowed_signature_methods => ['HMAC-SHA1'])->verify,
        'the api parameter is enough on its own');
    my $request = signed_request(allowed_signature_methods => ['PLAINTEXT']);
    ok(!eval { $request->verify; 1 },
        '... and refuses a method outside it');
}

{
    local @Net::OAuth::ALLOWED_SIGNATURE_METHODS = ('PLAINTEXT');
    ok(signed_request(allowed_signature_methods => ['HMAC-SHA1'])->verify,
        'the api parameter overrides the process-wide default');
    my $request = signed_request(allowed_signature_methods => ['RSA-SHA1']);
    ok(!eval { $request->verify; 1 },
        '... in the restrictive direction too');
}
