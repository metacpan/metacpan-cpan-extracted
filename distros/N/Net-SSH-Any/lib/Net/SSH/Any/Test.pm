package Net::SSH::Any::Test;

use strict;
use warnings;

use Carp;
use Time::HiRes ();
use IO::Socket::INET ();
use File::Temp ();
use Net::SSH::Any::Util qw(_array_or_scalar_to_list);
use Net::SSH::Any::URI;
use Net::SSH::Any::_Base;
use Net::SSH::Any::Constants qw(SSHA_NO_BACKEND_ERROR SSHA_REMOTE_CMD_ERROR SSHA_LOCAL_IO_ERROR SSHA_BACKEND_ERROR);

our @ISA = qw(Net::SSH::Any::_Base);

my @default_backends = qw(Remote OpenSSH_Daemon Dropbear_Daemon);

my @default_test_commands = ('true', 'exit', 'echo foo', 'date',
                             'cmd /c ver', 'cmd /c echo foo');

sub new {
    my ($class, %opts) = @_;
    return $class->_new(\%opts);
}

sub _log_at_level {
    local ($@, $!, $?, $^E);
    my $tssh = shift;
    my $level = shift;
    my ($pkg, undef, $line) = caller $level;
    my $time = sprintf "%.4f", Time::HiRes::time - $^T;
    my $text = join(': ', map { defined($_) ? $_ : '<undef>' } @_);
    # my $prefix = "$time $pkg $line|";
    my $prefix = sprintf "%s %s|", $time, $tssh->{backend} // 'Test';
    $text =~ s/\n$//;
    my $n;
    $text =~ s/^/$prefix.($n++?'\\':'-')/emg;
    $text .= "\n";
    print {$tssh->{logger_2_fh}} $text if defined $tssh->{logger_2_fh};
    eval { $tssh->{logger}->($tssh->{logger_fh}, $text) }
}

sub _log { shift->_log_at_level(1, @_) }

sub _log_dump {
    my $tssh = shift;
    my $head = shift;
    require Data::Dumper;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 0;
    $tssh->_log_at_level(1, $head, Data::Dumper::Dumper(@_));
}

sub _log_error_and_reset_backend {
    my $tssh = shift;
    $tssh->_log_at_level(1, "Saving error", $tssh->{error});
    $tssh->SUPER::_log_error_and_reset_backend(@_);
}

sub _default_logger {
    my ($fh, $text) = @_;
    print {$fh} $text;
}

my @uri_keys = qw(host user port);

sub _opts_delete_list {
    my $opts = shift;
    for (@_) {
        return @$_ if ref $_ eq 'ARRAY';
        if (defined (my $v = delete $opts->{$_})) {
            return _array_or_scalar_to_list $v
        }
    }
    ()
}

