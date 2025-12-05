package Sys::Cmd;
use v5.18;
use warnings;
no warnings "experimental::lexical_subs";
use feature 'lexical_subs';
use Carp           ();
use Encode::Locale ();    # Creates the 'locale' alias
use Encode 'resolve_alias';
use Exporter::Tidy _map => {
    run      => sub { run( undef, @_ ) },
    spawn    => sub { spawn( undef, @_ ) },
    syscmd   => sub { syscmd( undef, @_ ) },
    runsub   => sub { syscmd( undef, @_ )->runsub },
    spawnsub => sub { syscmd( undef, @_ )->spawnsub },
};

our $VERSION = 'v0.986.0';

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
    Carp::confess( 'Sys::Cmd cmd: ' . $@ ) if $@;
    $_[0]{'dir'} = eval { $_FIELDS->{'dir'}->{'isa'}->( $_[0]{'dir'} ) }
      if exists $_[0]{'dir'};
    Carp::confess( 'Sys::Cmd dir: ' . $@ ) if $@;
    $_[0]{'encoding'} =
      eval { $_FIELDS->{'encoding'}->{'isa'}->( $_[0]{'encoding'} ) }
      if exists $_[0]{'encoding'};
    Carp::confess( 'Sys::Cmd encoding: ' . $@ ) if $@;
    $_[0]{'env'} = eval { $_FIELDS->{'env'}->{'isa'}->( $_[0]{'env'} ) }
      if exists $_[0]{'env'};
    Carp::confess( 'Sys::Cmd env: ' . $@ ) if $@;
    $_[0]{'mock'} = eval { $_FIELDS->{'mock'}->{'isa'}->( $_[0]{'mock'} ) }
      if exists $_[0]{'mock'};
    Carp::confess( 'Sys::Cmd mock: ' . $@ ) if $@;
    map { delete $_[1]->{$_} } 'cmd', 'dir', 'encoding', 'env', 'err', 'input',
      'mock', 'on_exit', 'out';
}

