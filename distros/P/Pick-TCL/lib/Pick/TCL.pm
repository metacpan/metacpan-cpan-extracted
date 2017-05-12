package Pick::TCL;

use 5.006;
use strict;
use warnings;
use Carp;
use Errno;
use IO::Select;
use IO::Socket;
use Socket;

=head1 NAME

Pick::TCL - class to run commands in a Pick TCL shell

=head1 VERSION

Version 0.06

=cut

###################
# PACKAGE GLOBALS #
###################

our $VERSION = '0.06';
our %_mods;

#########################
# OPTIONAL DEPENDENCIES #
#########################

BEGIN
{
    %_mods = ();
    if (eval { require IPC::Run; })
    {
        $_mods{'local'} = 'IPC::Run';
    }
    if (eval { require Net::OpenSSH; })
    {
        $_mods{'remote'} = 'Net::OpenSSH';
    }
}

if (scalar(keys %_mods) == 0)
{
    croak "Pick::TCL requires either IPC::Run or Net::OpenSSH";
}

=head1 SYNOPSIS

    use Pick::TCL;

    # Establish connection
    my $ap = Pick::TCL->new(%options);
    
    # Execute commands
    my $output = $ap->exec('TCL.COMMAND PARAMS (OPTIONS)');
    my $unsanitised = $ap->execraw('TCL.COMMAND PARAMS (OPTIONS)');

    # Spawn, check & retrieve output of long-running commands
    $ap->spawn('TCL.COMMAND PARAMS (OPTIONS)')} = 1;
    # ...
    do_something_with($ap->output) if $ap->is_ready;

    # Clean up
    $ap->logout();

=head1 DESCRIPTION

C<Pick::TCL> provides a class to run arbitrary B<TCL> (that's
I<Terminal Control Language>, not the "other" TCL) commands in a
local or remote Pick or Pick-like environment, either synchronously
(blocking until execution has completed) or asynchronously.

=over 4

=item Local connections

require either L<IPC::Run> or L<Net::OpenSSH> to be installed and usable.

=item Remote connections

require L<Net::OpenSSH> to be installed and usable.

=back

Note that C<Pick::TCL> will croak() if used when neither L<IPC::Run>
nor L<Net::OpenSSH> are usable.

=cut

###################
# Private methods #
###################

# Get an ssh link. Returns 1 on success. On failure returns undef
# and sets $!
sub _bring_up_ssh
{
    my $self = shift;

    # Build connection string
    my %options = %{$$self{'_OPTIONS'}};
    my $cs = defined($options{'SSHUSER'}) ? $options{'SSHUSER'} : "";
    $cs .= ':'.$options{'SSHPASS'} if defined($options{'SSHPASS'});
    $cs .= '@' unless $cs eq '';
    $cs .= $options{'HOST'};
    $cs .= ':'.$options{'PORT'} if defined($options{'PORT'});

    # Survive in Taint mode
    local %ENV;
    $ENV{'PATH'} = "";
    
    # Find ssh binary
    unless (defined($options{'SSHCMD'}))
    {
        my $cmd = '';
        foreach my $c (qw[/usr/local/bin/ssh /usr/bin/ssh /bin/ssh])
        {
          next unless -x $c;
          $cmd = $c;
          last;
        }
        croak "Pick::TCL: can't find ssh" unless $cmd;
        $$self{'_OPTIONS'}->{'SSHCMD'} = $cmd;
    }

    # Bring up link
    croak "Pick::TCL: No usable module found for remote connections"
        unless $_mods{'remote'};
    my $ssh = undef;
    $ssh = Net::OpenSSH->new($cs, ssh_cmd => $$self{'_OPTIONS'}->{'SSHCMD'},
        master_stderr_discard => 1,
        timeout => $$self{'_OPTIONS'}->{'TIMEOUT'}, kill_ssh_on_timeout => 1,
        default_ssh_opts => [ '-oConnectionAttempts=0' ] );
    my $e = $ssh->error;
    if ($e)
    {
        carp "Pick::TCL: Failed to bring up ssh link: $e";
        $! = &Errno::ETIMEDOUT;
        return undef;
    }
    $$self{'_SSH'} = \$ssh;
    return 1;
}

