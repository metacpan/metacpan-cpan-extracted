package 
    Mojo::ATProto::OAuth::SessionStore;
use Mojo::Base -base, -signatures;

use constant UPDATABLE_SESSION_FIELDS => {map { $_ => 1 } qw/access_token refresh_token dpop_authserver_nonce dpop_host_nonce/};

sub get_auth_request {
    die 'You must implement get_auth_request' . "\n";
}

sub get_auth_request_p {
    die 'You must implement get_auth_request_p' . "\n";
}

sub save_auth_request {
    die 'You must implement save_auth_request' . "\n";
}

sub save_auth_request_p {
    die 'You must implement save_auth_request_p' . "\n";
}

sub delete_auth_request_p {
    die 'You must implement delete_auth_request_p' . "\n";
}

sub delete_auth_request {
    die 'You must implement delete_auth_request' . "\n";
}

sub get_session {
    die 'You must implement get_session' . "\n";
}

sub get_session_p {
    die 'You must implement get_session_p' . "\n";
}

sub save_session {
    die 'You must implement save_session' . "\n";
}

sub save_session_p {
    die 'You must implement save_session_p' . "\n";
}

sub delete_session {
    die 'You must implement delete_session' . "\n";
}

sub delete_session_p {
    die 'You must implement delete_session_p' . "\n";
}

sub update_session {
    die 'You must implement update_session' . "\n";
}

sub update_session_p {
    die 'You must implement update_session_p' . "\n";
}

sub lock_session {
    die 'You must implement lock_session' . "\n";
}

sub lock_session_p {
    die 'You must implement lock_session_p' . "\n";
}

# Validates an update_session(_p) field hashref against the fields that
# may change over a session's lifetime (tokens and DPoP nonces - never
# identity, endpoints, scopes or the DPoP key), and returns a shallow
# copy safe to hand to the backend. Dies on an empty hashref or any
# other key, so a caller can't widen a partial update back into the
# whole-row overwrite update_session exists to avoid.
sub _validated_session_update($self, $fields) {
    die 'update_session: fields must be a non-empty hashref' . "\n" unless ref($fields) eq 'HASH' && %$fields;
    for my $field (sort keys %$fields) {
        die 'update_session: field \'' . $field . '\' cannot be updated' . "\n" unless UPDATABLE_SESSION_FIELDS->{$field};
    }
    return {%$fields};
}

1;

