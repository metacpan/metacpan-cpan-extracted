package Net::SSH::Any;

our $VERSION = '0.10';

use strict;
use warnings;
use warnings::register;
use Carp;

use Net::SSH::Any::Util;
use Net::SSH::Any::URI;
use Net::SSH::Any::Constants qw(:error);
use Scalar::Util qw(dualvar);

use Net::SSH::Any::_Base;
our @ISA = qw(Net::SSH::Any::_Base);

my $REQUIRED_BACKEND_VERSION = '2';
our @default_backends = qw(Net_OpenSSH Net_SSH2 Net_SSH_Perl Ssh_Cmd Plink_Cmd);

sub _new {
    my ($class, $opts) = @_;
    my $any = $class->SUPER::_new($opts);
    $opts->{uri} // $opts->{host} // croak "either host or uri argument must be given";
    $opts->{password} //= delete $opts->{passwd};

    my @uri_opts = (port => 22);
    if (defined (my $uri = delete $opts->{uri})) {
        $uri = $uri->as_string if ref $uri and $uri->can('as_string');
        push @uri_opts, uri => $uri;
    }
    for (qw(host user port password passphrase)) {
        if (defined (my $v = delete $opts->{$_})) {
            push @uri_opts, $_, $v;
        }
    }
    my $uri = $any->{uri} = Net::SSH::Any::URI->new(@uri_opts);
    unless ($uri) {
        $any->_set_error(SSHA_CONNECTION_ERROR, "Unable to parse URI");
        return $any;
    }

    unless (defined $uri->user) {
        if (defined (my $current_user = $any->_os_current_user)) {
            $uri->user($current_user);
        }
        else {
            $any->_set_error(SSHA_UNIMPLEMENTED_ERROR, "Unable to infer login name");
            return $any;
        }
    }

    if (defined (my $key_paths = delete $opts->{key_path} // delete $opts->{key_paths})) {
        $uri->or_set(key_path => _array_or_scalar_to_list($key_paths))
    }

    $any->{io_timeout} = delete $opts->{io_timeout} // 120;
    $any->{timeout} = delete $opts->{timeout};
    $any->{remote_shell} = delete $opts->{remote_shell} // 'POSIX';
    $any->{known_hosts_path} = delete $opts->{known_hosts_path};
    $any->{strict_host_key_checking} = delete $opts->{strict_host_key_checking} // 1;
    $any->{compress} = delete $opts->{compress} // 1;
    $any->{backend_opts} = delete $opts->{backend_opts};
    $any->{batch_mode} = delete $opts->{batch_mode};

    my @backends = _array_or_scalar_to_list(delete $opts->{backend} // delete $opts->{backends} // \@default_backends);
    $any->{backends} = \@backends;

    for my $backend (@backends) {
        $any->{error} = 0;
        if ($any->_load_backend_module(__PACKAGE__, $backend, $REQUIRED_BACKEND_VERSION)) {
            $any->{backend} or croak "internal error: backend not set";
            my %backend_opts = map { $_ => $any->{$_} // scalar($uri->get($_)) }
                qw(host port user password passphrase key_path timeout io_timeout
                   strict_host_key_checking known_hosts_path compress batch_mode);


            if (my $extra = $any->{backend_opts}{$backend}) {
                @backend_opts{keys %$extra} = values %$extra;
            }
            defined $backend_opts{$_} or delete $backend_opts{$_}
                for keys %backend_opts;

            if ($any->_validate_backend_opts(%backend_opts)) {
                $any->_connect;
                return $any;
            }
            unless ($any->{error}) {
                $any->_set_error(SSHA_BACKEND_ERROR, "internal error: _validate_backend_opts failed without setting the error");
            }
            $any->_log_error_and_reset_backend;
        }
    }
    $any->_set_error(SSHA_NO_BACKEND_ERROR, "no backend available");
    $any;
}

sub new {
    my $class = shift;
    my %opts = (@_ & 1 ? (uri => @_) : @_);
    $class->_new(\%opts);
}

sub _clear_error {
    my $any = shift;
    my $error = $any->{error};
    return if ( $error and
                ( $error == SSHA_NO_BACKEND_ERROR or
                  $error == SSHA_BACKEND_ERROR or
                  $error == SSHA_CONNECTION_ERROR ) );
    $any->{error} = 0;
    1;
}

sub _quoter {
    my ($any, $shell) = @_;
    if (defined $shell and $shell ne $any->{remote_shell}) {
	return $any->_new_quoter($shell);
    }
    $any->{quoter} //= $any->_new_quoter($any->{remote_shell});
}

sub _delete_stream_encoding_and_encode_input_data {
    my ($any, $opts) = @_;
    my $stream_encoding = $any->_delete_stream_encoding($opts) or return;
    $debug and $debug & 1024 and _debug("stream_encoding: "
                                        . ($stream_encoding ? $stream_encoding : '<undef>') );
    if (defined(my $data = $opts->{stdin_data})) {
        my @input = grep defined, _array_or_scalar_to_list $data;
        $any->_encode_data($stream_encoding => @input) or return;
        $opts->{stdin_data} = \@input;
    }
    $stream_encoding
}

sub _check_child_error {
    my $any = shift;
    $any->error and return;
    if ($?) {
        $any->_set_error(SSHA_REMOTE_CMD_ERROR,
                         "remote command failed with code " . ($? >> 8)
                         . " and signal " . ($? & 255));
        return;
    }
    return 1;
}

_sub_options capture => qw(timeout stdin_data stderr_to_stdout stderr_discard
                           stderr_fh stderr_file);
sub capture {
    my $any = shift;
    $any->_clear_error or return undef;
    my %opts = (ref $_[0] eq 'HASH' ? %{shift()} : ());
    my $stream_encoding = $any->_delete_stream_encoding_and_encode_input_data(\%opts) or return;
    my $cmd = $any->_quote_args(\%opts, @_) // return;
    _croak_bad_options %opts;
    my ($out) = $any->_capture(\%opts, $cmd) or return;
    $any->_check_child_error;
    if ($stream_encoding) {
	$any->_decode_data($stream_encoding => $out) or return;
    }
    if (wantarray) {
	my $pattern = quotemeta $/;
	return split /(?<=$pattern)/, $out;
    }
    $out
}

_sub_options capture2 => qw(timeout stdin_data);
sub capture2 {
    my $any = shift;
    $any->_clear_error or return undef;
    my %opts = (ref $_[0] eq 'HASH' ? %{shift()} : ());
    my $stream_encoding = $any->_delete_stream_encoding_and_encode_input_data(\%opts) or return;
    my $cmd = $any->_quote_args(\%opts, @_) // return;
    _croak_bad_options %opts;
    my ($out, $err) = $any->_capture2(\%opts, $cmd) or return;
    $any->_check_child_error;
    if ($stream_encoding) {
        $any->_decode_data($stream_encoding => $out) or return;
        $any->_decode_data($stream_encoding => $err) or return;
    }
    wantarray ? ($out, $err) : $out
}

_sub_options system => qw(timeout stdin_data stdin_file stdin_fh
                          stdout_fh stdout_file stdout_discard
                          stderr_to_stdout stderr_fh stderr_file stderr_discard
                          _window_size);
sub system {
    my $any = shift;
    $any->_clear_error or return undef;
    my %opts = (ref $_[0] eq 'HASH' ? %{shift()} : ());
    my $stream_encoding = $any->_delete_stream_encoding_and_encode_input_data(\%opts) or return;
    my $cmd = $any->_quote_args(\%opts, @_) // return;
    _croak_bad_options %opts;
    $any->_system(\%opts, $cmd);
    $any->_check_child_error;
}

_sub_options dpipe => qw(stderr_to_stdout stderr_discard subsystem);
sub dpipe {
    my $any = shift;
    $any->_clear_error or return undef;
    my %opts = (ref $_[0] eq 'HASH' ? %{shift()} : ());
    my $cmd = $any->_quote_args(\%opts, @_) // return;
    _croak_bad_options %opts;
    $any->_dpipe(\%opts, $cmd);
}

_sub_options sftp => qw(fs_encoding timeout block_size queue_size autoflush write_delay
                        read_ahead late_set_perm autodie remote_sftp_server_cmd ssh1);
sub sftp {
    my ($any, %opts) = @_;

    $opts{timeout} //= $any->{timeout} if defined $any->{timeout};
    $opts{fs_encoding} //= $any->_delete_argument_encoding(\%opts);

    _croak_bad_options %opts;
    $any->_load_module('Net::SFTP::Foreign') or return;
    if (my $sftp = $any->_sftp(\%opts)) {
        if (my $error = $sftp->error) {
            $any->_set_error(SSHA_SFTP_ERROR, 'Unable to start SFTP connection', $sftp->error);
            return;
        }
        return $sftp;
    }
    else {
        $any->_or_set_error(SSHA_SFTP_ERROR, 'Unable to start SFTP connection', 'Unknown error');
    }
    ()
}

sub _helper_delegate {
    my $any = shift;
    my $class = shift;
    $any->_load_module($class) or return;
    my %opts = (ref $_[0] eq 'HASH' ? %{shift()} : ());
    my $obj = $class->_new($any, \%opts, @_) or return;
    $obj->run(\%opts);
}

sub _wait_ssh_proc {
    my ($any, $proc, $timeout, $force_kill) = @_;
    $force_kill //= $any->{_kill_ssh_on_timeout};
    if ($force_kill) {
        $timeout = $any->{_timeout} unless defined $timeout;
        $timeout = 0 if $any->error == SSHA_TIMEOUT_ERROR;
    }

    $any->_os_wait_proc($proc, $timeout, $force_kill);
}

sub scp_get         { shift->_helper_delegate('Net::SSH::Any::SCP::Getter::Standard', @_) }
sub scp_get_content { shift->_helper_delegate('Net::SSH::Any::SCP::Getter::Content',  @_) }
sub scp_mkdir       { shift->_helper_delegate('Net::SSH::Any::SCP::Putter::DirMaker', @_) }
sub scp_put         { shift->_helper_delegate('Net::SSH::Any::SCP::Putter::Standard', @_) }
sub scp_put_content { shift->_helper_delegate('Net::SSH::Any::SCP::Putter::Content',  @_) }

sub scp_find        {
    _warn("this feature is not finished yet");
    shift->_helper_delegate('Net::SSH::Any::SCP::Getter::Finder', @_)
}

sub autodetect {
    my $any = shift;
    my $auto = $any->_helper_delegate('Net::SSH::Any::Autodetector', @_) // return;
    wantarray ? %$auto : $auto;
}

1;

__END__

=head1 NAME

Net::SSH::Any - SSH client module

=head1 SYNOPSIS

  use Net::SSH::Any;

  my $ssh = Net::SSH::Any->new($host, user => $user, password => $passwd);

  my @out = $ssh->capture(cat => "/etc/passwd");
  my ($out, $err) = $ssh->capture2("ls -l /");
  $ssh->system("foo");

  my $sftp = $ssh->sftp; # returns Net::SFTP::Foreign object
  $sftp->put($local_path, $remote_path);

=head1 DESCRIPTION

  **************************************************************
  ***                                                        ***
  *** NOTE: This is an early release that may contain bugs.  ***
  *** The API is not stable and may change between releases. ***
  ***                                                        ***
  *** Also, the module tests are quite aggresive, containing ***
  *** checks for experimental features, and may fail even if ***
  *** the module mostly works.                               ***
  ***                                                        ***
  **************************************************************

C<Net::SSH::Any> is a SSH client module providing a high level and
powerful API.

It can run remote commands and redirect its output or capture it, and
perform file transfers using SCP or SFTP easily.

Net::SSH::Any does not implement the SSH protocol itself. Instead, it
has a plugable architecture allowing it to delegate that task to
other SSH client modules or external binaries.

=head1 BACKENDS

The backends (modules that interface with other Perl SSH client
modules or external binaries) currently available are as follows:

=over 4

=item Net_OpenSSH

Uses the perl module L<Net::OpenSSH> which relies itself on the
OpenSSH C<ssh> binary to connect to the remote hosts. As it uses the
multiplexing feature of OpenSSH, it can run several commands (or other
operations) over one single SSH connection and so it is quite fast and
reliable.

Using the OpenSSH client also ensures maximum interoperability and a
mature an secure protocol implementation.

If you are going to run your program in a Linux/Unix box with a recent
version of the OpenSSH client installed, this is probably your
best option. On the other hand, Net::OpenSSH does not support Windows.

See L<Net::SSH::Any::Backend::Net_OpenSSH>.

=item Net_SSH2

Uses the perl module Net::SSH2 which is a wrapper for the libssh2 C
library, a fast and portable implementation of the client side
of the SSH version 2 protocol.

L<Net::SSH2> is an actively maintained module that works on both
Unix/Linux an Windows systems (don't known about VMS). Compiling it
may be a hard task, specially on Windows, but PPM packages are
available from the Internet.

That was intended to be main backend for Net::SSH::Any when used on
Windows. Unfortunately, the current stable version of libssh2 is
still somewhat buggy, causing this backend to be unreliable.

See L<Net::SSH::Any::Backend::Net_SSH2>.

=item Ssh_Cmd

This backend uses any binary <c>ssh</c> client available on the box
that accepts the same command line arguments as the OpenSSH one. In
practice that means SSH clients forked from old versions of OpenSSH as
for instance, the one bundled in Solaris and other commercial unixen.

Password authentication is only supported on Linux/UNIX and it
requires the additional module IO::Pty. It may work under Cygwin too.

This backend establishes a new SSH connection for every remote
command run and so it is quite slow, although reliable.

See L<Net::SSH::Any::Backend::Ssh_Cmd>.

=item Plink_Cmd

This backend uses the C<plink> utility, part of the
L<PuTTY|http://www.chiark.greenend.org.uk/~sgtatham/putty/> package.

It supports password authentication, but in a somewhat insecure manner,
as passwords are given to putty as a command line argument. Anybody
(user or program) logged on the machine would be able to see them.

This backend also establishes a new SSH connection for every remote
command run and so it is reliable but slow.

See L<Net::SSH::Any::Backend::Plink_Cmd>.

=item Sexec_Cmd

This backend uses the C<sexec> utility that is bundled with the
non-free Bitwise SSH client.

This backend also establishes a new SSH connection for every remote
command run and so it is reliable but slow.

See L<Net::SSH::Any::Backend::Sexec_Cmd>.

=item Sshg3_Cmd

This backend uses the C<sshg3> utility that is bundled with the
non-free Tectia SSH client.

This module supports password authentication in a secure manner and it
is also quite fast as the Tectia client reuses connections.

See L<Net::SSH::Any::Backend::Sshg3_Cmd>.

=back

=head1 DEPENDENCIES

Depending on the backend selected and on the feature set used, you may
need to install additional Perl modules.

What follows is a summary of the optional modules and when they are
required:

=over

=item IO::Pty

Used for password authentication with the C<Net_OpenSSH> and
C<Ssh_Cmd> backends.

=item Net::OpenSSH

Used by the C<Net_OpenSSH> backend and also when a non-POSIX shell
quoter is required.

=item Net::SSH2

Used by the C<Net_SSH2> backend.

=item Net::SFTP::Foreign

Required for SFTP support.

=item Win32::SecretFile

Used by the C<Sshg3_Cmd> backend on Windows.

=back

=head1 API

The API of Net::SSH::Any is heavily based on that of Net::OpenSSH.
Basic usage of both modules is mostly identical and it should be very
easy to port scripts between the two.

=head2 Optional parameters

Almost all methods in this package accept as first argument a
reference to a hash containing optional parameters. In example:

  $ssh->scp_get({recursive => 1}, $remote_src, $local_target);
  my @out = $ssh->capture({stderr_to_stdout => 1}, "ls ~/");

The hash reference can be omitted when optional parameters are not
required. In example:

  $ssh->scp_get($remote_src, $local_target);
  my @out = $ssh->capture("ls ~/");

=head2 Error handling

Most methods return undef or an empty list to indicate
failure. Exceptions to this rule are the constructor, which always
returns and object, and those methods able to generate partial results
as for instance <c>capture</c> or <c>scp_get_content</c>.

The L</error> method can always be used to explicitly check for
errors. For instance:

  my $out = $ssh->capture($cmd);
  $ssh->error and die "capture method failed: " . $ssh->error;

=head2 Shell quoting

By default when calling remote commands, this module tries to mimic
perl C<system> builtin in regard to argument processing.

When calling some method as <c>capture</c>:

   $out = $ssh->capture($cmd)

the given command (C<$cmd>) is first processed by the remote shell who
performs interpolation of environment variables, globs expansion,
redirections, etc.

If more than one argument is passed, as in the following example:

   $out = $ssh->capture($cmd, $arg1, $arg2)

The module will escape any shell metacharacter so that, effectively,
the remote call is equivalent to executing the remote command without
going through a shell (the SSH protocol does not provides a way to
just avoid the shell by not calling it).

All the methods that invoke a remote command (system, capture, etc.)
accept the option C<quote_args> allowing one to force or disable
shell quoting.

For instance, spaces in the command path will be correctly handled in
the following case:

  $ssh->system({quote_args => 1}, "/path with spaces/bin/foo");

Deactivating quoting when passing multiple arguments can also be
useful, for instance:

  $ssh->system({quote_args => 0}, 'ls', '-l', "/tmp/files_*.dat");

In that case, the argument are joined with spaces interleaved.

When the C<glob> option is set in SCP file transfer methods, an
alternative quoting mechanism which leaves file wildcards
unquoted is used.

Another way to selectively use quote globing or fully disable quoting
for some specific arguments is to pass them as scalar references or
double scalar references respectively. In practice, that means
prepending them with one or two backslashes. For instance:

  # quote the last argument for globing:
  $ssh->system('ls', '-l', \'/tmp/my files/filed_*dat');

  # append a redirection to the remote command
  $ssh->system('ls', '-lR', \\'>/tmp/ls-lR.txt');

  # expand remote shell variables and glob in the same command:
  $ssh->system('tar', 'czf', \\'$HOME/out.tgz', \'/var/log/server.*.log');

The builtin quoting implementation expects a remote shell compatible
with Unix C<sh> as defined by the POSIX standard. The module can also
use the shell quoters available from L<Net::OpenSSH> when installed
(that currently includes quoters for C<csh> and MS Windows).

The C<remote_shell> option can be used to select which one to use both
at construction time or when some remote command in invoked. For
instance:

  $ssh = Net::SSH::Any->new($host, remote_shell => 'csh');

  $ssh->system({remote_shell => 'MSWin'}, dir => $directory);

For unsupported shells or systems such as VMS, you will have to perform
any quoting yourself:

  # for VMS
  $ssh->system('DIR/SIZE NFOO::USERS:[JSMITH.DOCS]*.TXT;0');

=head2 Timeouts

Several of the methods described below support a C<timeout> argument
that aborts the remote command when the given time lapses without any
data arriving via SSH.

In order to stop some remote process when it times out, the ideal
approach would be to send appropriate signals through the SSH
connection , but unfortunately, this is a feature of the standard
that most SSH implementations do not support.

As a less than perfect alternative solution, in order to force
finishing a remote process on timeout, the module closes its stdio
streams. That would deliver a SIGPIPE on the remote process next time
it tries to write something.

Most backends are able to detect broken connections due to network
problems by other means, as for instance, enabling C<SO_KEEPALIVE> on
the TCP socket, or using the protocol internal keep alive (currently,
only supported by the Net::OpenSSH backend).

=head2 Net::SSH::Any methods

These are the methods available from the module:

=over 4

=item $ssh = Net::SSH::Any->new($target, %opts)

This method creates a new Net::SSH::Any object representing a SSH
connection to the remote machine as described by C<$target>.

C<$target> has to follow the pattern
<c>user:password@hostname:port</c> where all parts but hostname are
optional. For instance, the following constructor calls are all
equivalent:

   Net::SSH::Any->new('hberlioz:f#nta$71k6@harpe.cnsmdp.fr:22');
   Net::SSH::Any->new('hberlioz@harpe.cnsmdp.fr',
                      password => 'f#nta$71k6', port => 22);
   Net::SSH::Any->new('harpe.cnsmdp.fr',
                      user => 'hberlioz', password => 'f#nta$71k6');

=over 4

=item user => $user_name

Login name

=item port => $port

TCP port number where the remote server is listening.

=item password => $password

Password for user authentication.

=item key_path => $key_path

Path to file containing the private key to be used for
user authentication.

Some backends (i.e. Net::SSH2), require the public key to be
stored in a file of the same name with C<.pub> appended.

=item passphrase => $passphrase

Passphrase to be used to unlock the private key.

=item batch_mode => 1

Disable any authentication method requiring user interaction.

=item timeout => $seconds

Default timeout.

=item argument_encoding => $encoding

The encoding used for the commands and arguments sent to the remote stream.

=item stream_encoding => $encoding

On operation interchanging data between perl and the remote commands
(as opposed to operations redirecting the remote commands output to the
file system) the encoding to be used.

=item encoding => $encoding

This option is equivalent to setting C<argument_encoding> and
C<stream_encoding>.

=item remote_shell => $shell

Name of the remote shell. This argument lets the module pick the right
shell quoter.

=item known_hosts_path => $path

Location of the C<known_hosts> file where host keys are saved.

On Unix/Linux systems defaults to C<~/.ssh/known_hosts>, on Windows to
C<%APPDATA%/libnet-ssh-any-perl/known_hosts>.

=item strict_host_key_checking => $bool

When this flag is set, the connection to the remote host will be
aborted unless the host key is already stored in the C<known_hosts>
file.

Setting this flag to zero, relaxes that condition so that remote keys
are accepted unless a different key exists on the C<known_hosts> file.

=item remote_*_cmd => $remote_cmd_path

Some operations (i.e. SCP operations) execute a remote
command implicitly. By default the corresponding standard command
without any path is invoked (i.e C<scp>).

If any other command is preferred, it can be requested through these
set of options. For instance:

   $ssh = Net::SSH::Any->new($target,
                             remote_scp_cmd => '/usr/local/bin/scp',
                             remote_tar_cmd => '/usr/local/bin/gtar');

=item local_*_cmd => $local_cmd_path

Similar to C<remote_*_cmd> parameters but for local commands.

For instance:

   $ssh = Net::SSH::Any->new($target,
                             remote_ssh_cmd => '/usr/local/bin/ssh');

=item backends => \@preferred_backends

List of preferred backends to be tried.

=item backend_opts => \%backend_opts

Options specific for the backends.

=back

=item $ssh->error

This method returns the error, if any, from the last method.

=item $ssh->system(\%opts, @cmd)

Runs a command on the remote machine redirecting the stdout and stderr
streams to STDOUT and STDERR respectively.

Note than STDIN is not forwarded to the remote command.

The set of options accepted by this method is as follows:

=over 4

=item timeout => $seconds

If there is not any network traffic over the given number of seconds,
the command is aborted. See L</Timeouts>.

=item stdin_data => $data

=item stdin_data => \@data

The given data is sent as the remote command stdin stream.

=item stdout_fh => $fh

The remote stdout stream is redirected to the given file handle.

=item stdout_file => $filename

The remote stdout stream is saved to the given file.

=item stdout_discard => $bool

The remote stdout stream is discarded.

=item stderr_to_stdout => $bool

The remote stderr stream is mixed into the stdout stream.

=item stderr_fh => $fh

The remote stderr stream is redirected to the given file handle.

=item stderr_file => $filename

The remote stderr stream is saved on the given file.

=item stderr_discard => $bool

The remote stderr stream is discarded.

=back

=item $output = $ssh->capture(\%opts, @cmd)

=item @output = $ssh->capture(\%opts, @cmd)

The given command is executed on the remote machine and the output
captured and returned.

When called in list context this method returns the output split in
lines.

In case of error the partial output is returned. The C<error> method
should be used to check that no error happened even when output has
been returned.

The set of options accepted by this method is as follows:

=over 4

=item timeout => $seconds

Remote command timeout.

=item stdin_data => $data

=item stdin_data => \@data

Data to be sent through the remote command stdin stream.

=item stderr_to_stdout => $bool

The remote stderr stream is redirected to the stdout stream (and then
captured).

=item stderr_discard => $bool

Remote stderr is discarded.

=item stderr_fh => $fh

Redirect remote stderr stream to the given file handle.

=item stderr_file => $filename

Save the remote stderr stream to the given file.

=back

=item ($stdout, $stderr) = $ssh->capture2(\%opts, @cmd)

Captures both the stdout and stderr streams from the remote command
and returns them.

=over 4

=item timeout => $seconds

Command is aborted after the given numbers of seconds with no activity
elapse.

=item stdin_data => $data

=item stdin_data => \@data

Sends the given data through the stdin stream of the remote process.

Example:

    $ssh->system({stdin_data => \@data}, "cat >/tmp/foo")
        or die "unable to write file: " . $ssh->error;

=back

=item $pipe = $ssh->pipe(\%opts, @cmd)

Returns a bidirectional file handle object (that may be a real
operating system file handle or an emulated tied file handle,
depending on the used backend), connected to the remote command stdin
and stdout streams.

The returned pipe objects provide most of the API of L<IO::Handle>.

=over 4

=item stderr_to_stdout => $bool

Redirects the stderr stream of the remote process into its stdout
stream.

=item stderr_discard => $bool

Discards the stderr stream of the remote process.

=back

=item $ssh->scp_get(\%opts, @srcs, $target)

Copies the given files from the remote host using scp.

The accepted set of options are as follow:

=over

=item glob => $bool

Allows the remote shell to expand wildcards when selecting the files
to download.

=item recursive => $bool

When this flag is set, the module will descend into directories and
retrieve them recursively.

=item copy_attr => $bool

When this flag is set the attributes of the local files (permissions
and timestamps) are copied from the remote ones.

=item copy_perm => $bool

=item copy_time => $bool

Selectively copy the permissions or the timestamps.

=item update => $bool

If the target file already exists locally, it is only copied when the
timestamp of the remote version is newer. If the file doesn't exist
locally, it is unconditionally copied.

=item numbered => $bool

When for some remote file a local file of the same name already exists
at its destination, a increasing suffix is added just before any
extension.

For instance, C<foo> may become C<foo(1)>, C<foo(2)>, etc.; C<foo.txt>
may become C<foo(1).txt>, C<foo(2).txt>, etc.

=item overwrite => $bool

When a local file of the same name already exist, overwrite it. Set by
default.

=back

=item $ssh->scp_put(\%opts, @srcs, $target)

Copies the set of given files to the remote host.

The accepted options are as follows:

=over 4

=item glob => $bool

Allows wildcard expansion when selecting the files to copy.

=item recursive => $bool

Recursively descend into directories.

=item copy_attr => $bool

Copy permission and time attributes from the local files.

=item follow_links => 0

Symbolic links are not supported by SCP. By default, when a symbolic
link is found, the method just copies the file pointed by the link.

If this flag is unset symbolic links are skipped.

=back

=item $data = $ssh->scp_get_content(\%opts, @srcs)

Retrieves the contents of some file or files via SCP.

=over 4

=item glob => $bool

Allows wildcard expansion on the remote host when selecting the files
to transfer.

=item recursive => $bool

Recursively descends into directories

=back

=item $ssh->scp_put_content(\%opts, $target, $content)

Creates or overwrites the remote file C<$target> with the data given
in C<$content>.

=over 4

=item perm => $perm

The permissions for the new remote file. Defaults to 0666.

=item atime => $atime

=item mtime => $mtime

Sets the atime and mtime properties of the remote file.

=back

=item $ssh->scp_mkdir(\%opts, $dir)

Creates a directory using SCP.

=over 4

=item perm => $perm

Sets the permissions of the remote directories created. Defaults to
0777.

=item atime => $atime

=item mtime => $mtime

Sets the atime and mtime properties of the remote directories.

=back

=item $sftp = $ssh->sftp(%opts);

Returns a new L<Net::SFTP::Foreign> object connected to the remote
system or C<undef> in case of failure.

=over

=item fs_encoding => $encoding

=item timeout => $seconds

=back

=item %data = $ssh->autodetect(@tests)

Calls L<Net::SSH::Any::Autodetect>, which implements tests and
heuristics that allow one to discover several properties about the
remote machine as for instance its operating system or the user shell.

That module is still highly experimental and the way it is used or the
format of the returned data may change in future releases.

=back

=head1 FAQ

Frequent questions about this module:

=over 4

=item Disabling host key checking

B<Query>: How can host key checking be completely disabled?

B<Answer>: You don't want to do that, disabling host key checking
breaks SSH security model. You will be exposed to man-in-the-middle
attacks, and anything transferred over the SSH connection may be
captured by a third party, including passwords if you are also using
password authentication.

B<Q>: I don't mind about security, can I disable host key checking?

B<A>: You have been warned...

The way to disable host key checking is to unset the
C<strict_host_key_checking> flag and point C<known_hosts> to
C</dev/null> or your preferred OS equivalent.

In example:

  my $ssh = Net::SSH::Any->new($host,
                               strict_host_key_checking => 0,
                               known_hosts_path => ($^O =~ /^Win/
                                                    ? 'nul'
                                                    : '/dev/null'));

I am not making that easier on purpose!

=item known_hosts file

B<Q>: How can I manipulate the C<known_hosts> file. I.e, adding and
removing entries?

B<A>: If you have a recent version of OpenSSH installed on your
machine, the companion utility C<ssh-keygen(1)> provides a relatively
easy to use command line interface to such file.

Otherwise, you can just add or remove the entries manually using a
text editor.

If you are on Linux/Unix and using the default C<known_hosts> file, an
easy way to add some host key to it is to just log once manually from
the command line using your system C<ssh> command. It will get the key
from the remote host and ask you if you want to add the key to the
store.

Later versions of L<Net::SSH2> provide basic support for
C<known_hosts> file manipulation in L<Net::SSH2::KnownHosts>.

=item More questions

See also the FAQ from the L<Net::OpenSSH/FAQ> module as most of the
entries there are generic.

=back

=head1 SEE ALSO

L<Net::OpenSSH>, L<Net::SSH2>, L<Net::SSH::Perl>.

L<Net::SFTP::Foreign>

=head1 BUGS AND SUPPORT

To report bugs send an email to the address that appear below or use
the CPAN bug tracking system at L<http://rt.cpan.org>.

B<Post questions related to how to use the module in Perlmonks>
L<http://perlmoks.org/>, you will probably get faster responses than
if you address me directly and I visit Perlmonks quite often, so I
will see your question anyway.

The source code of this module is hosted at GitHub:
L<http://github.com/salva/p5-Net-SSH-Any>.

=head2 Commercial support

Commercial support, professional services and custom software
development around this module are available through my current
company. Drop me an email with a rough description of your
requirements and we will get back to you ASAP.

=head2 My wishlist

If you like this module and you're feeling generous, take a look at my
Amazon Wish List: L<http://amzn.com/w/1WU1P6IR5QZ42>.

Also consider contributing to the OpenSSH project this module builds
upon: L<http://www.openssh.org/donations.html>.

=head1 TODO

Thinks that I would like to add in this module in the future:

=over 4

=item * Host key checking policies

I.e. strict, tofu, ask, advisory.

=item * Install client software automatically

Add infrastructure to download, maybe compile and install client
software from the internet. This will be used to test the module in
automating testing environments as CPAN Testers or Travis CI.

=item * Expect like functionality

A subset of L<Expect> adapted to work on top of Net::SSH::Any.

=item * Gateway support

I am still not sure about how viable it would be, but I would like to
get something like Net::OpenSSH::Gateway available for Net::SSH::Any.

=item * Move to Moo+Moo::Role or Role::Tiny

The ad-hoc composition model used internally by Net::SSH::Any has
several quirks that would be gone using the dynamic inheritance model
provided by L<Role::Tiny>, though that would probably be a huge
effort.

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2016 by Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