# Tear down & re-establish an ssh link
sub _reconnect_ssh
{
    my $self = shift;
    if (ref($$self{'_SSH'}))
    {
        ${$$self{'_SSH'}}->DESTROY;
    }
    delete($$self{'_SSH'});
    return $self->_bring_up_ssh();
}

# Generate user logon sequence
sub _mklogon
{
    my $self = shift;
    my $logon = '';
    foreach my $k (qw/USER PASS MD MDPASS/)
    {
        next unless defined($$self{'_OPTIONS'}->{$k});
        $logon .= $$self{'_OPTIONS'}->{$k} . "\n";
    }
    return $logon;
}

# Build Pick command
sub _mkpickcmd
{
    my $self = shift;
    my $tclcmd = shift;
    my @args;
    push @args, $$self{'_OPTIONS'}->{'PICKBIN'};
    push @args, $$self{'_OPTIONS'}->{'OPTVM'};
    push @args, $$self{'_OPTIONS'}->{'VM'};
    push @args, $$self{'_OPTIONS'}->{'OPTSILENT'};
    push @args, $$self{'_OPTIONS'}->{'OPTDATA'};
    push @args, $self->_mklogon . $tclcmd . "\r";
    return @args;
}

=head1 CLASS METHODS

=head2 new(%options)

Returns a new C<Pick::TCL> object on success (or C<undef>
on failure). C<%options> is optional and if present may contain
any combination of the following keys:

=over 4

=item HOST

The hostname of the Pick host. If specified, all calls to Pick
will be made via a L<Net::OpenSSH> link to the host of the
supplied name; if not specified, Pick is presumed to be running
on the local host and L<Net::OpenSSH> is not used
(unless L<IPC::Run> is missing and C<HOST> is not specified, in
which case C<HOST> will be set implicitly to C<localhost>).

=item PORT

Only valid if C<HOST> is also set. Specifies the TCP port on
which to connect to sshd(8) on C<HOST>. Defaults to 22.

=item SSHUSER

Only valid if C<HOST> is also given. Specifies the Unix username
to supply to the remote sshd(8) on C<HOST>. Defaults to the
current local username.

=item SSHPASS

Only valid if C<HOST> is also given. Specifies that password
authentication should be used, with the given Unix password.
If C<HOST> is given but C<SSHPASS> is not, public key
authentication is used instead of password authentication.

=item SSHCMD

Only valid if C<HOST> is also given. Specifies the full path
to the ssh(1) binary (in case L<Net::OpenSSH> cannot find
it). If not specified, only F</usr/local/bin/ssh>,
F</usr/bin/ssh> and F</bin/ssh> (in that order) are tried.

=item TIMEOUT

Only valid if C<HOST> is also given. Specifies the maximum
number of seconds for which to wait for a response from a
remote Pick system.

=item VM

The name of the Pick virtual machine to which to connect.
Defaults to C<pick0>.

=item USER

The user name with which to log on to C<VM>. Defaults
to the value of C<SSHUSER> (or to the current Unix username
if C<HOST> is not given).

=item PASS

The password with which to log on to C<VM>, if required.

=item MD

The Pick I<master dictionary> to log onto, if required.

=item MDPASS

Only valid if C<MD> is also given. The password for C<MD>,
if required.

=item PICKBIN

The full path to the Pick binary on C<HOST>. Defaults
to F</usr/bin/ap>.

=item OPTVM

The switch to pass to C<PICKBIN> indicating that the
next parameter is a VM / config-file name. Defaults to
C<-n>.

=item OPTSILENT

The switch to pass to C<PICKBIN> in order to suppress
logon and logoff messages. Defaults to C<-s>.

