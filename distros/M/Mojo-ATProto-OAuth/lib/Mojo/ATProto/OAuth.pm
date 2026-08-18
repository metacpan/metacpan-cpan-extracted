package Mojo::ATProto::OAuth;
use Mojo::Base -base, -signatures;

use Mojo::UserAgent qw//;
use Mojo::URL qw//;
use Mojo::Promise qw//;
use Mojo::Log qw//;
use Mojo::Loader qw/load_class/;
use Mojo::ATProto::OAuth::ClientMetadata qw//;
use Mojo::ATProto::OAuth::DPoP           qw//;
use Mojo::ATProto::OAuth::Identity       qw//;
use Mojo::ATProto::OAuth::Resolver       qw//;

use Scalar::Util qw/blessed/;

use feature 'try';

use constant DEBUG => $ENV{MOJO_OAUTH_DEBUG} || 0;

our $VERSION = '1.00'; # VERSION

has 'ua'                 => sub { 
    my $ua = Mojo::UserAgent->new(request_timeout => 10);
    no strict;
    $ua->transactor->name('Mojo::ATProto::OAuth/' . $VERSION || 'dev');
    use strict;
    return $ua;
};
has 'client_id'          => sub { die "client_id is required\n" };
has 'callback_url'       => sub { die "callback_url is required\n" };
has 'scopes'             => sub { ['atproto'] };
has 'private_key'        => undef;    # Crypt::PK::ECC, confidential clients only
has 'key_id'             => undef;
has 'loopback'           => 0;        # true for new_localhost() clients - see below
has 'identity'           => sub { Mojo::ATProto::OAuth::Identity->new };
has 'resolver'           => sub { Mojo::ATProto::OAuth::Resolver->new };
has 'log'                => sub { Mojo::Log->new(level => $ENV{MOJO_LOG_LEVEL} || 'info') };

sub is_confidential ($self) {
    return defined($self->private_key) && defined($self->key_id);
}

sub store ($self, @value) {
    # this is basically straight up setter 
    if (@value) {
        $self->{store} = $value[0];
        return $self;
    }

    my $store = $self->{store};
    return undef unless defined $store; # no store supplied, at all, by symbolic name, module name, or actual instantiated class
    return $store if blessed($store); # if it's an instantiated class, return it (getter) 

    # and here we come to the meat and veg
    my $class;
    my @args; 
    if(ref($store) eq 'ARRAY') {
        # first element will be the class , the rest will be arguments -
        # list-assign rather than shift(@$store), since $store is the
        # same arrayref the caller handed us (not a copy) - shifting it
        # would mutate their spec in place, corrupting it for reuse
        my ($temp, @rest) = @$store;
        $class = ($temp =~ /::/) ? $temp : sprintf('Mojo::ATProto::OAuth::SessionStore::%s', $temp);
        @args = @rest;
    } elsif(ref($store)) {
        # not the right kind of ref, time to blow up
        die 'store must be a scalar or arrayref', "\n";
    } else {
        # scalar
        $class = ($store =~ /::/) ? $store : sprintf('Mojo::ATProto::OAuth::SessionStore::%s', $store); 
    }
    my $e     = load_class($class);
    if ($e) {
        # Mojo::Loader::load_class returns a plain true value (not a
        # ref) for "no such class", and a Mojo::Exception (a ref) only
        # for a real error (e.g. a syntax error) inside a class that
        my $reason = ref($e) ? "$e" : 'no such session store class';
        die "store: could not load session store class $class: $reason\n";
    }
    return $self->{store} = $class->new(@args); 
}

sub new_localhost ($class, %args) {
    my $callback_url  = $args{callback_url} // die "new_localhost: 'callback_url' required\n";
    my $scopes        = $args{scopes}       // ['atproto'];

    my $client_id = Mojo::URL->new('http://localhost')->query({
        redirect_uri => $callback_url,
        scope        => join(' ', @$scopes),
    })->to_string;

    return $class->new(
        client_id    => $client_id,
        callback_url => $callback_url,
        scopes       => $scopes,
        loopback     => 1,
        (defined($args{ua}) ? (ua => $args{ua}) : ()),
        (defined($args{store}) ? (store => $args{store}) : ()),
    );
}

sub client_metadata ($self) {
    die "client_metadata: loopback clients don't serve a client metadata document\n" if $self->loopback;

    return Mojo::ATProto::OAuth::ClientMetadata->build(
        client_id    => $self->client_id,
        callback_url => $self->callback_url,
        scopes       => $self->scopes,
        ($self->is_confidential ? (private_key => $self->private_key, key_id => $self->key_id) : ()),
    );
}

# The `client_assertion_type`/`client_assertion` form fields every
# confidential-client request (PAR, token exchange, refresh) needs -
# empty for a public client, so callers can unconditionally merge this
# in rather than each repeating an `if ($self->is_confidential)` guard.
sub _client_assertion_params ($self, $audience) {
    return {} unless $self->is_confidential;
    return {
        client_assertion_type => 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
        client_assertion      => Mojo::ATProto::OAuth::DPoP->client_assertion(
            key       => $self->private_key,
            key_id    => $self->key_id,
            client_id => $self->client_id,
            audience  => $audience,
        ),
    };
}

