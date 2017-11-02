#
# Copyright (C) 2015-2017 Joelle Maslak
# All Rights Reserved - See License
#

package Parallel::WorkUnit;
$Parallel::WorkUnit::VERSION = '1.012';
use v5.8;

# ABSTRACT: Provide easy-to-use forking with ability to pass back data

use strict;
use warnings;
use autodie;

use Try::Tiny;
my $do_thread;
## no critic (BuiltinFunctions::ProhibitStringyEval)
$do_thread = eval 'use threads qw//; 1' if $^O eq 'MSWin32';
## critic
if ($do_thread) { eval 'use Thread::Queue;'; }

use Carp;

use IO::Pipe;
use IO::Select;
use Moose;
use Moose::Util::TypeConstraints;
use POSIX ':sys_wait_h';
use Storable;

use namespace::autoclean;


subtype 'Parallel::WorkUnit::PositiveInt', as 'Int',
  where { $_ > 0 },
  message { "The number you provided, $_, was not a positive number" };


has 'max_children' => (
    is      => 'rw',
    isa     => 'Maybe[Parallel::WorkUnit::PositiveInt]',
    default => 5,
    trigger => sub { $_[0]->_start_queued_children() },
);

has '_subprocs' => (
    is       => 'rw',
    isa      => 'HashRef',
    init_arg => undef
);

# This only gets used on Win32.
has '_queue' => (
    is       => 'rw',
    init_arg => undef
);

# This only gets used on Win32
has '_count' => (
    is       => 'rw',
    isa      => 'Int',
    init_arg => undef,
    default  => 1
);

# Children queued
has '_queued_children' => (
    is       => 'rw',
    isa      => 'ArrayRef[ArrayRef[Coderef]]',
    init_arg => undef,
    default  => sub { [] },
);


sub BUILD {
    my $self = shift;

    $self->_subprocs( {} );

    if ($do_thread) {
        $self->_queue( Thread::Queue->new() );
    }

    return;
}


