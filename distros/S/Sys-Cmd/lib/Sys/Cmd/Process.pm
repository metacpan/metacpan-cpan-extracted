package Sys::Cmd::Process;
use v5.18;
our $VERSION = 'v0.986.0';
use warnings;
use parent 'Sys::Cmd';
use Encode 'encode';
use IO::Handle;
use Log::Any qw/$log/;
use Proc::FastSpawn;
### START Class::Inline ### v0.0.1 Tue Dec  2 10:53:28 2025
require Carp;
our ( @_CLASS, $_FIELDS, %_NEW );

sub new {
    my $class = shift;
    my $CLASS = ref $class || $class;
    $_NEW{$CLASS} //= do {
        my ( %seen, @new, @build );
        my @possible = ($CLASS);
        while (@possible) {
            my $c = shift @possible;
            no strict 'refs';
            push @new,   $c . '::_NEW'  if exists &{ $c . '::_NEW' };
            push @build, $c . '::BUILD' if exists &{ $c . '::BUILD' };
            $seen{$c}++;
            if ( exists &{ $c . '::DOES' } ) {
                push @possible, grep { not $seen{$_}++ } $c->DOES('*');
            }
            push @possible, grep { not $seen{$_}++ } @{ $c . '::ISA' };
        }
        [ [ reverse(@new) ], [ reverse(@build) ] ];
    };
    my $self = { @_ ? @_ > 1 ? @_ : %{ $_[0] } : () };
    bless $self, $CLASS;
    my $attrs = { map { ( $_ => 1 ) } keys %$self };
    map { $self->$_($attrs) } @{ $_NEW{$CLASS}->[0] };
    {
        local $Carp::CarpLevel = 3;
        Carp::carp("Sys::Cmd::Process: unexpected argument '$_'")
          for keys %$attrs
    }
    map { $self->$_ } @{ $_NEW{$CLASS}->[1] };
    $self;
}

sub _NEW {
    CORE::state $fix_FIELDS = do {
        $_FIELDS = { @_CLASS > 1 ? @_CLASS : %{ $_CLASS[0] } };
        $_FIELDS = $_FIELDS->{'FIELDS'} if exists $_FIELDS->{'FIELDS'};
    };
    map { delete $_[1]->{$_} } '_coderef';
}

sub __RO {
    my ( undef, undef, undef, $sub ) = caller(1);
    Carp::confess("attribute $sub is read-only");
}

sub _coderef {
    __RO() if @_ > 1;
    $_[0]{'_coderef'} //= $_FIELDS->{'_coderef'}->{'default'}->( $_[0] );
}

sub core {
    if ( @_ > 1 ) { $_[0]{'core'} = $_[1] }
    $_[0]{'core'} //= $_FIELDS->{'core'}->{'default'}->( $_[0] );
}

sub exit {
    if ( @_ > 1 ) { $_[0]{'exit'} = $_[1] }
    $_[0]{'exit'} //= $_FIELDS->{'exit'}->{'default'}->( $_[0] );
}
sub has_exit { exists $_[0]{'exit'} }

sub pid {
    if ( @_ > 1 ) { $_[0]{'pid'} = $_[1] }
    $_[0]{'pid'} // undef;
}

sub signal {
    if ( @_ > 1 ) { $_[0]{'signal'} = $_[1] }
    $_[0]{'signal'} //= $_FIELDS->{'signal'}->{'default'}->( $_[0] );
}

sub stderr {
    if ( @_ > 1 ) { $_[0]{'stderr'} = $_[1] }
    $_[0]{'stderr'} //= $_FIELDS->{'stderr'}->{'default'}->( $_[0] );
}

sub stdin {
    if ( @_ > 1 ) { $_[0]{'stdin'} = $_[1] }
    $_[0]{'stdin'} //= $_FIELDS->{'stdin'}->{'default'}->( $_[0] );
}

sub stdout {
    if ( @_ > 1 ) { $_[0]{'stdout'} = $_[1] }
    $_[0]{'stdout'} //= $_FIELDS->{'stdout'}->{'default'}->( $_[0] );
}