# Builds the PAR (Pushed Authorization Request) form body, minus the
# DPoP proof (added per-attempt by the caller, since the DPoP nonce can
# change between attempts).
sub _par_body ($self, $auth_meta, $state, $code_challenge, $scopes, $login_hint) {
    my $body = {
        client_id             => $self->client_id,
        state                 => $state,
        redirect_uri          => $self->callback_url,
        scope                 => join(' ', @$scopes),
        response_type         => 'code',
        code_challenge        => $code_challenge,
        code_challenge_method => 'S256',
        %{$self->_client_assertion_params($auth_meta->{issuer})},
    };
    $body->{login_hint} = $login_hint if length($login_hint // '');

    return $body;
}

sub _parse_auth_error_reason ($self, $res) {
    try {
        my $body = $res->json;
        return 'unknown' unless ref($body) eq 'HASH';
        return $body->{error} // 'unknown';
    } catch($ex) {
        return 'unknown (exception decoding body)';
    }
}

# Shared DPoP-nonce-retry POST helper (RFC 9449: the first attempt with
# no known nonce is expected to be rejected with a fresh one to retry
# with) - used by both send_auth_request (PAR) and
# send_initial_token_request (token exchange), matching indigo's own
# identical 2-attempt loop in both SendAuthRequest and
# SendInitialTokenRequest. Returns ($res, $final_dpop_nonce); does not
# itself validate the final response status - callers differ on what a
# success response looks like (200 vs. 200/201).
sub _post_dpop_retry($self, %args) {
    my $url   = $args{url};
    my $body  = $args{body};
    my $key   = $args{key};
    my $nonce = $args{nonce} // '';
    my $label = $args{label} // 'request';

    my $res;
    for my $attempt (1 .. 2) {
        $self->log->debug("$label: attempt $attempt POST $url (nonce=" . (length($nonce) ? 'yes' : 'no') . ')') if DEBUG;
        my $dpop_jwt = Mojo::ATProto::OAuth::DPoP->proof(key => $key, method => 'POST', url => $url, nonce => $nonce);
        my $tx       = $self->ua->post($url => {'DPoP' => $dpop_jwt } => form => $body);
        $res = $tx->res;
        $self->log->debug("$label: attempt $attempt response status=" . ($res->code // 'connection error')) if DEBUG;

        my $new_nonce = $res->headers->header('DPoP-Nonce') // '';
        $nonce = $new_nonce if length($new_nonce);

        if ($res->code == 400 && length($new_nonce)) {
            my $reason = $self->_parse_auth_error_reason($res);
            if ($reason eq 'use_dpop_nonce') {
                $self->log->debug("$label: retrying with fresh DPoP-Nonce") if DEBUG;
                next;
            }
            die "$label failed (HTTP 400): $reason\n";
        }
        last;
    }

    return ($res, $nonce);
}

sub _post_dpop_retry_p($self, %args) {
    my $url   = $args{url};
    my $body  = $args{body};
    my $key   = $args{key};
    my $label = $args{label} // 'request';

    my $attempt;
    $attempt = sub($nonce, $attempts_left) {
        $self->log->debug("$label: POST $url (nonce=" . (length($nonce) ? 'yes' : 'no') . ", attempts_left=$attempts_left)") if DEBUG;
        my $dpop_jwt = Mojo::ATProto::OAuth::DPoP->proof(key => $key, method => 'POST', url => $url, nonce => $nonce);
        return $self->ua->post_p($url => {'DPoP' => $dpop_jwt} => form => $body)->then(sub ($tx) {
            my $res       = $tx->res;
            $self->log->debug("$label: response status=" . ($res->code // 'connection error')) if DEBUG;
            my $new_nonce = $res->headers->header('DPoP-Nonce') // '';
            $nonce = $new_nonce if length($new_nonce);

            if ($res->code == 400 && length($new_nonce) && $attempts_left > 1) {
                my $reason = $self->_parse_auth_error_reason($res);
                if ($reason eq 'use_dpop_nonce') {
                    $self->log->debug("$label: retrying with fresh DPoP-Nonce") if DEBUG;
                    return $attempt->($nonce, $attempts_left - 1);
                }
                die "$label failed (HTTP 400): $reason\n";
            }

            return ($res, $nonce);
        });
    };
    return $attempt->($args{nonce} // '', 2);
}

# Sends the PAR request that kicks off an authorization flow. Returns an
# AuthRequestData-equivalent hashref: state, auth_server_url, scopes,
# pkce_verifier, request_uri, auth_server_token_endpoint,
# auth_server_revocation_endpoint, dpop_authserver_nonce,
# dpop_private_key_pem - everything a store needs to persist and later
# exchange for tokens via send_initial_token_request(_p) below.
#
# $auth_meta is the hashref Mojo::ATProto::OAuth::Resolver::
# resolve_auth_server_metadata(_p) already validated. Low-level: doesn't
# persist anything or resolve an identity - see start_auth_flow(_p) for
# the full orchestration.
sub send_auth_request($self, $auth_meta, %opts) {
    my $scopes     = $opts{scopes} // $self->scopes;
    my $login_hint = $opts{login_hint};

    $self->log->debug("send_auth_request: issuer=$auth_meta->{issuer} scopes=[" . join(',', @$scopes) . ']') if DEBUG;

    my $par_url        = $auth_meta->{pushed_authorization_request_endpoint};
    my $state          = Mojo::ATProto::OAuth::DPoP->secure_random_base64(16);
    my $pkce_verifier  = Mojo::ATProto::OAuth::DPoP->secure_random_base64(48);
    my $code_challenge = Mojo::ATProto::OAuth::DPoP->s256_challenge($pkce_verifier);
    my $dpop_key       = Mojo::ATProto::OAuth::DPoP->generate_keypair;
    my $body           = $self->_par_body($auth_meta, $state, $code_challenge, $scopes, $login_hint);

    my ($res, $dpop_nonce) = $self->_post_dpop_retry(url => $par_url, body => $body, key => $dpop_key, label => 'PAR request');

    die "PAR request failed (HTTP " . $res->code . "): " . $self->_parse_auth_error_reason($res) . "\n"
        unless $res->code == 200 || $res->code == 201;

    my $par_resp = $res->json;
    die "PAR response missing request_uri\n" unless length($par_resp->{request_uri} // '');

    $self->log->debug("send_auth_request: PAR succeeded, state=$state") if DEBUG;

    return {
        state                            => $state,
        auth_server_url                 => $auth_meta->{issuer},
        scopes                           => $scopes,
        pkce_verifier                    => $pkce_verifier,
        request_uri                      => $par_resp->{request_uri},
        auth_server_token_endpoint      => $auth_meta->{token_endpoint},
        auth_server_revocation_endpoint => $auth_meta->{revocation_endpoint},
        dpop_authserver_nonce           => $dpop_nonce,
        dpop_private_key_pem            => Mojo::ATProto::OAuth::DPoP->export_private_pem($dpop_key),
    };
}

sub send_auth_request_p($self, $auth_meta, %opts) {
    my $scopes     = $opts{scopes} // $self->scopes;
    my $login_hint = $opts{login_hint};

    $self->log->debug("send_auth_request_p: issuer=$auth_meta->{issuer} scopes=[" . join(',', @$scopes) . ']') if DEBUG;

    my $par_url        = $auth_meta->{pushed_authorization_request_endpoint};
    my $state          = Mojo::ATProto::OAuth::DPoP->secure_random_base64(16);
    my $pkce_verifier  = Mojo::ATProto::OAuth::DPoP->secure_random_base64(48);
    my $code_challenge = Mojo::ATProto::OAuth::DPoP->s256_challenge($pkce_verifier);
    my $dpop_key       = Mojo::ATProto::OAuth::DPoP->generate_keypair;
    my $body           = $self->_par_body($auth_meta, $state, $code_challenge, $scopes, $login_hint);

    return $self->_post_dpop_retry_p(url => $par_url, body => $body, key => $dpop_key, label => 'PAR request')->then(sub ($res, $dpop_nonce) {
        die "PAR request failed (HTTP " . $res->code . "): " . $self->_parse_auth_error_reason($res) . "\n"
            unless $res->code == 200 || $res->code == 201;

        my $par_resp = $res->json;
        die "PAR response missing request_uri\n" unless length($par_resp->{request_uri} // '');

        $self->log->debug("send_auth_request_p: PAR succeeded, state=$state") if DEBUG;

        return {
            state                           => $state,
            auth_server_url                 => $auth_meta->{issuer},
            scopes                          => $scopes,
            pkce_verifier                   => $pkce_verifier,
            request_uri                     => $par_resp->{request_uri},
            auth_server_token_endpoint      => $auth_meta->{token_endpoint},
            auth_server_revocation_endpoint => $auth_meta->{revocation_endpoint},
            dpop_authserver_nonce           => $dpop_nonce,
            dpop_private_key_pem            => Mojo::ATProto::OAuth::DPoP->export_private_pem($dpop_key),
        };
    });
}

# Exchanges an authorization code for tokens. $info is the AuthRequestData-equivalent
# hashref from send_auth_request(_p)/a store lookup - reuses its DPoP
# keypair (RFC 9449 requires the same key for every proof tied to one
# authorization attempt) and PKCE verifier. Returns a TokenResponse-
# equivalent hashref (sub, scope, access_token, refresh_token) plus the
# final dpop_authserver_nonce, for the caller to persist.
sub send_initial_token_request($self, $auth_code, $info) {
    $self->log->debug("send_initial_token_request: exchanging code for tokens (state=$info->{state})") if DEBUG;

    my $body = {
        client_id     => $self->client_id,
        redirect_uri  => $self->callback_url,
        grant_type    => 'authorization_code',
        code          => $auth_code,
        code_verifier => $info->{pkce_verifier},
        %{$self->_client_assertion_params($info->{auth_server_url})},
    };

    my $dpop_key = Mojo::ATProto::OAuth::DPoP->import_private_pem($info->{dpop_private_key_pem});
    my ($res, $dpop_nonce) = $self->_post_dpop_retry(
        url => $info->{auth_server_token_endpoint}, body => $body, key => $dpop_key,
        nonce => $info->{dpop_authserver_nonce}, label => 'initial token request',
    );

    die "initial token request failed (HTTP " . $res->code . "): " . $self->_parse_auth_error_reason($res) . "\n"
        unless $res->code == 200;

    my $token_resp = $res->json;
    $token_resp->{dpop_authserver_nonce} = $dpop_nonce;
    $self->log->debug("send_initial_token_request: succeeded, sub=" . ($token_resp->{sub} // '?') . " scope=" . ($token_resp->{scope} // '')) if DEBUG;
    return $token_resp;
}

sub send_initial_token_request_p($self, $auth_code, $info) {
    $self->log->debug("send_initial_token_request_p: exchanging code for tokens (state=$info->{state})") if DEBUG;

    my $body = {
        client_id     => $self->client_id,
        redirect_uri  => $self->callback_url,
        grant_type    => 'authorization_code',
        code          => $auth_code,
        code_verifier => $info->{pkce_verifier},
        %{$self->_client_assertion_params($info->{auth_server_url})},
    };

    my $dpop_key = Mojo::ATProto::OAuth::DPoP->import_private_pem($info->{dpop_private_key_pem});
    return $self->_post_dpop_retry_p(
        url => $info->{auth_server_token_endpoint}, body => $body, key => $dpop_key,
        nonce => $info->{dpop_authserver_nonce}, label => 'initial token request',
    )->then(sub ($res, $dpop_nonce) {
        die "initial token request failed (HTTP " . $res->code . "): " . $self->_parse_auth_error_reason($res) . "\n"
            unless $res->code == 200;

        my $token_resp = $res->json;
        $token_resp->{dpop_authserver_nonce} = $dpop_nonce;
        $self->log->debug("send_initial_token_request_p: succeeded, sub=" . ($token_resp->{sub} // '?') . " scope=" . ($token_resp->{scope} // '')) if DEBUG;
        return $token_resp;
    });
}

# Builds the ClientSessionData-equivalent hashref to persist, once a
# token exchange has succeeded and the account DID has been verified
# against the identity that vouches for it (pure - no I/O, shared by
# both process_callback and process_callback_p). `client_state`/`extra`
# ride through from $info untouched (whatever start_auth_flow(_p) was
# given, if anything) - this library never interprets either one, it's
# purely opaque pass-through for the caller (e.g. a plugin) to unpack
# on the other side. 
sub _build_session_data($self, $info, $token_resp, $account_did, $handle, $host_url) {
    return {
        account_did                      => $account_did,
        handle                           => $handle,
        session_id                       => $info->{state},
        host_url                         => $host_url,
        auth_server_url                  => $info->{auth_server_url},
        auth_server_token_endpoint       => $info->{auth_server_token_endpoint},
        auth_server_revocation_endpoint  => $info->{auth_server_revocation_endpoint},
        scopes                           => [split(/ /, $token_resp->{scope} // '')],
        access_token                     => $token_resp->{access_token},
        refresh_token                    => $token_resp->{refresh_token},
        dpop_authserver_nonce            => $token_resp->{dpop_authserver_nonce},
        dpop_host_nonce                  => $token_resp->{dpop_authserver_nonce},    # bootstrap host nonce from authserver
        dpop_private_key_pem             => $info->{dpop_private_key_pem},
        client_state                     => $info->{client_state},
        extra                            => $info->{extra},
    };
}

# If this auth request was a scope upgrade (see start_scope_upgrade(_p)
# below), collapse the just-issued session data onto the *existing*
# session_id it's upgrading - so the customer's browser session is
# undisturbed - and union its scopes with what's already stored, rather
# than narrowing to just this exchange's own granted scope set. A no-op
# (returns $session_data unchanged) for an ordinary login.
sub _apply_scope_upgrade_merge($self, $info, $session_data) {
    return $session_data unless length($info->{upgrade_session_id} // '');

    $self->log->debug("_apply_scope_upgrade_merge: landing on existing session_id=$info->{upgrade_session_id}") if DEBUG;
    my $existing;
    try {
        $existing = $self->store->get_session($session_data->{account_did}, $info->{upgrade_session_id});
    } catch($ex) {
        $existing = undef;
    }
    $session_data->{scopes} = $self->_union_scopes($existing->{scopes}, $session_data->{scopes}) if $existing;
    $session_data->{session_id} = $info->{upgrade_session_id};
    return $session_data;
}

sub _apply_scope_upgrade_merge_p($self, $info, $session_data) {
    return Mojo::Promise->resolve($session_data) unless length($info->{upgrade_session_id} // '');

    $self->log->debug("_apply_scope_upgrade_merge_p: landing on existing session_id=$info->{upgrade_session_id}") if DEBUG;
    return $self->store->get_session_p($session_data->{account_did}, $info->{upgrade_session_id})->then(sub ($existing) {
        $session_data->{scopes}     = $self->_union_scopes($existing->{scopes}, $session_data->{scopes});
        $session_data->{session_id} = $info->{upgrade_session_id};
        return $session_data;
    })->catch(sub ($err) {
        # No prior session found under that id (shouldn't normally
        # happen - the upgrade flow only ever starts from an existing
        # one) - still land under the upgrade target id, just without a
        # scope merge to fall back on.
        $session_data->{session_id} = $info->{upgrade_session_id};
        return $session_data;
    });
}

sub _union_scopes($self, $a, $b) {
    my %union = map { $_ => 1 } (@{$a // []}, @{$b // []});
    return [sort keys %union];
}

sub _validate_callback_params($self, $info, $params) {
    if (length($params->{error} // '')) {
        my $msg = "OAuth request callback error: $params->{error}";
        $msg .= ": $params->{error_description}" if length($params->{error_description} // '');
        die "$msg\n";
    }

    my $authserver_url = $params->{iss}  // '';
    my $auth_code      = $params->{code} // '';
    die "missing required query param\n" unless length($authserver_url) && length($auth_code);
    die "callback iss doesn't match request info\n" unless $info->{auth_server_url} eq $authserver_url;

    return ($authserver_url, $auth_code);
}

# High-level helper for starting a new session 
# resolves an identity to auth-server metadata, sends the PAR request,
# persists the auth request via `store`, and returns the URL the user
# should be redirected to (browser) to approve the auth flow. Requires
# `store` to be configured.
#
# %opts, exactly one of:
#   identifier - an atproto handle/DID, or an https:// auth-server URL
#                directly (skips identity resolution entirely until the
#                callback, same dual-mode as always).
#   did + handle + host_url - all three together, when the caller has
#                already resolved identity itself (e.g. to make a
#                pre-auth decision - reading a public repo record to
#                pick a scope set, say) and there's no reason to pay
#                for a second identity->lookup(_p) here just to re-derive
#                the same did/handle. Auth-server discovery (host_url ->
#                auth_server_url) still always happens regardless of
#                which mode is used - that's a separate step from
#                identity resolution, not something a caller would
#                plausibly have pre-computed.
# Plus, independent of the above:
#   scopes       (optional arrayref) - overrides $self->scopes for just
#                this call, falls back to the client's configured
#                default when omitted.
#   client_state (optional hashref) - opaque, never inspected here;
#                persisted on the auth request and handed back untouched
#                inside process_callback(_p)'s result. Intended for
#                things like a post-login redirect target.
#   extra        (optional hashref) - same opaque-pass-through treatment
#                as client_state, but conventionally used for data that
#                belongs in the caller's own session metadata once
#                login completes (e.g. a pre-auth decision worth
#                remembering) rather than being callback-routing data.
#                This library draws no distinction between the two
#                beyond "two separate opaque slots" - what each is used
#                for is entirely up to the caller.
sub start_auth_flow($self, %opts) {
    die "start_auth_flow: 'store' must be configured\n" unless defined($self->store);
    $self->log->debug('start_auth_flow: ' . _describe_start_opts(%opts)) if DEBUG;

    my ($did, $handle, $host_url, $auth_server_url) = $self->_resolve_start(%opts);
    $self->log->debug('start_auth_flow: resolved did=' . ($did // '(bare auth-server URL)') . " handle=" . ($handle // '?') . " auth_server=$auth_server_url") if DEBUG;

    my $auth_meta = $self->resolver->resolve_auth_server_metadata($auth_server_url);
    my $info      = $self->send_auth_request($auth_meta, login_hint => ($handle // $did // $opts{identifier}), ($opts{scopes} ? (scopes => $opts{scopes}) : ()));
    $info->{account_did}  = $did      if defined($did);
    $info->{handle}       = $handle   if defined($handle);
    $info->{host_url}     = $host_url if defined($host_url);
    $info->{client_state} = $opts{client_state} if defined($opts{client_state});
    $info->{extra}        = $opts{extra}        if defined($opts{extra});

    $self->store->save_auth_request($info);
    $self->log->debug("start_auth_flow: auth request persisted, state=$info->{state}") if DEBUG;
    return $self->_authorization_redirect_url($auth_meta, $info);
}

sub start_auth_flow_p($self, %opts) {
    die "start_auth_flow_p: 'store' must be configured\n" unless defined($self->store);
    $self->log->debug('start_auth_flow_p: ' . _describe_start_opts(%opts)) if DEBUG;

    return $self->_resolve_start_p(%opts)->then(sub ($did, $handle, $host_url, $auth_server_url) {
        $self->log->debug('start_auth_flow_p: resolved did=' . ($did // '(bare auth-server URL)') . " handle=" . ($handle // '?') . " auth_server=$auth_server_url") if DEBUG;
        return $self->resolver->resolve_auth_server_metadata_p($auth_server_url)->then(sub ($auth_meta) {
            return $self->send_auth_request_p($auth_meta, login_hint => ($handle // $did // $opts{identifier}), ($opts{scopes} ? (scopes => $opts{scopes}) : ()))->then(sub ($info) {
                $info->{account_did}  = $did      if defined($did);
                $info->{handle}       = $handle   if defined($handle);
                $info->{host_url}     = $host_url if defined($host_url);
                $info->{client_state} = $opts{client_state} if defined($opts{client_state});
                $info->{extra}        = $opts{extra}        if defined($opts{extra});
                return $self->store->save_auth_request_p($info)->then(sub {
                    $self->log->debug("start_auth_flow_p: auth request persisted, state=$info->{state}") if DEBUG;
                    return $self->_authorization_redirect_url($auth_meta, $info);
                });
            });
        });
    });
}

sub _describe_start_opts(%opts) {
    return 'identifier=' . $opts{identifier} . ($opts{scopes} ? ' scopes=[' . join(',', @{$opts{scopes}}) . ']' : '')
        if defined($opts{identifier});
    return 'did=' . ($opts{did} // '?') . ' handle=' . ($opts{handle} // '?') . ' host_url=' . ($opts{host_url} // '?')
        . ($opts{scopes} ? ' scopes=[' . join(',', @{$opts{scopes}}) . ']' : '');
}

sub _authorization_redirect_url($self, $auth_meta, $info) {
    return Mojo::URL->new($auth_meta->{authorization_endpoint})->query({
        client_id   => $self->client_id,
        request_uri => $info->{request_uri},
    })->to_string;
}

# Returns (did, handle, host_url, auth_server_url) - did/handle/host_url
# are undef together for the bare-https://-URL entry mode (identity
# genuinely isn't known yet, resolved later in process_callback(_p)
# instead), populated together in every other mode. See
# start_auth_flow(_p)'s own header for what %opts recognizes.
sub _resolve_start($self, %opts) {
    if (defined($opts{did}) && defined($opts{handle}) && defined($opts{host_url})) {
        return ($opts{did}, $opts{handle}, $opts{host_url}, $self->resolver->resolve_auth_server_url($opts{host_url}));
    }

    my $identifier = $opts{identifier} // die "start_auth_flow: 'identifier' or 'did'+'handle'+'host_url' required\n";
    return (undef, undef, undef, $identifier) if $identifier =~ m{^https://};

    my $identity = $self->identity->lookup($identifier);
    my $host_url = $self->identity->pds_endpoint($identity);
    die "identity does not link to an atproto host (PDS)\n" unless length($host_url // '');

    return ($identity->{did}, $identity->{handle}, $host_url, $self->resolver->resolve_auth_server_url($host_url));
}

sub _resolve_start_p($self, %opts) {
    if (defined($opts{did}) && defined($opts{handle}) && defined($opts{host_url})) {
        return $self->resolver->resolve_auth_server_url_p($opts{host_url})->then(sub ($auth_server_url) {
            return ($opts{did}, $opts{handle}, $opts{host_url}, $auth_server_url);
        });
    }

    my $identifier = $opts{identifier} // return Mojo::Promise->reject("start_auth_flow_p: 'identifier' or 'did'+'handle'+'host_url' required\n");
    return Mojo::Promise->resolve(undef, undef, undef, $identifier) if $identifier =~ m{^https://};

    return $self->identity->lookup_p($identifier)->then(sub ($identity) {
        my $host_url = $self->identity->pds_endpoint($identity);
        die "identity does not link to an atproto host (PDS)\n" unless length($host_url // '');

        return $self->resolver->resolve_auth_server_url_p($host_url)->then(sub ($auth_server_url) {
            return ($identity->{did}, $identity->{handle}, $host_url, $auth_server_url);
        });
    });
}

# High-level helper for completing the auth flow (indigo's
# ProcessCallback): verifies callback query params ($params, a plain
# hashref of the callback request's query parameters) against the
# persisted auth request, exchanges the code for tokens, verifies the
# account identity, persists the resulting session via `store`, and
# returns the ClientSessionData-equivalent hashref. Requires `store` to
# be configured.
sub process_callback($self, $params) {
    die "process_callback: 'store' must be configured\n" unless defined($self->store);

    my $state = $params->{state} // die "missing state query param\n";
    $self->log->debug("process_callback: state=$state iss=" . ($params->{iss} // '?')) if DEBUG;
    my $info  = $self->store->get_auth_request($state);

    my ($authserver_url, $auth_code) = $self->_validate_callback_params($info, $params);
    my $token_resp = $self->send_initial_token_request($auth_code, $info);

    my ($account_did, $handle, $host_url);
    if (length($info->{account_did} // '')) {
        $account_did = $info->{account_did};
        die "token subject didn't match original DID\n" unless $token_resp->{sub} eq $account_did;
        if (length($info->{host_url} // '')) {
            # Already resolved and persisted at start_auth_flow(_p) time
            # (either from the identifier, or handed in pre-resolved) -
            # reusing it avoids a third identity lookup for what's purely
            # descriptive metadata at this point; the token subject match
            # above is what actually re-confirms the account. Not every
            # known-DID auth request has this though - start_scope_upgrade
            # doesn't set it on its own auth-request rows - hence the
            # fallback below, unchanged from before this option existed.
            $handle    = $info->{handle};
            $host_url = $info->{host_url};
        } else {
            my $identity = $self->identity->lookup($account_did);
            $handle    = $identity->{handle};
            $host_url = $self->identity->pds_endpoint($identity);
        }
        $self->log->debug("process_callback: known-DID path, account_did=$account_did") if DEBUG;
    } else {
        $account_did = $token_resp->{sub} // die "token response missing sub\n";
        my $identity = $self->identity->lookup($account_did);
        $handle       = $identity->{handle};
        $host_url    = $self->identity->pds_endpoint($identity);
        my $resolved  = $self->resolver->resolve_auth_server_url($host_url);
        die "token subject auth server did not match original\n" unless $resolved eq $authserver_url;
        $self->log->debug("process_callback: bare-URL entry path, resolved account_did=$account_did") if DEBUG;
    }

    my $session_data = $self->_build_session_data($info, $token_resp, $account_did, $handle, $host_url);
    $session_data = $self->_apply_scope_upgrade_merge($info, $session_data);
    $self->store->save_session($session_data);
    $self->log->debug("process_callback: session saved, account_did=$account_did session_id=$session_data->{session_id}") if DEBUG;

    # Non-fatal on failure to clean up, matching indigo's own
    # ProcessCallback (log-and-continue) - the session itself is already
    # safely persisted at this point; a leftover auth-request row is
    # inert, not a correctness problem.
    try {
        $self->store->delete_auth_request($state);
    } catch($ex) {
        $self->log->warn("failed to delete auth request info for state=$state: $ex");
    }
    return $session_data;
}

sub process_callback_p($self, $params) {
    die "process_callback_p: 'store' must be configured\n" unless defined($self->store);

    my $state = $params->{state} // return Mojo::Promise->reject("missing state query param\n");
    $self->log->debug("process_callback_p: state=$state iss=" . ($params->{iss} // '?')) if DEBUG;

    return $self->store->get_auth_request_p($state)->then(sub ($info) {
        my ($authserver_url, $auth_code) = $self->_validate_callback_params($info, $params);

        return $self->send_initial_token_request_p($auth_code, $info)->then(sub ($token_resp) {
            if (length($info->{account_did} // '')) {
                my $account_did = $info->{account_did};
                die "token subject didn't match original DID\n" unless $token_resp->{sub} eq $account_did;
                $self->log->debug("process_callback_p: known-DID path, account_did=$account_did") if DEBUG;

                # See process_callback's identical branch for why this is
                # conditional - start_scope_upgrade_p's own auth-request
                # rows don't persist host_url, so they still fall back to
                # a fresh lookup here exactly as before this option existed.
                return Mojo::Promise->resolve($info->{handle}, $info->{host_url})
                    ->then(sub ($handle, $host_url) { return $self->_finish_callback_p($state, $info, $token_resp, $account_did, $handle, $host_url) })
                    if length($info->{host_url} // '');

                return $self->identity->lookup_p($account_did)->then(sub ($identity) {
                    return $self->_finish_callback_p($state, $info, $token_resp, $account_did, $identity->{handle}, $self->identity->pds_endpoint($identity));
                });
            }

            my $account_did = $token_resp->{sub} // die "token response missing sub\n";
            return $self->identity->lookup_p($account_did)->then(sub ($identity) {
                my $host_url = $self->identity->pds_endpoint($identity);
                return $self->resolver->resolve_auth_server_url_p($host_url)->then(sub ($resolved) {
                    die "token subject auth server did not match original\n" unless $resolved eq $authserver_url;
                    $self->log->debug("process_callback_p: bare-URL entry path, resolved account_did=$account_did") if DEBUG;
                    return $self->_finish_callback_p($state, $info, $token_resp, $account_did, $identity->{handle}, $host_url);
                });
            });
        });
    });
}

sub _finish_callback_p($self, $state, $info, $token_resp, $account_did, $handle, $host_url) {
    my $session_data = $self->_build_session_data($info, $token_resp, $account_did, $handle, $host_url);

    return $self->_apply_scope_upgrade_merge_p($info, $session_data)->then(sub ($merged) {
        $session_data = $merged;
        return $self->store->save_session_p($session_data);
    })->then(sub {
        $self->log->debug("_finish_callback_p: session saved, account_did=$account_did session_id=$session_data->{session_id}") if DEBUG;
        return $self->store->delete_auth_request_p($state)->catch(sub ($err) {
            $self->log->warn("failed to delete auth request info for state=$state: $err");
        });
    })->then(sub { return $session_data });
}

# Starts a scope-upgrade authorization for an already-known, already-
# verified session; seamlessly request a broader scope set without a
# full re-login, merging the result back into the *existing* session
# (see _apply_scope_upgrade_merge(_p) above) rather than replacing it.
# $session is the existing stored session hashref; $additional_scopes is
# what's newly needed. The PAR request actually asks for the union of
# the session's current scopes and these, so a repeated upgrade request
# for the same additional scope is idempotent rather than narrowing what
# gets asked for. Returns the redirect URL, same as start_auth_flow.
sub start_scope_upgrade($self, $session, $additional_scopes) {
    die "start_scope_upgrade: 'store' must be configured\n" unless defined($self->store);

    my $scopes = $self->_union_scopes($session->{scopes}, $additional_scopes);
    $self->log->debug("start_scope_upgrade: session_id=$session->{session_id} requesting scopes=[" . join(',', @$scopes) . ']') if DEBUG;
    my $auth_meta = $self->resolver->resolve_auth_server_metadata($session->{auth_server_url});
    my $info      = $self->send_auth_request($auth_meta, scopes => $scopes, login_hint => $session->{account_did});
    $info->{account_did}        = $session->{account_did};
    $info->{upgrade_session_id} = $session->{session_id};

    $self->store->save_auth_request($info);

    return $self->_authorization_redirect_url($auth_meta, $info);
}

sub start_scope_upgrade_p($self, $session, $additional_scopes) {
    die "start_scope_upgrade_p: 'store' must be configured\n" unless defined($self->store);

    my $scopes = $self->_union_scopes($session->{scopes}, $additional_scopes);
    $self->log->debug("start_scope_upgrade_p: session_id=$session->{session_id} requesting scopes=[" . join(',', @$scopes) . ']') if DEBUG;

    return $self->resolver->resolve_auth_server_metadata_p($session->{auth_server_url})->then(sub ($auth_meta) {
        return $self->send_auth_request_p($auth_meta, scopes => $scopes, login_hint => $session->{account_did})->then(sub ($info) {
            $info->{account_did}        = $session->{account_did};
            $info->{upgrade_session_id} = $session->{session_id};
            return $self->store->save_auth_request_p($info)->then(sub { return $self->_authorization_redirect_url($auth_meta, $info) });
        });
    });
}

# Uses the stored refresh token to mint a new access token, without
# involving the user.
# Reuses the session's own DPoP key - RFC 9449 requires the same key for
# every proof across one authorization's lifetime, refreshing never
# generates a new one. Persists the updated session via `store` and
# returns it.
sub refresh_tokens($self, $session) {
    die "refresh_tokens: 'store' must be configured\n" unless defined($self->store);
    $self->log->debug("refresh_tokens: account_did=$session->{account_did} session_id=$session->{session_id}") if DEBUG;

    my $body = {
        client_id     => $self->client_id,
        grant_type    => 'refresh_token',
        refresh_token => $session->{refresh_token},
        %{$self->_client_assertion_params($session->{auth_server_url})},
    };

    my $dpop_key = Mojo::ATProto::OAuth::DPoP->import_private_pem($session->{dpop_private_key_pem});
    my ($res, $dpop_nonce) = $self->_post_dpop_retry(
        url => $session->{auth_server_token_endpoint}, body => $body, key => $dpop_key,
        nonce => $session->{dpop_authserver_nonce}, label => 'token refresh',
    );
    die "token refresh failed (HTTP " . $res->code . "): " . $self->_parse_auth_error_reason($res) . "\n"
        unless $res->code == 200;

    my $token_resp = $res->json;
    $session->{access_token}          = $token_resp->{access_token};
    $session->{refresh_token}         = $token_resp->{refresh_token};
    $session->{dpop_authserver_nonce} = $dpop_nonce;

    $self->store->save_session($session);
    $self->log->debug("refresh_tokens: succeeded and persisted, session_id=$session->{session_id}") if DEBUG;
    return $session;
}

sub refresh_tokens_p($self, $session) {
    die "refresh_tokens_p: 'store' must be configured\n" unless defined($self->store);
    $self->log->debug("refresh_tokens_p: account_did=$session->{account_did} session_id=$session->{session_id}") if DEBUG;

    my $body = {
        client_id     => $self->client_id,
        grant_type    => 'refresh_token',
        refresh_token => $session->{refresh_token},
        %{$self->_client_assertion_params($session->{auth_server_url})},
    };

    my $dpop_key = Mojo::ATProto::OAuth::DPoP->import_private_pem($session->{dpop_private_key_pem});
    return $self->_post_dpop_retry_p(
        url => $session->{auth_server_token_endpoint}, body => $body, key => $dpop_key,
        nonce => $session->{dpop_authserver_nonce}, label => 'token refresh',
    )->then(sub ($res, $dpop_nonce) {
        die "token refresh failed (HTTP " . $res->code . "): " . $self->_parse_auth_error_reason($res) . "\n"
            unless $res->code == 200;

        my $token_resp = $res->json;
        $session->{access_token}          = $token_resp->{access_token};
        $session->{refresh_token}         = $token_resp->{refresh_token};
        $session->{dpop_authserver_nonce} = $dpop_nonce;

        return $self->store->save_session_p($session)->then(sub {
            $self->log->debug("refresh_tokens_p: succeeded and persisted, session_id=$session->{session_id}") if DEBUG;
            return $session;
        });
    });
}

1;

__END__

=head1 NAME

Mojo::ATProto::OAuth - ATProto OAuth client: PAR, DPoP, token exchange,
refresh, and scope upgrade

=head1 SYNOPSIS

=head2 Inside a Mojolicious app (async, non-blocking)

    use Mojo::ATProto::OAuth;

    my $oauth = Mojo::ATProto::OAuth->new(
        client_id    => 'https://example.com/oauth/client-metadata.json',
        callback_url => 'https://example.com/oauth/callback',
        scopes       => ['atproto', 'transition:generic'],
        store        => 'Memory' # or [ 'Pg' => 'pg-connection-string'] or ['SQLite' => 'sqlite-connection-string' ]
    );

    # kick off login (in a route handler)
    $c->render_later;
    $oauth->start_auth_flow_p(identifier => $handle_or_did)->then(sub ($redirect_url) {
        $c->redirect_to($redirect_url);
    });

    # handle the callback
    $c->render_later;
    $oauth->process_callback_p($c->req->params->to_hash)->then(sub ($session_data) {
        # $session_data->{account_did}, ->{handle}, ->{access_token}, ...
    });

    # later: refresh, or ask for more scopes
    $oauth->refresh_tokens_p($session)->then(sub ($refreshed) { ... });
    $oauth->start_scope_upgrade_p($session, ['repo:generic'])->then(sub ($redirect_url) { ... });

=head2 Standalone - no Mojolicious app, no plugin, just this module

This module can bb used outside of a Mojolicious application, so long as there's I<some> way to send the user's browser to a URL, and I<some> way to receive the callback request's query parameters, which any web framework (Dancer, PSGI, plain CGI, a raw socket listener) or even a manual copy/paste can supply. A minimal, complete, synchronous example, using only this module plus its own shipped in-memory L<store|/THE STORE INTERFACE>:

    use Mojo::ATProto::OAuth;

    my $oauth = Mojo::ATProto::OAuth->new_localhost(
        callback_url => 'http://127.0.0.1:8080/callback',
        store        => 'Memory',    # resolves to Mojo::ATProto::OAuth::SessionStore::Memory
    );

    # 1. get the URL to open in a browser
    my $redirect_url = $oauth->start_auth_flow(identifier => 'alice.bsky.social');
    print "Open this URL in a browser: $redirect_url\n";

    # 2. once the browser lands back on your callback URL, collect its
    #    query params however your own app does it, and hand them to
    #    process_callback as a plain hashref
    my $session = $oauth->process_callback(\%callback_query_params);

    print "Logged in as $session->{handle} ($session->{account_did})\n";

=head1 DESCRIPTION

This module provides an implementation of ATproto flavor OAuth - so named because it incorporates just about every RFC known to man, woman, and neither, and no existing OAuth library on CPAN currently provides any of this.

The client core provides: client metadata, PAR, DPoP-sender-constrained requests, the full auth redirect/callback/token exchange flow, token refresh and the ability to upgrade scopes without a full re-authentication.

Based on Bluesky Social's from indigo C<atproto/auth/oauth> package (C<oauth.go>'s C<ClientApp>/C<ClientConfig>/C<SendAuthRequest>/ C<SendInitialTokenRequest>/C<StartAuthFlow>/C<ProcessCallback>), source at L<https://github.com/bluesky-social/indigo/tree/main/atproto/auth/oauth>.

This module is framework-decoupled on purpose - it does not depend on Mojolicious's request/response cycle, sessions, or any web-framework concept beyond L<Mojo::UserAgent> for HTTP and L<Mojo::Promise> for async. It holds only client configuration (C<client_id>, callback URL, scopes, an optional confidential-client key), collaborator instances (an identity resolver, an auth-server resolver, an HTTP client), and a pluggable C<store>. Every method takes and returns plain hashrefs.

Every network-calling method has a matching non-blocking C<_p> (L<Mojo::Promise>-returning) variant, intended to run inside a Mojolicious request handler (e.g. login), where a blocking call would stall every other concurrent request on the same worker.

=head1 ATTRIBUTES

=head2 client_id

(Required.) The OAuth client's C<client_id> - either a real C<https://> URL where L</client_metadata> should be served, or (for a loopback client - see L</new_localhost>) the fixed sentinel string with parameters encoded in its own query string.

=head2 callback_url

(Required.) The single redirect URI this client uses.

=head2 scopes

Arrayref of default scope strings requested by L</start_auth_flow> when no per-call C<scopes> opt is given. Defaults to C<['atproto']>.

=head2 private_key

A L<Crypt::PK::ECC> private key, for a confidential client. C<undef> (the default) for a public client. Must be set together with L</key_id> - see L</is_confidential>.

=head2 key_id

The key ID matching L</private_key>. See L</is_confidential>.

=head2 loopback

Boolean, true for clients constructed via L</new_localhost>. Governs whether L</client_metadata> may be called (it dies for a loopback client - there is no document to serve).

=head2 identity

A L<Mojo::ATProto::OAuth::Identity> instance, used to resolve handles and DIDs. Defaults to a fresh instance.

=head2 resolver

A L<Mojo::ATProto::OAuth::Resolver> instance, used for auth-server discovery and metadata validation. Defaults to a fresh instance.

=head2 store

A session/auth-request persistence backend - required for L</start_auth_flow>, L</process_callback>, L</start_scope_upgrade>, and L</refresh_tokens> (each dies immediately if unset). See L</THE STORE
INTERFACE> below. C<undef> by default.

May be set to either a store instance, or a short class-name string that resolves to one of the built-in session storage drivers, or the full class name of a driver you want to use. A driver *must* implement the methods listed in L<Mojo::ATProto::OAuth::SessionStore>. 

=head2 ua

A L<Mojo::UserAgent> instance used for every HTTP request this module makes. Defaults to a fresh instance with a 10-second request timeout.

=head2 log

A L<Mojo::Log> instance for debug logging (see L</DEBUG LOGGING>).  Defaults to a fresh instance at the level named by C<MOJO_LOG_LEVEL> (C<info> if unset).

=head1 CONSTRUCTORS

=head2 new_localhost

    my $oauth = Mojo::ATProto::OAuth->new_localhost(
        callback_url      => $callback_url,    # required
        scopes            => \@scopes,         # optional, default ['atproto']
        ua                => $ua,              # optional
        user_agent_header => $header,          # optional
        store             => $store,           # optional
    );

Builds a client using ATProto OAuth's "loopback client" allowance for local-dev testing (ported from indigo's C<NewLocalhostConfig>): rather than a real C<https://> C<client_id> URL serving a fetched metadata document, C<client_id> is the fixed sentinel C<http://localhost> with C<redirect_uri>/C<scope> encoded directly in its own query string.  Conformant auth servers recognize this literal C<client_id> and parse those params instead of fetching anything. Always a public client (loopback clients can't declare a JWKS), so this constructor doesn't accept C<private_key>/C<key_id>.

The C<client_id> host is the literal string C<localhost> - a fixed spec sentinel, not a real address to resolve. That is a separate thing from C<callback_url>, which must actually point at C<127.0.0.1> (not C<localhost>) for a plain-C<http> redirect URI to be accepted, per the same loopback exception on the I<redirect_uri> side. Getting the callback URL's host wrong here is not validated by this constructor (it isn't validated by indigo's C<NewLocalhostConfig> either) - a real auth server will reject the resulting PAR request with an invalid C<redirect_uri> instead; it's the caller's responsibility to actually run on C<127.0.0.1>.

=head2 new

    my $oauth = Mojo::ATProto::OAuth->new(
        client_id         => $client_id,       # required, in the form of https://your-site.com/client-metadata.json or something appropriate
        callback_url      => $callback_url,    # required
        scopes            => \@scopes,         # optional, default ['atproto']
        ua                => $ua,              # optional
        user_agent_header => $header,          # optional
        store             => $store,           # optional
    );

=head1 METHODS

=head2 is_confidential

    my $bool = $oauth->is_confidential;

True if both L</private_key> and L</key_id> are set.

=head2 client_metadata

    my $doc = $oauth->client_metadata;

Returns the client ID metadata document (see L<Mojo::ATProto::OAuth::ClientMetadata>) this client's C<client_id> URL must serve byte for byte. Dies if called on a loopback client (see L</loopback>) - a loopback client's C<client_id> isn't a fetchable URL at all, so calling this is a caller bug, not a runtime condition to handle gracefully.

=head2 start_auth_flow

    my $redirect_url = $oauth->start_auth_flow(%opts);

High-level helper for starting a new login; resolves an identity to auth-server metadata, sends the PAR request, persists the auth request via L</store>, and returns the URL the user's browser should be redirected to for approval. Requires L</store> to be configured (dies immediately otherwise).

C<%opts> - exactly one of:

=over 4

=item * C<identifier> - an ATProto handle/DID, or an C<https://> auth-server URL directly (this second form skips identity resolution entirely until the callback - the returned session's C<account_did>/ C<handle> stay unresolved until then).

=item * C<did> + C<handle> + C<host_url> (all three together) - when the caller has already resolved identity itself (e.g. to make a pre-auth decision, such as reading a public repo record to pick a scope set) and there's no reason to pay for a second identity lookup here just to re-derive the same C<did>/C<handle>. Auth-server discovery (C<host_url> -> auth-server URL) still always happens regardless of which mode is used - that's a separate step from identity resolution, not something a caller would plausibly have pre-computed.

=back

Plus, independent of the above:

=over 4

=item * C<scopes> (optional arrayref) - overrides L</scopes> for just this call; falls back to the client's configured default when omitted.

=item * C<client_state> (optional hashref) - opaque, never inspected by this module; persisted on the auth request and handed back untouched inside L</process_callback>'s result. Intended for things like a post-login redirect target that needs to survive the round trip to the auth server and back.

=item * C<extra> (optional hashref) - the same opaque pass-through treatment as C<client_state>, but conventionally used by callers for data that belongs in their own session metadata once login completes (e.g. a pre-auth decision worth remembering), rather than callback-routing data. This module draws no distinction between the two beyond "two separate opaque slots" - what each is used for is entirely up to the caller.

=back

=head2 start_auth_flow_p

Non-blocking counterpart of L</start_auth_flow>.

=head2 process_callback

    my $session_data = $oauth->process_callback($params);

High-level helper for completing the auth flow.  C<$params> is a plain hashref of the callback request's query parameters (e.g.  C<< $c->req->params->to_hash >> in a Mojolicious route handler).  Verifies the callback params against the persisted auth request, exchanges the authorization code for tokens, verifies the account identity, persists the resulting session via L</store>, and returns the session hashref (shape below). Requires L</store> to be configured.

A hashref will be returned as follows:

    {
        account_did                     => 'did:plc:...',
        handle                          => 'alice.bsky.social',         # or undef
        session_id                      => $state,                      # the PAR 'state' value
        host_url                        => 'https://pds.example.com',
        auth_server_url                 => 'https://auth.example.com',
        auth_server_token_endpoint      => '...',
        auth_server_revocation_endpoint => '...',                       # or undef
        scopes                          => [ 'atproto', ... ],
        access_token                    => '...',
        refresh_token                   => '...',
        dpop_authserver_nonce           => '...',
        dpop_host_nonce                 => '...',
        dpop_private_key_pem            => '...',                       # PEM, see Mojo::ATProto::OAuth::DPoP
        client_state                    => $opts_client_state,          # from start_auth_flow(_p), or undef
        extra                           => $opts_extra,                 # from start_auth_flow(_p), or undef
    }

If this auth request came from L</start_scope_upgrade>, C<session_id> here is the I<existing> session's id (not a new one) and C<scopes> is the union of the existing session's scopes and the newly-granted ones - see L</start_scope_upgrade> for why.

On success, the now-consumed auth-request row is deleted from L</store>; a failure to delete it is logged and otherwise ignored (the session itself is already safely persisted at that point - a leftover auth-request row is inert, not a correctness problem), matching indigo's own log-and-continue behavior.

=head2 process_callback_p

Non-blocking counterpart of L</process_callback>. Rejects (rather than dying) on failure, with the same messages.

=head2 start_scope_upgrade

    my $redirect_url = $oauth->start_scope_upgrade($session, \@additional_scopes);

Starts a scope-upgrade authorization for an already-known, already- verified session; seamlessly request a broader scope set without a full re-login, merging the result back into the I<existing> session (rather than replacing it) once the callback completes. C<$session> is the existing stored session hashref (as returned by L</process_callback>); C<$additional_scopes> is an arrayref of the newly-needed scopes.

The PAR request actually asks for the union of C<$session>'s current scopes and C<$additional_scopes>, so a repeated upgrade request for the same additional scope is idempotent rather than narrowing what gets asked for. Returns the redirect URL, same as L</start_auth_flow>.  Requires L</store> to be configured.

=head2 start_scope_upgrade_p

Non-blocking counterpart of L</start_scope_upgrade>.

=head2 refresh_tokens

    my $refreshed_session = $oauth->refresh_tokens($session);

Uses the session's stored refresh token to mint a new access token, without involving the user. Reuses the session's own DPoP key - RFC 9449 requires the same key for every proof across one authorization's lifetime, so refreshing never generates a new one.  Persists the updated session via L</store> and returns it (the same hashref, mutated in place, for convenience). Note this rotates I<both> the access token and the refresh token. Requires L</store> to be configured.

=head2 refresh_tokens_p

Non-blocking counterpart of L</refresh_tokens>.

=head1 LOWER-LEVEL METHODS

These are used internally by the high-level methods above, and are also exposed for callers that need finer-grained control (e.g. a caller already holding a persisted auth-request row and only needing the token exchange step). Ordinary use of this module should not need to call these directly.

=head2 send_auth_request / send_auth_request_p

    my $info = $oauth->send_auth_request($auth_meta, %opts);

Sends the PAR request that kicks off an authorization flow, given already-validated auth-server metadata (as returned by L<Mojo::ATProto::OAuth::Resolver/resolve_auth_server_metadata>).  C<%opts>: C<scopes> (optional arrayref, defaults to L</scopes>), C<login_hint> (optional). Returns an C<AuthRequestData>-equivalent hashref (C<state>, C<auth_server_url>, C<scopes>, C<pkce_verifier>, C<request_uri>, C<auth_server_token_endpoint>, C<auth_server_revocation_endpoint>, C<dpop_authserver_nonce>, C<dpop_private_key_pem>) - everything a store needs to persist and later exchange for tokens via L</send_initial_token_request>. Does not itself persist anything or resolve an identity - see L</start_auth_flow> for the full orchestration.

=head2 send_initial_token_request / send_initial_token_request_p

    my $token_resp = $oauth->send_initial_token_request($auth_code, $info);

Exchanges an authorization code for tokens. C<$info> is the C<AuthRequestData>- equivalent hashref from L</send_auth_request> or a store lookup - reuses its DPoP keypair (RFC 9449 requires the same key for every proof tied to one authorization attempt) and PKCE verifier. Returns a C<TokenResponse>-equivalent hashref (C<sub>, C<scope>, C<access_token>, C<refresh_token>) plus the final C<dpop_authserver_nonce>, for the caller to persist.

=head1 THE STORE INTERFACE

L</store> is semi-duck-typed, a base class exists in L<Mojo::ATProto::OAuth::SessionStore> that will complain loudly if you subclass it without implementing the proper methods. If you write your own session store driver, you must implement the following methods:

=over 4

=item * C<get_auth_request($state)> / C<get_auth_request_p($state)>

=item * C<save_auth_request($info)> / C<save_auth_request_p($info)>

=item * C<delete_auth_request($state)> / C<delete_auth_request_p($state)>

=item * C<get_session($account_did, $session_id)> / C<get_session_p($account_did, $session_id)>

=item * C<save_session($session_data)> / C<save_session_p($session_data)>

=item * C<delete_session($account_did, $session_id)> / C<delete_session_p($account_did, $session_id)>

=back

A store only needs to implement whichever half a given caller actually uses - the synchronous methods if the caller only ever calls this module's synchronous methods (L</start_auth_flow>, L</process_callback>, etc. - see the standalone example in L</SYNOPSIS>, whose C<My::MemoryStore> implements only the sync half), or the C<_p> methods if the caller only ever uses the async ones. A store used with both needs both halves implemented.

This distribution ships three session store drivers:

=over 4 

=item * L<Mojo::ATProto::OAuth::SessionStore::Memory> - a plain in-process hashref store - sessions and auth requests are lost on process exit; fine for a single-process script or a test suite, not for a real deployment).

=item * L<Mojo::ATProto::OAuth::SessionStore::SQLite> - an SQLite backed session store, requires L<Mojo::SQLite> to be installed. 

=item * L<Mojo::ATProto::OAuth::SessionStore::Pg> - a Postgres backed session store, requires L<Mojo::Pg> to be installed.

=back

The Memory store takes no arguments, whereas the SQLite and Pg stores do (connection strings), these can be passed during construction of the OAuth object:

    my $pg_backed = Mojo::ATProto::OAuth->new(
        client_id         => $client_id,       
        callback_url      => $callback_url,   
        scopes            => [ 'atproto account:email' ],
        store             => [ 'Pg' => 'postgresql://user:pass@host:port/dbname' ]
    );

    my $sqlite_backed = Mojo::ATProto::OAuth->new(
        client_id         => $client_id,       
        callback_url      => $callback_url,   
        scopes            => [ 'atproto account:email' ],
        store             => [ 'SQLite' => 'file:/tmp/test.db?wal_mode=1' ]
    );

=head1 ERROR HANDLING

Synchronous methods C<die> with a newline-terminated message on failure (per Perl convention - no "at FILE line N" is appended).  Asynchronous (C<_p>) methods reject their returned L<Mojo::Promise> with the same message string instead of dying.

=head1 DEBUG LOGGING

Two independent environment variables control logging: C<MOJO_LOG_LEVEL> sets the actual L<Mojo::Log> level (the same variable Mojolicious itself honors for an application's own C<< ->log >>); C<MOJO_OAUTH_DEBUG> (any true value) additionally enables this module's own debug-level log calls. This means that you need to set C<MOJO_LOG_LEVEL> to 'debug' *and* set C<MOJO_OAUTH_DEBUG> to a true value in order to see debug logs emitted from this module. 

Debug logs never include secret material (tokens, private keys, client assertions, PKCE verifiers) - only identifiers (DID, handle, state, session_id) and results.

=head1 SEE ALSO

L<Mojo::ATProto::OAuth::Identity>, L<Mojo::ATProto::OAuth::Resolver>, L<Mojo::ATProto::OAuth::DPoP>, L<Mojo::ATProto::OAuth::ClientMetadata>

=cut
