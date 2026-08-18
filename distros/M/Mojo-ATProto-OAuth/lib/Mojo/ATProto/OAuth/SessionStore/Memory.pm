package 
    Mojo::ATProto::OAuth::SessionStore::Memory;
use Mojo::Base 'Mojo::ATProto::OAuth::SessionStore', -signatures;
use feature 'try';
use Mojo::Promise qw//;

has 'auth_requests'      => sub { {} };
has 'auth_request_order' => sub { [] };    
has 'sessions'           => sub { {} };

sub _session_key($self, $account_did, $session_id) {
    return "$account_did:$session_id";
}

# Fetches a persisted auth-request hashref by its PAR-generated `state`
# value. Dies with a message matching /no auth request found/ on a
# miss
sub get_auth_request($self, $state) {
    my $info = $self->auth_requests->{$state};
    die "no auth request found for state\n" unless defined $info;
    return {%$info};
}

sub get_auth_request_p($self, $state) {
    try {
        return Mojo::Promise->resolve($self->get_auth_request($state));
    } catch($ex) {
        return Mojo::Promise->reject($ex);
    }
}

# Persists an auth-request hashref, keyed by its own `state`. 
# A `state` value is never reused, so this never needs to merge with an existing row.
sub save_auth_request($self, $info) {
    $self->auth_requests->{$info->{state}} = {%$info};
    push @{$self->auth_request_order}, $info->{state};
    return;
}

sub save_auth_request_p($self, $info) {
    $self->save_auth_request($info);
    return Mojo::Promise->resolve;
}

sub delete_auth_request($self, $state) {
    delete $self->auth_requests->{$state};
    return;
}

sub delete_auth_request_p($self, $state) {
    $self->delete_auth_request($state);
    return Mojo::Promise->resolve;
}

# Fetches a persisted session hashref by the *pair* of (account_did,
# session_id) - not session_id alone, since one account can have
# multiple concurrent sessions (e.g. multiple browsers/devices). Dies
# with a message matching /no session found/ on a miss.
sub get_session($self, $account_did, $session_id) {
    my $session = $self->sessions->{$self->_session_key($account_did, $session_id)};
    die "no session found for did/session_id\n" unless defined $session;
    return {%$session};
}

sub get_session_p($self, $account_did, $session_id) {
    try {
        my $session = $self->get_session($account_did, $session_id);
        return Mojo::Promise->resolve($session);
    } catch($ex) {
        return Mojo::Promise->reject($ex);
    }
}

# Persists a session hashref, upserting by (account_did, session_id) -
# both an ordinary login and a scope-upgrade callback may call this on
# what's already an existing row (see Mojo::ATProto::OAuth's own
# _apply_scope_upgrade_merge(_p)), and the existing row must be updated
# in place, not duplicated.
sub save_session($self, $session_data) {
    $self->sessions->{$self->_session_key($session_data->{account_did}, $session_data->{session_id})} = {%$session_data};
    return;
}

sub save_session_p($self, $session_data) {
    $self->save_session($session_data);
    return Mojo::Promise->resolve;
}

sub delete_session($self, $account_did, $session_id) {
    delete $self->sessions->{$self->_session_key($account_did, $session_id)};
    return;
}

sub delete_session_p($self, $account_did, $session_id) {
    $self->delete_session($account_did, $session_id);
    return Mojo::Promise->resolve;
}

