package Net::Async::Zitadel::OIDC;

# ABSTRACT: Async OIDC client for Zitadel - token verification, JWKS, discovery

use Moo;
use Crypt::JWT qw(decode_jwt);
use JSON::MaybeXS qw(decode_json);
use HTTP::Request;
use URI;
use Future;
use Net::Async::Zitadel::Error;
use namespace::clean;

our $VERSION = '0.001';

has issuer => (
    is       => 'ro',
    required => 1,
);

sub BUILD {
    my $self = shift;
    die Net::Async::Zitadel::Error::Validation->new(
        message => 'issuer must not be empty',
    ) unless length $self->issuer;
}

has http => (
    is       => 'ro',
    required => 1,
    doc      => 'Net::Async::HTTP instance (shared from parent)',
);


has discovery_ttl => (
    is      => 'ro',
    default => 3600,
);

has jwks_ttl => (
    is      => 'ro',
    default => 300,
);

has _discovery_cache => (
    is      => 'rw',
    default => sub { undef },
);

has _discovery_expires => (
    is      => 'rw',
    default => sub { 0 },
);

has _jwks_cache => (
    is      => 'rw',
    default => sub { undef },
);

has _jwks_expires => (
    is      => 'rw',
    default => sub { 0 },
);

# Stores the in-flight JWKS Future to coalesce concurrent refresh requests.
has _jwks_inflight => (
    is      => 'rw',
    default => sub { undef },
);

# --- Discovery ---

sub discovery_f {
    my ($self) = @_;

    if ($self->_discovery_cache && time() < $self->_discovery_expires) {
        return Future->done($self->_discovery_cache);
    }

    my $url = $self->issuer . '/.well-known/openid-configuration';

    return $self->http->GET(URI->new($url))->then(sub {
        my ($response) = @_;
        unless ($response->is_success) {
            return Future->fail(Net::Async::Zitadel::Error::Network->new(
                message => 'Discovery failed: ' . $response->status_line,
            ));
        }
        my $doc = decode_json($response->decoded_content);
        $self->_discovery_cache($doc);
        $self->_discovery_expires(time() + $self->discovery_ttl);
        return Future->done($doc);
    });
}

# --- JWKS ---

sub jwks_f {
    my ($self, %args) = @_;
    my $force = $args{force_refresh} // 0;

    if (!$force && $self->_jwks_cache && time() < $self->_jwks_expires) {
        return Future->done($self->_jwks_cache);
    }

    # Coalesce concurrent JWKS refreshes: if a fetch is already in-flight,
    # return the same Future rather than issuing a second HTTP request.
    if (!$force && $self->_jwks_inflight) {
        return $self->_jwks_inflight;
    }

    my $f = $self->discovery_f->then(sub {
        my ($doc) = @_;
        my $jwks_uri = $doc->{jwks_uri}
            // return Future->fail(Net::Async::Zitadel::Error::Validation->new(
                message => 'No jwks_uri in discovery document',
            ));
        return $self->http->GET(URI->new($jwks_uri));
    })->then(sub {
        my ($response) = @_;
        unless ($response->is_success) {
            return Future->fail(Net::Async::Zitadel::Error::Network->new(
                message => 'JWKS fetch failed: ' . $response->status_line,
            ));
        }
        my $jwks = decode_json($response->decoded_content);
        $self->_jwks_cache($jwks);
        $self->_jwks_expires(time() + $self->jwks_ttl);
        $self->_jwks_inflight(undef);
        return Future->done($jwks);
    })->on_fail(sub {
        $self->_jwks_inflight(undef);
    });

    # Only store the in-flight Future if it is still pending.
    # Synchronous (already-resolved) chains must not be stored, because
    # the on_fail/on_done clearing inside the chain already ran before we
    # reach this line, and storing $f here would re-populate the slot.
    $self->_jwks_inflight($f) unless $force || $f->is_ready;
    return $f;
}

# --- Token verification ---

