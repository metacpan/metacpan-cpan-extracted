package
    Mojo::ATProto::OAuth::SessionStore::SQLite;
use Mojo::Base 'Mojo::ATProto::OAuth::SessionStore', -signatures;
use feature qw/try current_sub/;
use Mojo::Loader  qw/load_class/;
use Mojo::JSON    qw/encode_json decode_json/;
use Mojo::Promise qw//;
use Crypt::PRNG   qw/random_string/;
use Time::HiRes   qw/time sleep/;

# Mojo::SQLite is an optional prerequisite of this distribution (see
# dist.ini's RuntimeRecommends) - only consumers who actually load this
# class need it installed. Fail loudly and specifically here at compile
# time, rather than with Perl's own bare "Can't locate Mojo/SQLite.pm"
# once something below tries to call it.
BEGIN {
    my $e = load_class('Mojo::SQLite');
    if ($e) {
        my $reason = ref($e) ? "$e" : 'module not found in @INC';
        die "Mojo::ATProto::OAuth::SessionStore::SQLite requires the optional 'Mojo::SQLite' module, which is not installed ($reason).\n"
          . "Install it separately, e.g.: cpanm Mojo::SQLite\n";
    }
}

has 'sqlite'             => undef;
has 'lock_sessions'      => 1;
has 'lock_timeout'       => 30;
has 'lock_poll_interval' => 0.1;

sub new {
    my $self = shift->SUPER::new(sqlite => Mojo::SQLite->new(@_));
    $self->sqlite->auto_migrate(1)->migrations->name('sessionstore')->from_data;
    return $self;
}

#-- add after this line

sub get_auth_request($self, $state) {
    my $row = $self->sqlite->db->select('auth_requests', undef, {state => $state})->hash;
    die "no auth request found for state\n" unless defined $row;
    return $self->_auth_request_from_row($row);
}

sub get_auth_request_p($self, $state) {
    return $self->sqlite->db->select_p('auth_requests', undef, {state => $state})->then(sub($results) {
        my $row = $results->hash;
        die "no auth request found for state\n" unless defined $row;
        return $self->_auth_request_from_row($row);
    });
}

sub save_auth_request($self, $info) {
    $self->sqlite->db->insert('auth_requests', $self->_row_from_auth_request($info));
    return;
}

sub save_auth_request_p($self, $info) {
    return $self->sqlite->db->insert_p('auth_requests', $self->_row_from_auth_request($info))->then(sub { return });
}

sub delete_auth_request($self, $state) {
    $self->sqlite->db->delete('auth_requests', {state => $state});
    return;
}

sub delete_auth_request_p($self, $state) {
    return $self->sqlite->db->delete_p('auth_requests', {state => $state})->then(sub { return });
}

sub get_session($self, $account_did, $session_id) {
    my $row = $self->sqlite->db->select('sessions', undef, {account_did => $account_did, session_id => $session_id})->hash;
    die "no session found for did/session_id\n" unless defined $row;
    return $self->_session_from_row($row);
}

sub get_session_p($self, $account_did, $session_id) {
    return $self->sqlite->db->select_p('sessions', undef, {account_did => $account_did, session_id => $session_id})->then(sub($results) {
        my $row = $results->hash;
        die "no session found for did/session_id\n" unless defined $row;
        return $self->_session_from_row($row);
    });
}

# save_session must be an upsert keyed on (account_did, session_id) - both
# an ordinary login and a scope-upgrade callback may call this on what's
# already an existing row. SQLite's ON CONFLICT DO UPDATE (3.24.0+) handles
# this in one statement.
sub save_session($self, $session_data) {
    my ($row, $update) = $self->_session_upsert_args($session_data);
    $self->sqlite->db->insert('sessions', $row, {on_conflict => [['account_did', 'session_id'] => $update]});
    return;
}

sub save_session_p($self, $session_data) {
    my ($row, $update) = $self->_session_upsert_args($session_data);
    return $self->sqlite->db->insert_p('sessions', $row, {on_conflict => [['account_did', 'session_id'] => $update]})->then(sub { return });
}

sub delete_session($self, $account_did, $session_id) {
    $self->sqlite->db->delete('sessions', {account_did => $account_did, session_id => $session_id});
    return;
}

sub delete_session_p($self, $account_did, $session_id) {
    return $self->sqlite->db->delete_p('sessions', {account_did => $account_did, session_id => $session_id})->then(sub { return });
}