sub __RO {
    my ( undef, undef, undef, $sub ) = caller(1);
    Carp::confess("attribute $sub is read-only");
}
sub cmd { __RO() if @_ > 1; $_[0]{'cmd'} // undef }
sub dir { __RO() if @_ > 1; $_[0]{'dir'} // undef }

sub encoding {
    __RO() if @_ > 1;
    $_[0]{'encoding'} //= eval {
        $_FIELDS->{'encoding'}->{'isa'}
          ->( $_FIELDS->{'encoding'}->{'default'} );
    };
    Carp::confess( 'invalid (Sys::Cmd::encoding) default: ' . $@ ) if $@;
    $_[0]{'encoding'};
}
sub env   { __RO() if @_ > 1; $_[0]{'env'}   // undef }
sub err   { __RO() if @_ > 1; $_[0]{'err'}   // undef }
sub input { __RO() if @_ > 1; $_[0]{'input'} // undef }

sub mock {
    if ( @_ > 1 ) {
        $_[0]{'mock'} =
          eval { $_FIELDS->{'mock'}->{'isa'}->( $_[0]{'mock'} // undef ) };
        Carp::confess( 'invalid (Sys::Cmd::mock) value: ' . $@ ) if $@;
    }
    $_[0]{'mock'} // undef;
}

sub on_exit {
    if ( @_ > 1 ) { $_[0]{'on_exit'} = $_[1] }
    $_[0]{'on_exit'} // undef;
}
sub out { __RO() if @_ > 1; $_[0]{'out'} // undef }

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
    encoding => {
        default => 'locale',
        isa     => sub {
            my $e = resolve_alias( $_[0] )
              || _croak("Unknown Encoding: $_[0]");
            $e;
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
    input => {},
    out   => {},
    err   => {},
    mock  => {
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

my sub merge_args {
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
        return { %$template, %$opts };
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
    $opts;
}

my sub new_proc {
    require Sys::Cmd::Process;
    Sys::Cmd::Process->new(@_);
}

sub run {
    my $opts    = merge_args(@_);
    my $ref_out = delete $opts->{out};
    my $ref_err = delete $opts->{err};
    my $proc    = new_proc($opts);
    my @err     = $proc->stderr->getlines;
    my @out     = $proc->stdout->getlines;
    $proc->wait_child;

    if ( $proc->signal != 0 ) {
        _croak(
            sprintf(
                '%s[%d] %s [signal: %d core: %d]',
                join( '', @err ), $proc->pid, scalar $proc->cmdline,
                $proc->signal,    $proc->core
            )
        );
    }
    elsif ( $proc->exit != 0 ) {
        _croak(
            sprintf(
                '%s[%d] %s [exit: %d]',
                join( '', @err ),      $proc->pid,
                scalar $proc->cmdline, $proc->exit
            )
        );
    }

    if ($ref_err) {
        $$ref_err = join '', @err;
    }
    elsif (@err) {
        local @Carp::CARP_NOT = (__PACKAGE__);
        Carp::carp @err;
    }

    if ($ref_out) {
        $$ref_out = join '', @out;
    }
    elsif ( defined( my $wa = wantarray ) ) {
        return @out if $wa;
        return join( '', @out );
    }
}

sub spawn {
    new_proc( merge_args(@_) );
}

sub syscmd {
    Sys::Cmd->new( merge_args(@_) );
}

sub runsub {
    my $self = shift;
    sub { $self->run(@_) };
}

sub spawnsub {
    my $self = shift;
    sub { $self->spawn(@_) };
}

1;

__END__

=head1 NAME

Sys::Cmd - run a system command or spawn a system processes

=head1 VERSION

v0.986.0 (2025-12-04)

=head1 SYNOPSIS

    use Sys::Cmd qw/run runsub spawn/;

    my $output   = run( 'ls', '--long' );    # /usr/bin/ls --long
    my @numbered = run( 'cat', '-n',         # /usr/bin/cat -n <<EOF
        {                                    # > X
            input => "X\nY\nZ\n",            # > Y
        }                                    # > Z
    );                                       # EOF

    my $ls = runsub( 'ls',                   # Does nothing... yet
        {
            dir => '/tmp',
            out => \$output,
        }
    );
    $ls->( 'here' );                         # Runs in /tmp and puts
    $ls->( '-l', 'there');                   # (long) output in $output

    # Spawn a process for asynchronous interaction
    my $proc = spawn( @cmd, { encoding => 'iso-8859-3' } );
    while ( my $line = $proc->stdout->getline ) {
        $proc->stdin->print("thanks\n");
    }
    warn $proc->stderr->getlines;

    $proc->close();    # Finished talking to file handles
    $proc->wait_child && die "Non-zero exit!: " . $proc->exit;

=head1 DESCRIPTION

B<Sys::Cmd> lets you run a system command and capture its output, or
spawn and interact with a process through its stdin, stdout and error
handles.

It provides something of a superset of Perl's builtin external process
functions ("system", "qx//", "fork"+"exec", and "open"):

=over

=item * Command lookups using L<File::Which> (run, spawn)

=item * Efficient process spawning with L<Proc::FastSpawn> (run, spawn)

=item * Warn on error output (run)

=item * Raise exception on failure (run)

=item * Capture output and error separately (run, spawn)

=item * Asynchronous interaction through file handles (spawn)

=item * Sensible exit values (spawn)

=item * Template functions for repeated calls (runsub, spawnsub)

=back

=head1 COMMAND PROCESSING

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

=head1 OPTIONS

The C<@cmd> list may also include an optional C<\%opts> HASH reference
to adjust aspects of the execution.

The following configuration items (key => default) are common to all
B<Sys::Cmd> functions and are passed to the underlying
L<Sys::Cmd::Process> objects at creation time:

=over

=item dir => $PWD

The working directory the command will be run in. Note that if C<@cmd>
is a relative path, it may not be found from the new location.

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

=item out => undef

A reference to a scalar which is populated with output. When given
C<run()> returns nothing.

=item err => undef

A reference to a scalar which is populated with error output. When
given C<run()> does not warn of errors.

=back

=item spawn( @cmd, [\%opt] ) => Sys::Cmd::Process

Returns a L<Sys::Cmd::Process> object representing the process running
C<@cmd>. You can interrogate this and interact with the process via
C<cmdline()>, C<stdin()>, C<stdout()>, C<stderr()>, C<close()>,
C<wait_child()>, C<exit()>, C<signal()>, C<core()>, etc.

=back

=head2 Template Functions

When repeatedly calling a command, possibly with only slightly
different arguments or environments, a kind of "templating" mechanism
can be useful, to avoid repeating full configuration values and wearing
a path lookup penalty each call.

The B<Sys::Cmd> class itself provides this functionality, exposed as
follows:

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

(Equivalent to manually calling C<syscmd(...)> below, followed by the
C<runsub> method).

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

(Equivalent to manually calling C<syscmd(...)> below followed by the
C<spawnsub> method).

=item syscmd( @cmd, [\%opt] ) => Sys::Cmd

Returns a B<Sys::Cmd> object representing a I<future> command (or
coderef) to be executed in some way. You can then call multiple
C<run()> or C<spawn()> I<methods> on the object for the actual work.
The methods work the same way in terms of input, output, and return
values as the exported package functions.

This function underlies the "runsub" and "spawnsub" functions, but the
author finds it less attractive as an interface.

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

