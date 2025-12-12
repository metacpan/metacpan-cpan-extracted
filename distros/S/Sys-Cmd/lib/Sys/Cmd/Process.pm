package Sys::Cmd::Process;
use v5.18;
use warnings;
use Carp     qw[];
use Log::Any qw[$log];

our $VERSION = 'v0.986.3';

### START Class::Inline ### v0.0.1 Thu Dec 11 13:24:57 2025
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
    if ( my @missing = grep { not exists $_[0]->{$_} } 'cmd', 'pid', 'stderr',
        'stdin', 'stdout' )
    {
        Carp::croak( 'Sys::Cmd::Process required initial argument(s): '
              . join( ', ', @missing ) );
    }
    $_[0]{'_ret'} = eval { $_FIELDS->{'_ret'}->{'isa'}->( $_[0]{'_ret'} ) }
      if exists $_[0]{'_ret'};
    delete $_[0]{'_ret'} || Carp::confess( 'Sys::Cmd::Process _ret: ' . $@ )
      if $@;
    $_[0]{'cmd'} = eval { $_FIELDS->{'cmd'}->{'isa'}->( $_[0]{'cmd'} ) };
    delete $_[0]{'cmd'} || Carp::confess( 'Sys::Cmd::Process cmd: ' . $@ )
      if $@;
    map { delete $_[1]->{$_} } 'cmd', 'on_exit', 'pid', 'status', 'stderr',
      'stdin', 'stdout';
}

sub __RO {
    my ( undef, undef, undef, $sub ) = caller(1);
    Carp::confess("attribute $sub is read-only");
}

