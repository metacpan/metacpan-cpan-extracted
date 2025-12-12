package Sys::Cmd;
use v5.18;

use warnings;
no warnings "experimental::lexical_subs";
use feature 'lexical_subs';

use Carp            qw[];
use Cwd             qw[getcwd];
use Encode::Locale  qw[$ENCODING_LOCALE];      # Also Creates the 'locale' alias
use Encode          qw[encode resolve_alias];
use IO::Handle      qw[];
use Log::Any        qw[$log];
use Proc::FastSpawn qw[];
use Sys::Cmd::Process;
use Exporter::Tidy _map => {
    run    => sub { _syscmd( undef, @_ )->_run },
    spawn  => sub { _syscmd( undef, @_ )->_spawn },
    syscmd => sub { _syscmd( undef, @_ ) },
    runsub => sub {
        my $cmd = _syscmd( undef, @_ );
        sub { @_ ? _syscmd( $cmd, @_ )->_run : $cmd->_run }
    },
    spawnsub => sub {
        my $cmd = syscmd( undef, @_ );
        sub { @_ ? _syscmd( $cmd, @_ )->_spawn : $cmd->_spawn }
    },
};

our $VERSION = 'v0.986.3';

### START Class::Inline ### v0.0.1 Thu Dec 11 13:24:56 2025
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
        Carp::carp("Sys::Cmd: unexpected argument '$_'") for keys %$attrs
    }
    map { $self->$_ } @{ $_NEW{$CLASS}->[1] };
    $self;
}

sub _NEW {
    CORE::state $fix_FIELDS = do {
        $_FIELDS = { @_CLASS > 1 ? @_CLASS : %{ $_CLASS[0] } };
        $_FIELDS = $_FIELDS->{'FIELDS'} if exists $_FIELDS->{'FIELDS'};
    };
    if ( my @missing = grep { not exists $_[0]->{$_} } 'cmd' ) {
        Carp::croak( 'Sys::Cmd required initial argument(s): '
              . join( ', ', @missing ) );
    }
    $_[0]{'cmd'} = eval { $_FIELDS->{'cmd'}->{'isa'}->( $_[0]{'cmd'} ) };
    delete $_[0]{'cmd'} || Carp::confess( 'Sys::Cmd cmd: ' . $@ ) if $@;
    $_[0]{'dir'} = eval { $_FIELDS->{'dir'}->{'isa'}->( $_[0]{'dir'} ) }
      if exists $_[0]{'dir'};
    delete $_[0]{'dir'} || Carp::confess( 'Sys::Cmd dir: ' . $@ ) if $@;
    $_[0]{'encoding'} =
      eval { $_FIELDS->{'encoding'}->{'isa'}->( $_[0]{'encoding'} ) }
      if exists $_[0]{'encoding'};
    delete $_[0]{'encoding'} || Carp::confess( 'Sys::Cmd encoding: ' . $@ )
      if $@;
    $_[0]{'env'} = eval { $_FIELDS->{'env'}->{'isa'}->( $_[0]{'env'} ) }
      if exists $_[0]{'env'};
    delete $_[0]{'env'} || Carp::confess( 'Sys::Cmd env: ' . $@ ) if $@;
    $_[0]{'mock'} = eval { $_FIELDS->{'mock'}->{'isa'}->( $_[0]{'mock'} ) }
      if exists $_[0]{'mock'};
    delete $_[0]{'mock'} || Carp::confess( 'Sys::Cmd mock: ' . $@ ) if $@;
    map { delete $_[1]->{$_} } '_coderef', 'cmd', 'dir', 'encoding', 'env',
      'err', 'exit', 'input', 'log_any', 'mock', 'on_exit', 'out';
}

sub __RO {
    my ( undef, undef, undef, $sub ) = caller(1);
    Carp::confess("attribute $sub is read-only");
}