sub _new {
    my ($class, $opts) = @_;
    my $tssh = $class->SUPER::_new($opts);

    $tssh->{state} = 'new';

    my $logger_fh = delete $opts->{logger_fh} // \*STDERR;
    open my $logger_fh_dup, '>>&', $logger_fh;
    $tssh->{logger_fh} = $logger_fh_dup;
    $tssh->{logger} = delete $opts->{logger} // \&_default_logger;

    # A copy of the log is always stored in disk:
    my $wdir = $tssh->{wdir} = delete $opts->{working_dir} //
        File::Temp::tempdir('libnet-ssh-any-perl.XXXXXXXXXX', TMPDIR => 1);

    unless (-d $wdir) {
        $tssh->_set_error("Invalid working directory '$wdir'");
        return $tssh;
    }

    my $logger_2_fn = File::Spec->join($wdir, 'test.log');
    open my $logger_2_fh, '>', $logger_2_fn;
    unless ($logger_2_fh) {
        $tssh->_set_error("Unable to open log file at $logger_2_fn", $!);
        return $tssh;
    }
    $tssh->{logger_2_fh} = $logger_2_fh;
    $tssh->_log("Working dir set to '$wdir'");

    $tssh->{find_keys} = delete $opts->{find_keys} // 1;
    $tssh->{timeout} = delete $opts->{timeout} // 10;
    $tssh->{run_server} = delete $opts->{run_server} // 1;
    $tssh->{test_commands} = [_opts_delete_list($opts, 'test_commands',
                                                \@default_test_commands)];
    $tssh->{backend_opts} = delete $opts->{backend_opts};
    # This is a bit thorny, but we are trying to support receiving
    # just one uri or an array of them and also uris represented as
    # strings or as hashes. For instance:
    #   uri => 'ssh://localhost:1022'
    #   uri => { host => localhost, port => 1022 }
    #   uri => [ 'ssh://localhost:1022',
    #            { host => localhost, port => 2022} ]
    my @targets = _opts_delete_list($opts, qw(targets target uris uri));
    # And we also want to support passing the target details as direct
    # arguments to the constructor.
    push @targets, {} unless @targets;
    my $user_default = $tssh->_os_current_user;
    my @uri_defaults = (scheme => 'ssh', user => $user_default,
                        host => 'localhost', port => 22);
    for (@uri_keys) {
        if (defined (my $v = delete $opts->{$_})) {
            push @uri_defaults, $_, $v;
        }
    }

    for (@targets) {
        my @args = (@uri_defaults, (ref $_ ? %$_ : (uri => $_)));
        my $uri = Net::SSH::Any::URI->new(@args);
        if ($uri) {
            if ($tssh->_is_server_running($uri)) {
                $tssh->_log("Potential target", $uri->uri(1));
                push @{$tssh->{uris}}, $uri;
            }
        }
        else {
            require Data::Dumper;
            $tssh->_log_dump("Bad target found", {@args});
        }
    }

    my @passwords = _opts_delete_list($opts, qw(passwords password));
    $tssh->{passwords} = \@passwords;

    my @keys_found;
    if ($tssh->{find_keys}) {
        @keys_found = $tssh->_find_keys;
        $tssh->{keys_found} = \@keys_found;
    }
    my @key_paths = (@keys_found,
                     _opts_delete_list($opts, qw(key_paths key_path)));
    $tssh->{key_paths} = \@key_paths;

    my @backends = _opts_delete_list($opts, qw(test_backends test_backend backends backend), \@default_backends);
    $tssh->{backends} = \@backends;

    $tssh->{any_backends} = delete $opts->{any_backend} // delete $opts->{any_backends};

    for my $backend (@backends) {
        if ($tssh->_load_backend_module(__PACKAGE__, $backend)) {
            my %opts = %{$tssh->{backend_opts}{$backend} // {}};
            $tssh->{current_opts} = \%opts;
            if ($tssh->_validate_backend_opts and
                $tssh->_start_and_check) {
                $tssh->{state} = 'running';
                $tssh->_log("Ok, backend $backend can do it!");
                return $tssh;
            }
            $tssh->_log_error_and_reset_backend
        }
    }
    $tssh->{state} = 'failed';
    $tssh->_set_error(SSHA_NO_BACKEND_ERROR, "no backend available");
    $tssh;
}

sub stop {
    my $tssh = shift;
    if ($tssh->{state} eq 'running') {
        $tssh->_stop;
        $tssh->{state} = 'stopped';
    }
}

sub DESTROY {
    my $tssh = shift;
    $tssh->_stop;
}

sub _make_path {
    my ($tssh, $head, @paths) = @_;
    for (@paths) {
        $head = File::Spec->join($head, $_);
        mkdir $head, 0755 unless -d $head;
        unless (do { local $!; -d $head}) {
            $tssh->_set_error(SSHA_LOCAL_IO_ERROR, "Unable to create directory '$head'", $!);
            return;
        }
    }
    $head;
}

sub _backend_wdir {
    my $tssh = shift;
    my $backend = $tssh->{backend} // croak "Internal error: backend not set";
    $tssh->_make_path($tssh->{wdir}, $backend);
}

sub make_wdir {
    my $tssh = shift;
    $tssh->_make_path($tssh->{wdir}, @_)
}

sub _backend_wfile {
    my ($tssh, $fn) = @_;
    my $wdir = $tssh->_backend_wdir;
    File::Spec->join($wdir, $fn);
}

sub uri { shift->{good_uri} }

sub is_localhost {
    my ($tssh, $ssh) = @_;
    my $ok = $tssh->_is_localhost($ssh);
    $tssh->_log("Remote connection points to localhost", $ok);
    $ok
}

sub _is_server_running {
    my ($tssh, $uri) = @_;
    my $host = $uri->host;
    my $port = $uri->port;
    my $tcp = IO::Socket::INET->new(PeerHost => $host,
                                    PeerPort => $port,
                                    Proto => 'tcp',
                                    Timeout => $tssh->{timeout});
    if ($tcp) {
        my $line;
        local ($@, $SIG{__DIE__});
        eval {
            alarm $tssh->{timeout};
            $line = <$tcp>;
            alarm 0;
        };
        if (defined $line and $line =~ /^SSH\b/) {
            $tssh->_log("SSH server found at ${host}:$port");
            return 1;
        }
        $tssh->_log("Server at ${host}:$port doesn't look like a SSH server, ignoring it!");
    }
    else {
        $tssh->_log("No server found listening at ${host}:$port");
    }
    0;
}

sub _find_keys {
    my $tssh = shift;
    my @keys;
    my @dirs = $tssh->_os_find_user_dirs({POSIX => '.ssh'});
    for my $dir (@dirs) {
        for my $name (qw(id_dsa id_ecdsa id_ed25519 id_rsa identity)) {
            my $key = File::Spec->join($dir, $name);
            -f $key and push @keys, $key;
        }
    }
    $tssh->_log("Key found at $_") for @keys;
    @keys;
}

1;

__END__

=head1 NAME

Net::SSH::Any::Test - Test SSH modules

=head1 SYNOPSIS

  use Net::SSH::Any::Test;

  my $tssh = Net::SSH::Any::Test->new;
  $tssh->error and die "Unable to get a working SSH service";

  my $ssh = My::SSH::Module->new($tssh->uri);
  ...

=head1 DESCRIPTION

C<Net::SSH::Any::Test> is a module that tries hard to provide a
working SSH service that can be used for testing SSH client packages
as Net::SSH::Any.

It has several backends implementing different strategies that range
from finding an already working SSH server to installing, setting up
and running a new temporary one.

The backends are tried in turn until one is found able to provide a
working SSH service.

=head1 API

=over 4

=item $tssh = Net::SSH::Any::Test->new(%opts)

This method creates and returns a new object.

It accepts the following options:

=over 4

=item backends => \@backends

Array with the names of the backends which the module should try in
order to provide the working SSH service.

For instance:

  my $tssh = Net::SSH::Any::Test->new(...,
                                      backends => ['Cygwin']);

=item run_server => 0

Disables backends that may start a new SSH server in any way on the
local machine.

=item test_commands => \@cmds

A set of commands that are executed on the remote server in order to
determine if it is working properly or not. The server is considered
good when any of the commands completes successfully.

The default set includes commands for common Linux, UNIX and MS
Windows systems.

=item working_dir => $path

Path to a directory where to write temporary files and logs.

=item timeout => $timeout

The given value is later honoured by methods doing network IO.

=item logger => sub { ... }

A logging function that will be used for reporting information to the
user. The function is called with the logging file handle and the
message as arguments.

For instance, using C<diag> from L<Test::More>:

  use Test::More;
  ...

  sub my_logger {
    my ($fh, $msg) = @_;
    # note that $fh is just not used!
    diag $msg;
  }

  my $tssh = Net::SSH::Any::Test->new(...,
                                      logger => \&my_logger);

The default logger prints the messages to the logger file handle.

=item logger_fh => $fh

Sets the logger file handle. Defaults to C<STDERR>.

=item target => $uri

=item targets => \@uris

Set of server targets to be used by the Remote backend.

The information in the targets is combined with that passed in other
options. For instance:

   my $tssh = Net::SSH::Any::Test->new(target => 'ssh://leo_caldas@10.0.3.1/',
                                       password => $password,
                                       port => 1022);

See also L<Net::SSH::Any::URI>.

=item port => $port

Sets the SSH port number used when looking for running servers.

=item password => $password

Sets the SSH password.

=item key_path => $private_key_path

=item key_paths => \@private_key_paths

Path to files containing private keys to use for authentication.

=item backend_opts => { $backend_name => \%opts, ... }

Per backend specific options.

=back

=item $uri = $tssh->uri

Returns a L<Net::SSH::Any::URI> object representing a working SSH
service.

=item $error = $tssh->error

Returns the last error.

=item $tssh->stop

Terminates any running process (i.e. any SSH server).

=back

=head1 BACKENDS

The following backends are currently available.

They lack proper documentation as this is a work in progress yet.

=over 4

=item Remote

Tries to connect to localhost or to any other given service.

See L<Net::SSH::Any::Test::Backend::Remote>.

=item OpenSSH_Daemon

Starts a new OpenSSH server.

See L<Net::SSH::Any::Test::Backend::OpenSSH_Daemon>.

=item Dropbear_Daemon

Starts a new Dropbear server.

Note: requires a patched version of dropbear installed
(L<https://github.com/salva/dropbear>).

See L<Net::SSH::Any::Test::Backend::Dropbear_Daemon>.

=item Cygwin

In MS Windows systems, downloads and install Cygwin, including the
OpenSSH packages, and uses then to run a SSH server.

See L<Net::SSH::Any::Test::Backend::Cygwin>.

=back

