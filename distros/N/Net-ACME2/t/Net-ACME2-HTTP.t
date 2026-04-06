#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::FailWarnings;

use JSON ();
use MIME::Base64 ();
use HTTP::Status ();

use FindBin;
use lib "$FindBin::Bin/lib";

use Net::ACME2::HTTP;
use Net::ACME2::AccountKey;

#----------------------------------------------------------------------
# Test key material
# Use ECDSA P-256 to avoid Crypt::OpenSSL::RSA 0.35+ pkcs1 padding issues
#----------------------------------------------------------------------

my $_KEY_PEM = <<END;
-----BEGIN EC PRIVATE KEY-----
MHcCAQEEIKDv8TBijBVbTYB7lfUnwLn4qjqWD0GD7XOXzdp0wb61oAoGCCqGSM49
AwEHoUQDQgAEBJIULcFadtIBc0TuNzT80UFcfkQ0U7+EPqEJNXamG1H4/z8xVgE7
3hoBfX4xbN2Hx2p26eNIptt+1jj2H/M44g==
-----END EC PRIVATE KEY-----
END

#----------------------------------------------------------------------
# Mock UA that returns controlled responses
#----------------------------------------------------------------------

{
    package MockUA;

    sub new {
        my ($class, %opts) = @_;
        return bless {
            responses => $opts{responses} || [],
            requests  => [],
        }, $class;
    }

    sub request {
        my ($self, $method, $url, $args) = @_;

        push @{ $self->{requests} }, {
            method => $method,
            url    => $url,
            args   => $args,
        };

        my $resp = shift @{ $self->{responses} };
        die "MockUA: no more responses queued!" if !$resp;

        # Convert symbolic status names to numeric
        if ($resp->{status} && $resp->{status} =~ /^HTTP_/) {
            $resp->{status} = HTTP::Status->can($resp->{status})->();
        }

        $resp->{reason}  ||= HTTP::Status::status_message($resp->{status});
        $resp->{success}   = HTTP::Status::is_success($resp->{status});
        $resp->{url}       = $url;

        ref && ($_ = JSON::encode_json($_)) for $resp->{content};

        my $resp_obj = HTTP::Tiny::UA::Response->new($resp);

        return $resp_obj;
    }

    sub timeout { return 30 }
}

#----------------------------------------------------------------------

my $acme_key = Net::ACME2::AccountKey->new($_KEY_PEM);

#----------------------------------------------------------------------
# Test: GET request returns Response object
#----------------------------------------------------------------------

{
    my $mock = MockUA->new(responses => [
        {
            status  => 'HTTP_OK',
            headers => { 'content-type' => 'application/json' },
            content => { foo => 'bar' },
        },
    ]);

    my $http = Net::ACME2::HTTP->new(
        key => $acme_key,
        ua  => $mock,
    );

    my $resp = $http->get('https://example.com/directory');

    isa_ok($resp, 'Net::ACME2::HTTP::Response', 'get() returns Response');
    is($resp->status(), 200, 'get() response has correct status');

    my $struct = $resp->content_struct();
    is($struct->{foo}, 'bar', 'get() response content parsed correctly');

    my $req = $mock->{requests}[0];
    is($req->{method}, 'GET', 'get() sends GET method');
    is($req->{url}, 'https://example.com/directory', 'get() sends correct URL');
}

#----------------------------------------------------------------------
# Test: nonce is extracted from POST response
#----------------------------------------------------------------------

