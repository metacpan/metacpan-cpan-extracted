package Sys::Cmd;
use strict;
use warnings;
use 5.006;
use Carp;
use Exporter::Tidy all => [qw/spawn run runx/];
use File::Spec;
use IO::Handle;
use Log::Any qw/$log/;
use Sys::Cmd_CI has => {
    cmd => {
        isa => sub {
            ref $_[0] eq 'ARRAY' || Carp::confess "cmd must be ARRAYREF";
            @{ $_[0] }           || Carp::confess "Missing cmd elements";
            if ( grep { !defined $_ } @{ $_[0] } ) {
                Carp::confess 'cmd array cannot contain undef elements';
            }
            $_[0];
        },
        required => 1,
    },
    _code => {
        default => sub {
            my $c = $_[0]->cmd->[0];
            ref($c) eq 'CODE' ? $c : undef;
        },
    },
    encoding => {
        default => sub { ':utf8' },
    },
    env => {
        isa => sub {
            ref $_[0] eq 'HASH' || Carp::confess "env must be HASHREF";
            $_[0];
        },
    },
    dir   => {},
    input => {},
    pid   => {
        is       => 'rw',
        init_arg => undef,
    },
    stdin => {
        is       => 'rw',
        init_arg => undef,
        default  => sub { IO::Handle->new },
    },
    stdout => {
        is       => 'rw',
        init_arg => undef,
        default  => sub { IO::Handle->new },
    },
    stderr => {
        is       => 'rw',
        init_arg => undef,
        default  => sub { IO::Handle->new },
    },
    on_exit => {
        is => 'rw',
    },
    exit => {
        is       => 'rw',
        init_arg => undef,
    },
    signal => {
        is       => 'rw',
        init_arg => undef,
    },
    core => {
        is       => 'rw',
        init_arg => undef,
    },
};

our $VERSION = '0.99.0';
our $CONFESS;

sub run {
    my $proc = spawn(@_);
    my @out  = $proc->stdout->getlines;
    my @err  = $proc->stderr->getlines;

    $proc->wait_child;

    if ( $proc->exit != 0 ) {
        Carp::confess(
            join( '', @err ) . 'Command exited with value ' . $proc->exit )
          if $CONFESS;
        Carp::croak(
            join( '', @err ) . 'Command exited with value ' . $proc->exit );
    }

    warn @err if @err;

    if (wantarray) {
        return @out;
    }
    else {
        return join( '', @out );
    }
}

sub runx {
    my $proc = spawn(@_);
    my @out  = $proc->stdout->getlines;
    my @err  = $proc->stderr->getlines;

    $proc->wait_child;

    if ( $proc->exit != 0 ) {
        Carp::confess(
            join( '', @err ) . 'Command exited with value ' . $proc->exit )
          if $CONFESS;
        Carp::croak(
            join( '', @err ) . 'Command exited with value ' . $proc->exit );
    }

    if (wantarray) {
        return @out, @err;
    }
    else {
        return join( '', @out, @err );
    }
}

sub spawn {
    my ( @cmd, @opts );
    map {
        if ( ref($_) eq 'HASH' ) {
            push( @opts, $_ );
        }
        else {
            push( @cmd, $_ );
        }
    } @_;

    Carp::confess '$cmd must be defined' unless @cmd && defined $cmd[0];
    Carp::confess __PACKAGE__ . ": only a single hashref allowed" if @opts > 1;

    unless ( 'CODE' eq ref $cmd[0] ) {

        if ( File::Spec->splitdir( $cmd[0] ) == 1 ) {
            require File::Which;
            $cmd[0] = File::Which::which( $cmd[0] )
              || Carp::confess 'command not found: ' . $cmd[0];
        }

        if ( !-x $cmd[0] ) {
            Carp::confess 'command not executable: ' . $cmd[0];
        }
    }

    $opts[0]->{cmd} = \@cmd;
    Sys::Cmd->new( %{ $opts[0] } );
}

sub BUILD {
    my $self = shift;
    my $dir  = $self->dir;

    require File::chdir            if $dir;
    local $File::chdir::CWD = $dir if $dir;

    local %ENV = %ENV;

    if ( defined( my $x = $self->env ) ) {
        while ( my ( $key, $val ) = each %$x ) {
            if ( defined $val ) {
                $ENV{$key} = $val;
            }
            else {
                delete $ENV{$key};
            }
        }
    }

    $self->_code ? $self->_fork : $self->_spawn;
    $self->stdin->autoflush(1);

    my $enc = $self->encoding;
    binmode( $self->stdin,  $enc ) or warn "binmode stdin: $!";
    binmode( $self->stdout, $enc ) or warn "binmode stdout: $!";
    binmode( $self->stderr, $enc ) or warn "binmode stderr: $!";

    $log->debugf( '[%d][%s] %s', $self->pid, $enc, scalar $self->cmdline );

    # some input was provided
    if ( defined( my $input = $self->input ) ) {
        local $SIG{PIPE} =
          sub { warn "Broken pipe when writing to:" . $self->cmdline };

        $self->stdin->print($input) if length $input;

        $self->stdin->close;
    }

    return;
}