sub _coderef {
    __RO() if @_ > 1;
    $_[0]{'_coderef'} //= $_FIELDS->{'_coderef'}->{'default'}->( $_[0] );
}
sub cmd { __RO() if @_ > 1; $_[0]{'cmd'} // undef }
sub dir { __RO() if @_ > 1; $_[0]{'dir'} // undef }

sub encoding {
    __RO() if @_ > 1;
    $_[0]{'encoding'} //= eval {
        $_FIELDS->{'encoding'}->{'isa'}
          ->( $_FIELDS->{'encoding'}->{'default'} );
    };
    delete $_[0]{'encoding'}
      || Carp::confess( 'invalid (Sys::Cmd::encoding) default: ' . $@ )
      if $@;
    $_[0]{'encoding'};
}
sub env     { __RO() if @_ > 1; $_[0]{'env'}     // undef }
sub err     { __RO() if @_ > 1; $_[0]{'err'}     // undef }
sub exit    { __RO() if @_ > 1; $_[0]{'exit'}    // undef }
sub input   { __RO() if @_ > 1; $_[0]{'input'}   // undef }
sub log_any { __RO() if @_ > 1; $_[0]{'log_any'} // undef }

sub mock {
    if ( @_ > 1 ) {
        $_[0]{'mock'} = eval { $_FIELDS->{'mock'}->{'isa'}->( $_[1] ) };
        delete $_[0]{'mock'}
          || Carp::confess( 'invalid (Sys::Cmd::mock) value: ' . $@ )
          if $@;
    }
    $_[0]{'mock'} // undef;
}

sub on_exit {
    if ( @_ > 1 ) { $_[0]{'on_exit'} = $_[1] }
    $_[0]{'on_exit'} // undef;
}
sub out { __RO() if @_ > 1; $_[0]{'out'} // undef }
@_CLASS = grep 1,    ### END Class::Inline ###
  {
    cmd => {
        isa => sub {
            ref $_[0] eq 'ARRAY' || _croak("cmd must be ARRAYREF");
            @{ $_[0] }           || _croak("Missing cmd elements");
            if ( grep { !defined $_ } @{ $_[0] } ) {
                _croak('cmd array cannot contain undef elements');
            }
            $_[0];
        },
        required => 1,
    },
    _coderef => {
        default => sub {
            my $c = $_[0]->cmd->[0];
            ref($c) eq 'CODE' ? $c : undef;
        },
    },
    encoding => {
        default => $ENCODING_LOCALE,
        isa     => sub {
            resolve_alias( $_[0] )
              || _croak("Unknown Encoding: $_[0]");
            $_[0];
        },
    },
    env => {
        isa => sub {
            ref $_[0] eq 'HASH' || _croak("env must be HASHREF");
            $_[0];
        },
    },
    dir => {
        isa => sub {
            -d $_[0] || _croak("directory not found: $_[0]");
            $_[0];
        },
    },
    input   => {},
    log_any => {},
    out     => {},
    err     => {},
    exit    => {},
    mock    => {
        is  => 'rw',
        isa => sub {
            ( ( not defined $_[0] ) || 'CODE' eq ref $_[0] )
              || _croak('must be CODEref');
            $_[0];
        },
    },
    on_exit => { is => 'rw', },
  };

sub _croak {
    local $Carp::CarpInternal{'Sys::Cmd'}          = 1;
    local $Carp::CarpInternal{'Sys::Cmd::Process'} = 1;
    Carp::croak(@_);
}

sub _syscmd {
    my $template = shift;

    my ( @cmd, $opts );
    foreach my $arg (@_) {
        if ( ref($arg) eq 'HASH' ) {
            _croak( __PACKAGE__ . ': only a single hashref allowed' )
              if $opts;
            $opts = $arg;
        }
        else {
            push( @cmd, $arg );
        }
    }
    $opts //= {};

    if ($template) {
        $opts->{cmd} = [ @{ $template->cmd }, @cmd ];
        if ( exists $opts->{env} ) {
            my %env = ( each %{ $template->env }, each %{ $opts->{env} } );
            $opts->{env} = \%env;
        }
        return Sys::Cmd->new( { %$template, %$opts } );
    }

    _croak('$cmd must be defined') unless @cmd && defined $cmd[0];

    if ( 'CODE' ne ref( $cmd[0] ) and not $opts->{mock} ) {
        delete $opts->{mock};
        require File::Spec;
        if ( File::Spec->splitdir( $cmd[0] ) == 1 ) {
            require File::Which;
            $cmd[0] = File::Which::which( $cmd[0] )
              || _croak( 'command not found: ' . $cmd[0] );
        }

        if ( !-x $cmd[0] ) {
            _croak( 'command not executable: ' . $cmd[0] );
        }
    }
    $opts->{cmd} = \@cmd;
    Sys::Cmd->new($opts);
}

my sub _fastspawn {
    my @cmd = @_;

    # Backup the original 0,1,2 file descriptors
    open my $old_fd0, '<&', 0;
    open my $old_fd1, '>&', 1;
    open my $old_fd2, '>&', 2;

    # Get new handles to descriptors 0,1,2
    my $fd0 = IO::Handle->new_from_fd( 0, 'r' );
    my $fd1 = IO::Handle->new_from_fd( 1, 'w' );
    my $fd2 = IO::Handle->new_from_fd( 2, 'w' );

    # New handles for the child
    my $stdin  = IO::Handle->new;
    my $stdout = IO::Handle->new;
    my $stderr = IO::Handle->new;

    # Pipe our filehandles to new child filehandles
    pipe( my $child_in, $stdin )        || die "pipe: $!";
    pipe( $stdout,      my $child_out ) || die "pipe: $!";
    pipe( $stderr,      my $child_err ) || die "pipe: $!";

    # Make sure that 0,1,2 are inherited (probably are anyway)
    Proc::FastSpawn::fd_inherit( $_, 1 ) for 0, 1, 2;

    # But don't inherit the rest
    Proc::FastSpawn::fd_inherit( fileno($_), 0 )
      for $old_fd0, $old_fd1, $old_fd2,
      $child_in, $child_out, $child_err,
      $stdin,    $stdout,    $stderr;

    # Re-open 0,1,2 by duping the child pipe ends
    open $fd0, '<&', fileno($child_in)  || die "open: $!";
    open $fd1, '>&', fileno($child_out) || die "open: $!";
    open $fd2, '>&', fileno($child_err) || die "open: $!";

    # Kick off the new process
    my $pid = eval {
        Proc::FastSpawn::spawn(
            $cmd[0],
            \@cmd,
            [
                map { $_ . '=' . ( defined $ENV{$_} ? $ENV{$_} : '' ) }
                  keys %ENV
            ]
        );
    };
    my $err = $@;

    # Restore our local 0,1,2 to the originals
    open $fd0, '<&', fileno($old_fd0) || die "open: $!";
    open $fd1, '>&', fileno($old_fd1) || die "open: $!";
    open $fd2, '>&', fileno($old_fd2) || die "open: $!";

    # Parent doesn't need to see the child or backup descriptors anymore
    close($_) || die "close: $!"
      for $old_fd0,
      $old_fd1,
      $old_fd2,
      $child_in,
      $child_out,
      $child_err;

    # Complain if the spawn failed for some reason
    _croak($err) if $err;
    _croak('Unable to spawn child') unless defined $pid;

    (
        pid    => $pid,
        stdin  => $stdin,
        stdout => $stdout,
        stderr => $stderr
    );
}

my sub _fork {
    my $encoding = shift // die 'need encoding';
    my $code     = shift // die 'need code';
    my @args     = @_;
    my ( $stdin, $stdout, $stderr ) =
      ( IO::Handle->new, IO::Handle->new, IO::Handle->new, );

    pipe( my $child_in, $stdin )        || die "pipe: $!";
    pipe( $stdout,      my $child_out ) || die "pipe: $!";
    pipe( $stderr,      my $child_err ) || die "pipe: $!";

    my $pid = fork();
    if ( !defined $pid ) {
        my $why = $!;
        die "fork: $why";
    }

    if ( $pid > 0 ) {    # parent
        close($_) for
          $child_in,
          $child_out,
          $child_err;

        return (
            pid    => $pid,
            stdin  => $stdin,
            stdout => $stdout,
            stderr => $stderr
        );
    }

    # Child
    $child_err->autoflush(1);

    foreach my $quad (
        [ \*STDERR, '>&=', fileno($child_err), 1 ],
        [ \*STDOUT, '>&=', fileno($child_out), 1 ],
        [ \*STDIN,  '<&=', fileno($child_in),  0 ],
      )
    {
        my ( $fh, $mode, $fileno, $autoflush ) = @$quad;

        open( $fh, $mode, $fileno )
          or print $child_err sprintf "[%d] open %s, %s: %s\n", $pid,
          $fh, $mode, $!;

        binmode $fh, ':encoding(' . $encoding . ')'
          or warn sprintf "[%d] binmode %d(%s) %s: %s", $pid,
          $fileno, $mode, $encoding, $!;

        $fh->autoflush(1) if $autoflush;
    }

    close($_) for
      $stdin,
      $stdout,
      $stderr,
      $child_in,
      $child_out,
      $child_err;

    $code->(@args);
    _exit(0);

    #    exec( @{ $self->cmd } );
    #    die "exec: $!";
}

sub _spawn {
    my $self = shift;
    my $dir  = $self->dir;
    my $cwd  = getcwd if defined $dir;

    my $proc = eval {
        local %ENV = %ENV;
        my $locale = $self->encoding;
        while ( my ( $key, $val ) = each %{ $self->env // {} } ) {
            my $keybytes = encode( $locale, $key, Encode::FB_CROAK );
            if ( defined $val ) {
                $ENV{$keybytes} = encode( $locale, $val, Encode::FB_CROAK );
            }
            else {
                delete $ENV{$keybytes};
            }
        }

        chdir $dir or die "chdir: $!" if defined $dir;
        my $oe = $self->on_exit;

        Sys::Cmd::Process->new(
            cmd => $self->cmd,
            $oe ? ( on_exit => $oe ) : (),
            $self->_coderef
            ? _fork( $self->encoding, @{ $self->cmd } )
            : _fastspawn(
                map {
                    encode(
                        $locale => $_,
                        Encode::FB_CROAK | Encode::LEAVE_SRC
                    )
                } @{ $self->cmd }
            )
        );
    };
    my $err = $@;
    chdir $cwd if defined $dir;
    die $err   if $err;

    my $enc = ':encoding(' . $self->encoding . ')';
    binmode( $proc->stdin,  $enc ) or warn "binmode stdin: $!";
    binmode( $proc->stdout, $enc ) or warn "binmode stdout: $!";
    binmode( $proc->stderr, $enc ) or warn "binmode stderr: $!";

    $proc->stdin->autoflush(1);

    # some input was provided
    if ( defined( my $input = $self->input ) ) {
        local $SIG{PIPE} =
          sub { warn "Broken pipe when writing to:" . $proc->cmdline };

        if ( ( 'ARRAY' eq ref $input ) && @$input ) {
            $proc->stdin->print(@$input);
        }
        elsif ( length $input ) {
            $proc->stdin->print($input);
        }

        $proc->stdin->close;
    }

    $proc;
}

sub _run {
    my $self   = shift;
    my $proc   = $self->_spawn;
    my $stderr = $proc->stderr;
    my $stdout = $proc->stdout;

    # Select idea borrowed from System::Command
    require IO::Select;
    my $select = IO::Select->new( $stdout, $stderr );
    my @err;
    my @out;

    while ( my @ready = $select->can_read ) {
        for my $fh (@ready) {
            my $dest = $fh == $stdout ? \@out : \@err;
            if ( defined( my $line = <$fh> ) ) {
                push @$dest, $line;
            }
            else {
                $select->remove($fh);
                $fh->close;
            }
        }
    }

    $proc->stdin->close;
    my $ok = $proc->wait_child;

    if ( my $ref = $self->exit ) {
        $$ref = $proc->exit;
    }
    elsif ( !$ok ) {
        _croak( join( '', @err ) . $proc->status );
    }

    if ( my $ref = $self->err ) {
        $$ref = join '', @err;
    }
    elsif (@err) {
        local @Carp::CARP_NOT = (__PACKAGE__);
        Carp::carp @err;
    }

    if ( my $ref = $self->out ) {
        $$ref = join '', @out;
    }
    elsif ( defined( my $wa = wantarray ) ) {
        return @out if $wa;
        return join( '', @out );
    }
}

# Legacy object interface, undocumented.
sub run   { _syscmd(@_)->_run }
sub spawn { _syscmd(@_)->_spawn }

1;

__END__

=head1 NAME

Sys::Cmd - Run a system command or spawn a process

=head1 VERSION

v0.986.3 (2025-12-11)

=head1 SYNOPSIS

    use Sys::Cmd qw/run runsub spawn/;

Catch a command's standard output, warning on anything sent to stderr,
raise an exception on abnormal exit:

    my $output = run( 'ls', '--long' );

Commands can be fed input from Perl and return separate lines in in
array context:

    my @XYZ = run( 'cat', '-n', { input => "X\nY\nZ\n", } );

Put outputs and exit value directly into scalars, in which case no
warnings or exceptions are triggered:

    my ($out, $err, $exit);
    run( 'ls', 'FILE_NOT_FOUND', {
        out => \$out,
        err => \$err,
        exit => \$exit,
    });

A type of templating exists for multiple calls to the same command with
pre-defined defaults:

    my $ls = runsub( 'ls',        # Returns a subref
        {
            dir => '/tmp',
            out => \$out,
        }
    );
    $ls->()                       &&  print $out;
    $ls->({ dir => '/elsewhere'}) &&  print $out;

Use C<spawn> for asynchronous interaction:

    my $proc = spawn( @cmd );
    printf "pid %d\n", $proc->pid;

    while ( defined ( my $line = $proc->stdout->getline ) ) {
        $proc->stdin->print("thanks\n");
    }
    warn $proc->stderr->getlines;

    $proc->wait_child || warn $proc->status;

=head1 DESCRIPTION

B<Sys::Cmd> lets you run a system command and capture its output, or
spawn and interact with a process through its C<stdin>, C<stdout> and
C<stderr> handles.

It provides something of a superset of Perl's builtin external process
functions ("system", "qx//", "fork"+"exec", and "open"):

=over

=item * Command lookups using L<File::Which> (run, spawn)

=item * Efficient process spawning with L<Proc::FastSpawn> (run, spawn)

=item * Warn on error output (run)

=item * Raise exception on failure (run)

=item * Capture output, error and exit separately (run, spawn)

=item * Sensible exit and signal values

=item * Asynchronous interaction through file handles (spawn)

=item * Template functions for repeated calls (runsub, spawnsub)

=back

=head2 Command Path

All functions take a C<@cmd> list that specifies the command and its
arguments. The first element of C<@cmd> determines what/how things are
run:

=over

=item * If it has one or more path components (absolute or relative) it
is executed as is, with L<Proc::FastSpawn>.

=item * If it is a CODE reference (subroutine) then a fork is performed
before calling it in the child process. Unsupported on Win32.

=item * Everything else is looked up using L<File::Which> and the
result is executed with L<Proc::FastSpawn>.

=back

The remaining scalar elements of C<@cmd> are passed as arguments.

=head2 Common Options

A function's C<@cmd> list may also include an optional C<\%opts> HASH
reference to adjust aspects of the execution.  The following
configuration items (key => default) are common to all B<Sys::Cmd>
functions.

=over

=item dir => $CWD

The working directory the command will be run in. Note that a relative
command path might not be valid if the current directory changes.

=item encoding => $Encode::Locale::ENCODING_LOCALE

A string value identifying the encoding that applies to input/output
file-handles, command arguments, and environment variables.  Defaults
to the 'locale' alias from L<Encode::Locale>.

=item env => {}

A hashref containing key/values to be added to the current environment
at run-time. If a key has an undefined value then the key is removed
from the environment altogether.

=item input => undef

A scalar (string), or ARRAY reference, which is fed to the command via
its standard input, which is then closed.  An empty value ('') or empty
list will close the command's standard input without printing. An
undefined value (the default) leaves the handle open.

Some commands close their standard input on startup, which causes a
SIGPIPE when trying to write to it, for which B<Sys::Cmd> will warn.

=begin comment

=item mock

A subroutine reference which runs instead of the actual command, which
provides the fake outputs and exit values. See L</"MOCKING"> below for
details.

=end comment

=item on_exit

A subref to be called at the time that process termination is detected.

=back

=head1 FUNCTIONS

The following functions are exportable from B<Sys::Cmd>:

=over 4

=item run( @cmd, [\%opt] ) => $output | @output

Executes C<@cmd> and waits for the process to exit. Raises an exception
in the event of non-zero exit value, otherwise warns for any errors
received. In array context returns a list of lines instead of a scalar
string. Accepts the following additional configuration keys:

=over

=item out => \$scalar

A reference to a scalar which is populated with output. When given
C<run()> returns nothing.

=item err => \$scalar

A reference to a scalar which is populated with error output. When
given C<run()> does not warn of errors.

=item exit => \$scalar

A reference to a scalar which is populated with the exit value. When
given C<run()> does not raise an exception on a non-zero exit.

=back

=item spawn( @cmd, [\%opt] ) => Sys::Cmd::Process

Return an object representing the process running according to C<@cmd>
and C<\%opt>. This is the core mechanism underlying C<run>.

You can interact with the process object via its C<cmdline()>,
C<stdin()>, C<stdout()>, C<stderr()>, C<close()>, C<wait_child()>,
C<exit()>, C<signal()>, C<core()> attributes and handles. See
L<Sys::Cmd::Process> for details.

=back

=head2 Template Functions

When repeatedly calling a command, possibly with only slightly
different arguments or environments, a kind of "templating" mechanism
can be useful, to avoid repeating full configuration values and wearing
a path lookup penalty each call.

=begin comment

=item syscmd( @cmd, [\%opt] ) => Sys::Cmd

Return a B<Sys::Cmd> object representing a I<future> command (or
coderef) to be executed in some way. You can then call multiple
C<run()> or C<spawn()> I<methods> on the object for the actual work.
The methods work the same way in terms of input, output, and return
values as the exported package functions below.

=end comment

=over

=item runsub( @cmd, [\%opt] ) => CODEref

Returns a subroutine reference representing a I<future> command to be
executed in the style of "run", with default arguments and options.
When called, additional arguments and options are I<merged>:

    use Sys::Cmd 'runsub';
    my $git = runsub(
        'git',
        {
            env => {
                GIT_AUTHOR_NAME  => 'Geekette',
                GIT_AUTHOR_EMAIL => 'xyz@example.com',
            }
        }
    );

    my @list   = $git->( 'add', 'file.txt' );
    my $result = $git->( 'commit', 'HEAD',
        {
            env => {
                GIT_AUTHOR_NAME  => 'Override',
            }
        }
    ));

=item spawnsub( @cmd, [\%opt] ) => CODEref

Returns a subroutine reference representing a I<future> process to be
created in the style of "spawn", with default arguments and options.
When called, additional arguments and options are I<merged>.

    use Sys::Cmd 'spawnsub';
    my $cmd = spawnsub('command');
    my @kids;
    foreach my $i ( 0 .. 9 ) {
        $kids[$i] = $cmd->( 'arg', $i );
        $kids[$i]->stdin->print("Hello\n");
    }
    print $_->pid . ': ' . $_->stdout->getlines for @kids;
    $_->wait_child for @kids;

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