sub async {
    if ( $#_ != 2 ) { confess 'invalid call'; }
    my ( $self, $sub, $callback ) = @_;

    my $pipe = IO::Pipe->new();

    my ( $pid, $thr );
    if ($do_thread) {
        $pid = $self->_count();
        $self->_count( $pid + 1 );

        $thr = threads->create( sub { $self->_child( $sub, $pipe, $pid ); } );
        if ( !defined($thr) ) { die "thread creation failed: $!"; }
    } else {
        $pid = fork();
    }

    if ($pid) {
        # We are in the parent process
        $pipe->reader();

        $self->_subprocs()->{$pid} = {
            fh       => $pipe,
            callback => $callback,
            caller   => [ caller() ],
            thread   => $thr
        };

        return $pid;

    } else {
        return $self->_child( $sub, $pipe, undef );
    }
}

sub _child {
    if ( scalar(@_) != 4 ) { confess 'invalid call'; }
    my ( $self, $sub, $pipe, $pid ) = @_;

    # We are in the child process
    $pipe->writer();
    $pipe->autoflush(1);

    try {
        my $result = $sub->();
        $self->_send_result( $pipe, $result, $pid );
    }
    catch {
        $self->_send_error( $pipe, $_, $pid );
    };

    # Windows doesn't do fork(), it does threads...
    if ($do_thread) {
        return 1;
    } else {
        exit();
    }
}


sub waitall {
    if ( $#_ != 0 ) { confess 'invalid call'; }
    my ($self) = @_;

    # Tail recursion
    if ( $self->waitone() ) { goto &waitall }
}


sub waitone {
    if ( $#_ != 0 ) { confess 'invalid call'; }
    my ($self) = @_;

    my $sp = $self->_subprocs();
    if ( !keys(%$sp) ) { return; }

    if ($do_thread) {
        # On Windows
        #
        my $child = $self->_queue()->dequeue();

        my $thr = $self->_subprocs()->{$child}{thread};
        $self->_read_result($child);
        $thr->join();

        # Start queued children, if needed
        $self->_start_queued_children();

        return 1;
    } else {
        # On everything but Windows
        #
        my $s = IO::Select->new();
        foreach ( keys(%$sp) ) { $s->add( $sp->{$_}{fh} ); }

        my @ready = $s->can_read();

        foreach my $fh (@ready) {
            foreach my $child ( keys(%$sp) ) {
                if ( defined( $fh->fileno() ) ) {
                    if ( $fh->fileno() == $sp->{$child}{fh}->fileno() ) {
                        my $thr = $self->_subprocs()->{$child}{thread};
                        $self->_read_result($child);

                        if ($do_thread) {
                            $thr->join();
                        } else {
                            waitpid( $child, 0 );
                        }

                        # Start queued children, if needed
                        $self->_start_queued_children();

                        return 1;    # We don't want to read more than one!
                    }
                }
            }
        }
    }

    # We should never get here
    return;
}


## no critic ('Subroutines::ProhibitBuiltinHomonyms')
sub wait {
    if ( $#_ != 1 ) { confess 'invalid call'; }
    my ( $self, $pid ) = @_;

    if ( !exists( $self->_subprocs()->{$pid} ) ) {

        # We don't warn/die because it's possible that there is
        # a race between callback and here, in the main thread.
        return;
    }

    my $thr    = $self->_subprocs()->{$pid}{thread};
    my $result = $self->_read_result($pid);

    if ($do_thread) {
        $thr->join();
    } else {
        waitpid( $pid, 0 );
    }

    return $result;
}
## use critic


sub count {
    if ( $#_ != 0 ) { confess 'invalid call'; }
    my ($self) = @_;

    my $sp = $self->_subprocs();
    return scalar( keys %$sp );
}


sub queue {
    if ( $#_ != 2 ) { confess 'invalid call'; }
    my ( $self, $sub, $callback ) = @_;

    push @{ $self->_queued_children }, [ $sub, $callback ];
    return $self->_start_queued_children();
}

sub _send_result {
    if ( $#_ != 3 ) { confess 'invalid call'; }
    my ( $self, $fh, $msg, $pid ) = @_;

    return $self->_send( $fh, 'RESULT', $msg, $pid );
}

sub _send_error {
    if ( $#_ != 3 ) { confess 'invalid call'; }
    my ( $self, $fh, $err, $pid ) = @_;

    return $self->_send( $fh, 'ERROR', $err, $pid );
}

sub _send {
    if ( $#_ != 4 ) { confess 'invalid call'; }
    my ( $self, $fh, $type, $data, $pid ) = @_;

    my $msg = Storable::freeze( \$data );

    if ( !defined($msg) ) {
        die 'freeze() returned undef for child return value';
    }

    if ($do_thread) {
        $self->_queue()->enqueue($pid);
    }

    $fh->write($type);
    $fh->write("\n");

    $fh->write( length($msg) );
    $fh->write("\n");

    binmode( $fh, ':raw' );

    $fh->write($msg);

    $fh->close();
    return;
}

sub _read_result {
    if ( $#_ != 1 ) { confess 'invalid call'; }
    my ( $self, $child ) = @_;

    my $cinfo = $self->_subprocs()->{$child};
    my $fh    = $cinfo->{fh};

    my $type = <$fh>;
    if ( !defined($type) ) { die 'Could not read child data'; }
    chomp($type);

    my $size = <$fh>;
    chomp($size);

    binmode($fh);

    my $result = '';

    my $ret = 1;
    while ( defined($ret) && ( length($result) < $size ) ) {
        my $s = $size - length($result);

        my $part = '';
        $ret = $fh->read( $part, $s );
        if ( defined($ret) ) { $result .= $part; }
    }

    my $data = ${ Storable::thaw($result) };

    my $caller = $self->_subprocs()->{$child}{caller};
    my $thr    = $self->_subprocs()->{$child}{thread};
    delete $self->_subprocs()->{$child};
    $fh->close();

    if ( $type eq 'RESULT' ) {
        $cinfo->{callback}->($data);
    } else {
        if ($do_thread) { $thr->join(); }
        die(    "Child (created at "
              . $caller->[1]
              . " line "
              . $caller->[2]
              . ") died with error: $data" );
    }

    return;
}

# Start queued children, if possible.
# Returns 1 if children were started, undef otherwise
sub _start_queued_children() {
    if ( $#_ != 0 ) { confess 'invalid call' }
    my ($self) = @_;

    if ( !( @{ $self->_queued_children } ) ) { return; }

    # Can we start a queued process?
    while ( scalar @{ $self->_queued_children } ) {
        if ( ( !defined( $self->max_children ) ) || ( $self->count < $self->max_children ) ) {
            # Start queued child
            my $ele = shift @{ $self->_queued_children };
            $self->async( $ele->[0], $ele->[1] );
        } else {
            # Can't unqueue
            return;
        }
    }

    # We started at least one process
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Parallel::WorkUnit - Provide easy-to-use forking with ability to pass back data

=head1 VERSION

version 1.012

=head1 SYNOPSIS

  my $wu = Parallel::WorkUnit->new();
  $wu->async( sub { ... }, \&callback );

  $wu->waitall();

  $wu->max_children(5);
  $wu->queue( sub { ... }, \&callback );
  $wu->waitall();

=head1 DESCRIPTION

This is a very simple forking implementation of parallelism, with the
ability to pass data back from the asyncronous child process in a
relatively efficient way (with the limitation of using a pipe to pass
the information, serialized, back).  It was designed to be very simple
for a developer to use, with the ability to pass reasonably large amounts
of data back to the parent process.

There are many other Parallel::* applications in CPAN - it would be worth
any developer's time to look through those and choose the best one.

=head1 ATTRIBUTES

=head2 max_children

  $wu->max_children(5);
  $wu->max_children(undef);

  say "Max number of children: " . $wu->max_children();

If set to a value other than undef, limits the number of outstanding
queue children (created by the C<queue()> method) that can be executing
at any given time.  This defaults to 5.

Calling without any parameters will return the number of children.

=head1 METHODS

=head2 new

Create a new workunit class.  Optionally, takes a list that corresponds
to a hashref, in the form of key and value.  This accepts the key
C<max_children>, which, if present (and not undef) will limit the
number of spawned subprocesses that can be active when using the
C<queue()> method.  Defaults to 5.  See the C<max_children> method
for additional information.

=head2 async( sub { ... }, \&callback )

Spawns work on a new forked process.  The forked process inherits
all Perl state from the parent process, as would be expected with
a standard C<fork()> call.  The child shares nothing with the
parent, other than the return value of the work done.

The work is specified either as a subroutine reference or an
anonymous sub (C<sub { ... }>) and should return a scalar.  Any
scalar that L<Storable>'s C<freeze()> method can deal with
is acceptable (for instance, a hash reference or C<undef>).

When the work is completed, it serializes the result and streams
it back to the parent process via a pipe.  The parent, in a
C<waitall()> call, will call the callback function with the
unserialized return value.

Should the child process C<die>, the parent process will also
die (inside the C<waitall()> method).

The PID of the child is returned to the parent process when
this method is executed.

The C<max_children> attribute is not examined in this method - you
can spawn a new child regardless of the number of children already
spawned. However, you children started with this method still count
against the limit used by C<queue()>.

Note: on Windows with threaded Perl, threads instead of forks are used.
See C<thread> for the caveats that apply.  The PID returned is instead
a meaningless (outside of this module) counter, not associated with any
Windows thread identifier.

=head2 waitall()

Called from the parent method while waiting for the children
to exit.  This method handles children that C<die()> or return
a serializable data structure.  When all children return, this
method will return.

If a child dies unexpectedly, this method will C<die()> and propagate a
modified exception.

=head2 waitone()

This method similarly to C<waitall()>, but only waits for
a single PID.  It will return after any PID exits.

If this method is called when there is no processes executing,
it will simply return undef. Otherwise, it will wait and then
return 1.

=head2 wait($pid)

This functions simiarly to C<waitone()>, but waits only for
a specific PID.  See the C<waitone()> documentation above
for details.

If C<wait()> is called on a process that is already done
executing, it simply returns.  Otherwise, it waits until the
child process's work unit is complete and executes the callback
routine, then returns.

=head2 count()

This method returns the number of currently outstanding
threads (in either a running state or a waiting to send their
output).

=head2 queue( sub { ... }, \&callback )

Spawns work on a new forked process, doing so immediately if less
than C<max_children> are running.  If there are already
C<max_children> are running, this will run the process once a slot
becomes available.

This method should be treated as nearly identical to C<async()>,
with the only difference being the above behavior (limiting to
C<max_children>) and not returning a PID.  Instead, a value of 1
is returned if the process is immediately started, C<undef>
otherwise.

=head1 BUGS

Windows doesn't do C<fork()>, but emulates it with threads.  As a result,
any thread unsafe library is going to cause problems with Windows.  In
addition, all the normal thread caveats apply - see L<threads> for more
information.

In addition, this code is unlikely to function properly on a Windows without
threaded Perl.

=head1 AUTHOR

Joelle Maslak <jmaslak@antelope.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Joelle Maslak.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
