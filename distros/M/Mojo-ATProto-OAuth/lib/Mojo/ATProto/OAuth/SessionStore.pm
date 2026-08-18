package 
    Mojo::ATProto::OAuth::SessionStore;
use Mojo::Base -base, -signatures;

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

1;