=item OPTDATA

The switch to pass to C<PICKBIN> indicating that the
next parameter contains "stacked" data for input to
the Pick session. Defaults to C<-d>.

=back

All keys are optional, with the caveats that if C<PORT>,
C<SSHUSER>, C<SSHPASS> and/or C<TIMEOUT> are specified,
for those options to take effect C<HOST> must also be
specified; and likewise C<MDPASS> has no effect without
C<MD>.

=head3 Note:

new() does not actually try to log on to C<VM> -- where
Pick is local, the C<%options> are merely stored in the
C<Pick::TCL> object for later use; on the other hand if
C<HOST> is set (i.e. Pick is remote), new() will establish
a L<Net::OpenSSH> link to C<HOST> or croak() trying.

=cut

sub new
{
    my $class = shift;
    if (ref($class))
    {
        # Reset existing login
        $class->logout();
        $class = ref($class);
    }
    my $self = {};

    # Check/set options
    croak "Pick::TCL constructor options must be a balanced hash"
        unless scalar(@_) % 2 == 0;
    my %options = @_;
    $options{'VM'} = 'pick0' unless defined($options{'VM'});
    unless (defined($options{'USER'}))
    {
        # Default Pick username to remote Unix username if set
        my $u = $options{'SSHUSER'};
        # Otherwise local username
        $u = eval { getpwuid($<); } unless defined($u);
        # Handle platforms without a working getpwuid()
        $u = getlogin() unless defined($u);
    }
    $options{'PICKBIN'} = '/usr/bin/ap' unless defined($options{'PICKBIN'});
    $options{'OPTDATA'} = '-d' unless defined($options{'OPTDATA'});
    $options{'OPTSILENT'} = '-s' unless defined($options{'OPTSILENT'});
    $options{'OPTVM'} = '-n' unless defined($options{'OPTVM'});
    if (defined($options{'TIMEOUT'}))
    {
      $options{'TIMEOUT'} = 0 + $options{'TIMEOUT'};
    } else {
      $options{'TIMEOUT'} = 15;
    }
    if ((not defined($options{'HOST'})) && (not defined($_mods{'local'})))
    {
        # For a local VM, if we're missing IPC::Run, just ssh to the
        # loopback interface instead
        $options{'HOST'} = 'localhost';
    }
    $$self{'_OPTIONS'} = \%options;
    bless $self, $class;

    # Check ssh host reachable
    if ($options{'HOST'})
    {
        return undef unless $self->_bring_up_ssh();
    }

    return $self;
}

=head1 INSTANCE METHODS

=head2 $ap->exec($tclcmd, @input)

Executes the Pick B<TCL> command C<$tclcmd> on the Pick VM associated
with the C<Pick::TCL> object C<$ap> synchronously and returns the output.

In order to cope with the wide variety of terminal settings found on
different Pick systems in the wild (or in some cases, even on different
ports of the same VM, allocated dynamically...), line endings in the
returned output are sanitised: any sequence of one or more control
characters (other than tabs) is treated as a single line ending. As a
consequence, any consecutive line endings are collapsed.

In list context, returns a list of output lines; in scalar context,
returns all output lines joined with line feeds.

The second parameter, C<@input>, is optional. If specified, its
elements, joined with carriage returns, are supplied as input to
the B<TCL> session.

On caller or Pick error (including if Pick or ssh emit anything
on C<stderr>), returns false, sets C<$!> and emits a suitable
message. Likewise on B<ssh> error, except that exit codes 11 and 255
are ignored, in order to support ancient versions of L<sshd(8)>).

croak()s if the call to a local VM fails outright.

=head2 $ap->execraw($tclcmd, @input)

Does the same thing as the exec() method but without any
output sanitisation.

This is useful when dealing with binary output, or when consecutive
line breaks in output are significant. However, in those circumstances
the caller will need to know in advance the pertinent terminal settings
of the port to which it is connecting on the target Pick system and do
its own filtering of extraneous nulls, form feeds, etc. to suit.