# Updates only the given fields of an existing session - a caller that
# only learned a new DPoP nonce must not write back the tokens it read
# earlier, which another process may have rotated since.
sub update_session($self, $account_did, $session_id, $fields) {
    my $set = $self->_validated_session_update($fields);
    my $rows = $self->sqlite->db->update('sessions', $set, {account_did => $account_did, session_id => $session_id})->sth->rows;
    die "no session found for did/session_id\n" unless $rows > 0;
    return;
}

sub update_session_p($self, $account_did, $session_id, $fields) {
    my $set = $self->_validated_session_update($fields);
    return $self->sqlite->db->update_p('sessions', $set, {account_did => $account_did, session_id => $session_id})->then(sub($results) {
        die "no session found for did/session_id\n" unless $results->sth->rows > 0;
        return;
    });
}

# Serializes $code per (account_did, session_id) across every process
# sharing this database file, via a lease row in session_locks rather
# than a SQLite transaction: BEGIN IMMEDIATE would hold the database-wide
# write lock for as long as $code runs (an auth-server round trip), and
# $code's own writes go through a different pooled connection, which
# that lock would block - deadlocking the caller against itself. A lease
# left behind by a crashed holder expires after lock_timeout seconds.
# With lock_sessions off, $code just gets a fresh read with no locking.
sub lock_session($self, $account_did, $session_id, $code) {
    return $code->($self->get_session($account_did, $session_id)) unless $self->lock_sessions;

    my $owner    = $self->_lock_owner;
    my $deadline = time + $self->lock_timeout;
    until ($self->_try_lock($account_did, $session_id, $owner)) {
        die "lock_session: timed out waiting for session lock\n" if time >= $deadline;
        sleep($self->lock_poll_interval);
    }

    my $result;
    try {
        $result = $code->($self->get_session($account_did, $session_id));
    } catch($ex) {
        $self->_unlock($account_did, $session_id, $owner);
        die $ex;
    }
    $self->_unlock($account_did, $session_id, $owner);
    return $result;
}

# Waits for the lease with timers rather than sleep, so other work on
# the event loop (including whoever holds the lease in this process)
# keeps running. _try_lock/_unlock stay synchronous: Mojo::SQLite's own
# _p methods are blocking underneath anyway.
sub lock_session_p($self, $account_did, $session_id, $code) {
    return $self->get_session_p($account_did, $session_id)->then($code) unless $self->lock_sessions;

    my $owner    = $self->_lock_owner;
    my $deadline = time + $self->lock_timeout;
    my $acquire  = sub {
        return Mojo::Promise->resolve if $self->_try_lock($account_did, $session_id, $owner);
        return Mojo::Promise->reject("lock_session_p: timed out waiting for session lock\n") if time >= $deadline;
        return Mojo::Promise->timer($self->lock_poll_interval)->then(__SUB__);
    };

    return $acquire->()
        ->then(sub { return $self->get_session_p($account_did, $session_id) })
        ->then($code)
        ->finally(sub { $self->_unlock($account_did, $session_id, $owner) });
}

# Takes the lease if it's free or expired; a lease still held by someone
# else is left alone by the upsert's WHERE clause. Reading the owner back
# afterwards is what decides whether this caller got it.
sub _try_lock($self, $account_did, $session_id, $owner) {
    my $now = time;
    my $db  = $self->sqlite->db;
    $db->query(
        'INSERT INTO session_locks (account_did, session_id, owner, expires_at) VALUES (?, ?, ?, ?) '
            . 'ON CONFLICT (account_did, session_id) DO UPDATE SET owner = excluded.owner, expires_at = excluded.expires_at '
            . 'WHERE session_locks.expires_at < ?',
        $account_did, $session_id, $owner, $now + $self->lock_timeout, $now,
    );
    my $holder = $db->select('session_locks', ['owner'], {account_did => $account_did, session_id => $session_id})->array;
    return defined($holder) && $holder->[0] eq $owner;
}

# Deletes only this caller's own lease, so a holder whose lease expired
# and was taken over can't release the new holder's lock.
sub _unlock($self, $account_did, $session_id, $owner) {
    $self->sqlite->db->delete('session_locks', {account_did => $account_did, session_id => $session_id, owner => $owner});
    return;
}

sub _lock_owner($self) {
    return $$ . '-' . random_string(16);
}

sub _session_upsert_args($self, $session_data) {
    my $row    = $self->_row_from_session($session_data);
    my $update = {%$row};
    delete @{$update}{qw/account_did session_id/};
    return ($row, $update);
}