sub _spawn {
    my $self = shift;
    require Proc::FastSpawn;

    # Get new handles to descriptors 0,1,2
    my $fd0 = IO::Handle->new_from_fd( 0, 'r' );
    my $fd1 = IO::Handle->new_from_fd( 1, 'w' );
    my $fd2 = IO::Handle->new_from_fd( 2, 'w' );

    # Backup the original 0,1,2 file descriptors
    open my $old_fd0, '<&', 0;
    open my $old_fd1, '>&', 1;
    open my $old_fd2, '>&', 2;

    # Pipe our filehandles to new child filehandles
    pipe( my $child_in,  $self->stdin )  || die "pipe: $!";
    pipe( $self->stdout, my $child_out ) || die "pipe: $!";
    pipe( $self->stderr, my $child_err ) || die "pipe: $!";

    # Make sure that 0,1,2 are inherited (probably are anyway)
    Proc::FastSpawn::fd_inherit( $_, 1 ) for 0, 1, 2;

    # But don't inherit the rest
    Proc::FastSpawn::fd_inherit( fileno($_), 0 )
      for $old_fd0, $old_fd1, $old_fd2, $child_in, $child_out, $child_err,
      $self->stdin, $self->stdout, $self->stderr;

    eval {
        # Re-open 0,1,2 by duping the child pipe ends
        open $fd0, '<&', fileno($child_in);
        open $fd1, '>&', fileno($child_out);
        open $fd2, '>&', fileno($child_err);

        # Kick off the new process
        $self->pid(
            Proc::FastSpawn::spawn(
                $self->cmd->[0],
                $self->cmd,
                [
                    map { $_ . '=' . ( defined $ENV{$_} ? $ENV{$_} : '' ) }
                      keys %ENV
                ]
            )
        );
    };
    my $err = $@;

    # Restore our local 0,1,2 to the originals
    open $fd0, '<&', fileno($old_fd0);
    open $fd1, '>&', fileno($old_fd1);
    open $fd2, '>&', fileno($old_fd2);

    # Complain if the spawn failed for some reason
    Carp::croak $err if $err;
    Carp::croak 'Unable to spawn child' unless defined $self->pid;

    # Parent doesn't need to see the child or backup descriptors anymore
    close($_)
      for $old_fd0, $old_fd1, $old_fd2, $child_in, $child_out, $child_err;

    return;
}

sub _fork {
    my $self = shift;

    pipe( my $child_in,  $self->stdin )  || die "pipe: $!";
    pipe( $self->stdout, my $child_out ) || die "pipe: $!";
    pipe( $self->stderr, my $child_err ) || die "pipe: $!";

    $self->pid( fork() );
    if ( !defined $self->pid ) {
        my $why = $!;
        die "fork: $why";
    }

    if ( $self->pid > 0 ) {    # parent
        close $child_in;
        close $child_out;
        close $child_err;
        return;
    }

    # Child
    $self->exit(0);            # stop DESTROY() from trying to reap
    $child_err->autoflush(1);

    my $enc = $self->encoding;

    foreach my $quad (
        [ \*STDIN,  '<&=' . $enc, fileno($child_in),  0 ],
        [ \*STDOUT, '>&=' . $enc, fileno($child_out), 1 ],
        [ \*STDERR, '>&=' . $enc, fileno($child_err), 1 ]
      )
    {
        my ( $fh, $mode, $fileno, $autoflush ) = @$quad;

        open( $fh, $mode, $fileno )
          or print $child_err sprintf "[%d] open %s, %s: %s\n", $self->pid,
          $fh, $mode, $!;

        $fh->autoflush(1) if $autoflush;
    }

    close $self->stdin;
    close $self->stdout;
    close $self->stderr;
    close $child_in;
    close $child_out;
    close $child_err;

    if ( my $code = $self->_code ) {
        $code->();
        _exit(0);
    }

    exec( @{ $self->cmd } );
    die "exec: $!";
}

sub cmdline {
    my $self = shift;
    if (wantarray) {
        return @{ $self->cmd };
    }
    else {
        return join( ' ', @{ $self->cmd } );
    }
}