=cut

sub execraw
{
    my $self = shift;
    my $func = 'Pick::TCL::execraw()';
    croak "$func is not a class method" unless ref($self);
    if (scalar(@_) == 0)
    {
        carp "$func: cowardly refusing to execute a null TCL command";
        $! = &Errno::ENOMSG;
        return undef;
    }
    my $tclcmd = shift;
    my $input = undef;
    $input = join "\r", @_ if scalar(@_) > 0;
    my @args = $self->_mkpickcmd($tclcmd);

    # Run command
    my ($result, $err) = ("", "");
    $ENV{'PATH'} = "";
    if (defined($$self{'_SSH'}))
    {
        # Remote VM
        unless ($self->_reconnect_ssh())
        {
            carp "$func: $!";
            return undef;
        }
        my $ssh = $$self{'_SSH'};
        ($result, $err) = $$ssh->capture2({stdin_data => $input}, @args);
        my $serr = $$ssh->error();
        if (($serr) && ($serr ne 'child exited with code 11')
            && ($serr ne 'child exited with code 255'))
        {
            carp "$func: fatal error: $serr detail ($! $?): $err";
            carp "$func: stdout was $result";
            $! = &Errno::EBADFD;
            return undef;
        }
    } else {
        # Local VM
        IPC::Run::run(\@args, \$input, \$result, \$err)
            or croak "Broken pipe to Pick: $!";
        if ($err)
        {
            carp "$func: $err";
            $! = &Errno::EBADFD;
            return undef;
        }
    }
    return $result;
}

sub exec
{
    my $self = shift;
    my $func = 'Pick::TCL::exec()';
    croak "$func is not a class method" unless ref($self);
    if (scalar(@_) == 0)
    {
        carp "$func: cowardly refusing to execute a null TCL command";
        $! = &Errno::ENOMSG;
        return wantarray ? () : undef;
    }

    # Get response & sanitise
    my $raw = $self->execraw(@_) or return wantarray ? () : undef;
    my @lines = split /[^\x09\x20-\x7e]+/m, $raw;
    return wantarray ? @lines : join "\n", @lines;
}

=head2 $ap->spawn($tclcmd, @input)

Spawns C<$tclcmd> for asynchronous execution on the Pick VM associated
with C<$ap>.

On success, returns true. On failure, returns C<undef> and sets C<$!>.

Output can be retrieved later with the output() method (see below).

=cut

sub spawn
{
    my $self = shift;
    my $func = 'Pick::TCL::spawn()';
    croak "$func is not a class method" unless ref($self);
    if (scalar(@_) == 0)
    {
        carp "$func: cowardly refusing to execute a null TCL command";
        $! = &Errno::ENOMSG;
        return undef;
    }
    my $tclcmd = shift;
    my $input = undef;
    $input = join "\r", @_ if scalar(@_) > 0;
    my @args = $self->_mkpickcmd($tclcmd);

    # Run command
    $ENV{'PATH'} = "";
    if (defined($$self{'_SSH'}))
    {
        # Remote VM
        unless ($self->_reconnect_ssh())
        {
            carp "$func: $!";
            return undef;
        }
        my $ssh = $$self{'_SSH'};
        my ($socket, $pid) = $$ssh->open2socket({}, @args);
        my $serr = $$ssh->error();
        if ($serr)
        {
            carp "$func: fatal error: $serr: $! $?";
            $! = &Errno::EBADFD;
            return undef;
        }
        if (defined($input))
        {
            while (length($input) > 0)
            {
                my $bytes = syswrite $socket, $input;
                unless (defined($bytes))
                {
                    carp "$func: socket write error: $!";
                    return undef;
                }
                $input = susbtr($input, $bytes);
            }
        }
        $socket->blocking(0);
        my $set = IO::Select->new();
        $set->add($socket);
        $$self{'_SOCKET'} = $socket;
        $$self{'_SOCKSET'} = $set;
        $$self{'_PID'} = $pid;
    } else {
        # Local VM -- IPC::Run cannot detect EOF when spawning asynchronously,
        #             so just fork() & run() instead
        my ($child, $parent);
        unless (socketpair($child, $parent, AF_UNIX, SOCK_STREAM, PF_UNSPEC))
        {
            carp "$func: socketpair(): $!";
            return undef;
        }
        $child->autoflush(1);
        $parent->autoflush(1);

        my $pid = fork();
        unless (defined($pid))
        {
            my $errno = $!;
            carp "$func: fork(): $errno";
            $child->close;
            $parent->close;
            $! = $errno;
            return undef;
        }
        if ($pid)
        {
            # In parent, act just like we would for a remote VM
            $parent->close;
            my $set = IO::Select->new();
            $set->add($child);
            $$self{'_SOCKET'} = $child;
            $$self{'_SOCKSET'} = $set;
            $$self{'_PID'} = $pid;
            return 1;
        }
        # In child, act just like we would for synchronous execution
        $child->close;
        my ($result, $err) = ('', '');
        my $ran = IPC::Run::run(\@args, \$input, \$result, \$err)
          or croak "Broken pipe to Pick: $!";
        croak "$func: $err" if $err;
        print $parent $result;
        exit 0;
    }
    return 1;
}