sub _row_from_auth_request($self, $info) {
    return {
        state                            => $info->{state},
        account_did                      => $info->{account_did},
        handle                           => $info->{handle},
        host_url                         => $info->{host_url},
        auth_server_url                  => $info->{auth_server_url},
        auth_server_token_endpoint       => $info->{auth_server_token_endpoint},
        auth_server_revocation_endpoint  => $info->{auth_server_revocation_endpoint},
        scopes                           => $self->_encode_scopes($info->{scopes}),
        request_uri                      => $info->{request_uri},
        pkce_verifier                    => $info->{pkce_verifier},
        dpop_authserver_nonce            => $info->{dpop_authserver_nonce},
        dpop_private_key_pem             => $info->{dpop_private_key_pem},
        upgrade_session_id               => $info->{upgrade_session_id},
        client_state                     => $self->_encode_json($info->{client_state}),
        extra                            => $self->_encode_json($info->{extra}),
    };
}

sub _auth_request_from_row($self, $row) {
    return {
        state                            => $row->{state},
        account_did                      => $row->{account_did},
        handle                           => $row->{handle},
        host_url                         => $row->{host_url},
        auth_server_url                  => $row->{auth_server_url},
        auth_server_token_endpoint       => $row->{auth_server_token_endpoint},
        auth_server_revocation_endpoint  => $row->{auth_server_revocation_endpoint},
        scopes                           => $self->_decode_scopes($row->{scopes}),
        request_uri                      => $row->{request_uri},
        pkce_verifier                    => $row->{pkce_verifier},
        dpop_authserver_nonce            => $row->{dpop_authserver_nonce},
        dpop_private_key_pem             => $row->{dpop_private_key_pem},
        upgrade_session_id               => $row->{upgrade_session_id},
        client_state                     => $self->_decode_json($row->{client_state}),
        extra                            => $self->_decode_json($row->{extra}),
    };
}

# client_state/extra deliberately omitted - Mojo::ATProto::OAuth never
# reads them back off a persisted session, only off an auth request (see
# oauth-store-interface memory).
sub _row_from_session($self, $session_data) {
    return {
        account_did                      => $session_data->{account_did},
        session_id                       => $session_data->{session_id},
        handle                           => $session_data->{handle},
        host_url                         => $session_data->{host_url},
        auth_server_url                  => $session_data->{auth_server_url},
        auth_server_token_endpoint       => $session_data->{auth_server_token_endpoint},
        auth_server_revocation_endpoint  => $session_data->{auth_server_revocation_endpoint},
        scopes                           => $self->_encode_scopes($session_data->{scopes}),
        access_token                     => $session_data->{access_token},
        refresh_token                    => $session_data->{refresh_token},
        dpop_authserver_nonce            => $session_data->{dpop_authserver_nonce},
        dpop_host_nonce                  => $session_data->{dpop_host_nonce},
        dpop_private_key_pem             => $session_data->{dpop_private_key_pem},
    };
}

sub _session_from_row($self, $row) {
    return {
        account_did                      => $row->{account_did},
        session_id                       => $row->{session_id},
        handle                           => $row->{handle},
        host_url                         => $row->{host_url},
        auth_server_url                  => $row->{auth_server_url},
        auth_server_token_endpoint       => $row->{auth_server_token_endpoint},
        auth_server_revocation_endpoint  => $row->{auth_server_revocation_endpoint},
        scopes                           => $self->_decode_scopes($row->{scopes}),
        access_token                     => $row->{access_token},
        refresh_token                    => $row->{refresh_token},
        dpop_authserver_nonce            => $row->{dpop_authserver_nonce},
        dpop_host_nonce                  => $row->{dpop_host_nonce},
        dpop_private_key_pem             => $row->{dpop_private_key_pem},
    };
}

