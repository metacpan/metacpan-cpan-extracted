package Net::SSH::Any::Backend::Dbclient_Cmd;

use strict;
use warnings;
use Carp;

use Net::SSH::Any::Util qw(_first_defined _array_or_scalar_to_list $debug _debug);
use Net::SSH::Any::Constants qw(SSHA_CONNECTION_ERROR SSHA_UNIMPLEMENTED_ERROR);

require Net::SSH::Any::Backend::_Cmd;
our @ISA = qw(Net::SSH::Any::Backend::_Cmd);

sub _validate_backend_opts {
    my ($any, %be_opts) = @_;
    $any->SUPER::_validate_backend_opts(%be_opts) or return;

    defined $be_opts{host} or croak "host argument missing";
    my ($auth_type, $interactive_login);

    $be_opts{local_dbclient_cmd} //= $any->_find_cmd(dbclient => undef,
                                                     { POSIX => 'Dropbear',
                                                       MSWin => 'Cygwin' }) // return;

    $be_opts{dbk_path} //= "$be_opts{key_path}.dbk" if defined $be_opts{key_path};

    if (defined $be_opts{password}) {
        # $auth_type = 'password';
        # $interactive_login = 1;
        # if (my @too_more = grep defined($be_opts{$_}), qw(key_path passphrase)) {
        #    croak "option(s) '".join("', '", @too_more)."' can not be used together with 'password'"
        # }
        $any->_set_error(SSHA_UNIMPLEMENTED_ERROR,
                         "password authentication is not supported by the Dbclient_Cmd backend");
        return
    }
    elsif (defined (my $dbk = $be_opts{dbk_path})) {
        $auth_type = 'publickey';
        unless (-e $dbk) {
            my $key = $be_opts{key_path} // do {
                $dbk =~ /^(.+)\.dbk$/ or do {
                    $any->_set_error(SSHA_CONNECTION_ERROR, 'cannot generate dropbear key file');
                    return;
                };
                $1;
            };
            unless (-e $key) {
                $any->_set_error(SSHA_CONNECTION_ERROR, "key file '$key' does not exists");
                return;
            }


            my $convert_cmd = $be_opts{local_dropbearconvert_cmd} //=
                $any->_find_cmd(dropbearconvert => $be_opts{local_dbclient_cmd},
                                { POSIX => 'Dropbear',
                                  MSWin => 'Cygwin' },
                                '/usr/lib/dropbear/dropbearconvert') // return;
            local $?;
            my @cmd = ($convert_cmd, 'openssh', 'dropbear', $key, $dbk);
            $debug and $debug & 1024 and _debug "generating dbk file with command '".join("', '", @cmd)."'";
            # FIXME: redirect command stderr to /dev/null
            if (do { no warnings 'exec'; system @cmd}) {
                $any->_set_error(SSHA_CONNECTION_ERROR, 'dropbearconvert failed, rc: ' . ($? >> 8));
                return
            }
            unless (-e $dbk) {
                $any->_set_error(SSHA_CONNECTION_ERROR, 'dropbearconvert failed to convert key to dropbear format');
                return
            }
        }
    }
    else {
        $auth_type = 'default';
    }

    $be_opts{dbclient_opt_y} = 1
        unless $be_opts{strict_host_key_checking};

    if (defined (my $knp = $be_opts{known_hosts_path})) {
        if (!$be_opts{strict_host_key_checking} and
            $any->_os_unix_path($knp) eq '/dev/null') {
            $be_opts{dbclient_opt_yy} = 1;
        }
        else {
            $any->_set_error(SSHA_CONNECTION_ERROR,
                             "dbclient does not support the given combination of " .
                             "strict_host_key_checking and known_hosts_path options");
            return;
        }
    }

    $any->{be_opts} = \%be_opts;
    $any->{be_auth_type} = $auth_type;
    $any->{be_interactive_login} = $interactive_login;
    1;
}

sub _make_cmd {
    my ($any, $cmd_opts, @cmd) = @_;
    my $be_opts = $any->{be_opts};

    my @args = ( $be_opts->{local_dbclient_cmd} );

    push @args, -l => $be_opts->{user} if defined $be_opts->{user};
    push @args, -p => $be_opts->{port} if defined $be_opts->{port};
    push @args, -i => $be_opts->{dbk_path} if defined $be_opts->{dbk_path};

    push @args, _array_or_scalar_to_list($be_opts->{dbclient_opts})
        if defined $be_opts->{dbclient_opts};

    push @args, '-y' if $be_opts->{dbclient_opt_y};
    push @args, '-y' if $be_opts->{dbclient_opt_yy};

    push @args, '-s' if delete $cmd_opts->{subsystem};
    push @args, $be_opts->{host};

    if ($any->{be_auth_type} eq 'password') {
        # croak "password authentication is not supported yet by the dropbear backend";
    }

    return (@args, @cmd);

}

1;
