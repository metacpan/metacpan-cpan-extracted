package
    Mojo::ATProto::OAuth::SessionStore::Pg;
use Mojo::Base 'Mojo::ATProto::OAuth::SessionStore', -signatures;
use feature 'try';
use Mojo::Loader qw/load_class/;
use Mojo::JSON    qw/encode_json decode_json/;

# Mojo::Pg is an optional prerequisite of this distribution (see
# dist.ini's RuntimeRecommends) - only consumers who actually load this
# class need it installed. Fail loudly and specifically here at compile
# time, rather than with Perl's own bare "Can't locate Mojo/Pg.pm" once
# something below tries to call it.
BEGIN {
    my $e = load_class('Mojo::Pg');
    if ($e) {
        my $reason = ref($e) ? "$e" : 'module not found in @INC';
        die "Mojo::ATProto::OAuth::SessionStore::Pg requires the optional 'Mojo::Pg' module, which is not installed ($reason).\n"
          . "Install it separately, e.g.: cpanm Mojo::Pg\n";
    }
}

has 'pg' => undef;

sub new {
    my $self = shift->SUPER::new(pg => Mojo::Pg->new(@_));
    $self->pg->auto_migrate(1)->migrations->name('sessionstore')->from_data;
    return $self;
}

#-- add after this line

sub get_auth_request($self, $state) {
    my $row = $self->pg->db->select('auth_requests', undef, {state => $state})->expand->hash;
    die "no auth request found for state\n" unless defined $row;
    return $self->_auth_request_from_row($row);
}

sub get_auth_request_p($self, $state) {
    return $self->pg->db->select_p('auth_requests', undef, {state => $state})->then(sub($results) {
        my $row = $results->expand->hash;
        die "no auth request found for state\n" unless defined $row;
        return $self->_auth_request_from_row($row);
    });
}

sub save_auth_request($self, $info) {
    $self->pg->db->insert('auth_requests', $self->_row_from_auth_request($info));
    return;
}

sub save_auth_request_p($self, $info) {
    return $self->pg->db->insert_p('auth_requests', $self->_row_from_auth_request($info))->then(sub { return });
}

sub delete_auth_request($self, $state) {
    $self->pg->db->delete('auth_requests', {state => $state});
    return;
}

sub delete_auth_request_p($self, $state) {
    return $self->pg->db->delete_p('auth_requests', {state => $state})->then(sub { return });
}

sub get_session($self, $account_did, $session_id) {
    my $row = $self->pg->db->select('sessions', undef, {account_did => $account_did, session_id => $session_id})->hash;
    die "no session found for did/session_id\n" unless defined $row;
    return $self->_session_from_row($row);
}

sub get_session_p($self, $account_did, $session_id) {
    return $self->pg->db->select_p('sessions', undef, {account_did => $account_did, session_id => $session_id})->then(sub($results) {
        my $row = $results->hash;
        die "no session found for did/session_id\n" unless defined $row;
        return $self->_session_from_row($row);
    });
}

# save_session must be an upsert keyed on (account_did, session_id) - both
# an ordinary login and a scope-upgrade callback may call this on what's
# already an existing row. Postgres's native ON CONFLICT DO UPDATE handles
# this in one statement.
sub save_session($self, $session_data) {
    my ($row, $update) = $self->_session_upsert_args($session_data);
    $self->pg->db->insert('sessions', $row, {on_conflict => [['account_did', 'session_id'] => $update]});
    return;
}

sub save_session_p($self, $session_data) {
    my ($row, $update) = $self->_session_upsert_args($session_data);
    return $self->pg->db->insert_p('sessions', $row, {on_conflict => [['account_did', 'session_id'] => $update]})->then(sub { return });
}

sub delete_session($self, $account_did, $session_id) {
    $self->pg->db->delete('sessions', {account_did => $account_did, session_id => $session_id});
    return;
}

sub delete_session_p($self, $account_did, $session_id) {
    return $self->pg->db->delete_p('sessions', {account_did => $account_did, session_id => $session_id})->then(sub { return });
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

# client_state/extra come back already-decoded to Perl values by
# ->expand (called on the results object in get_auth_request(_p) above) -
# a JSONB column decodes to undef on its own when the stored value is
# SQL NULL, so no manual decode step is needed here.
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
        client_state                     => $row->{client_state},
        extra                            => $row->{extra},
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

# Wraps a defined value for Mojo::Pg's -json bind-type handling, so it's
# stored as real JSONB rather than a plain TEXT column. undef stays plain
# undef (real SQL NULL), not JSON's 'null' text.
sub _encode_json($self, $value) {
    return defined($value) ? {-json => $value} : undef;
}

1;
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
    client_state                     JSONB,
    extra                            JSONB
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
