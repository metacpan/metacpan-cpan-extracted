#!/usr/bin/env perl
# Tests for SignalWire::Security::WebhookMiddleware.
#
# Confirms the end-to-end signed-webhook gate:
#   - Valid signature -> wrapped app called, body forwarded.
#   - Invalid signature -> 403, app NOT called.
#   - Missing header -> 403, app NOT called.
#   - URL reconstruction honors X-Forwarded-* and SWML_PROXY_URL_BASE.
#   - Empty signing_key -> middleware is a passthrough (handled at higher
#     layers; AgentBase emits the disabled-warning).
#
# Uses Plack::Test which builds a real PSGI request env, so the
# psgi.input slurp + rewind path is exercised for real.

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Plack::Test;
use HTTP::Request::Common qw(POST);
use HTTP::Headers ();
use HTTP::Request ();
use Digest::SHA qw(hmac_sha1 hmac_sha1_hex);
use MIME::Base64 qw(encode_base64);

use SignalWire::Security::WebhookMiddleware;

my $SIGNING_KEY = 'PSKtest1234567890abcdef';

# Build a downstream PSGI app that records what it saw and returns 200.
sub make_recorder_app {
    my ($state) = @_;
    return sub {
        my $env = shift;
        $state->{called}++;
        # Pull psgi.input and read whatever's there so we can confirm
        # the body was forwarded intact.
        my $body = '';
        my $input = $env->{'psgi.input'};
        if ($input) {
            my $buf;
            while (my $n = $input->read($buf, 8192)) {
                $body .= $buf;
            }
        }
        $state->{body}      = $body;
        $state->{stash}     = $env->{'signalwire.raw_body'};
        $state->{path_info} = $env->{PATH_INFO};
        return [200, ['Content-Type' => 'application/json'],
            ['{"ok":true}']];
    };
}

# Compute the Scheme A signature for a given URL + body.
sub scheme_a_sig {
    my ($key, $url, $body) = @_;
    return hmac_sha1_hex($url . $body, $key);
}

# ---------------------------------------------------------------------------
# 1. Valid signature -> 200 + downstream app called + body forwarded.
# ---------------------------------------------------------------------------
subtest 'Valid signature -> app called, 200, body forwarded' => sub {
    my %state;
    my $app = SignalWire::Security::WebhookMiddleware->wrap(
        app             => make_recorder_app(\%state),
        signing_key     => $SIGNING_KEY,
        public_url_base => 'https://example.ngrok.io',
        # No path whitelist -> all POSTs gated.
    );

    my $body = '{"event":"call.state","params":{"call_id":"abc"}}';
    # Reconstructed URL = public_url_base + REQUEST_URI = base + path.
    my $sig = scheme_a_sig($SIGNING_KEY, 'https://example.ngrok.io/swaig', $body);

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new('POST' => '/swaig');
        $req->header('Content-Type'              => 'application/json');
        $req->header('X-SignalWire-Signature'    => $sig);
        $req->content($body);
        $req->header('Content-Length' => length($body));
        my $res = $cb->($req);
        is($res->code, 200, '200 OK on valid signature');
        is($state{called}, 1, 'downstream app was called once');
        is($state{body}, $body, 'raw body forwarded to downstream app');
        is($state{stash}, $body, 'signalwire.raw_body env stash populated');
        is($state{path_info}, '/swaig', 'PATH_INFO preserved');
    };
};

# ---------------------------------------------------------------------------
# 2. Invalid signature -> 403, app NOT called.
# ---------------------------------------------------------------------------
subtest 'Invalid signature -> 403, app NOT called' => sub {
    my %state;
    my $app = SignalWire::Security::WebhookMiddleware->wrap(
        app             => make_recorder_app(\%state),
        signing_key     => $SIGNING_KEY,
        public_url_base => 'https://example.ngrok.io',
    );

    my $body = '{"event":"call.state"}';

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new('POST' => '/swaig');
        $req->header('Content-Type'           => 'application/json');
        $req->header('X-SignalWire-Signature' => 'totally-bogus-sig');
        $req->content($body);
        $req->header('Content-Length' => length($body));
        my $res = $cb->($req);
        is($res->code, 403, '403 Forbidden on bad signature');
        ok(!$state{called}, 'downstream app NOT called');
    };
};

# ---------------------------------------------------------------------------
# 3. Missing header -> 403, app NOT called.
# ---------------------------------------------------------------------------
subtest 'Missing X-SignalWire-Signature -> 403, app NOT called' => sub {
    my %state;
    my $app = SignalWire::Security::WebhookMiddleware->wrap(
        app             => make_recorder_app(\%state),
        signing_key     => $SIGNING_KEY,
        public_url_base => 'https://example.ngrok.io',
    );

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new('POST' => '/swaig');
        $req->header('Content-Type' => 'application/json');
        $req->content('{"event":"call.state"}');
        my $res = $cb->($req);
        is($res->code, 403, '403 when signature header is missing');
        ok(!$state{called}, 'app NOT called when sig missing');
    };
};