sub _encode_scopes($self, $scopes) {
    return join(' ', @{$scopes // []});
}

sub _decode_scopes($self, $text) {
    return [split(/ /, $text // '')];
}

# Stores real SQL NULL (not the JSON text 'null') when $value is undef,
# so it doesn't round-trip as the string 'null' on the way back out.
sub _encode_json($self, $value) {
    return defined($value) ? encode_json($value) : undef;
}

sub _decode_json($self, $text) {
    return defined($text) ? decode_json($text) : undef;
}

1;

=head1 NAME

Mojo::ATProto::OAuth::SessionStore::SQLite - SQLite-backed session store for Mojo::ATProto::OAuth

=head1 SYNOPSIS

    my $oauth = Mojo::ATProto::OAuth->new(..., store => [SQLite => 'file:/var/lib/myapp/oauth.db']);

    # opt out of cross-process session locking (read the caveats below first)
    $oauth->store->lock_sessions(0);

=head1 DESCRIPTION

Implements the full store interface described in L<Mojo::ATProto::OAuth/THE STORE INTERFACE> on top of L<Mojo::SQLite>. Constructor arguments are passed straight to C<< Mojo::SQLite->new >>; the schema is created and migrated automatically.

=head2 Session locking

C<lock_session>/C<lock_session_p> (which L<Mojo::ATProto::OAuth/refresh_tokens> runs under) take a lease: a row in the C<session_locks> table naming the holder and an expiry time. A caller that finds a live lease held by someone else polls every L</lock_poll_interval> seconds until it's released, giving up with C<lock_session: timed out waiting for session lock> after L</lock_timeout> seconds. The async form waits on timers, so the event loop keeps running while it waits. A lease left behind by a crashed process expires after L</lock_timeout> seconds and is then taken over.

No SQLite transaction or database lock is held while the lease is held, so the lock never blocks any other reads or writes to the database - only other C<lock_session> callers for the same session.

Caveats of leaving it on (the default):

=over 4

=item * A caller waiting for the lock waits in steps of L</lock_poll_interval>, so a concurrent refresh finishes up to that much later than it otherwise would. Each poll is a small write to the database.

=item * L</lock_timeout> doubles as the lease length. It must be longer than a refresh can take - the default of 30 seconds covers L<Mojo::ATProto::OAuth>'s default 10-second request timeout with its one DPoP-nonce retry. If you raise the user agent's timeout, raise this too; otherwise a slow refresh can outlive its lease and a second caller can refresh concurrently.

=item * The synchronous C<lock_session> blocks (sleeps) while it waits. Within one process, a synchronous call waiting on a lease held by a still-pending C<lock_session_p> for the same session can't make progress, and times out.

=back

Setting L</lock_sessions> to false skips all of this: the code just gets a fresh read of the session, with no lock. B<Only do this if no session is ever used by more than one process, or by more than one in-flight C<_p> call, at a time.> Otherwise two callers can present the same refresh token; the auth server rejects the second with C<invalid_grant>, and an ATProto auth server may revoke the whole session in response. L<Mojo::ATProto::OAuth/refresh_tokens> recovers from that C<invalid_grant> only if the other caller's refresh has already been saved by the time it re-reads the session.

=head1 ATTRIBUTES

=head2 sqlite

The underlying L<Mojo::SQLite> instance.

=head2 lock_sessions

Whether C<lock_session>/C<lock_session_p> actually lock. Defaults to C<1>. See L</Session locking> before turning this off.

=head2 lock_timeout

Seconds to wait for a session lock before giving up, and the length of the lease once taken. Defaults to C<30>.

=head2 lock_poll_interval

Seconds between attempts to take a session lock held by someone else. Defaults to C<0.1>.

=head1 SEE ALSO

L<Mojo::ATProto::OAuth>, L<Mojo::ATProto::OAuth::SessionStore::Pg>

=cut

__DATA__
@@ sessionstore

-- 1 up
CREATE TABLE auth_requests (
    state                            TEXT PRIMARY KEY,
    account_did                      TEXT,
    handle                           TEXT,
    host_url                         TEXT,
    auth_server_url                  TEXT NOT NULL,
    auth_server_token_endpoint       TEXT NOT NULL,
    auth_server_revocation_endpoint  TEXT,
    scopes                           TEXT NOT NULL,
    request_uri                      TEXT NOT NULL,
    pkce_verifier                    TEXT NOT NULL,
    dpop_authserver_nonce            TEXT,
    dpop_private_key_pem             TEXT NOT NULL,
    upgrade_session_id               TEXT,
    client_state                     TEXT,
    extra                            TEXT
);

CREATE TABLE sessions (
    account_did                      TEXT NOT NULL,
    session_id                       TEXT NOT NULL,
    handle                           TEXT,
    host_url                         TEXT,
    auth_server_url                  TEXT NOT NULL,
    auth_server_token_endpoint       TEXT NOT NULL,
    auth_server_revocation_endpoint  TEXT,
    scopes                           TEXT NOT NULL,
    access_token                     TEXT NOT NULL,
    refresh_token                    TEXT,
    dpop_authserver_nonce            TEXT,
    dpop_host_nonce                  TEXT,
    dpop_private_key_pem             TEXT NOT NULL,
    PRIMARY KEY (account_did, session_id)
);

-- 1 down
DROP TABLE sessions;
DROP TABLE auth_requests;

-- 2 up
CREATE TABLE session_locks (
    account_did                      TEXT NOT NULL,
    session_id                       TEXT NOT NULL,
    owner                            TEXT NOT NULL,
    expires_at                       REAL NOT NULL,
    PRIMARY KEY (account_did, session_id)
);

-- 2 down
DROP TABLE session_locks;