=head2 $ap->is_ready

Returns true if a previously spawned job has completed. Returns false
but defined if the job is still running. Returns C<undef> if the job
has aborted or if no job was spawned in the first place.

=cut

sub is_ready
{
    my $self = shift;
    my $func = 'Pick::TCL::is_ready()';
    croak "$func is not a class method" unless ref($self);

    # Same approach for local or remote VM
    # -- both use sockets for asyncrhonous execution
    unless (defined($$self{'_SOCKSET'}))
    {
        $! = &Errno::ENOENT;
        return undef;
    }
    my $buf = '';
    my $errflag = 0;
    my $errno = 0;
    while(1)
    {
        my $readable = scalar($$self{'_SOCKSET'}->can_read(0));
        unless (defined($readable))
        {
            return 0 unless defined($$self{'_PARTIAL'});
            $errflag++;
            $errno = $!;
            last;
        }
        $$self{'_PARTIAL'} = '' unless defined($$self{'_PARTIAL'});
        last if $readable == 0;
        my $res = sysread $$self{'_SOCKET'}, $buf, 65536, length($buf);
        unless (defined($res))
        {
            carp "$func: socket error: $!" unless $! == &Errno::EAGAIN;
            $errno = $!;
            $errflag++;
            last;
        }
        last if $res == 0;
    }
    $$self{'_PARTIAL'} .= $buf;
    if (($errflag) && ($errno == 0))
    {
        return 0;
    }
    $$self{'_SOCKSET'}->remove($$self{'_SOCKET'});
    $$self{'_SOCKET'}->close;
    waitpid($$self{'_PID'}, 0);
    delete $$self{'_SOCKSET'};
    delete $$self{'_SOCKET'};
    delete $$self{'_PID'};
    if ($errflag)
    {
      $! = $errno;
      return undef;
    }
    return 1;
}

=head2 $ap->output

=head2 $ap->outputraw

Returns the (raw or cooked) output of a previously spawned job if
it has completed.

Sets C<$!> and returns C<undef> (or, for the cooked form, the empty
list if called in list context) if no job has been spawned.

=cut

sub outputraw
{
    my $self = shift;
    my $func = 'Pick::TCL::outputraw()';
    croak "$func is not a class method" unless ref($self);
    $$self{'_PARTIAL'} = '' unless defined($$self{'_PARTIAL'});

    # Same approach for local or remote VM
    # -- both use sockets for asyncrhonous execution
    $! = &Errno::ENOENT unless defined($$self{'_PARTIAL'});
    return $$self{'_PARTIAL'};
}