{
    my $nonce_url = 'https://example.com/new-nonce';

    my $mock = MockUA->new(responses => [
        # HEAD for first nonce
        {
            status  => 'HTTP_NO_CONTENT',
            headers => { 'replay-nonce' => 'first-nonce-abc' },
            content => '',
        },
        # POST /new-account
        {
            status  => 'HTTP_CREATED',
            headers => {
                'replay-nonce' => 'second-nonce-def',
                'content-type' => 'application/json',
                'location'     => 'https://example.com/acct/1',
            },
            content => { status => 'valid' },
        },
    ]);

    my $http = Net::ACME2::HTTP->new(
        key    => $acme_key,
        key_id => 'https://example.com/acct/1',
        ua     => $mock,
    );

    $http->set_new_nonce_url($nonce_url);

    my $resp = $http->post_key_id(
        'https://example.com/new-account',
        { termsOfServiceAgreed => JSON::true() },
    );

    isa_ok($resp, 'Net::ACME2::HTTP::Response', 'post_key_id() returns Response');
    is($resp->status(), 201, 'post_key_id() response status correct');

    # Verify HEAD was sent for nonce
    is($mock->{requests}[0]{method}, 'HEAD', 'first request is HEAD for nonce');
    is($mock->{requests}[0]{url}, $nonce_url, 'HEAD targets nonce URL');

    # Verify POST was sent with JWS
    is($mock->{requests}[1]{method}, 'POST', 'second request is POST');
    my $post_args = $mock->{requests}[1]{args};
    is($post_args->{headers}{'content-type'}, 'application/jose+json',
       'POST content-type is application/jose+json');

    # Verify the JWS contains the nonce
    my $jws = JSON::decode_json($post_args->{content});
    my $protected = JSON::decode_json(MIME::Base64::decode_base64url($jws->{protected}));
    is($protected->{nonce}, 'first-nonce-abc', 'JWS uses nonce from HEAD response');
    is($protected->{url}, 'https://example.com/new-account', 'JWS includes target URL');
}

#----------------------------------------------------------------------
# Test: subsequent POST reuses nonce from prior response (no HEAD)
#----------------------------------------------------------------------

{
    my $mock = MockUA->new(responses => [
        # HEAD for first nonce
        {
            status  => 'HTTP_NO_CONTENT',
            headers => { 'replay-nonce' => 'nonce-1' },
            content => '',
        },
        # first POST
        {
            status  => 'HTTP_OK',
            headers => {
                'replay-nonce' => 'nonce-2',
                'content-type' => 'application/json',
            },
            content => { ok => 1 },
        },
        # second POST (should reuse nonce-2, no HEAD)
        {
            status  => 'HTTP_OK',
            headers => {
                'replay-nonce' => 'nonce-3',
                'content-type' => 'application/json',
            },
            content => { ok => 2 },
        },
    ]);

    my $http = Net::ACME2::HTTP->new(
        key    => $acme_key,
        key_id => 'https://example.com/acct/1',
        ua     => $mock,
    );

    $http->set_new_nonce_url('https://example.com/new-nonce');

    # First POST triggers HEAD + POST
    $http->post_key_id('https://example.com/endpoint', '');

    # Second POST should reuse nonce-2
    $http->post_key_id('https://example.com/endpoint2', '');

    # Should be: HEAD, POST, POST (not HEAD, POST, HEAD, POST)
    is(scalar @{ $mock->{requests} }, 3, 'only 3 requests total (no extra HEAD)');
    is($mock->{requests}[2]{method}, 'POST', 'third request is POST, not HEAD');

    # Verify second POST used nonce-2
    my $jws = JSON::decode_json($mock->{requests}[2]{args}{content});
    my $protected = JSON::decode_json(MIME::Base64::decode_base64url($jws->{protected}));
    is($protected->{nonce}, 'nonce-2', 'second POST reuses nonce from first response');
}

#----------------------------------------------------------------------
# Test: post_full_jwt sends JWK in protected header (no kid)
#----------------------------------------------------------------------

{
    my $mock = MockUA->new(responses => [
        # HEAD for nonce
        {
            status  => 'HTTP_NO_CONTENT',
            headers => { 'replay-nonce' => 'nonce-full-jwt' },
            content => '',
        },
        # POST
        {
            status  => 'HTTP_CREATED',
            headers => {
                'replay-nonce' => 'nonce-next',
                'content-type' => 'application/json',
                'location'     => 'https://example.com/acct/1',
            },
            content => { status => 'valid' },
        },
    ]);

    my $http = Net::ACME2::HTTP->new(
        key => $acme_key,
        ua  => $mock,
    );

    $http->set_new_nonce_url('https://example.com/new-nonce');

    my $resp = $http->post_full_jwt(
        'https://example.com/new-account',
        { termsOfServiceAgreed => JSON::true() },
    );

    my $jws = JSON::decode_json($mock->{requests}[1]{args}{content});
    my $protected = JSON::decode_json(MIME::Base64::decode_base64url($jws->{protected}));

    ok(exists $protected->{jwk}, 'post_full_jwt() includes JWK in header');
    ok(!exists $protected->{kid}, 'post_full_jwt() does not include kid');
    is($protected->{alg}, 'ES256', 'post_full_jwt() uses ES256 for P-256 key');
}

