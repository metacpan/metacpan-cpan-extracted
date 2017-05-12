package Net::SSH::Any::Test::Backend::_Daemon;

use strict;
use warnings;

use Net::SSH::Any;
use Net::SSH::Any::Constants qw(SSHA_BACKEND_ERROR);

use parent 'Net::SSH::Any::Test::Backend::_Base';

sub _validate_backend_opts {
    my $tssh = shift;

    $tssh->SUPER::_validate_backend_opts or return;

    unless ($tssh->{run_server}) {
        $tssh->_log("Skipping Dropbear_Daemon backend as run_server is unset");
        return
    }

    my $opts = $tssh->{current_opts};

    $opts->{"${_}_key_path"} //= $tssh->_backend_wfile("${_}_key") for qw(user host);
    $opts->{user} //= $tssh->_os_current_user // do {
        $tssh->_log("Unable to determine current user");
        return;
    };

    $opts->{port} //= $tssh->_find_unused_tcp_port // return;

    1;
}

my $log_ix;
sub _log_fn {
    my ($tssh, $name) = @_;
    my $fn = sprintf "%d-%s.log", ++$log_ix, $name;
    $tssh->_backend_wfile($fn);
}

sub _find_unused_tcp_port {
    my $tssh = shift;
    $tssh->_log("looking for an unused TCP port");
    for (1..32) {
        my $port = 5000 + int rand 27000;
        unless (IO::Socket::INET->new(PeerAddr => "localhost:$port",
                                      Proto => 'tcp',
                                      Timeout => $tssh->{timeout})) {
            $tssh->_log("port $port is available");
            return $port;
        }
    }
    $tssh->_set_error(SSHA_BACKEND_ERROR, "Can't find free TCP port for SSH server");
    return;
}

sub _create_all_keys {
    my $tssh = shift;
    $tssh->_create_key($tssh->{current_opts}{"${_}_key_path"}) or return
        for qw(user host);
    1;
}

sub _is_localhost { 1 }

sub _check_daemon_and_set_uri {
    my $tssh = shift;
    my $opts = $tssh->{current_opts};
    my $uri = Net::SSH::Any::URI->new(host => "localhost",
                                      port => $opts->{port},
                                      user => $opts->{user},
                                      key_path => $opts->{user_key_path});

    $tssh->_log("Waiting for SSH service to pop up at", $uri->as_string );

    for (1..20) {
        if ($tssh->_is_server_running($uri)) {
            $tssh->_check_and_set_uri($uri) and return 1;
            $tssh->_or_set_error(SSHA_BACKEND_ERROR, "unable to connect to server: SSH handshake failed");
            return;
        }
        unless ($tssh->_os_check_proc($tssh->{daemon_proc})) {
            $tssh->_or_set_error(SSHA_BACKEND_ERROR, "unable to connect to server: daemon died");
            last;
        }
        $tssh->_log("Retrying in 1s [$_]...");
        sleep 1;
    }

    $tssh->_or_set_error(SSHA_BACKEND_ERROR, "unable to connect to server: too many retries");
    ()
}

sub _stop {
    my $tssh = shift;
    my $daemon = $tssh->_daemon_name;
    my $proc = $tssh->{daemon_proc};

    $tssh->_log("Stopping daemon process, pid", $proc->{pid});
    $tssh->_os_wait_proc($proc, 0, 1);
}

1;