sub wait_child {
    my $self = shift;

    return unless defined $self->pid;
    return $self->exit if defined $self->exit;

    local $?;
    local $!;

    my $pid = waitpid $self->pid, 0;
    my $ret = $?;

    if ( $pid != $self->pid ) {
        warn sprintf( 'Could not reap child process %d (waitpid returned: %d)',
            $self->pid, $pid );
        $pid = $self->pid;
        $ret = 0;
    }

    if ( $ret == -1 ) {

        # So waitpid returned a PID but then sets $? to this
        # strange value? (Strange in that tests randomly show it to
        # be invalid.) Most likely a perl bug; I think that waitpid
        # got interrupted and when it restarts/resumes the status
        # is lost.
        #
        # See http://www.perlmonks.org/?node_id=641620 for a
        # possibly related discussion.
        #
        # However, since I localised $? and $! above I haven't seen
        # this problem again, so I hope that is a good enough work
        # around. Lets warn any way so that we know when something
        # dodgy is going on.
        warn __PACKAGE__
          . ' received invalid child exit status for pid '
          . $pid
          . ' Setting to 0';
        $ret = 0;

    }

    $log->debugf(
        '(PID %d) exit: %d signal: %d core: %d',
        $pid,
        $self->exit( $ret >> 8 ),
        $self->signal( $ret & 127 ),
        $self->core( $ret & 128 )
    );

    if ( my $subref = $self->on_exit ) {
        $subref->($self);
    }

    return $self->exit;
}

sub close {
    my $self = shift;

    foreach my $h (qw/stdin stdout stderr/) {

        # may not be defined during global destruction
        my $fh = $self->$h or next;
        $fh->opened        or next;
        if ( $h eq 'stderr' ) {
            warn sprintf( '[%d] uncollected stderr: %s', $self->pid, $_ )
              for $self->stderr->getlines;
        }
        $fh->close || Carp::carp "error closing $h: $!";
    }

    return;
}

sub DESTROY {
    my $self = shift;
    $self->close;
    $self->wait_child;
    return;
}

1;

__END__

=head1 NAME

Sys::Cmd - run a system command or spawn a system processes

=head1 VERSION

0.99.0 (2022-10-05)

=head1 SYNOPSIS

    use Sys::Cmd qw/run spawn/;

    # Get command output, raise exception on failure:
    $output = run(@cmd);

    # Feed command some input, get output as lines,
    # raise exception on failure:
    @output = run( @cmd, { input => 'feedme' } );

    # Spawn and interact with a process somewhere else:
    $proc = spawn(
        @cmd,
        {
            dir      => '/',
            encoding => 'encoding(iso-8859-3)'
        },
    );

    while ( my $line = $proc->stdout->getline ) {
        $proc->stdin->print("thanks\n");
    }

    my @errors = $proc->stderr->getlines;

    $proc->close();         # Finished talking to file handles
    $proc->wait_child();    # Cleanup

    # read exit information
    $proc->exit();          # exit status
    $proc->signal();        # signal
    $proc->core();          # core dumped? (boolean)

=head1 DESCRIPTION

B<Sys::Cmd> lets you run system commands and capture their output, or
spawn and interact with a system process through its C<STDIN>,
C<STDOUT>, and C<STDERR> file handles. The following functions are
exported on demand by this module:

=over 4

=item run( @cmd, [\%opt] ) => $output | @output

Execute C<@cmd> and return what the command sent to its C<STDOUT>,
raising an exception in the event of error. In array context returns a
list instead of a plain string.

The first element of C<@cmd> determines what/how things are run:

=over

=item * If it is a relative file name it is executed directly using
L<Proc::Spawn>.

=item * If it is a CODE reference (subroutine) B<Sys::Cmd> forks before
running it in the child process. This is not supported on Win32.

=item * Everything else is looked up using L<File::Which> and then
executed with L<Proc::Spawn>.

=back

The command input and environment can be modified with an optional
hashref containing the following key/values:

=over 4

=item dir

The working directory the command will be run in.

=item encoding

An string value identifying the encoding of the input/output
file-handles. Defaults to 'utf8'.

=item env

A hashref containing key/values to be added to the current environment
at run-time. If a key has an undefined value then the key is removed
from the environment altogether.

=item input

A string which is fed to the command via its standard input, which is
then closed.

=back

=item runx( @cmd, [\%opt] ) => $outerrput | @outerrput

The same as the C<run> function but with the command's C<STDERR> output
appended to the C<STDOUT> output.

=item spawn( @cmd, [\%opt] ) => Sys::Cmd

Return a B<Sys::Cmd> object (documented below) representing the process
running @cmd, with attributes set according to the optional \%opt
hashref.  The first element of C<@cmd> determines the execution method
just like the C<run()> function.

=back