#----------------------------------------------------------------------
# Test: post_key_id sends kid in protected header (no jwk)
#----------------------------------------------------------------------

{
    my $mock = MockUA->new(responses => [
        # HEAD for nonce
        {
            status  => 'HTTP_NO_CONTENT',
            headers => { 'replay-nonce' => 'nonce-kid' },
            content => '',
        },
        # POST
        {
            status  => 'HTTP_OK',
            headers => {
                'replay-nonce' => 'nonce-next',
                'content-type' => 'application/json',
            },
            content => { ok => 1 },
        },
    ]);

    my $http = Net::ACME2::HTTP->new(
        key    => $acme_key,
        key_id => 'https://example.com/acct/1',
        ua     => $mock,
    );

    $http->set_new_nonce_url('https://example.com/new-nonce');

    $http->post_key_id('https://example.com/some-resource', '');

    my $jws = JSON::decode_json($mock->{requests}[1]{args}{content});
    my $protected = JSON::decode_json(MIME::Base64::decode_base64url($jws->{protected}));

    ok(exists $protected->{kid}, 'post_key_id() includes kid in header');
    is($protected->{kid}, 'https://example.com/acct/1', 'kid matches key_id');
    ok(!exists $protected->{jwk}, 'post_key_id() does not include JWK');
}

#----------------------------------------------------------------------
# Test: HTTP error (4xx) is transformed into ACME exception
#----------------------------------------------------------------------

{
    my $mock = MockUA->new(responses => [
        # HEAD for nonce
        {
            status  => 'HTTP_NO_CONTENT',
            headers => { 'replay-nonce' => 'nonce-err' },
            content => '',
        },
    ]);

    # Override request to throw HTTP::Protocol error for the POST
    my $orig_request = \&MockUA::request;
    no warnings 'redefine';
    local *MockUA::request = sub {
        my ($self, $method, $url, $args) = @_;

        push @{ $self->{requests} }, {
            method => $method,
            url    => $url,
            args   => $args,
        };

        if ($method eq 'POST') {
            die Net::ACME2::X->create(
                'HTTP::Protocol',
                {
                    method  => 'POST',
                    url     => $url,
                    status  => 403,
                    reason  => 'Forbidden',
                    headers => { 'replay-nonce' => 'nonce-from-error' },
                    content => JSON::encode_json({
                        type   => 'urn:ietf:params:acme:error:unauthorized',
                        detail => 'Account not authorized',
                        status => 403,
                    }),
                },
            );
        }

        return $orig_request->($self, $method, $url, $args);
    };
    use warnings 'redefine';

    my $http = Net::ACME2::HTTP->new(
        key    => $acme_key,
        key_id => 'https://example.com/acct/1',
        ua     => $mock,
    );

    $http->set_new_nonce_url('https://example.com/new-nonce');

    my $err;
    eval {
        $http->post_key_id('https://example.com/some-resource', '');
        1;
    } or $err = $@;

    ok($err, 'HTTP error throws exception');
    ok($err->isa('Net::ACME2::X::ACME'), 'exception is Net::ACME2::X::ACME');

    my $acme_err = $err->get('acme');
    isa_ok($acme_err, 'Net::ACME2::Error', 'exception contains ACME error');
    like($acme_err->type(), qr/unauthorized/, 'ACME error type is unauthorized');
    is($acme_err->detail(), 'Account not authorized', 'ACME error detail preserved');
}

#----------------------------------------------------------------------
# Test: badNonce triggers retry
#----------------------------------------------------------------------

