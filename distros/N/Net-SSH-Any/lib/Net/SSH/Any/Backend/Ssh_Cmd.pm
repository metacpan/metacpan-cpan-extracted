package Net::SSH::Any::Backend::Ssh_Cmd;

use strict;
use warnings;
use Carp;
use Net::SSH::Any::Util qw(_first_defined _array_or_scalar_to_list $debug _debug);
use Net::SSH::Any::Constants qw(SSHA_CHANNEL_ERROR SSHA_REMOTE_CMD_ERROR SSHA_CONNECTION_ERROR);
use parent 'Net::SSH::Any::Backend::_Cmd';

sub _validate_backend_opts {
    my ($any, %be_opts) = @_;
    $any->SUPER::_validate_backend_opts(%be_opts) or return;

    $be_opts{local_ssh_cmd} //= $any->_find_cmd('ssh',
                                                undef,
                                                { MSWin => 'Cygwin', POSIX => 'OpenSSH' },
                                                '/usr/bin/ssh') // return;
    my $out = $any->_local_capture($be_opts{local_ssh_cmd}, '-V');
    if ($?) {
        $out =~ s/\s+/ /gs; $out =~ s/ $//;
        $any->_set_error(SSHA_CONNECTION_ERROR, 'ssh not found or bad version, rc: '.($? >> 8)." output: $out");
        return;
    }

    my ($auth_type, $interactive_login);

    if (defined $be_opts{password}) {
        $auth_type = 'password';
        $interactive_login = 1;
        if (my @too_more = grep defined($be_opts{$_}), qw(key_path passphrase)) {
            croak "option(s) '".join("', '", @too_more)."' can not be used together with 'password'"
        }
    }
    elsif (defined $be_opts{key_path}) {
        $auth_type = 'publickey';
        if (defined $be_opts{passphrase}) {
            $auth_type .= ' with passphrase';
            $interactive_login = 1;
        }
    }
    else {
        $auth_type = 'default';
    }

    $any->{be_opts} = \%be_opts;
    $any->{be_auth_type} = $auth_type;
    $any->{be_interactive_login} = $interactive_login;
    1;
}

sub _make_cmd {
    my ($any, $cmd_opts, $cmd) = @_;
    my $be_opts = $any->{be_opts};

    my @args = ( $be_opts->{local_ssh_cmd},
                 $be_opts->{host} );
    push @args, '-C';
    push @args, -l => $be_opts->{user} if defined $be_opts->{user};
    push @args, -p => $be_opts->{port} if defined $be_opts->{port};
    push @args, -i => $any->_os_unix_path($be_opts->{key_path}) if defined $be_opts->{key_path};
    push @args, -o => 'BatchMode=yes' unless grep defined($be_opts->{$_}), qw(password passphrase);
    push @args, -o => 'StrictHostKeyChecking=no' unless $be_opts->{strict_host_key_checking};
    push @args, -o => 'UserKnownHostsFile=' . $any->_os_unix_path($be_opts->{known_hosts_path})
        if defined $be_opts->{known_hosts_path};

    if ($any->{be_auth_type} eq 'password') {
        push @args, ( -o => 'PreferredAuthentications=keyboard-interactive,password',
                      -o => 'NumberOfPasswordPrompts=1' );
    }
    else {
        push @args, -o => 'PreferredAuthentications=publickey';
    }

    push @args, '-s' if delete $cmd_opts->{subsystem};

    push @args, _array_or_scalar_to_list($be_opts->{ssh_opts})
        if defined $be_opts->{ssh_opts};

    return (@args, '--', $cmd);
}

sub _remap_child_error {
    my ($any, $proc) = @_;
    my $rc = $proc->{rc} // 0;
    if ($rc == (255 << 8)) {
        # A remote command may actually exit with code 255, but it
        # is quite uncommon.
        # SSHA_CONNECTION_ERROR is not recoverable so we use
        # SSHA_CHANNEL_ERROR instead.
	$debug and $debug & 1024 and _debug "child error remaped to channel error";
        $any->_or_set_error(SSHA_CHANNEL_ERROR, "child command exited with code 255, ssh was probably unable to connect to the remote server");
        return
    }
    1;
}

1;
