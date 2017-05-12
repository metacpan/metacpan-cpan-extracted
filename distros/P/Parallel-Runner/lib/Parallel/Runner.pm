package Parallel::Runner;
use strict;
use warnings;

use POSIX ();
use Time::HiRes qw/sleep/;
use Carp;
use Child qw/child/;

our $VERSION = '0.013';

for my $accessor (qw/ exit_callback data_callback iteration_callback _children pid max iteration_delay reap_callback pipe/) {
    my $sub = sub {
        my $self = shift;
        ( $self->{$accessor} ) = @_ if @_;
        return $self->{$accessor};
    };
    no strict 'refs';
    *$accessor = $sub;
}

sub children {
    my $self = shift;
    my @active;

    for my $proc ( @{$self->_children || []}, @_ ) {
        if ( defined $proc->exit_status ) {
            if ( $self->data_callback ) {
                my $data = $proc->read();
                $self->data_callback->($data);
            }

            $self->reap_callback->( $proc->exit_status, $proc->pid, $proc->pid, $proc )
                if $self->reap_callback;

            next;
        }
        push @active => $proc;
    }

    $self->_children( \@active );
    return @active;
}

sub new {
    my $class = shift;
    my ($max) = shift;
    return bless(
        {
            _children       => [],
            pid             => $$,
            max             => $max || 1,
            iteration_delay => 0.1,
            @_,
        },
        $class
    );
}

sub run {
    my $self = shift;
    my ( $code, $force_fork ) = @_;
    croak("Called run() in child process")
        unless $self->pid == $$;

    my $fork = $force_fork || $self->max > 1;
    return $self->_fork($code)
        if $fork;

    my ($data) = $code->();
    $self->data_callback->($data)
        if $self->data_callback;

    return;
}

sub _fork {
    my $self = shift;
    my ($code) = @_;

    # Wait for a slot
    $self->_iterate(
        sub {
            $self->children >= $self->max;
        }
    );

    my $proc = Child->new(
        sub {
            my $parent = shift;
            $self->_children( [] );

            my @return = $code->($parent);

            $self->exit_callback->(@return)
                if $self->exit_callback;

            $parent->write( $return[0] )
                if $self->data_callback;

        },
        $self->pipe || $self->data_callback ? ( pipe => $self->pipe ) : ()
    )->start();

    $self->_iterate( sub { !defined $proc->exit_status } )
        if $self->max == 1;

    $self->children($proc);

    return $proc;
}

sub finish {
    my $self = shift;
    $self->_iterate( sub { $self->children }, @_ );
}

sub _iterate {
    my $self = shift;
    my ( $condition, $timeout, $timeoutsub ) = @_;
    my $counter = 0;

    while ( $condition->() ) {
        $self->iteration_callback->($self)
            if $self->iteration_callback;

        $counter += $self->iteration_delay;
        last if $timeout and $counter >= $timeout;

        sleep $self->iteration_delay;
    }

    $timeoutsub->()
        if $timeout
        && $timeoutsub
        && $counter >= $timeout;
    1;
}

sub killall {
    my $self = shift;
    my ( $sig, $warn ) = @_;

    if ($warn) {
        warn time . " - Killing: $_ - $sig\n" for grep { $_->pid } $self->children;
    }

    $_->kill($sig) for $self->children;
}

sub DESTROY {
    my $self = shift;
    return
        unless $self->pid == $$
        && $self->children;
    warn <<EOT;
Parallel::Runner object destroyed without first calling finish(), This will
terminate all your child processes. This either means you forgot to call
finish() or your parent process has died.
EOT

    return $self->finish()
        if $^O eq 'MSWin32';

    $self->finish(
        1,
        sub {
            $self->killall( 15, 1 );
            $self->finish(
                4,
                sub {
                    $self->killall( 9, 1 );
                    $self->finish(10);
                }
            );
        }
    );
}

1;

=pod

=head1 NAME

Parallel::Runner - An object to manage running things in parallel processes.

=head1 DESCRIPTION

There are several other modules to do this, you probably want one of them. This
module exists as a super specialised parallel task manager. You create the
object with a proces limit and callbacks for what to do while waiting for a
free process slot, as well as a callback for what a process shoudl do just
before exiting.

You must explicetly call $runner->finish() when you are done. If the runner is
destroyed before it's children are finished a warning will be generated and
your child processes will be killed, by force if necessary.

If you specify a maximum of 1 then no forking will occur, and run() will block
until the coderef returns. You can force a fork by providing a boolean true
value as the second argument to run(), this will force the runner to fork
before running the coderef, however run() will still block until it the child
exits.