{
    my $attempt = 0;
    my $mock = MockUA->new(responses => []);

    # We need to intercept at a lower level for badNonce testing
    no warnings 'redefine';
    local *MockUA::request = sub {
        my ($self, $method, $url, $args) = @_;

        push @{ $self->{requests} }, {
            method => $method,
            url    => $url,
            args   => $args,
        };

        # HEAD for nonce
        if ($method eq 'HEAD') {
            my %resp = (
                status  => HTTP::Status::HTTP_NO_CONTENT(),
                reason  => 'No Content',
                success => 1,
                url     => $url,
                headers => { 'replay-nonce' => "nonce-$attempt" },
                content => '',
            );
            $attempt++;
            return HTTP::Tiny::UA::Response->new(\%resp);
        }

        # First POST attempt: badNonce error
        if ($method eq 'POST' && $attempt == 1) {
            $attempt++;
            die Net::ACME2::X->create(
                'HTTP::Protocol',
                {
                    method  => 'POST',
                    url     => $url,
                    status  => 403,
                    reason  => 'Forbidden',
                    headers => { 'replay-nonce' => "retry-nonce-$attempt" },
                    content => JSON::encode_json({
                        type   => 'urn:ietf:params:acme:error:badNonce',
                        detail => 'JWS has invalid anti-replay nonce',
                        status => 403,
                    }),
                },
            );
        }

        # Second POST attempt: success
        my %resp = (
            status  => HTTP::Status::HTTP_OK(),
            reason  => 'OK',
            success => 1,
            url     => $url,
            headers => {
                'replay-nonce' => 'final-nonce',
                'content-type' => 'application/json',
            },
            content => JSON::encode_json({ success => 1 }),
        );
        return HTTP::Tiny::UA::Response->new(\%resp);
    };
    use warnings 'redefine';

    my $http = Net::ACME2::HTTP->new(
        key    => $acme_key,
        key_id => 'https://example.com/acct/1',
        ua     => $mock,
    );

    $http->set_new_nonce_url('https://example.com/new-nonce');

    my $resp;
    my @warnings;
    {
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        $resp = $http->post_key_id('https://example.com/some-resource', '');
    }

    isa_ok($resp, 'Net::ACME2::HTTP::Response', 'badNonce retry succeeds');
    is($resp->status(), 200, 'retried request returns 200');

    # Should have logged a warning about the retry
    ok(scalar(@warnings) > 0, 'badNonce retry emits warning');
    like($warnings[0], qr/badNonce/, 'warning mentions badNonce');
}

#----------------------------------------------------------------------
# Test: set_key_id updates the key ID used in subsequent requests
#----------------------------------------------------------------------

{
    my $mock = MockUA->new(responses => [
        # HEAD for nonce
        {
            status  => 'HTTP_NO_CONTENT',
            headers => { 'replay-nonce' => 'nonce-setkey' },
            content => '',
        },
        # POST
        {
            status  => 'HTTP_OK',
            headers => {
                'replay-nonce' => 'nonce-next',
                'content-type' => 'application/json',
            },
            content => { ok => 1 },
        },
    ]);

    my $http = Net::ACME2::HTTP->new(
        key    => $acme_key,
        key_id => 'https://example.com/acct/old',
        ua     => $mock,
    );

    $http->set_new_nonce_url('https://example.com/new-nonce');

    # Update key ID
    $http->set_key_id('https://example.com/acct/new');

    $http->post_key_id('https://example.com/endpoint', '');

    my $jws = JSON::decode_json($mock->{requests}[1]{args}{content});
    my $protected = JSON::decode_json(MIME::Base64::decode_base64url($jws->{protected}));

    is($protected->{kid}, 'https://example.com/acct/new',
       'set_key_id() updates kid in subsequent JWS');
}

#----------------------------------------------------------------------
# Test: missing nonce URL on POST triggers error
#----------------------------------------------------------------------

{
    my $mock = MockUA->new(responses => []);

    my $http = Net::ACME2::HTTP->new(
        key    => $acme_key,
        key_id => 'https://example.com/acct/1',
        ua     => $mock,
    );

    # Don't call set_new_nonce_url()

    throws_ok(
        sub { $http->post_key_id('https://example.com/endpoint', '') },
        qr/newNonce/,
        'POST without nonce URL dies with helpful message',
    );
}

#----------------------------------------------------------------------
# Test: POST without key dies with structured exception
#----------------------------------------------------------------------