sub verify_token_f {
    my ($self, $token, %args) = @_;

    return Future->fail(Net::Async::Zitadel::Error::Validation->new(
        message => 'No token provided',
    )) unless defined $token;

    return $self->jwks_f->then(sub {
        my ($jwks) = @_;

        my $claims;
        eval {
            $claims = $self->_decode_jwt(
                token            => $token,
                kid_keys         => $jwks,
                verify_exp       => $args{verify_exp} // 1,
                verify_iat       => $args{verify_iat} // 0,
                verify_nbf       => $args{verify_nbf} // 0,
                verify_iss       => $self->issuer,
                verify_aud       => $args{audience},
                accepted_key_alg => $args{accepted_key_alg} // ['RS256', 'RS384', 'RS512'],
            );
        };
        if ($@ && !$args{no_retry}) {
            # Key rotation: refresh JWKS and retry once
            return $self->jwks_f(force_refresh => 1)->then(sub {
                my ($fresh_jwks) = @_;
                my $retry_claims = $self->_decode_jwt(
                    token            => $token,
                    kid_keys         => $fresh_jwks,
                    verify_exp       => $args{verify_exp} // 1,
                    verify_iat       => $args{verify_iat} // 0,
                    verify_nbf       => $args{verify_nbf} // 0,
                    verify_iss       => $self->issuer,
                    verify_aud       => $args{audience},
                    accepted_key_alg => $args{accepted_key_alg} // ['RS256', 'RS384', 'RS512'],
                );
                return Future->done($retry_claims);
            });
        }
        elsif ($@) {
            return Future->fail($@);
        }

        return Future->done($claims);
    });
}

sub _decode_jwt {
    my ($self, %args) = @_;
    return decode_jwt(%args);
}

# --- UserInfo ---

sub userinfo_f {
    my ($self, $access_token) = @_;

    return Future->fail(Net::Async::Zitadel::Error::Validation->new(
        message => 'No access token provided',
    )) unless defined $access_token;

    return $self->discovery_f->then(sub {
        my ($doc) = @_;
        my $endpoint = $doc->{userinfo_endpoint}
            // return Future->fail(Net::Async::Zitadel::Error::Validation->new(
                message => 'No userinfo_endpoint in discovery document',
            ));
        my $req = HTTP::Request->new(GET => $endpoint);
        $req->header(Authorization => "Bearer $access_token");
        return $self->http->do_request(request => $req);
    })->then(sub {
        my ($response) = @_;
        unless ($response->is_success) {
            return Future->fail(Net::Async::Zitadel::Error::Network->new(
                message => 'UserInfo failed: ' . $response->status_line,
            ));
        }
        return Future->done(decode_json($response->decoded_content));
    });
}

# --- Token Introspection ---

sub introspect_f {
    my ($self, $token, %args) = @_;

    return Future->fail(Net::Async::Zitadel::Error::Validation->new(
        message => 'No token provided',
    )) unless defined $token;

    return Future->fail(Net::Async::Zitadel::Error::Validation->new(
        message => 'Introspection requires client_id and client_secret',
    )) unless $args{client_id} && $args{client_secret};

    return $self->discovery_f->then(sub {
        my ($doc) = @_;
        my $endpoint = $doc->{introspection_endpoint}
            // return Future->fail(Net::Async::Zitadel::Error::Validation->new(
                message => 'No introspection_endpoint in discovery document',
            ));

        my $form = URI->new;
        $form->query_form(
            token           => $token,
            client_id       => $args{client_id},
            client_secret   => $args{client_secret},
            token_type_hint => $args{token_type_hint} // 'access_token',
        );

        my $req = HTTP::Request->new(POST => $endpoint);
        $req->header('Content-Type' => 'application/x-www-form-urlencoded');
        $req->content($form->query);

        return $self->http->do_request(request => $req);
    })->then(sub {
        my ($response) = @_;
        unless ($response->is_success) {
            return Future->fail(Net::Async::Zitadel::Error::Network->new(
                message => 'Introspection failed: ' . $response->status_line,
            ));
        }
        return Future->done(decode_json($response->decoded_content));
    });
}

# --- Token Endpoint ---

sub token_f {
    my ($self, %args) = @_;

    my $grant_type = delete $args{grant_type};
    return Future->fail(Net::Async::Zitadel::Error::Validation->new(
        message => 'grant_type required',
    )) unless defined $grant_type;

    return $self->discovery_f->then(sub {
        my ($doc) = @_;
        my $endpoint = $doc->{token_endpoint}
            // return Future->fail(Net::Async::Zitadel::Error::Validation->new(
                message => 'No token_endpoint in discovery document',
            ));

        my $form = URI->new;
        $form->query_form(grant_type => $grant_type, %args);

        my $req = HTTP::Request->new(POST => $endpoint);
        $req->header('Content-Type' => 'application/x-www-form-urlencoded');
        $req->content($form->query);

        return $self->http->do_request(request => $req);
    })->then(sub {
        my ($response) = @_;
        unless ($response->is_success) {
            return Future->fail(Net::Async::Zitadel::Error::Network->new(
                message => 'Token endpoint failed: ' . $response->status_line,
            ));
        }
        return Future->done(decode_json($response->decoded_content));
    });
}