B<Sys::Cmd> objects can of course be created using the standard C<new>
constructor if you prefer that to the C<spawn> function:

    $proc = Sys::Cmd->new(
        cmd => \@cmd,
        dir => '/',
        env => { SOME => 'VALUE' },
        enc => 'iso-8859-3',
        input => 'feedme',
        on_exit => sub {
            my $proc = shift;
            print $proc->pid .' exited with '. $proc->exit;
        },
    );

Note that B<Sys::Cmd> objects created this way will not lookup the
command using L<File::Which> the way the C<run>, C<runx> and C<spawn>
functions do. CODE references in C<$cmd[0]> are however still
recognized and forked off.

B<Sys::Cmd> uses L<Log::Any> C<debug> calls for logging purposes. An
easy way to see the output is to add C<use Log::Any::Adapter 'Stdout'>
in your program.

=head1 CONSTRUCTOR

=over 4

=item new(%args) => Sys::Cmd

Spawns a process based on %args. %args must contain at least a C<cmd>
value, and optionally C<encoding>, C<env>, C<dir> and C<input> values
as defined as attributes below.

If an C<on_exit> subref argument is provided it will be called by the
C<wait_child> method, which can either be called manually or will be
automatically called when the object is destroyed.

=back

=head1 ATTRIBUTES

All attributes are read-only.

=over 4

=item cmd

An array ref containing the command or CODE reference (UNIX only) and
its arguments.

=item dir

The working directory the command will be run in.

=item encoding

An string value identifying the encoding of the input/output
file-handles. Defaults to 'utf8'.

=item env

A hashref containing key/values to be added to the current environment
at run-time. If a key has an undefined value then the key is removed
from the environment altogether.

=item input

A string which is fed to the command via its standard input, which is
then closed. This is a shortcut for printing to, and closing the
command's I<stdin> file-handle. An empty string will close the
command's standard input without writing to it. On some systems, some
commands may close standard input on startup, which will cause a
SIGPIPE when trying to write to it for which B<Sys::Cmd> will warn.

=item pid

The command's process ID.

=item stdin

The command's I<STDIN> file handle, based on L<IO::Handle> so you can
call print() etc methods on it. Autoflush is automatically enabled on
this handle.

=item stdout

The command's I<STDOUT> file handle, based on L<IO::Handle> so you can
call getline() etc methods on it.

=item stderr

The command's I<STDERR> file handle, based on L<IO::Handle> so you can
call getline() etc methods on it.

=item exit

The command's exit value, shifted by 8 (see "perldoc -f system"). Set
by C<wait_child()>.

=item signal

The signal number (if any) that terminated the command, bitwise-added
with 127 (see "perldoc -f system"). Set by C<wait_child()>.

=item core

A boolean indicating the process core was dumped. Set by
C<wait_child()>.

=back

=head1 METHODS

=over 4

=item cmdline => @list | $str

In array context returns a list of the command and its arguments.  In
scalar context returns a string of the command and its arguments joined
together by spaces.

=item close()

Close all filehandles to the child process. Note that file handles will
automaticaly be closed when the B<Sys::Cmd> object is destroyed.
Annoyingly, this means that in the following example C<$fh> will be
closed when you tried to use it:

    my $fh = Sys::Cmd->new( %args )->stdout;

So you have to keep track of the Sys::Cmd object manually.

=item wait_child() -> $exit_value

Wait for the child to exit using
L<waitpid|http://perldoc.perl.org/functions/waitpid.html>, collect the
exit status and return it. This method sets the I<exit>, I<signal> and
I<core> attributes and will also be called automatically when the
B<Sys::Cmd> object is destroyed.

=back

=head1 SEE ALSO

L<Sys::Cmd::Template>

=head1 ALTERNATIVES

L<AnyEvent::Run>, L<AnyEvent::Util>, L<Argv>, L<Capture::Tiny>,
L<Child>, L<Forks::Super>, L<IO::Pipe>, L<IPC::Capture>, L<IPC::Cmd>,
L<IPC::Command::Multiplex>, L<IPC::Exe>, L<IPC::Open3>,
L<IPC::Open3::Simple>, L<IPC::Run>, L<IPC::Run3>,
L<IPC::RunSession::Simple>, L<IPC::ShellCmd>, L<IPC::System::Simple>,
L<POE::Pipe::TwoWay>, L<Proc::Background>, L<Proc::Fork>,
L<Proc::Spawn>, L<Spawn::Safe>, L<System::Command>

=head1 SUPPORT

This distribution is managed via github:

    https://github.com/mlawren/sys-cmd/tree/devel

This distribution follows the semantic versioning model:

    http://semver.org/

Code is tidied up on Git commit using githook-perltidy:

    http://github.com/mlawren/githook-perltidy

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>, based heavily on
L<Git::Repository::Command> by Philippe Bruhat (BooK).

=head1 COPYRIGHT AND LICENSE

Copyright 2011-2021 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