{
    my $mock = MockUA->new(responses => []);

    my $http = Net::ACME2::HTTP->new(
        ua => $mock,
    );

    $http->set_new_nonce_url('https://example.com/new-nonce');

    my $err;
    eval {
        $http->post_key_id('https://example.com/endpoint', '');
        1;
    } or $err = $@;

    ok($err, 'POST without key throws exception');
    like("$err", qr/key/, 'POST without key message mentions "key"');
    ok(
        eval { $err->isa('Net::ACME2::X::Generic') },
        'POST without key throws Net::ACME2::X::Generic',
    ) or diag("Got: " . ref($err) || $err);
}

#----------------------------------------------------------------------
# Test: _post with empty JWT method dies with structured exception
#----------------------------------------------------------------------

{
    my $mock = MockUA->new(responses => []);

    my $http = Net::ACME2::HTTP->new(
        key    => $acme_key,
        key_id => 'https://example.com/acct/1',
        ua     => $mock,
    );

    $http->set_new_nonce_url('https://example.com/new-nonce');

    # Call _post directly with an empty jwt_method to trigger the guard
    my $err;
    eval {
        $http->_post('', 'https://example.com/endpoint', '');
        1;
    } or $err = $@;

    ok($err, '_post without JWT method throws exception');
    like("$err", qr/JWT method/, '_post without JWT method message is descriptive');
    ok(
        eval { $err->isa('Net::ACME2::X::Generic') },
        '_post without JWT method throws Net::ACME2::X::Generic',
    ) or diag("Got: " . ref($err) || $err);
}

#----------------------------------------------------------------------
# Test: _xform_http_error re-throws exception intact (not via fragile $@)
#
# Historically, _xform_http_error did `$@ = $exc; die;` which relies on
# $@ surviving between assignment and die. If any DESTROY method (or
# other code) runs an eval{} in between, $@ gets clobbered to "" and
# the die propagates an empty/wrong exception. This test uses a guard
# object whose DESTROY clobbers $@ to prove the exception survives.
#----------------------------------------------------------------------

{
    package ClobberGuard;
    sub new { bless {}, shift }
    sub DESTROY { eval { 1 } }  # clobbers $@
}

{
    my $mock = MockUA->new(responses => []);

    # Make the UA throw an HTTP::Protocol error with a non-ACME body
    # so _xform_http_error doesn't convert it to an ACME exception —
    # it falls through to the bare re-throw path.
    no warnings 'redefine';
    local *MockUA::request = sub {
        my ($self, $method, $url, $args) = @_;

        # Create a guard that will clobber $@ when it goes out of scope
        my $guard = ClobberGuard->new();

        die Net::ACME2::X->create(
            'HTTP::Protocol',
            {
                method  => 'GET',
                url     => $url,
                status  => 500,
                reason  => 'Internal Server Error',
                headers => {},
                content => 'not json',
            },
        );
    };
    use warnings 'redefine';

    my $http = Net::ACME2::HTTP->new(
        key => $acme_key,
        ua  => $mock,
    );

    my $err;
    eval {
        $http->get('https://example.com/directory');
        1;
    } or $err = $@;

    ok($err, '_xform_http_error re-throws when DESTROY clobbers $@');
    ok(
        eval { $err->isa('Net::ACME2::X::Generic') },
        '_xform_http_error wraps unparsable body in Generic exception',
    ) or diag("Got: " . (defined $err ? $err : "(undef)"));

    # The original HTTP::Protocol exception is accessible via get('http')
    ok(
        eval { $err->get('http')->isa('Net::ACME2::X::HTTP::Protocol') },
        '_xform_http_error carries original HTTP::Protocol in "http" property',
    ) or diag("Got: " . (defined $err ? $err : "(undef)"));
}

#----------------------------------------------------------------------
# Test: _post catch block re-throws non-badNonce errors intact
#
# Same $@ clobbering concern as _xform_http_error, but in the _post
# method's catch callback. A non-badNonce ACME error must survive
# re-throw even when destructors clobber $@.
#----------------------------------------------------------------------