sub _dump {
    my $self = shift;
    my $x    = do {
        require Data::Dumper;
        no warnings 'once';
        local $Data::Dumper::Indent   = 1;
        local $Data::Dumper::Maxdepth = ( shift // 2 );
        local $Data::Dumper::Sortkeys = 1;
        Data::Dumper::Dumper($self);
    };
    $x =~ s/.*?{/{/;
    $x =~ s/}.*?\n$/}/;
    my $i = 0;
    my @list;
    do { @list = caller( $i++ ) } until $list[3] eq __PACKAGE__ . '::_dump';
    wantarray
      ? warn "$self $x at $list[1]:$list[2]\n"
      : "$self $x at $list[1]:$list[2]\n";
}
@_CLASS = grep 1,    ### END Class::Inline ###
  {
    _coderef => {
        default => sub {
            my $c = $_[0]->cmd->[0];
            ref($c) eq 'CODE' ? $c : undef;
        },
    },
    pid => {
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
    exit => {
        is        => 'rw',
        init_arg  => undef,
        predicate => 1,
        default   => sub {
            Sys::Cmd::_croak(
                'Process status values invalid before wait_child()');
        },
    },
    signal => {
        is       => 'rw',
        init_arg => undef,
        default  => sub {
            Sys::Cmd::_croak(
                'Process status values invalid before wait_child()');
        },
    },
    core => {
        is       => 'rw',
        init_arg => undef,
        default  => sub {
            Sys::Cmd::_croak(
                'Process status values invalid before wait_child()');
        },
    },
  };

sub _spawn {
    my $self = shift;

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

    my $locale = $self->encoding;
    my $cmd_as_octets =
      [ map { encode( $locale => $_, Encode::FB_CROAK | Encode::LEAVE_SRC ) }
          @{ $self->cmd } ];

    eval {
        # Re-open 0,1,2 by duping the child pipe ends
        open $fd0, '<&', fileno($child_in);
        open $fd1, '>&', fileno($child_out);
        open $fd2, '>&', fileno($child_err);

        # Kick off the new process
        $self->pid(
            Proc::FastSpawn::spawn(
                $cmd_as_octets->[0],
                $cmd_as_octets,
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
    Sys::Cmd::_croak($err) if $err;
    Sys::Cmd::_croak('Unable to spawn child') unless defined $self->pid;

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

    my $enc = ':encoding(' . $self->encoding . ')';

    foreach my $quad (
        [ \*STDIN,  '<&=', fileno($child_in),  0 ],
        [ \*STDOUT, '>&=', fileno($child_out), 1 ],
        [ \*STDERR, '>&=', fileno($child_err), 1 ]
      )
    {
        my ( $fh, $mode, $fileno, $autoflush ) = @$quad;

        open( $fh, $mode, $fileno )
          or print $child_err sprintf "[%d] open %s, %s: %s\n", $self->pid,
          $fh, $mode, $!;

        binmode $fh, $enc or print $child_err $fh . 'binmode: ' . $!;
        $fh->autoflush(1) if $autoflush;
    }

    close $self->stdin;
    close $self->stdout;
    close $self->stderr;
    close $child_in;
    close $child_out;
    close $child_err;

    if ( my $code = $self->_coderef ) {
        $code->();
        _exit(0);
    }

    exec( @{ $self->cmd } );
    die "exec: $!";
}

sub BUILD {
    my $self = shift;

    Carp::carp '"out" attribute ignored' if defined $self->out;
    Carp::carp '"err" attribute ignored' if defined $self->err;

    {
        my $dir = $self->dir;
        require File::chdir if $dir;

        no warnings 'once';
        local $File::chdir::CWD = $dir if $dir;

        if ( my $mock = $self->mock ) {
            my $ref = $mock->($self);
            my $out = shift @$ref // '';
            my $err = shift @$ref // '';
            open my $outfd, '<', \$out || die "open \$out: $!";
            open my $errfd, '<', \$err || die "open \$err: $!";
            $self->pid( -$$ );
            $self->stdout($outfd);
            $self->stderr($errfd);
            $self->mock( sub { $ref } );
            $log->debugf(
                '[%d] %s [%s]',        $self->pid,
                scalar $self->cmdline, $self->encoding
            );
            return;
        }

        local %ENV = $self->_env_merged;
        $self->_coderef ? $self->_fork : $self->_spawn;
    }

    $self->stdin->autoflush(1);

    my $enc = ':encoding(' . $self->encoding . ')';
    binmode( $self->stdin,  $enc ) or warn "binmode stdin: $!";
    binmode( $self->stdout, $enc ) or warn "binmode stdout: $!";
    binmode( $self->stderr, $enc ) or warn "binmode stderr: $!";

    $log->debugf( '[%d] %s [%s]', $self->pid, scalar $self->cmdline, $enc );

    # some input was provided
    if ( defined( my $input = $self->input ) ) {
        local $SIG{PIPE} =
          sub { warn "Broken pipe when writing to:" . $self->cmdline };

        if ( 'ARRAY' eq ref $input && @$input ) {
            $self->stdin->print(@$input);
        }
        elsif ( length $input ) {
            $self->stdin->print($input);
        }

        $self->stdin->close;
    }

    return;
}

sub _env_merged {
    my $self = shift;
    my %env  = %ENV;

    if ( defined( my $x = $self->env ) ) {
        my $locale = $self->encoding;
        while ( my ( $key, $val ) = each %$x ) {
            my $keybytes = encode( $locale, $key, Encode::FB_CROAK );
            if ( defined $val ) {
                $env{$keybytes} = encode( $locale, $val, Encode::FB_CROAK );
            }
            else {
                delete $env{$keybytes};
            }
        }
    }

    wantarray ? %env : \%env;
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

sub close {
    my $self = shift;

    foreach my $h (qw/stdin stdout stderr/) {

        # may not be defined during global destruction
        my $fh = $self->$h or next;
        $fh->opened        or next;
        if ( $h eq 'stderr' ) {
            warn sprintf( '[%d] uncollected stderr: %s', $self->pid // -1, $_ )
              for $self->stderr->getlines;
        }
        $fh->close || Carp::carp "error closing $h: $!";
    }

    return;
}

sub wait_child {
    my $self = shift;
    my $pid  = $self->pid // return;
    return $self->exit if $self->has_exit;

    if ( $self->mock ) {
        my ( $exit, $signal, $core ) = @{ $self->mock->() };
        $self->exit( $exit     // 0 );
        $self->signal( $signal // 0 );
        $self->core( $core     // 0 );
    }
    elsif ( $pid > 0 ) {

        local $?;
        local $!;

        my $pid = waitpid $self->pid, 0;
        my $ret = $?;

        if ( $pid != $self->pid ) {
            warn
              sprintf( 'Could not reap child process %d (waitpid returned: %d)',
                $self->pid, $pid );
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
              . $self->pid
              . ' Setting to 0';
            $ret = 0;

        }

        $self->exit( $ret >> 8 );
        $self->signal( $ret & 127 );
        $self->core( $ret & 128 );
    }

    # $pid <= 0, so... bad execution by spawn
    else {
        $self->exit(-1);
        $self->signal(0);
        $self->core(0);
    }

    if ( $self->signal != 0 ) {
        $log->infof(
            '[%d] %s [signal: %d core: %d]',
            $self->pid,    scalar $self->cmdline,
            $self->signal, $self->core
        );
    }
    else {
        $log->infof(
            '[%d] %s [exit: %d]',  $self->pid,
            scalar $self->cmdline, $self->exit,
        );
    }

    if ( my $subref = $self->on_exit ) {
        $subref->($self);
    }

    $self->exit;
}

sub DESTROY {
    my $self = shift;
    $self->close;
    $self->wait_child;
}

1;

__END__

=head1 NAME

Sys::Cmd::Process - spawn and interact with a process

=head1 VERSION

v0.986.0 (2025-12-04)

=head1 SYNOPSIS

    use Sys::Cmd::Process;

    my $proc = Sys::Cmd::Process->new(
        cmd   => [ '/usr/bin/cat', '--number' ],
        dir   => '/',
        input => "x\ny\nz\n",
    );

    while ( my $line = $proc->stdout->getline ) {
        print $line;
    }

    my @errors = $proc->stderr->getlines;
    $proc->wait_child();    # Cleanup

    # read process termination information
    $proc->exit();          # exit status
    $proc->signal();        # signal
    $proc->core();          # core dumped? (boolean)

=head1 DESCRIPTION

B<Sys::Cmd::Process> is a wrapper around L<Proc::FastSpawn> for
creating and interacting with system commands. It provides, in the
author's opinion, a more efficient and powerful interface than Perl's
built-in "system", "fork" and "exec" functions.

Most users will probably prefer to start B<Sys::Cmd::Process> objects
through the utility functions exported by L<Sys::Cmd>.

=head1 CONSTRUCTOR

The C<new()> constructor takes the following arguments (key =>
default), either as a list or in a single HASH reference:

=over

=item cmd

An ARRAY reference where the first element contains:

=over

=item * The path to an executable which will be executed by
L<Proc::FastSpawn> with the remaining elements; or

=item * A subroutine reference which will be run after forking a new
process, passed the remaining elements.

=back

=item dir => $PWD

The working directory to run in.

=item encoding => $Encode::Locale::ENCODING_LOCALE

A string value identifying the encoding that applies to input/output
file-handles, command arguments, and environment variables.  Defaults
to the 'locale' alias from L<Encode::Locale>.

=item env

A hashref containing key/values to be added to the current environment
at run-time. If a key has an undefined value then the key is removed
from the environment altogether.

=item input

A scalar (string) or ARRAY reference containing strings, which are fed
to the command via its standard input, which is then closed.  An empty
value ('') or empty list will close the command's standard input
without printing. An undefined value (the default) leaves the handle
open.

Some commands close their standard input on startup, which causes a
SIGPIPE when trying to write to it, for which B<Sys::Cmd::Process> will
warn.

=begin comment

=item mock

A subroutine reference which runs instead of the actual command, which
provides the fake outputs and exit values. See L</"MOCKING"> below for
details.

=end comment

=item on_exit

A subref to be called at the time that process termination is detected.

=back

=head1 ATTRIBUTES / METHODS

=over

=item cmdline() -> @list | $scalar

In array context returns a list of the command and its arguments.  In
scalar context returns a string of the command and its arguments joined
together by spaces.

=item pid() -> $int

The command's process ID.

=item stdin() -> IO::Handle

The command's I<STDIN> file handle, based on L<IO::Handle> so you can
call print() etc methods on it. Autoflush is automatically enabled on
this handle.

=item stdout() -> IO::Handle

The command's I<STDOUT> file handle, based on L<IO::Handle> so you can
call getline() etc methods on it.

=item stderr() -> IO::Handle

The command's I<STDERR> file handle, based on L<IO::Handle> so you can
call getline() etc methods on it.

=item close()

Close all filehandles to the child process.

This is called automatically when the B<Sys::Cmd::Process> object is
destroyed if it has not already run.

Annoyingly, this means that in the following example C<$fh> will be
closed when you tried to use it:

    my $fh = Sys::Cmd::Process->new( %args )->stdout;

So you have to keep track of the Sys::Cmd::Process object manually.

=item wait_child() -> $exit_value

Wait for the child to exit using
L<waitpid|http://perldoc.perl.org/functions/waitpid.html>, collect the
exit status and return it.

This is called automatically when the B<Sys::Cmd::Process> object is
destroyed if it has not already run.

=back

After C<wait_child> has been called the following are also valid:

=over

=item core() -> $boolean

A boolean indicating the process core was dumped.

=item exit() -> $exit

The command's exit value (already shifted by 8; see "perldoc -f system
for details").

=item signal() -> $signum

The signal number (if any) that terminated the command (already
bitwise-added with 127; see "perldoc -f system" for details).

=back

=begin comment

=head1 MOCKING (EXPERIMENTAL!)

The C<mock> subroutine, when given, runs instead of the command line
process. It is passed the B<Sys::Cmd::Process> object as its first
argument, which gives it access to the cmdline, dir, env, encoding,
attributes as methods.

    run(
        'junk',
        {
            input => 'food',
            mock  => sub {
                my $proc  = shift;
                my $input = shift;
                [ $proc->cmdline . ":Thanks for $input!\n", '', 0 ];
            }
        }
    );

It is required to return an ARRAY reference (possibly empty), with the
following elements:

    [
        "standard output\n",    # default ''
        "standard error\n",     # default ''
        $exit,                  # default 0
        $signal,                # default 0
        $core,                  # default 0
    ]

Those values are then returned from C<run> as usual. At present this
feature is not useful for interactive (i.e. spawned) use, as it does
not dynamically respond to calls to C<$proc->stdin->print()>.

Note that this interface is B<EXPERIMENTAL> and subject to change!
Don't use it anywhere you can't deal with breakage!

=end comment


=head1 LOGGING

L<Log::Any> is used to log process start/end events at the "info"
level.

=head1 ALTERNATIVES

L<AnyEvent::Run>, L<AnyEvent::Util>, L<Argv>, L<Capture::Tiny>,
L<Child>, L<Forks::Super>, L<IO::Pipe>, L<IPC::Capture>, L<IPC::Cmd>,
L<IPC::Command::Multiplex>, L<IPC::Exe>, L<IPC::Open3>,
L<IPC::Open3::Simple>, L<IPC::Run>, L<IPC::Run3>,
L<IPC::RunSession::Simple>, L<IPC::ShellCmd>, L<IPC::System::Simple>,
L<POE::Pipe::TwoWay>, L<Proc::Background>, L<Proc::Fork>,
L<Proc::FastSpawn>, L<Spawn::Safe>, L<System::Command>

=head1 SUPPORT

This distribution is managed via github:

    https://github.com/mlawren/p5-Sys-Cmd

This distribution follows the semantic versioning model:

    http://semver.org/

Code is tidied up on Git commit using githook-perltidy:

    http://github.com/mlawren/githook-perltidy

=head1 AUTHOR

Mark Lawrence E<lt>mark@rekudos.netE<gt>, based heavily on
L<Git::Repository::Command> by Philippe Bruhat (BooK).

=head1 COPYRIGHT AND LICENSE

Copyright 2011-2025 Mark Lawrence <mark@rekudos.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

