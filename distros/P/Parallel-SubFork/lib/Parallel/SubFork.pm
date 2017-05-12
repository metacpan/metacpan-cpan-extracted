package Parallel::SubFork;

=head1 NAME

Parallel::SubFork - Manage Perl functions in forked processes. 

=head1 SYNOPSIS

	use Parallel::SubFork;
	my $manager = Parallel::SubFork->new();
	
	# Start two parallel tasks
	$manager->start(sub { sleep 10; print "Done\n" });
	$manager->start(\&callback, @args);
	
	# Wait for all tasks to resume
	$manager->wait_for_all();
	
	# Loop through all tasks
	foreach my $task ($manager->tasks) {
		# Access any of the properties
		printf "Task with PID %d resumed\n", $task->pid;
		printf "Exist status: %d, exit code: %d\n", $task->status, $task->exit_code;
		printf "Args of task where: %s\n", join(', ', $task->args);
		print "\n";
	}

or more easily:

	use Parallel::SubFork qw(sub_fork);
	
	my $task = sub_fork(\&callback, @args);
	$task->wait_for();

=head1 DESCRIPTION

This module provides a simple wrapper over the module L<Parallel::SubFork::Task>
which in turns simplifies the usage of the system calls C<fork> and C<waitpid>.
The idea is to isolate the tasks to be execute in functions or closures and to
execute them in a separated process in order to take advantage of
parallelization.

=head1 TASKS

A task is simply a Perl function or a closure that will get executed in a
different process. This module will take care of creating and managing the new
processes. All that's left is to code the logic of each task and to provide the
proper I<inter process communication> (IPC) mechanism if needed.

A task will run in it's own process thus it's important to understand that all
modifications to variables within the function, even global variables, will have
no impact on the parent process. Communication or data exchange between the task
and the dispatcher (the code that started the task) has to be performed through
standard IPC mechanisms. For further details on how to establish different
communication channels refer to the documentation of L<perlipc>.

Since a task is running within a process it's expected that the task will return
an exit code (C<0> for an execution without flaws and any other integer for
reporting an error) and not a true value in the I<Perl> sense. The return value
will be used as the exit code of the process that's running the task.

=cut

use strict;
use warnings;

use Carp;

use base 'Exporter';
our @EXPORT_OK = qw(
	sub_fork
);

use Parallel::SubFork::Task;

use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(
	qw(
		tasks
		_dispatcher_pid
	)
);


# Version of the module
our $VERSION = '0.10';


=head1 FUNCTIONS

The module provides the following functions:

=cut


=head2 sub_fork

This function provides a simple way for creating and launching tasks. It is
declared using a prototype which allows it to be called as:

	my $task = sub_fork { print "$$ > $_\n" for 1 .. 10 };
	$task->wait_for();

Parameters:

=over

=item $code

The code reference to execute.

=item @args (optional)

The arguments to pass to the code reference.

=back

=cut

sub sub_fork (&;@) {

	# Arguments
	my ($code, @args) = @_;

	my $task;
	eval {
		$task = Parallel::SubFork::Task->start($code, @args);
		1;
	} or do {
		croak $@;
	};
	return $task;
}


=head1 METHODS

The module defines the following methods:

=cut


=head2 new

Creates a new C<Parallel::SubFork>.

=cut

sub new {

	# Arguments
	my $class = shift;
	
	# Create a blessed instance
	my $self = bless {}, ref($class) || $class;
	
	# The list of children spawned
	$self->tasks([]);
	
	# The PID of the dispacher
	$self->_dispatcher_pid($$);

	return $self;
}


=head2 start

Starts the execution of a new task in a different process. A task consists of a
code reference (a closure or a reference to a subroutine) and of an arguments
list.

This method will actually fork a new process and execute the given code
reference in the child process. For the parent process this method will return
automatically. The child process will start executing the code reference with
the given arguments.

The parent process, the one that started the task should wait for the child
process to resume. This can be performed individually on each tasks through the
method L<"Parallel::SubFork::Task/wait_for"> or for all tasks launched through
this instance through the method L<"wait_for_all">

B<NOTE:> This method requires that the caller process is the same process as the
one that created the instance object being called.

Parameters:

=over

=item $code

The code reference to execute.

=item @args (optional)

The arguments to pass to the code reference.

=back

=cut

sub start {

	# Arguments
	my $self = shift;
	my ($code, @args) = @_;

	# Stop if this is not the dispatcher
	$self->_assert_is_dispatcher();


	# Start the task and remember it
	my $task;
	eval {
		$task = Parallel::SubFork::Task->start($code, @args);
		1;
	} or do {
		croak $@;
	};
	push @{ $self->{tasks} }, $task;
	
	return $task;
}


=head2 wait_for_all

This method waits for all tasks started so far and returns when they all have
resumed. This is useful for creating a rally point for multiple tasks.

B<NOTE:> This method requires that the caller process is the same process as the
one that created the instance object being called.

=cut

sub wait_for_all {
	my $self = shift;

	$self->_assert_is_dispatcher();

	foreach my $task ($self->tasks) {
		eval {
			$task->wait_for();
			1;
		} or do {
			croak $@;
		};
	}
}


=head2 tasks

Returns the tasks started so far by this instance. This method returns a list
and not an array ref.

=cut

sub tasks {
	my $self = shift;

	my $tasks = $self->{tasks};
	my @tasks = defined $tasks ? @{ $tasks } : ();
	return @tasks;
}


=head2 _assert_is_dispatcher

Used to check if the current process is the same one that invoked the
constructor.

This is required as only the dispatcher process is allowed to start and wait for
tasks.

=cut

sub _assert_is_dispatcher {
	my $self = shift;
	return if $self->_dispatcher_pid == $$;
	croak "Process $$ is not the main dispatcher";
}


# Return a true value
1;


=head1 NOTES

The API is not yet frozen and could change as the module goes public.

=head1 SEE ALSO

Take a look at L<POE> for asynchronous multitasking and networking.

=head1 AUTHOR

Emmanuel Rodriguez, E<lt>emmanuel.rodriguez@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2010 by Emmanuel Rodriguez

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