# ---------------------------------------------------------------------------
# 4. X-Twilio-Signature alias accepted on legacy compat surface.
# ---------------------------------------------------------------------------
subtest 'X-Twilio-Signature legacy alias accepted' => sub {
    my %state;
    my $app = SignalWire::Security::WebhookMiddleware->wrap(
        app             => make_recorder_app(\%state),
        signing_key     => $SIGNING_KEY,
        public_url_base => 'https://example.ngrok.io',
    );

    my $body = '{"event":"call.state"}';
    my $sig  = scheme_a_sig($SIGNING_KEY, 'https://example.ngrok.io/cxml', $body);

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new('POST' => '/cxml');
        $req->header('Content-Type'        => 'application/json');
        $req->header('X-Twilio-Signature'  => $sig);
        $req->content($body);
        $req->header('Content-Length' => length($body));
        my $res = $cb->($req);
        is($res->code, 200, 'legacy X-Twilio-Signature accepted');
        is($state{called}, 1, 'downstream app called');
    };
};

# ---------------------------------------------------------------------------
# 5. Path whitelist: requests outside the whitelist passthrough unchecked.
# ---------------------------------------------------------------------------
subtest 'Path whitelist - non-gated paths passthrough' => sub {
    my %state;
    my $app = SignalWire::Security::WebhookMiddleware->wrap(
        app             => make_recorder_app(\%state),
        signing_key     => $SIGNING_KEY,
        public_url_base => 'https://example.ngrok.io',
        paths           => ['/swaig'],
    );

    test_psgi $app, sub {
        my $cb = shift;
        # /healthz isn't gated -> no signature required, app reachable.
        my $req = HTTP::Request->new('POST' => '/healthz');
        $req->content('');
        $req->header('Content-Length' => 0);
        my $res = $cb->($req);
        is($res->code, 200, 'non-gated path returns 200 without signature');
        is($state{called}, 1, 'downstream app reached');
    };
};

# ---------------------------------------------------------------------------
# 6. GET requests passthrough by default (only POST is gated).
# ---------------------------------------------------------------------------
subtest 'GET passes through, POST is gated' => sub {
    my %state;
    my $app = SignalWire::Security::WebhookMiddleware->wrap(
        app             => make_recorder_app(\%state),
        signing_key     => $SIGNING_KEY,
        public_url_base => 'https://example.ngrok.io',
    );

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new('GET' => '/swaig');
        my $res = $cb->($req);
        is($res->code, 200, 'GET passes through');
        is($state{called}, 1, 'downstream app reached on GET');
    };
};

# ---------------------------------------------------------------------------
# 7. SWML_PROXY_URL_BASE env var drives URL reconstruction.
# ---------------------------------------------------------------------------
subtest 'SWML_PROXY_URL_BASE env var honored' => sub {
    local $ENV{SWML_PROXY_URL_BASE} = 'https://example.ngrok.io';
    my %state;
    my $app = SignalWire::Security::WebhookMiddleware->wrap(
        app         => make_recorder_app(\%state),
        signing_key => $SIGNING_KEY,
        # Note: no public_url_base passed.
    );

    my $body = '{"hello":"world"}';
    my $sig  = scheme_a_sig($SIGNING_KEY, 'https://example.ngrok.io/post_prompt', $body);

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new('POST' => '/post_prompt');
        $req->header('Content-Type'           => 'application/json');
        $req->header('X-SignalWire-Signature' => $sig);
        $req->content($body);
        $req->header('Content-Length' => length($body));
        my $res = $cb->($req);
        is($res->code, 200, 'SWML_PROXY_URL_BASE drives URL reconstruction');
        is($state{called}, 1, 'app called');
    };
};

# ---------------------------------------------------------------------------
# 8. X-Forwarded-Proto / X-Forwarded-Host honored when trust_proxy is on.
# ---------------------------------------------------------------------------
subtest 'X-Forwarded-* headers used when trust_proxy is on' => sub {
    my %state;
    my $app = SignalWire::Security::WebhookMiddleware->wrap(
        app         => make_recorder_app(\%state),
        signing_key => $SIGNING_KEY,
        trust_proxy => 1,
    );

    my $body = '{"forwarded":"yes"}';
    my $sig  = scheme_a_sig($SIGNING_KEY, 'https://public.example.com/swaig', $body);

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new('POST' => '/swaig');
        $req->header('Content-Type'           => 'application/json');
        $req->header('X-SignalWire-Signature' => $sig);
        $req->header('X-Forwarded-Proto'      => 'https');
        $req->header('X-Forwarded-Host'       => 'public.example.com');
        $req->content($body);
        $req->header('Content-Length' => length($body));
        my $res = $cb->($req);
        is($res->code, 200, 'X-Forwarded-* used when trust_proxy is on');
        is($state{called}, 1, 'app called');
    };
};