sub output
{
    my $self = shift;
    my $func = 'Pick::TCL::output()';
    croak "$func is not a class method" unless ref($self);

    # Get response & sanitise
    my $raw = $self->outputraw;
    my $errno = $!;
    if (defined($raw))
    {
        my @lines = split /[^\x09\x20-\x7e]+/m, $raw;
        return wantarray ? @lines : join "\n", @lines;
    }
    $! = $errno;
    return wantarray ? () : undef;
}

=head2 $ap->partialoutput

=head2 $ap->partialoutputraw

Returns the (raw or cooked) output of a previously spawned job
that may not yet have completed.

Returns C<undef> (or, for the cooked form, the empty list if
called in list context) if a previously spawned job does not
have any output yet or no job has been spawned.

=cut

sub partialoutputraw
{
    my $self = shift;
    my $func = 'Pick::TCL::partialoutputraw()';
    croak "$func is not a class method" unless ref($self);
    return $$self{'_PARTIAL'};
}

sub partialoutput
{
    my $self = shift;
    my $func = 'Pick::TCL::partialoutput()';
    croak "$func is not a class method" unless ref($self);
    my $raw = $self->partialoutputraw;
    if (defined($raw))
    {
        my @lines = split /[^\x09\x20-\x7e]+/m, $raw;
        return wantarray ? @lines : join "\n", @lines;
    }
    return wantarray ? () : undef;
}
 

=head2 $ap->logout

Destroys the connection. Not required to be called explicitly before
exit; does nothing when Pick is local.

=cut

sub logout
{
    my $self = shift;
    croak "Pick::TCL::logout() is not a class method" unless ref($self);
    if (ref($$self{'_SSH'}))
    {
        my $ssh = $$self{'_SSH'};
        $$ssh->DESTROY();
        delete $$self{'_SSH'};
    }
}

=head1 CAVEATS

=head2 Escaping metacharacters

The commands sent to exec() and execraw() are always interpreted by
the Pick B<TCL> interpreter -- so be sure to escape anything that needs
escaping in B<TCL> before feeding it to exec() or execraw() (no
different from running native).

If C<HOST> is set, there's also the remote login shell to consider.
C<Pick::TCL> uses L<Net::OpenSSH> (which does auto-escaping of most
metacharacters) for the remote link, so this should not cause problems
either, so long as the remote user's login shell is set to the Bourne
shell, or at least something that's sufficiently compatible with it.

Note especially that when C<HOST> is set, parentheses around options
to B<TCL> commands must be balanced (even though the Pick B<TCL>
interpreter does not normally require that), as unbalanced parentheses
will likely confuse the remote shell.

=head2 Parallel asynchronous commands

Each C<Pick::TCL> object can only spawn() or exec() one B<TCL>
command at a time. If the caller needs to spawn() multiple B<TCL>
commands in parallel (or exec() a B<TCL> command while waiting
for an asynchronous one to complete), it should instantiate a
separate C<Pick::TCL> object for each B<TCL> command.

=head2 Pick flavours

C<Pick::TCL> has only been tested with D3/Linux as the target Pick
platform (setting C<PICKBIN> to F</usr/bin/d3>). It should also work
unmodified with targets running D3/AIX, D3/SCO or legacy Advanced
Pick systems (on any host OS on which an sshd can be found or built).

No attempt has been made thus far to cater specifically to other /
licensee / "Pick-like" target platforms, although the configurability
provided through C<%OPTIONS> may be sufficient to work with some.

=head1 AUTHOR

Jack Burton, C<< <jack@saosce.com.au> >>

=head1 BUGS

Please report any bugs or feature requests
to C<bug-pick-tcl at rt.cpan.org>, or through the web interface
at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pick-TCL>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Thanks to Jemalong Wool who provided funding for initial development.

=head1 LICENSE AND COPYRIGHT

Copyright 2013, 2014 Jack Burton.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Pick::TCL