sub _ret {
    if ( @_ > 1 ) {
        $_[0]{'_ret'} = eval { $_FIELDS->{'_ret'}->{'isa'}->( $_[1] ) };
        delete $_[0]{'_ret'}
          || Carp::confess( 'invalid (Sys::Cmd::Process::_ret) value: ' . $@ )
          if $@;
    }
    $_[0]{'_ret'} //= eval {
        $_FIELDS->{'_ret'}->{'isa'}
          ->( $_FIELDS->{'_ret'}->{'default'}->( $_[0] ) );
    };
    delete $_[0]{'_ret'}
      || Carp::confess( 'invalid (Sys::Cmd::Process::_ret) default: ' . $@ )
      if $@;
    $_[0]{'_ret'};
}
sub has__ret { exists $_[0]{'_ret'} }
sub cmd      { __RO() if @_ > 1; $_[0]{'cmd'} // undef }

sub core {
    __RO() if @_ > 1;
    $_[0]{'core'} //= $_FIELDS->{'core'}->{'default'}->( $_[0] );
}

sub exit {
    __RO() if @_ > 1;
    $_[0]{'exit'} //= $_FIELDS->{'exit'}->{'default'}->( $_[0] );
}
sub has_exit { exists $_[0]{'exit'} }

sub on_exit {
    if ( @_ > 1 ) { $_[0]{'on_exit'} = $_[1] }
    $_[0]{'on_exit'} // undef;
}
sub pid { __RO() if @_ > 1; $_[0]{'pid'} // undef }

sub signal {
    __RO() if @_ > 1;
    $_[0]{'signal'} //= $_FIELDS->{'signal'}->{'default'}->( $_[0] );
}

sub status {
    if ( @_ > 1 ) { $_[0]{'status'} = $_[1] }
    $_[0]{'status'} //= $_FIELDS->{'status'}->{'default'};
}
sub stderr { __RO() if @_ > 1; $_[0]{'stderr'} // undef }
sub stdin  { __RO() if @_ > 1; $_[0]{'stdin'}  // undef }
sub stdout { __RO() if @_ > 1; $_[0]{'stdout'} // undef }
@_CLASS = grep 1,    ### END Class::Inline ###
  {
    cmd => {
        isa => sub {
            ref $_[0] eq 'ARRAY' || Sys::Cmd::_croak("cmd must be ARRAYREF");
            @{ $_[0] }           || Sys::Cmd::_croak("Missing cmd elements");
            if ( grep { !defined $_ } @{ $_[0] } ) {
                Sys::Cmd::_croak('cmd array cannot contain undef elements');
            }
            $_[0];
        },
        required => 1,
    },
    pid => {
        is       => 'ro',
        required => 1,
    },
    stdin => {
        is       => 'ro',
        required => 1,
    },
    stdout => {
        is       => 'ro',
        required => 1,
    },
    stderr => {
        is       => 'ro',
        required => 1,
    },
    _ret => {
        is  => 'rw',
        isa => sub {
            defined( $_[0] )
              or die Data::Dumper::Dumper( \@_ ) . "_ret must be defined! @_";
            $_[0];
        },
        init_arg  => undef,
        predicate => 1,
        default   => sub {
            Sys::Cmd::_croak(
                'Process status values invalid before wait_child()');
        },
    },
    exit => {
        is        => 'ro',
        init_arg  => undef,
        predicate => 1,
        default   => sub { my $r = $_[0]->_ret; $r < 0 ? $r : $r >> 8 },
    },
    signal => {
        is       => 'ro',
        init_arg => undef,
        default  => sub { $_[0]->_ret & 127 },
    },
    core => {
        is       => 'ro',
        init_arg => undef,
        default  => sub { $_[0]->_ret & 128 },
    },
    status => {
        is      => 'rw',
        default => 'Running',
    },
    on_exit => { is => 'rw', },
  };

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
    return $self->exit if $self->has__ret;

    my $ret = -1;    # default means: bad execution for some reasons

    if ( $pid > 0 ) {

        local $?;
        local $!;

        my $pid = waitpid $self->pid, 0;
        $ret = $?;

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
    }

    $self->_ret($ret);

    if ( my $subref = $self->on_exit ) {
        $subref->($self);
    }

    $self->status(
        do {
            if ( $self->signal != 0 ) {
                $log->warn(
                    'Killed',
                    {
                        pid    => $self->pid,
                        signal => $self->signal,
                        core   => $self->core
                    }
                );
            }
            elsif ( $self->exit != 0 ) {
                $log->warn(
                    'Non-zero exit',
                    {
                        pid  => $self->pid,
                        exit => $self->exit
                    }
                );
            }
            else {
                'Terminated';
            }
        }
    );

    not( $self->exit or $self->signal );
}

sub DESTROY {
    my $self = shift;
    $self->close;
    $self->wait_child;
}

1;

__END__

=head1 NAME

Sys::Cmd::Process - process interaction object for Sys::Cmd

=head1 VERSION

v0.986.3 (2025-12-11)

=head1 SYNOPSIS

    use Sys::Cmd qw[spawn];

    my $proc = spawn(
        '/usr/bin/cat', '--number',
        {
            dir   => '/',
            input => "x\ny\nz\n",
        }
    );

    while ( my $line = $proc->stdout->getline ) {
        print $line;
    }

    my @errors = $proc->stderr->getlines;
    $proc->wait_child() or warn $proc->status;

    # Or manually read process termination information
    $proc->exit();          # exit status
    $proc->signal();        # signal
    $proc->core();          # core dumped? (boolean)


=head1 DESCRIPTION

The B<Sys::Cmd::Process> class is used by L<Sys::Cmd> to represent a
running process. It holds Input/Output file handles and a few methods
for finalising the process and obtaining exit information.

Process objects come with the following read-only attributes:

=over

=item cmdline() -> @list | $string

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

=back

When no more interaction with the process is required, the following
methods are used for cleanup:

=over

=item close()

Close the remaining open filehandles to the child process.

=item wait_child() -> $bool

Wait for the child process to finish using
L<waitpid|http://perldoc.perl.org/functions/waitpid.html> and collect
the exit status. Returns true if the child terminated normally.

=back

After C<wait_child> has been called the following attributes are also
valid:

=over

=item core() -> $bool

A boolean indicating if the process core was dumped.

=item exit() -> $int

The command's exit value.

=item signal() -> $int

The signal number (if any) that terminated the command.

=item status() -> $str

A description of the process state. B<Sys::Cmd::Process> sets it to a
string starting with one of the following:

=over

=item * Running - set at creation time

=item * Terminated - normal process exit

=item * Non-zero exit - unusual process exit

=item * Killed - termination via signal

=back

This attribute can be set by the caller if desired, but note that
C<wait_child()> overwrites it.

=back

=head1 AUTHOR

Mark Lawrence E<lt>mark@rekudos.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011-2025 Mark Lawrence <mark@rekudos.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

