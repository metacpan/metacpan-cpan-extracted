use strict;
use warnings;

use Test::More;
use Test::Exception;
use JSON::MaybeXS qw(encode_json);
use Future;

use Net::Async::Zitadel::OIDC;
use Net::Async::Zitadel::Error;

# --- Mock helpers ---

{
    package Local::Response;
    sub new {
        my ($class, %args) = @_;
        bless \%args, $class;
    }
    sub is_success      { $_[0]->{is_success} }
    sub status_line     { $_[0]->{status_line} }
    sub decoded_content { $_[0]->{decoded_content} // '' }
}

{
    # Mock Net::Async::HTTP: queue of pre-resolved Futures.
    # GET and do_request both pull from the same queue.
    package Local::MockHTTP;

    sub new {
        my ($class, @futures) = @_;
        bless { queue => [@futures], calls => [] }, $class;
    }

    sub calls { $_[0]->{calls} }

    sub _next {
        my ($self, $label, @args) = @_;
        push @{ $self->{calls} }, { method => $label, args => [@args] };
        my $f = shift @{ $self->{queue} };
        die "No more mock responses in queue (next call: $label)\n" unless $f;
        return $f;
    }

    sub GET         { $_[0]->_next('GET',         @_[1..$#_]) }
    sub do_request  { my ($self, %args) = @_; $self->_next('do_request', %args) }
}

sub _ok { Future->done(Local::Response->new(is_success => 1, status_line => '200 OK', decoded_content => encode_json($_[0]))) }
sub _err { Future->done(Local::Response->new(is_success => 0, status_line => $_[0], decoded_content => $_[1] // '')) }
sub _never { Future->new }  # never resolves — simulates timeout

sub _discovery {
    return {
        jwks_uri               => 'https://zitadel.example.com/oauth/v2/keys',
        token_endpoint         => 'https://zitadel.example.com/oauth/v2/token',
        userinfo_endpoint      => 'https://zitadel.example.com/oidc/v1/userinfo',
        authorization_endpoint => 'https://zitadel.example.com/oauth/v2/authorize',
        introspection_endpoint => 'https://zitadel.example.com/oauth/v2/introspect',
    };
}

{
    # Subclass to inject a controllable JWT decoder
    package Local::MockOIDC;
    use Moo;
    extends 'Net::Async::Zitadel::OIDC';

    has decoder => (is => 'ro', required => 1);

    sub _decode_jwt {
        my ($self, %args) = @_;
        return $self->decoder->($self, %args);
    }
}

# --- Discovery caching and TTL ---

{
    my $http = Local::MockHTTP->new(
        _ok(_discovery()),
        _ok(_discovery()),
    );

    my $oidc = Net::Async::Zitadel::OIDC->new(
        issuer        => 'https://zitadel.example.com',
        http          => $http,
        discovery_ttl => 3600,
    );

    my $doc = $oidc->discovery_f->get;
    is $doc->{token_endpoint}, 'https://zitadel.example.com/oauth/v2/token',
        'discovery_f returns parsed document';

    # Second call within TTL uses cache
    my $doc2 = $oidc->discovery_f->get;
    is scalar @{ $http->calls }, 1, 'discovery fetched exactly once within TTL';
    is $doc2->{jwks_uri}, 'https://zitadel.example.com/oauth/v2/keys',
        'cached discovery has jwks_uri';

    # Simulate TTL expiry
    $oidc->_discovery_expires(time() - 1);
    my $doc3 = $oidc->discovery_f->get;
    is scalar @{ $http->calls }, 2, 'discovery re-fetched after TTL expiry';

    # TTL=0 disables caching
    my $oidc2 = Net::Async::Zitadel::OIDC->new(
        issuer        => 'https://zitadel.example.com',
        http          => Local::MockHTTP->new(_ok(_discovery()), _ok(_discovery())),
        discovery_ttl => 0,
    );
    $oidc2->discovery_f->get;
    $oidc2->discovery_f->get;
    is scalar @{ $oidc2->http->calls }, 2, 'discovery_ttl=0 disables caching';
}

# --- JWKS caching and force_refresh ---

{
    my $http = Local::MockHTTP->new(
        _ok(_discovery()),
        _ok({ keys => [{ kid => 'k1' }] }),
        _ok({ keys => [{ kid => 'k2' }] }),
    );

    my $oidc = Net::Async::Zitadel::OIDC->new(
        issuer => 'https://zitadel.example.com',
        http   => $http,
    );

    my $first  = $oidc->jwks_f->get;
    my $second = $oidc->jwks_f->get;
    my $third  = $oidc->jwks_f(force_refresh => 1)->get;

    is $first->{keys}[0]{kid},  'k1', 'first JWKS fetch';
    is $second->{keys}[0]{kid}, 'k1', 'second uses cache';
    is $third->{keys}[0]{kid},  'k2', 'force_refresh fetches fresh JWKS';
    is scalar @{ $http->calls }, 3, 'discovery + 2 JWKS GET calls total';
}

# --- Concurrent JWKS refresh coalescing (race condition prevention) ---

{
    # Two concurrent jwks_f calls without force_refresh should share
    # the same in-flight Future rather than issuing two HTTP requests.

    my $http = Local::MockHTTP->new(
        _ok(_discovery()),
        _ok({ keys => [{ kid => 'shared' }] }),
        # Only one JWKS response queued — a second HTTP call would die
    );

    my $oidc = Net::Async::Zitadel::OIDC->new(
        issuer => 'https://zitadel.example.com',
        http   => $http,
    );

    # Fetch discovery first so _discovery_cache is warm
    $oidc->discovery_f->get;

    # Clear JWKS cache to force a fresh fetch
    $oidc->_jwks_cache(undef);

    my $f1 = $oidc->jwks_f;
    my $f2 = $oidc->jwks_f;  # should coalesce, not make a second HTTP call

    my ($r1, $r2) = ($f1->get, $f2->get);

    is $r1->{keys}[0]{kid}, 'shared', 'first concurrent caller gets JWKS';
    is $r2->{keys}[0]{kid}, 'shared', 'second concurrent caller shares the same result';

    my $jwks_calls = grep { $_->{method} eq 'GET' } @{ $http->calls };
    is $jwks_calls, 2, 'only 2 GET calls total (discovery + 1 JWKS, not 2)';
}

# --- verify_token_f retries on key mismatch ---

{
    my $http = Local::MockHTTP->new(
        _ok(_discovery()),
        _ok({ keys => [{ kid => 'old' }] }),
        _ok({ keys => [{ kid => 'new' }] }),
    );

    my $decode_calls = 0;
    my @seen_kids;

    my $oidc = Local::MockOIDC->new(
        issuer  => 'https://zitadel.example.com',
        http    => $http,
        decoder => sub {
            my ($self, %args) = @_;
            $decode_calls++;
            push @seen_kids, $args{kid_keys}{keys}[0]{kid};
            die "signature check failed" if $decode_calls == 1;
            return { sub => 'user-1' };
        },
    );

    my $claims = $oidc->verify_token_f('token-value')->get;
    is_deeply $claims, { sub => 'user-1' }, 'verify_token_f returns claims after retry';
    is $decode_calls, 2, 'decoder called twice (initial + retry)';
    is_deeply \@seen_kids, ['old', 'new'], 'retry uses fresh JWKS';
}

# --- no_retry disables JWKS refresh ---

{
    my $http = Local::MockHTTP->new(
        _ok(_discovery()),
        _ok({ keys => [{ kid => 'old' }] }),
    );

    my $oidc = Local::MockOIDC->new(
        issuer  => 'https://zitadel.example.com',
        http    => $http,
        decoder => sub { die "always fails" },
    );

    my $f = $oidc->verify_token_f('token', no_retry => 1);
    ok $f->is_failed, 'no_retry returns failed Future';
    eval { $f->get };
    like "$@", qr/always fails/, 'no_retry surfaces original error';

    my $jwks_calls = grep { $_->{method} eq 'GET' } @{ $http->calls };
    is $jwks_calls, 2, 'no JWKS refresh GET (only discovery + first JWKS)';
}

# --- Network timeout: pending Future never resolves ---

{
    my $http = Local::MockHTTP->new(
        _never(),  # discovery never responds
    );

    my $oidc = Net::Async::Zitadel::OIDC->new(
        issuer => 'https://zitadel.example.com',
        http   => $http,
    );

    my $f = $oidc->discovery_f;
    ok !$f->is_ready, 'pending HTTP gives back a non-ready Future';
    ok !$f->is_failed, 'pending Future is not yet failed';

    # In production an IO::Async timeout would cancel this Future.
    # Here we just verify the Future is in pending state, not that it
    # completes — that is the domain of the event loop / timeout layer.
    pass 'timeout scenario: Future stays pending (no premature exception)';
}

# --- Discovery network failure ---

{
    my $http = Local::MockHTTP->new(
        _err('503 Service Unavailable'),
    );

    my $oidc = Net::Async::Zitadel::OIDC->new(
        issuer => 'https://zitadel.example.com',
        http   => $http,
    );

    my $f = $oidc->discovery_f;
    ok $f->is_failed, 'discovery failure gives failed Future';
    eval { $f->get };
    my $err = $@;
    ok ref $err && $err->isa('Net::Async::Zitadel::Error::Network'),
        'discovery failure throws Network exception';
    like "$err", qr/Discovery failed: 503/, 'discovery error stringifies with status';
}

# --- JWKS network failure ---

{
    my $http = Local::MockHTTP->new(
        _ok(_discovery()),
        _err('500 Internal Server Error'),
    );

    my $oidc = Net::Async::Zitadel::OIDC->new(
        issuer => 'https://zitadel.example.com',
        http   => $http,
    );

    my $f = $oidc->jwks_f;
    ok $f->is_failed, 'JWKS fetch failure gives failed Future';
    eval { $f->get };
    my $err = $@;
    ok ref $err && $err->isa('Net::Async::Zitadel::Error::Network'),
        'JWKS failure throws Network exception';
    like "$err", qr/JWKS fetch failed: 500/, 'JWKS error stringifies with status';

    # In-flight coalescing future must be cleared after failure
    is $oidc->_jwks_inflight, undef, 'in-flight slot cleared after JWKS failure';
}

# --- Incomplete discovery document ---

{
    my $http = Local::MockHTTP->new(
        _ok({ token_endpoint => 'https://zitadel.example.com/oauth/v2/token' }),
    );

    my $oidc = Net::Async::Zitadel::OIDC->new(
        issuer => 'https://zitadel.example.com',
        http   => $http,
    );

    my $f = $oidc->jwks_f;
    ok $f->is_failed, 'missing jwks_uri gives failed Future';
    eval { $f->get };
    like "$@", qr/No jwks_uri in discovery document/, 'missing jwks_uri error message';
}

# --- Malformed JWKS body ---

{
    my $http = Local::MockHTTP->new(
        _ok(_discovery()),
        Future->done(Local::Response->new(
            is_success      => 1,
            status_line     => '200 OK',
            decoded_content => '<html>not json</html>',
        )),
    );

    my $oidc = Net::Async::Zitadel::OIDC->new(
        issuer => 'https://zitadel.example.com',
        http   => $http,
    );

    throws_ok { $oidc->jwks_f->get } qr/.+/, 'non-JSON JWKS body propagates decode error';
}

# --- Empty JWKS keys array ---

{
    my $http = Local::MockHTTP->new(
        _ok(_discovery()),
        _ok({ keys => [] }),
        _ok({ keys => [] }),
    );

    my $oidc = Local::MockOIDC->new(
        issuer  => 'https://zitadel.example.com',
        http    => $http,
        decoder => sub { die "no matching key" },
    );

    my $f = $oidc->verify_token_f('some.jwt.token');
    ok $f->is_failed, 'empty JWKS keys array causes verify_token_f to fail';
    eval { $f->get };
    like "$@", qr/no matching key/, 'empty JWKS failure propagates';
}

# --- userinfo_f ---

{
    my $http = Local::MockHTTP->new(
        _ok(_discovery()),
        _ok({ sub => 'user-123', email => 'alice@example.com' }),
    );

    my $oidc = Net::Async::Zitadel::OIDC->new(
        issuer => 'https://zitadel.example.com',
        http   => $http,
    );

    my $info = $oidc->userinfo_f('access-token-1')->get;
    is $info->{sub}, 'user-123', 'userinfo_f returns decoded JSON';

    my $req = $http->calls->[-1]{args}[1];  # do_request => request => $req
    is $req->header('Authorization'), 'Bearer access-token-1', 'userinfo_f sends bearer token';
}

{
    # userinfo_f requires access token
    my $oidc = Net::Async::Zitadel::OIDC->new(
        issuer => 'https://zitadel.example.com',
        http   => bless {}, 'Local::FakeHTTP',
    );
    my $f = $oidc->userinfo_f(undef);
    ok $f->is_failed, 'userinfo_f(undef) returns failed Future';
    eval { $f->get };
    like "$@", qr/No access token provided/, 'userinfo_f validation message';
}

# --- introspect_f ---

{
    my $http = Local::MockHTTP->new(
        _ok(_discovery()),
        _ok({ active => JSON::MaybeXS::true, sub => 'user-123' }),
    );

    my $oidc = Net::Async::Zitadel::OIDC->new(
        issuer => 'https://zitadel.example.com',
        http   => $http,
    );

    my $result = $oidc->introspect_f('some-token',
        client_id     => 'client-1',
        client_secret => 'secret-1',
    )->get;

    ok $result->{active}, 'introspect_f returns active response';

    my $req = $http->calls->[-1]{args}[1];
    is $req->header('Content-Type'), 'application/x-www-form-urlencoded',
        'introspect_f uses form content type';
    like $req->content, qr/client_id=client-1/, 'introspect_f sends client_id';
    like $req->content, qr/token_type_hint=access_token/, 'introspect_f default token_type_hint';
}

{
    my $oidc = Net::Async::Zitadel::OIDC->new(
        issuer => 'https://zitadel.example.com',
        http   => bless {}, 'Local::FakeHTTP',
    );
    my $f = $oidc->introspect_f('tok');
    ok $f->is_failed, 'introspect_f without credentials fails';
    eval { $f->get };
    like "$@", qr/client_id and client_secret/, 'introspect_f validation message';
}

# --- token_f and helpers ---

{
    my $http = Local::MockHTTP->new(
        _ok(_discovery()),
        _ok({ access_token => 'cc-tok' }),
        _ok({ access_token => 'refresh-tok' }),
        _ok({ access_token => 'code-tok' }),
    );

    my $oidc = Net::Async::Zitadel::OIDC->new(
        issuer => 'https://zitadel.example.com',
        http   => $http,
    );

    my $cc = $oidc->client_credentials_token_f(
        client_id     => 'client-1',
        client_secret => 'secret-1',
        scope         => 'openid',
    )->get;
    is $cc->{access_token}, 'cc-tok', 'client_credentials_token_f returns token';

    my $r = $oidc->refresh_token_f('ref-123',
        client_id     => 'client-1',
        client_secret => 'secret-1',
    )->get;
    is $r->{access_token}, 'refresh-tok', 'refresh_token_f returns token';

    my $code = $oidc->exchange_authorization_code_f(
        code          => 'auth-code',
        redirect_uri  => 'https://app.example.com/cb',
        client_id     => 'client-1',
        client_secret => 'secret-1',
    )->get;
    is $code->{access_token}, 'code-tok', 'exchange_authorization_code_f returns token';

    my $cc_req = $http->calls->[1]{args}[1];
    like $cc_req->content, qr/grant_type=client_credentials/, 'CC grant_type in body';
    like $cc_req->content, qr/scope=openid/, 'CC scope in body';

    my $ref_req = $http->calls->[2]{args}[1];
    like $ref_req->content, qr/grant_type=refresh_token/, 'refresh grant_type in body';
    like $ref_req->content, qr/refresh_token=ref-123/, 'refresh_token in body';

    my $code_req = $http->calls->[3]{args}[1];
    like $code_req->content, qr/grant_type=authorization_code/, 'code grant_type in body';
    like $code_req->content, qr/redirect_uri=/, 'redirect_uri in body';
}

{
    my $oidc = Net::Async::Zitadel::OIDC->new(
        issuer => 'https://zitadel.example.com',
        http   => bless {}, 'Local::FakeHTTP',
    );

    my $f1 = $oidc->token_f();
    ok $f1->is_failed, 'token_f without grant_type fails immediately';
    eval { $f1->get };
    like "$@", qr/grant_type required/, 'token_f grant_type message';

    my $f2 = $oidc->client_credentials_token_f(client_secret => 'x');
    ok $f2->is_failed, 'client_credentials_token_f without client_id fails';

    my $f3 = $oidc->refresh_token_f('');
    ok $f3->is_failed, 'refresh_token_f with empty token fails';

    my $f4 = $oidc->exchange_authorization_code_f(redirect_uri => 'https://x.example/cb');
    ok $f4->is_failed, 'exchange_authorization_code_f without code fails';

    my $f5 = $oidc->exchange_authorization_code_f(code => 'x');
    ok $f5->is_failed, 'exchange_authorization_code_f without redirect_uri fails';
}

done_testing;
