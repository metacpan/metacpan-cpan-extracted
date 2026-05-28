#!/usr/bin/env perl
# Tests for SignalWire::Security::WebhookValidator.
#
# Cross-language SDK contract: every port must implement Scheme A (hex
# HMAC-SHA1 over url+raw_body for JSON/RELAY) and Scheme B (base64
# HMAC-SHA1 over url+sortedFormParams for cXML/Compat) per
# porting-sdk/webhooks.md. This file mirrors the Python reference test
# suite so a bug here is a real port-level bug.
#
# Vectors A, B, C below are the canonical vectors from the spec; if they
# break, a port has a real bug — DO NOT relax them.

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Digest::SHA qw(hmac_sha1);
use MIME::Base64 qw(encode_base64);

use SignalWire::Security::WebhookValidator
    qw(validate_webhook_signature validate_request);

# ---------------------------------------------------------------------------
# Canonical test vectors from porting-sdk/webhooks.md
# ---------------------------------------------------------------------------

my %VECTOR_A = (
    signing_key => 'PSKtest1234567890abcdef',
    url         => 'https://example.ngrok.io/webhook',
    raw_body    => '{"event":"call.state","params":{"call_id":"abc-123","state":"answered"}}',
    expected    => 'c3c08c1fefaf9ee198a100d5906765a6f394bf0f',
);

my %VECTOR_B_PARAMS = (
    CallSid => 'CA1234567890ABCDE',
    Caller  => '+14158675309',
    Digits  => '1234',
    From    => '+14158675309',
    To      => '+18005551212',
);
my %VECTOR_B = (
    signing_key => '12345',
    url         => 'https://mycompany.com/myapp.php?foo=1&bar=2',
    params      => \%VECTOR_B_PARAMS,
    expected    => 'RSOYDt4T1cUTdK1PDd93/VVr8B8=',
);

my %VECTOR_C = (
    signing_key => 'PSKtest1234567890abcdef',
    raw_body    => '{"event":"call.state"}',
    url         => 'https://example.ngrok.io/webhook?bodySHA256='
                 . '69f3cbfc18e386ef8236cb7008cd5a54b7fed637a8cb3373b5a1591d7f0fd5f4',
    expected    => 'dfO9ek8mxyFtn2nMz24plPmPfIY=',
);

# Build a percent-encoded form body that round-trips through the
# validator's parser back to the same key/value pairs Scheme B will
# sort and concat. We hand-encode rather than relying on hash-order so
# the test is deterministic.
sub form_encoded {
    my (%params) = @_;
    my $enc = sub {
        my ($s) = @_;
        $s =~ s/([^A-Za-z0-9._~-])/sprintf("%%%02X", ord($1))/ge;
        return $s;
    };
    return join('&', map { $enc->($_) . '=' . $enc->($params{$_}) }
        sort keys %params);
}

# Helper: produce a Scheme B base64 sig for arbitrary url + params.
sub b64_sig {
    my ($key, $url, %params) = @_;
    my $concat = $url;
    for my $k (sort keys %params) {
        $concat .= $k . $params{$k};
    }
    return encode_base64(hmac_sha1($concat, $key), '');
}

# ---------------------------------------------------------------------------
# Scheme A — RELAY/JSON (hex)
# ---------------------------------------------------------------------------

subtest 'Scheme A - canonical positive vector' => sub {
    ok(
        validate_webhook_signature(
            $VECTOR_A{signing_key},
            $VECTOR_A{expected},
            $VECTOR_A{url},
            $VECTOR_A{raw_body},
        ),
        'Vector A: known JSON body + URL + key produces expected hex digest',
    );
};

subtest 'Scheme A - tampered body returns false' => sub {
    my $tampered = $VECTOR_A{raw_body};
    $tampered =~ s/answered/ringing/;
    ok(
        !validate_webhook_signature(
            $VECTOR_A{signing_key},
            $VECTOR_A{expected},
            $VECTOR_A{url},
            $tampered,
        ),
        'Vector A: tampered body fails validation',
    );
};

subtest 'Scheme A - wrong key returns false' => sub {
    ok(
        !validate_webhook_signature(
            'wrong-key',
            $VECTOR_A{expected},
            $VECTOR_A{url},
            $VECTOR_A{raw_body},
        ),
        'different signing key against the same vector -> false',
    );
};

subtest 'Scheme A - wrong url returns false' => sub {
    ok(
        !validate_webhook_signature(
            $VECTOR_A{signing_key},
            $VECTOR_A{expected},
            'https://example.ngrok.io/different',
            $VECTOR_A{raw_body},
        ),
        'same body/key but different URL path -> false',
    );
};

# ---------------------------------------------------------------------------
# Scheme B — Compat / cXML (base64 form)
# ---------------------------------------------------------------------------