# ---------------------------------------------------------------------------
# 9. trust_proxy=0 ignores X-Forwarded-* headers.
# ---------------------------------------------------------------------------
subtest 'trust_proxy=0 ignores X-Forwarded-* headers' => sub {
    my %state;
    my $app = SignalWire::Security::WebhookMiddleware->wrap(
        app         => make_recorder_app(\%state),
        signing_key => $SIGNING_KEY,
        trust_proxy => 0,
    );

    my $body = '{"forwarded":"yes"}';
    # Sign as if the request came in via the public URL — but with
    # trust_proxy=0, the middleware will reconstruct from raw env (which
    # is the test client's loopback) so signature won't match.
    my $sig  = scheme_a_sig($SIGNING_KEY, 'https://public.example.com/swaig', $body);

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new('POST' => '/swaig');
        $req->header('Content-Type'           => 'application/json');
        $req->header('X-SignalWire-Signature' => $sig);
        $req->header('X-Forwarded-Proto'      => 'https');
        $req->header('X-Forwarded-Host'       => 'public.example.com');
        $req->content($body);
        $req->header('Content-Length' => length($body));
        my $res = $cb->($req);
        is($res->code, 403, '403 because reconstructed URL uses raw env, not X-Forwarded-*');
        ok(!$state{called}, 'app NOT called');
    };
};

# ---------------------------------------------------------------------------
# 10. Empty signing_key -> middleware is passthrough (caller's choice).
# ---------------------------------------------------------------------------
subtest 'Empty signing_key -> passthrough (no validation)' => sub {
    my %state;
    my $app = SignalWire::Security::WebhookMiddleware->wrap(
        app         => make_recorder_app(\%state),
        signing_key => '',  # disabled
    );

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new('POST' => '/swaig');
        $req->content('{"unsigned":"true"}');
        $req->header('Content-Length' => 19);
        my $res = $cb->($req);
        is($res->code, 200, 'unsigned request reaches downstream when key is empty');
        is($state{called}, 1, 'app called');
    };
};

# ---------------------------------------------------------------------------
# 11. wrap() input validation
# ---------------------------------------------------------------------------
subtest 'wrap() input validation' => sub {
    dies_ok {
        SignalWire::Security::WebhookMiddleware->wrap(
            signing_key => $SIGNING_KEY,
        );
    } "wrap dies without 'app'";

    dies_ok {
        SignalWire::Security::WebhookMiddleware->wrap(
            app         => 'not-a-coderef',
            signing_key => $SIGNING_KEY,
        );
    } "wrap dies when 'app' is not a CODE ref";
};

# ---------------------------------------------------------------------------
# 12. Form-encoded body (Scheme B) accepted via middleware.
# ---------------------------------------------------------------------------
subtest 'Form-encoded body validates via middleware (Scheme B)' => sub {
    my %state;
    my $app = SignalWire::Security::WebhookMiddleware->wrap(
        app             => make_recorder_app(\%state),
        signing_key     => '12345',
        public_url_base => 'https://mycompany.com',
    );

    # Twilio canonical vector: form params -> base64 sig.
    my %params = (
        CallSid => 'CA1234567890ABCDE',
        Caller  => '+14158675309',
        Digits  => '1234',
        From    => '+14158675309',
        To      => '+18005551212',
    );

    # Build the body the same way the middleware will see it.
    my $enc = sub {
        my ($s) = @_;
        $s =~ s/([^A-Za-z0-9._~-])/sprintf("%%%02X", ord($1))/ge;
        return $s;
    };
    my $body = join('&', map { $enc->($_) . '=' . $enc->($params{$_}) }
        sort keys %params);

    my $url = 'https://mycompany.com/myapp.php?foo=1&bar=2';
    my $concat = $url . join('', map { $_ . $params{$_} } sort keys %params);
    my $sig = encode_base64(hmac_sha1($concat, '12345'), '');

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new('POST' => '/myapp.php?foo=1&bar=2');
        $req->header('Content-Type'           => 'application/x-www-form-urlencoded');
        $req->header('X-SignalWire-Signature' => $sig);
        $req->content($body);
        $req->header('Content-Length' => length($body));
        my $res = $cb->($req);
        is($res->code, 200, 'form-encoded request validates (Scheme B)');
        is($state{called}, 1, 'app called');
    };
};

done_testing;
