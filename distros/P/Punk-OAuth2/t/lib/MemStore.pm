package MemStore;

# A reference in-memory store implementing the Punk::OAuth2 store
# contract - the same code that appears in Punk::OAuth2::Server::Store's
# "CREATING YOUR OWN STORE" POD. Kept here so the test suite proves the
# documented contract actually drives the authorization server.

use 5.024;
use strict;
use warnings;
use Crypt::JWS qw(sha256 b64url);

# Credentials are stored as base64url(sha256(...)) digests, the same
# convention the server uses when it checks a client secret.
sub _digest { b64url(sha256($_[0])) }

sub new {
    my ($class) = @_;
    return bless {
        clients  => {},
        codes    => {},
        refresh  => {},
        consents => {},
    }, $class;
}

# ---- clients --------------------------------------------------------------

sub client_put {
    my ($self, $c) = @_;
    $self->{clients}{ $c->{client_id} } = {
        client_id     => $c->{client_id},
        secret_digest => (defined $c->{secret} && length $c->{secret})
                         ? _digest($c->{secret}) : undef,
        name          => $c->{name},
        redirect_uris => $c->{redirect_uris} // [],   # an arrayref is fine
        grant_types   => $c->{grant_types}
                         // 'authorization_code refresh_token',
        scopes        => $c->{scopes},
        auth_method   => $c->{auth_method} // 'basic',
        is_public     => $c->{public} ? 1 : 0,
    };
    return;
}

sub client_get {
    my ($self, $client_id) = @_;
    my $c = $self->{clients}{$client_id} or return undef;
    return { %$c };   # a shallow copy; redirect_uris stays an arrayref
}

# ---- authorization codes (single use) -------------------------------------

sub code_put {
    my ($self, $code, $rec) = @_;
    $self->{codes}{ _digest($code) } = { %$rec };
    return;
}

sub code_take {
    my ($self, $code) = @_;
    return delete $self->{codes}{ _digest($code) };   # single use
}

# ---- refresh tokens -------------------------------------------------------

sub refresh_put {
    my ($self, $token, $rec) = @_;
    $self->{refresh}{ _digest($token) } = { %$rec, revoked => 0,
                                            rotated_to => undef };
    return;
}

sub refresh_take {
    my ($self, $token) = @_;
    my $r = $self->{refresh}{ _digest($token) } or return undef;
    return { %$r };
}

sub refresh_rotate {
    my ($self, $token, $new_digest) = @_;
    my $r = $self->{refresh}{ _digest($token) } or return;
    $r->{rotated_to} = $new_digest;   # marks the old token consumed
    return;
}

sub refresh_revoke_family {
    my ($self, $family_id) = @_;
    for my $r (values %{ $self->{refresh} }) {
        $r->{revoked} = 1 if ($r->{family_id} // '') eq $family_id;
    }
    return;
}

# ---- consent --------------------------------------------------------------

sub consent_get {
    my ($self, $user_id, $client_id) = @_;
    return $self->{consents}{"$user_id\0$client_id"};
}

sub consent_put {
    my ($self, $user_id, $client_id, $scopes) = @_;
    $self->{consents}{"$user_id\0$client_id"} =
        { user_id => $user_id, client_id => $client_id, scopes => $scopes };
    return;
}

# ---- housekeeping ---------------------------------------------------------

sub purge_expired {
    my ($self) = @_;
    my $now = time;
    for my $k (keys %{ $self->{codes} }) {
        delete $self->{codes}{$k}
            if ($self->{codes}{$k}{expires} // 0) < $now;
    }
    for my $k (keys %{ $self->{refresh} }) {
        delete $self->{refresh}{$k}
            if ($self->{refresh}{$k}{expires} // 0) < $now;
    }
    return;
}

1;