subtest 'Scheme B - canonical form-encoded vector' => sub {
    my $body = form_encoded(%VECTOR_B_PARAMS);
    ok(
        validate_webhook_signature(
            $VECTOR_B{signing_key},
            $VECTOR_B{expected},
            $VECTOR_B{url},
            $body,
        ),
        'Vector B: form params via raw body matches canonical Twilio digest',
    );
};

subtest 'Scheme B - validate_request with hashref delegates to Scheme B' => sub {
    ok(
        validate_request(
            $VECTOR_B{signing_key},
            $VECTOR_B{expected},
            $VECTOR_B{url},
            $VECTOR_B{params},
        ),
        'validate_request(..., \%params) goes straight to Scheme B',
    );
};

subtest 'Scheme B - validate_request with arrayref of pairs' => sub {
    my @pairs = map { [$_, $VECTOR_B_PARAMS{$_}] } keys %VECTOR_B_PARAMS;
    ok(
        validate_request(
            $VECTOR_B{signing_key},
            $VECTOR_B{expected},
            $VECTOR_B{url},
            \@pairs,
        ),
        'validate_request also accepts pre-parsed (key, value) tuples',
    );
};

subtest 'Scheme B - bodySHA256 canonical vector' => sub {
    ok(
        validate_webhook_signature(
            $VECTOR_C{signing_key},
            $VECTOR_C{expected},
            $VECTOR_C{url},
            $VECTOR_C{raw_body},
        ),
        'Vector C: JSON body on compat surface, signature over URL with bodySHA256',
    );
};

subtest 'Scheme B - bodySHA256 mismatch is rejected' => sub {
    # The HMAC over Vector C's URL and empty params still matches the
    # signature, but the bodySHA256 in the URL won't match a different
    # body — must reject.
    my $wrong_body = '{"event":"DIFFERENT"}';
    ok(
        !validate_webhook_signature(
            $VECTOR_C{signing_key},
            $VECTOR_C{expected},
            $VECTOR_C{url},
            $wrong_body,
        ),
        'bodySHA256 mismatch fails even when HMAC over URL would otherwise match',
    );
};

# ---------------------------------------------------------------------------
# URL port normalization
# ---------------------------------------------------------------------------

subtest 'URL port normalization - signed with :443, request without port' => sub {
    my $key  = 'test-key';
    my $with = 'https://example.com:443/webhook';
    my $sans = 'https://example.com/webhook';
    my $sig  = b64_sig($key, $with);
    # raw_body is non-form so Scheme B falls back to empty params.
    ok(
        validate_webhook_signature($key, $sig, $sans, '{}'),
        'sig signed with :443 accepted when request URL has no port',
    );
};

subtest 'URL port normalization - signed without port, request with :443' => sub {
    my $key  = 'test-key';
    my $with = 'https://example.com:443/webhook';
    my $sans = 'https://example.com/webhook';
    my $sig  = b64_sig($key, $sans);
    ok(
        validate_webhook_signature($key, $sig, $with, '{}'),
        'sig signed without port accepted when request URL has :443',
    );
};

subtest 'URL port normalization - http :80 mirrors https :443' => sub {
    my $key  = 'test-key';
    my $with = 'http://example.com:80/path';
    my $sans = 'http://example.com/path';
    my $sig  = b64_sig($key, $with);
    ok(
        validate_webhook_signature($key, $sig, $sans, ''),
        'http:80 normalization accepted',
    );
};

# ---------------------------------------------------------------------------
# Repeated form keys
# ---------------------------------------------------------------------------

subtest 'Repeated form keys - submission order preserved' => sub {
    my $key = 'test-key';
    my $url = 'https://example.com/hook';
    my $body = 'To=a&To=b';
    # Expected concat: "ToaTob" (sorted by key only; order within key preserved).
    my $expected_data = $url . 'ToaTob';
    my $sig = encode_base64(hmac_sha1($expected_data, $key), '');
    ok(
        validate_webhook_signature($key, $sig, $url, $body),
        'To=a&To=b hashes deterministically as ToaTob',
    );
};

subtest 'Repeated form keys - swapped order is a different signature' => sub {
    my $key = 'test-key';
    my $url = 'https://example.com/hook';
    my $sig_for_ab = encode_base64(hmac_sha1($url . 'ToaTob', $key), '');
    ok(
        validate_webhook_signature($key, $sig_for_ab, $url, 'To=a&To=b'),
        'sig for ab matches body To=a&To=b',
    );
    ok(
        !validate_webhook_signature($key, $sig_for_ab, $url, 'To=b&To=a'),
        'sig for ab does NOT match body To=b&To=a (order matters within key)',
    );
};

# ---------------------------------------------------------------------------
# Error modes
# ---------------------------------------------------------------------------

subtest 'Missing signature returns false (no exception)' => sub {
    ok(
        !validate_webhook_signature(
            $VECTOR_A{signing_key}, '', $VECTOR_A{url}, $VECTOR_A{raw_body},
        ),
        'empty signature -> false, no exception',
    );
    ok(
        !validate_webhook_signature(
            $VECTOR_A{signing_key}, undef, $VECTOR_A{url}, $VECTOR_A{raw_body},
        ),
        'undef signature -> false, no exception',
    );
};

