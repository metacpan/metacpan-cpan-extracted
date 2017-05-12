package Net::SSH::Any::Test::Backend::OpenSSH_Daemon;

use strict;
use warnings;

use Net::SSH::Any;
use Net::SSH::Any::Constants qw(SSHA_BACKEND_ERROR);

use parent 'Net::SSH::Any::Test::Backend::_Daemon';

sub _validate_backend_opts {
    my $tssh = shift;
    $tssh->SUPER::_validate_backend_opts or return;

    my $opts = $tssh->{current_opts};
    $opts->{sshd_config_file} //= $tssh->_backend_wfile('sshd_config');

    # ssh and sshd are resolved here so that they can be used as
    # friends by any other commands
    $tssh->_be_find_cmd({relaxed => 1}, 'ssh');
    $tssh->_be_find_cmd('sshd') // return;
    1;
}

sub _create_key {
    my ($tssh, $path) = @_;
    my $path_pub = "$path.pub";
    -f $path and -f $path_pub and return 1;
     my $tmppath = join('.', $path, $$, int(rand(9999999)));
    if ($tssh->_run_cmd({}, 'ssh-keygen', -t => 'rsa', -b => 1024, -f => $tmppath, -P => '')) {
        unlink $path;
        unlink $path_pub;
        if (rename $tmppath, $path and
            rename "$tmppath.pub", $path_pub) {
            $tssh->_log("key generated $path");
            return 1;
        }
    }
    $tssh->_set_error(SSHA_BACKEND_ERROR, "key generation failed");
    return;
}

sub _be_find_cmd {
    my $tssh = shift;
    my $find_opts = (ref($_[0]) ? shift : {});
    my ($name, $friend, $app, $default) = @_;
    my $opts = $tssh->{current_opts};
    $tssh->SUPER::_be_find_cmd($find_opts,
                               $name,
                               $friend // $opts->{local_ssh_cmd},
                               $app    // { POSIX => 'OpenSSH', MSWin => 'Cygwin' },
                               $default);
}

sub _user_key_path_quoted {
    my $tssh = shift;
    my $key = $tssh->_os_unix_path($tssh->{current_opts}{user_key_path});
    $tssh->_log("user_key_path: $tssh->{current_opts}{user_key_path}, unix path: $key");
    $key =~ s/%/%%/g;
    $key;
}

sub _escape_config {
    my ($tssh, $v) = @_;
    $v =~ s/([\\\s])/\\$1/g;
    return $v;
}

sub _write_config {
    my $tssh = shift;
    my $fn = $tssh->{current_opts}{sshd_config_file};
    -f $fn and return 1;
    if (open my $fn, '>', $fn) {
        while (@_) {
            my $k = $tssh->_escape_config(shift);
            my $v = $tssh->_escape_config(shift);
            print $fn "$k=$v\n";
        }
        close $fn and return 1
    }
    $tssh->_set_error(SSHA_BACKEND_ERROR, "unable to create sshd configuration file at '$fn': $!");
    ()
}

sub _override_config {
    my $tssh = shift;
    my %override = %{ $tssh->{current_opts}{override_config} // {} };
    my @cfg;
    while (@_) {
        my $k = shift;
        my $v = shift;
        if (exists $override{$k}) {
            $v = delete $override{$k};
            next unless defined $v;
        }
        push @cfg, $k, $v;
    }
    (@cfg, %override);
}

sub _start_and_check {
    my $tssh = shift;

    $tssh->_create_all_keys or return;

    my $opts = $tssh->{current_opts};
    my $port = $opts->{port};
    my $sftp_server = $tssh->_be_find_cmd({relaxed => 1}, 'sftp-server');

    my $user = $opts->{user};
    $user =~ s/\s/?/g;

    my @cfg = $tssh->_override_config( HostKey            => $tssh->_os_unix_path($opts->{host_key_path}),
                                       AuthorizedKeysFile => $tssh->_user_key_path_quoted . ".pub",
                                       AllowUsers         => $user, # only user running the script can log in
                                       AllowTcpForwarding => 'yes',
                                       GatewayPorts       => 'no', # bind port forwarder listener to localhost only
                                       ChallengeResponseAuthentication => 'no',
                                       PasswordAuthentication => 'no',
                                       Port               => $port,
                                       ListenAddress      => "localhost:$port",
                                       LogLevel           => 'INFO',
                                       PermitRootLogin    => 'yes',
                                       PidFile            => $tssh->_os_unix_path($tssh->_backend_wfile('sshd.pid')),
                                       PrintLastLog       => 'no',
                                       PrintMotd          => 'no',
                                       UseDNS             => 'no',
                                       StrictModes        => 'no',
                                       UsePrivilegeSeparation => 'no',
                                       Subsystem          => "sftp $sftp_server" );
    $tssh->_write_config(@cfg) or return;

    $tssh->_log("Starting sshd at localhost:$port");

    my @cmd;
    my @sshd_args = ( '-D', # no daemon
                      '-e', # send output to STDEE
                      '-f', $tssh->_os_unix_path($opts->{sshd_config_file}) );

    if ($^O eq 'MSWin32') {
        my $sshd_cmd = $tssh->_os_unix_path($tssh->_be_find_cmd('sshd'));
        my $bash_subcmd = $tssh->_quote_args({shell => 'MSCmd'}, exec => $sshd_cmd, @sshd_args) //
            return;
        @cmd = ('bash', '--login', '-c', $bash_subcmd);
    }
    else {
        @cmd = ('sshd', @sshd_args)
    }

    $tssh->{daemon_proc} = $tssh->_run_cmd({out_name => 'sshd',
                                            async => 1 },
                                           @cmd) or return;

    $tssh->_check_daemon_and_set_uri and return 1;
    $tssh->_stop;
    ()
}

sub _daemon_name { 'sshd' }

1;