# Not part of the store contract Mojo::ATProto::OAuth itself relies on
# but mostly here for testing to work (and find the most recently persisted
# auth request)
sub last_state_for_issuer ($self, $issuer) {
    for my $state (reverse @{$self->auth_request_order}) {
        my $info = $self->auth_requests->{$state};
        next unless defined $info;
        return $state if ($info->{auth_server_url} // '') eq $issuer;
    }
    return undef;
}

1;

__END__

=head1 NAME

Mojo::ATProto::OAuth::SessionStore::Memory - in-memory reference
implementation of Mojo::ATProto::OAuth's session store interface

=head1 SYNOPSIS

    use Mojo::ATProto::OAuth;

    # short-name resolution - Mojo::ATProto::OAuth loads and
    # instantiates this class for you
    my $oauth = Mojo::ATProto::OAuth->new(
        client_id    => 'https://example.com/oauth/client-metadata.json',
        callback_url => 'https://example.com/oauth/callback',
        store        => 'Memory',
    );

    # or construct it directly
    use Mojo::ATProto::OAuth::SessionStore::Memory qw//;
    my $store = Mojo::ATProto::OAuth::SessionStore::Memory->new;
    my $oauth2 = Mojo::ATProto::OAuth->new(..., store => $store);

=head1 DESCRIPTION

A plain in-process hashref implementation of the duck-typed C<store>
interface L<Mojo::ATProto::OAuth> expects - see that module's own "THE
STORE INTERFACE" section for the full contract this class
implements. Nothing is persisted beyond the life of the process: a
restart loses every in-flight auth request and every session. This
makes it a reasonable choice for a single-process script or a test
suite, but not for a real deployment, where a restart-surviving backend
(e.g. Postgres) implementing the same interface is what you want
instead.

C<< Mojo::ATProto::OAuth->new(store => 'Memory') >> resolves to this
class automatically via C<Mojo::ATProto::OAuth>'s own short
class-name-string handling for C<store> - see
L<Mojo::ATProto::OAuth/store>. Constructing it directly, as in the
second L</SYNOPSIS> example, works identically.

=head1 ATTRIBUTES

=head2 auth_requests

Hashref of persisted auth-request rows, keyed by C<state>. Defaults to
an empty hashref. Not part of the public interface - manipulate it only
through the methods below.

=head2 auth_request_order

Arrayref recording the order C<state> values were saved in, since a
plain hash's own iteration order isn't reliable. Used by
L</last_state_for_issuer>. Defaults to an empty arrayref.

=head2 sessions

Hashref of persisted session rows, keyed by
C<"$account_did:$session_id">. Defaults to an empty hashref.

=head1 METHODS

Implements the full sync + C<_p> store contract described in
L<Mojo::ATProto::OAuth/THE STORE INTERFACE>:

=head2 get_auth_request / get_auth_request_p

    my $info = $store->get_auth_request($state);

Fetches a persisted auth-request hashref by its PAR-generated C<state>
value. Dies (C<_p>: rejects) with a message matching
C</no auth request found/> on a miss.

=head2 save_auth_request / save_auth_request_p

    $store->save_auth_request($info);

Persists an auth-request hashref, keyed by its own C<state>. Create-
only, matching the store contract - a C<state> value is never reused.

=head2 delete_auth_request / delete_auth_request_p

    $store->delete_auth_request($state);

Deletes a persisted auth-request row by C<state>. A no-op (not an
error) if nothing is stored under that C<state>.

=head2 get_session / get_session_p

    my $session = $store->get_session($account_did, $session_id);

Fetches a persisted session hashref by the I<pair> of C<$account_did>
and C<$session_id> - not C<$session_id> alone, since one account can
have multiple concurrent sessions (e.g. multiple browsers/devices).
Dies (C<_p>: rejects) with a message matching C</no session found/> on
a miss.

=head2 save_session / save_session_p

    $store->save_session($session_data);

Persists a session hashref, upserting by C<(account_did, session_id)> -
both an ordinary login and a scope-upgrade callback may call this on
what's already an existing row (see
L<Mojo::ATProto::OAuth/start_scope_upgrade>), and the existing row is
updated in place rather than duplicated.

=head2 delete_session / delete_session_p

    $store->delete_session($account_did, $session_id);

Deletes a persisted session row by C<(account_did, session_id)>. A
no-op (not an error) if nothing is stored under that pair.

=head1 SEE ALSO

L<Mojo::ATProto::OAuth>

=cut