subtest 'Missing signing_key croaks' => sub {
    dies_ok {
        validate_webhook_signature('', 'sig',
            $VECTOR_A{url}, $VECTOR_A{raw_body});
    } 'empty signing_key croaks';

    dies_ok {
        validate_webhook_signature(undef, 'sig',
            $VECTOR_A{url}, $VECTOR_A{raw_body});
    } 'undef signing_key croaks';
};

subtest 'Non-string raw_body croaks (e.g. parsed dict)' => sub {
    dies_ok {
        validate_webhook_signature(
            $VECTOR_A{signing_key}, 'sig', $VECTOR_A{url},
            { event => 'call.state' },
        );
    } 'hashref as raw_body croaks';

    dies_ok {
        validate_webhook_signature(
            $VECTOR_A{signing_key}, 'sig', $VECTOR_A{url},
            [ 'a', 'b' ],
        );
    } 'arrayref as raw_body croaks';
};

subtest 'Malformed signature returns false without throwing' => sub {
    for my $garbage ('xyz', '!!!!', 'a' x 100, '%%notbase64%%') {
        ok(
            !validate_webhook_signature(
                $VECTOR_A{signing_key}, $garbage,
                $VECTOR_A{url}, $VECTOR_A{raw_body},
            ),
            "garbage signature '$garbage' -> false (no throw)",
        );
    }
};

# ---------------------------------------------------------------------------
# validate_request alias dispatch
# ---------------------------------------------------------------------------

subtest 'validate_request - string arg delegates to combined validator' => sub {
    ok(
        validate_request(
            $VECTOR_A{signing_key},
            $VECTOR_A{expected},
            $VECTOR_A{url},
            $VECTOR_A{raw_body},
        ),
        'string fourth arg behaves like validate_webhook_signature',
    );
};

subtest 'validate_request - hashref runs Scheme B directly' => sub {
    ok(
        validate_request(
            $VECTOR_B{signing_key},
            $VECTOR_B{expected},
            $VECTOR_B{url},
            $VECTOR_B{params},
        ),
        'hashref fourth arg runs Scheme B directly',
    );
};

subtest 'validate_request - bad ref types croak' => sub {
    dies_ok {
        validate_request(
            $VECTOR_A{signing_key}, 'sig', $VECTOR_A{url},
            \'scalar-ref',
        );
    } 'scalar ref as 4th arg croaks';

    # Coderef should croak.
    dies_ok {
        validate_request(
            $VECTOR_A{signing_key}, 'sig', $VECTOR_A{url},
            sub { 1 },
        );
    } 'coderef as 4th arg croaks';
};

# ---------------------------------------------------------------------------
# Constant-time compare — verify by reading the source. Timing tests are
# flaky in CI; the porting-sdk spec explicitly requires a constant-time
# compare, so we assert the implementation does NOT use plain `eq` on
# the signature.
# ---------------------------------------------------------------------------

subtest 'Constant-time compare in source' => sub {
    require SignalWire::Security::WebhookValidator;
    my $path = $INC{'SignalWire/Security/WebhookValidator.pm'};
    ok($path && -f $path, "module file located: $path");
    open my $fh, '<', $path or die "open $path: $!";
    my $src = do { local $/; <$fh> };
    close $fh;

    like($src, qr/sub\s+_safe_eq/,
         'validator defines a constant-time compare helper');
    like($src, qr/_safe_eq\s*\(/,
         '_safe_eq is invoked in the validator');
    # And it must NOT use plain == / eq on the expected vs. signature
    # variables. Allow == elsewhere (loop indexing, length-mismatch
    # short-circuit) but the literal direct comparison patterns must
    # not appear.
    unlike($src, qr/\$expected_a\s+eq\s+\$signature/,
           'direct eq on expected_a vs signature is absent');
    unlike($src, qr/\$expected\s+eq\s+\$signature/,
           'direct eq on expected vs signature is absent');
};

# ---------------------------------------------------------------------------
# Sanity: signature-leak protection. We don't time-measure; instead
# verify that mismatching signatures of different lengths still return
# false (and don't throw) — protects against accidental short-circuit
# logic that would tell an attacker "your sig is wrong length".
# ---------------------------------------------------------------------------

subtest 'Different-length wrong signature still returns false' => sub {
    for my $len (1, 2, 5, 39, 41, 80, 200) {
        my $junk = 'a' x $len;
        ok(
            !validate_webhook_signature(
                $VECTOR_A{signing_key}, $junk,
                $VECTOR_A{url}, $VECTOR_A{raw_body},
            ),
            "wrong-length sig (len=$len) -> false, no throw",
        );
    }
};

done_testing;