sub client_credentials_token_f {
    my ($self, %args) = @_;

    my $client_id = delete $args{client_id};
    return Future->fail(Net::Async::Zitadel::Error::Validation->new(
        message => 'client_id required',
    )) unless defined $client_id;

    my $client_secret = delete $args{client_secret};
    return Future->fail(Net::Async::Zitadel::Error::Validation->new(
        message => 'client_secret required',
    )) unless defined $client_secret;

    return $self->token_f(
        grant_type    => 'client_credentials',
        client_id     => $client_id,
        client_secret => $client_secret,
        %args,
    );
}

sub refresh_token_f {
    my ($self, $refresh_token, %args) = @_;

    return Future->fail(Net::Async::Zitadel::Error::Validation->new(
        message => 'refresh_token required',
    )) unless defined $refresh_token && length $refresh_token;

    return $self->token_f(
        grant_type    => 'refresh_token',
        refresh_token => $refresh_token,
        %args,
    );
}

sub exchange_authorization_code_f {
    my ($self, %args) = @_;

    my $code = delete $args{code};
    return Future->fail(Net::Async::Zitadel::Error::Validation->new(
        message => 'code required',
    )) unless defined $code;

    my $redirect_uri = delete $args{redirect_uri};
    return Future->fail(Net::Async::Zitadel::Error::Validation->new(
        message => 'redirect_uri required',
    )) unless defined $redirect_uri;

    return $self->token_f(
        grant_type   => 'authorization_code',
        code         => $code,
        redirect_uri => $redirect_uri,
        %args,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Zitadel::OIDC - Async OIDC client for Zitadel - token verification, JWKS, discovery

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use IO::Async::Loop;
    use Net::Async::Zitadel;

    my $loop = IO::Async::Loop->new;
    my $z = Net::Async::Zitadel->new(issuer => 'https://zitadel.example.com');
    $loop->add($z);

    # Async token verification
    my $claims = $z->oidc->verify_token_f($access_token)->get;

    # Async userinfo
    my $user = $z->oidc->userinfo_f($access_token)->get;

    # Async client credentials token
    my $token = $z->oidc->client_credentials_token_f(
        client_id     => $id,
        client_secret => $secret,
    )->get;

=head1 DESCRIPTION

Async OIDC client for Zitadel, built on L<Net::Async::HTTP> and L<Future>.
All methods return L<Future> objects (C<_f> suffix convention).

Token verification automatically retries with a refreshed JWKS on failure,
handling key rotation transparently. Concurrent JWKS refresh requests are
coalesced: if a refresh is already in-flight, subsequent callers receive the
same Future rather than triggering a second HTTP request.

=head2 issuer

Required. The Zitadel issuer URL. Must not be empty.

=head2 http

Required. A L<Net::Async::HTTP> instance (typically shared from
L<Net::Async::Zitadel>).

=head2 discovery_f

Returns a Future resolving to the parsed OpenID Connect discovery document.
Cached after first fetch.

=head2 jwks_f

Returns a Future resolving to the JSON Web Key Set. Cached after first fetch.
Pass C<< force_refresh => 1 >> to bypass the cache. Concurrent non-forced
calls coalesce into the same in-flight request.

=head2 verify_token_f

    my $f = $oidc->verify_token_f($jwt, %options);

Returns a Future resolving to the decoded claims hashref. Automatically retries
once with a fresh JWKS on verification failure (key rotation). Options:
C<audience>, C<verify_exp>, C<verify_iat>, C<verify_nbf>,
C<accepted_key_alg>, C<no_retry>.

=head2 userinfo_f

    my $f = $oidc->userinfo_f($access_token);

Returns a Future resolving to the UserInfo endpoint response.

=head2 introspect_f

    my $f = $oidc->introspect_f($token,
        client_id     => $id,
        client_secret => $secret,
    );

Returns a Future resolving to the token introspection response.

=head2 token_f

    my $f = $oidc->token_f(grant_type => 'client_credentials', %params);

Generic async token endpoint POST (form-encoded). Returns a Future.

=head2 client_credentials_token_f

Convenience wrapper for C<client_credentials> grant.

=head2 refresh_token_f

Convenience wrapper for C<refresh_token> grant.

=head2 exchange_authorization_code_f

Convenience wrapper for C<authorization_code> grant.

=head2 discovery_ttl

How many seconds to cache the OpenID Connect discovery document before
re-fetching. Default: C<3600> (one hour). Set to C<0> to disable caching.

=head2 jwks_ttl

How many seconds to cache the JSON Web Key Set before re-fetching. Default:
C<300> (five minutes). Set to C<0> to disable caching.

=head1 SEE ALSO

L<Net::Async::Zitadel>, L<WWW::Zitadel::OIDC>, L<Crypt::JWT>, L<Future>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-net-async-zitadel/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