=head1 SYNOPSYS

    #!/usr/bin/perl
    use strict;
    use warnings;
    use Parallel::Runner;

    my $runner = Parallel::Runner->new(4);
    $runner->run( sub { ... } );
    $runner->run( sub { ... } );
    $runner->run( sub { ... } );
    $runner->run( sub { ... } );

    # This will block until one of the previous 4 finishes
    $runner->run( sub { ... } );

    # Do not forget this.
    $runner->finish;

=head1 CONSTRUCTOR

=over 4

=item $runner = $class->new( $max, $accessor => $value, ... );

Create a new instance of Parallel::Runner. $accessor can be anything listed
under the ACCESSORS section. $max should be the maximum number of processes
allowed, defaults to 1.

=back

=head1 ACCESSORS

These are simple accessors, provididng an argument sets the accessor to that
argument, no argument it simply returns the current value.

=over 4

=item $val = $runner->data_callback( \&callback )

If this is specified than IPC will be automatically enabled, and the final
return from each process will be passed into this handler in the main process.
Due to the way IPC works only strings/numerical data is passed, if you need to
pass a ref you will need to serialize it yourself before returning it, followed
by deserializing it in your callback.

Example:

    # Place to put the accumulated data
    my @accum_data;

    # Create the runner with a callback that pushes the data onto our array.
    $runner = $CLASS->new( 2,
        data_callback => sub {
            my ($data) = @_;
            push @accum_data => $data;
        },
    );

    # 4 processes that return data
    $runner->run( sub { return "foo" });
    $runner->run( sub { return "bar" });
    $runner->run( sub { return "baz" });
    $runner->run( sub { return "bat" });
    $runner->finish;

    # Verify the data (order is not predictable)
    is_deeply(
        [ sort @accum_data ],
        [ sort qw/foo bar baz bat/ ],
        "Got all data returned by subprocesses"
    );

=item $val = $runner->exit_callback( \&callback )

Codref to call just before a child exits (called within child)

=item $val = $runner->iteration_delay( $float );

How long to wait per iterate if nothing has changed.

=item $val = $runner->iteration_callback( $newval )

Coderef to call multiple times in a loop while run() is blocking waiting for a
process slot.

=item $val = $runner->reap_callback( $newval )

Codref to call whenever a pid is reaped using waitpid. The callback sub will be
passed 3 values The first is the exit status of the child process. The second
is the pid of the child process. The third used to be the return of waitpid,
but this is depricated as L<Child> is now used and throws an exception when
waitpid is not what it should be. The third is simply the pid of the child
process again. The final argument is the child process object itself.

    $runner->reap_callback( sub {
        my ( $status, $pid, $pid_again, $proc ) = @_;

        # Status as returned from system, so 0 is good, 1+ is bad.
        die "Child $pid did not exit 0"
            if $status;
    });

=item @children = $runner->children( @append )

Returns a list of L<Child::Link::Proc> objects.

=item $val = $runner->pid()

pid of the parent process

=item $val = $runner->max( $newval )

Maximum number of children

=back

=head1 OBJECT METHODS

=over 4

=item run( $code )

=item run( $code, $force_fork )

Run the specified code in a child process. Blocks if no free slots are
available. Force fork can be used to force a fork when max is 1, however it
will still block until the child exits.

=item finish()

=item finish( $timeout )

=item finish( $timeout, $timeoutcallback )

Wait for all children to finish, then clean up after them. If a timeout is
specified it will return after the timeout regardless of wether or not children
have all exited. If there is a timeout call back then that code will be run
upon timeout just before the method returns.

NOTE: DO NOT LET YOUR RUNNER BE DESTROYED BEFORE FINISH COMPLETES WITHOUT A
TIMEOUT.

the runner will kill all children, possibly with force if your runner is
destroyed with children still running, or not waited on.

=item killall( $sig )

Send all children the specified kill signal.

=item DESTROY()

Automagically called when the object is destroyed. If called while children are
running it will forcefully clean up after you as follows:

1) Sends an ugly warning.

2) Will first give all your children 1 second to complete.

Windows) Strawberry fails with processes, so on windows DESTROY will wait as
long as needed, possibly forever.

3) Sends kill signal 15 to all children then waits up to 4 seconds.

4) Sends kill signal 9 to any remaining children then waits up to 10 seconds

5) Gives up and returns

=back

=head1 FENNEC PROJECT

This module is part of the Fennec project. See L<Fennec> for more details.
Fennec is a project to develop an extendable and powerful testing framework.
Together the tools that make up the Fennec framework provide a potent testing
environment.

The tools provided by Fennec are also useful on their own. Sometimes a tool
created for Fennec is useful outside the greator framework. Such tools are
turned into their own projects. This is one such project.

=over 2

=item L<Fennec> - The core framework

The primary Fennec project that ties them all together.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Parallel-Runner is free software; Standard perl licence.

Parallel-Runner is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