{
    my $mock = MockUA->new(responses => [
        # HEAD for nonce
        {
            status  => 'HTTP_NO_CONTENT',
            headers => { 'replay-nonce' => 'nonce-rethrow' },
            content => '',
        },
    ]);

    no warnings 'redefine';
    my $orig_request = \&MockUA::request;
    local *MockUA::request = sub {
        my ($self, $method, $url, $args) = @_;

        if ($method eq 'POST') {
            push @{ $self->{requests} }, {
                method => $method,
                url    => $url,
                args   => $args,
            };

            # Guard that clobbers $@ on destruction
            my $guard = ClobberGuard->new();

            die Net::ACME2::X->create(
                'HTTP::Protocol',
                {
                    method  => 'POST',
                    url     => $url,
                    status  => 403,
                    reason  => 'Forbidden',
                    headers => { 'replay-nonce' => 'nonce-err-rethrow' },
                    content => JSON::encode_json({
                        type   => 'urn:ietf:params:acme:error:unauthorized',
                        detail => 'Not authorized',
                        status => 403,
                    }),
                },
            );
        }

        return $orig_request->($self, $method, $url, $args);
    };
    use warnings 'redefine';

    my $http = Net::ACME2::HTTP->new(
        key    => $acme_key,
        key_id => 'https://example.com/acct/1',
        ua     => $mock,
    );

    $http->set_new_nonce_url('https://example.com/new-nonce');

    my $err;
    eval {
        $http->post_key_id('https://example.com/resource', '');
        1;
    } or $err = $@;

    ok($err, '_post catch re-throws non-badNonce error');
    ok(
        eval { $err->isa('Net::ACME2::X::ACME') },
        '_post catch preserves ACME exception type (not empty string)',
    ) or diag("Got: " . (defined $err ? $err : "(undef)"));
}

#----------------------------------------------------------------------
# Test: non-JSON error body includes parse failure in exception
#
# When a server returns a non-JSON error body (e.g., an HTML proxy error),
# JSON::decode_json() fails inside _xform_http_error(). The parse failure
# and raw response content must be surfaced in the exception so the caller
# can diagnose the server problem — not silently swallowed.
#----------------------------------------------------------------------

{
    my $mock = MockUA->new(responses => []);

    no warnings 'redefine';
    local *MockUA::request = sub {
        my ($self, $method, $url, $args) = @_;

        die Net::ACME2::X->create(
            'HTTP::Protocol',
            {
                method  => 'GET',
                url     => $url,
                status  => 502,
                reason  => 'Bad Gateway',
                headers => {},
                content => '<html><body>Bad Gateway</body></html>',
            },
        );
    };
    use warnings 'redefine';

    my $http = Net::ACME2::HTTP->new(
        key => $acme_key,
        ua  => $mock,
    );

    my $err;
    eval {
        $http->get('https://example.com/directory');
        1;
    } or $err = $@;

    ok($err, 'non-JSON error body throws exception');

    my $err_str = "$err";

    like(
        $err_str,
        qr/Bad Gateway/,
        'exception includes raw response content',
    );

    like(
        $err_str,
        qr/JSON|decode|parse/i,
        'exception mentions JSON parse failure',
    );
}

#----------------------------------------------------------------------
# Test: truncated JSON error body includes parse failure in exception
#----------------------------------------------------------------------

{
    my $mock = MockUA->new(responses => []);

    no warnings 'redefine';
    local *MockUA::request = sub {
        my ($self, $method, $url, $args) = @_;

        die Net::ACME2::X->create(
            'HTTP::Protocol',
            {
                method  => 'GET',
                url     => $url,
                status  => 500,
                reason  => 'Internal Server Error',
                headers => {},
                content => '{"type":"urn:ietf:params:acme:error:serverInternal","deta',
            },
        );
    };
    use warnings 'redefine';

    my $http = Net::ACME2::HTTP->new(
        key => $acme_key,
        ua  => $mock,
    );

    my $err;
    eval {
        $http->get('https://example.com/directory');
        1;
    } or $err = $@;

    ok($err, 'truncated JSON error body throws exception');

    my $err_str = "$err";

    like(
        $err_str,
        qr/serverInternal/,
        'truncated JSON: exception includes partial response content',
    );

    # Verify the original HTTP exception is accessible
    ok(
        eval { $err->get('http')->isa('Net::ACME2::X::HTTP::Protocol') },
        'exception carries original HTTP::Protocol error',
    );
}

done_testing();
