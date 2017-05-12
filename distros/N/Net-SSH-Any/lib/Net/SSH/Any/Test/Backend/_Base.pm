package Net::SSH::Any::Test::Backend::_Base;

use strict;
use warnings;

use Net::SSH::Any;
use Net::SSH::Any::Constants qw(SSHA_BACKEND_ERROR SSHA_REMOTE_CMD_ERROR);

our @CARP_NOT = qw(Net::SSH::Any::Test);

sub _validate_backend_opts { 1 }

sub _stop { 1 }

my $dev_null = File::Spec->devnull;
sub _dev_null { $dev_null }

sub _new_ssh_client {
    my ($tssh, $uri) = @_;
    $tssh->_log("Trying to connect to server at ".$uri->uri);
    my $ssh = Net::SSH::Any->new($uri,
                                 batch_mode => 1,
                                 timeout => $tssh->{timeout},
                                 backends => $tssh->{any_backends},
                                 strict_host_key_checking => 0,
                                 known_hosts_path => $tssh->_dev_null);
    if ($ssh->error) {
        $tssh->_log("Unable to establish SSH connection", $ssh->error, uri => $uri->as_string);
        return;
    }
    $ssh
}

sub _check_and_set_uri {
    my ($tssh, $uri) = @_;
    $uri //= $tssh->uri // return;
    $tssh->_log("Checking URI ".$uri->uri);
    my $ssh;
    for my $cmd (@{$tssh->{test_commands}}) {
        $ssh //= $tssh->_new_ssh_client($uri) // return;
        my ($out, $err) = $ssh->capture2($cmd);
        if (my $error = $ssh->error) {
            $tssh->_log("Running command '$cmd' failed, rc: $?, error: $error");
            undef $ssh unless $error == SSHA_REMOTE_CMD_ERROR;
        }
        else {
            if (length $out) {
                $out =~ s/\n?$/\n/; $out =~ s/^/out: /mg;
            }
            if (length $err) {
                $err =~ s/\n?$/\n/; $err =~ s/^/err: /mg;
            }
            $tssh->_log("Running command '$cmd', rc: $?\n$out$err");

            $tssh->{good_uri} = $uri;

            return 1;
        }
    }
}

sub _cmd_to_name {
    my ($tssh, $cmd) = @_;
    $cmd =~ s{.*[/\\]}{};
    $cmd =~ s{\.exe$}{};
    $cmd;
}

sub _run_cmd {
    my ($tssh, $opts, $cmd, @args) = @_;
    my $name = $opts->{out_name} // $tssh->_cmd_to_name($cmd);
    my $out_fn = $opts->{stdout_file} // $tssh->_log_fn($name);
    my $resolved_cmd = ($opts->{find} // 1
                        ? $tssh->_be_find_cmd($cmd)
                        : $cmd) // return;

    $tssh->_log("Running cmd: $resolved_cmd @args");

    if (open my ($out_fh), '>>', $out_fn and
        open my ($in_fh), '<', $tssh->_dev_null) {
        if (my $proc = $tssh->_os_open4([$in_fh, $out_fh], [], undef, 1,
                                        $resolved_cmd => @args)) {
            $opts->{async} and return $proc;
            $tssh->_log("Waiting for process $proc->{pid} to finish");
            $tssh->_os_wait_proc($proc, $opts->{timeout}, $opts->{force_kill}) and return 1;
        }
        $tssh->_set_error(SSHA_BACKEND_ERROR, "Can't execute command $cmd: $!");
    }
    ()
}

# _be_find_cmd first checks if the user has given us the exact command
# location as a backend argument:

sub _be_find_cmd {
    my $tssh = shift;
    my $opts = $tssh->{current_opts};

    # if we have the opts argument, name is at $_[1], otherwise it is
    # at $_[0]:
    my $safe_name = (ref $_[0] ? $_[1] : $_[0]);
    $safe_name =~ s/\W/_/g;

    $opts->{"local_${safe_name}_cmd"} //=
        $tssh->_find_cmd(@_);
}

sub _is_localhost { 0 }

1;
