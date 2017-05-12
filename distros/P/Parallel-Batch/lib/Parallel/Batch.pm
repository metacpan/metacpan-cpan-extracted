package Parallel::Batch;

use 5.008;
use strict;
use warnings;

use POSIX qw/:sys_wait_h/;
use parent qw/Class::Accessor::Fast/;
Parallel::Batch->mk_accessors(qw/jobs code maxprocs progress_cb/);

our $VERSION = '0.04';


sub run {
    my $self = shift;

    my $procs = 0;
    my @jobs = @{$self->jobs};
    my %inprogress;
    # progress start(count)
    $self->_send_progress(start => scalar @jobs);

    while (@jobs) {
	if ($procs < $self->maxprocs) {
	    my $job = shift @jobs;
	    my $pid = fork();
	    die unless defined $pid;
	    if ($pid == 0) {
		$self->code->($job);
		exit;
	    }
	    if ($pid > 0) {
		$procs++;
                # progress new child
                $inprogress{$pid} = $job;
                $self->_send_progress('new', $job);
	    }
	}
	if ($procs == $self->maxprocs) {
	    if ((my $pid = wait()) > 0) {
		$procs--;
                # progress child finished
                $self->_send_progress('finish', delete $inprogress{$pid});
	    }
	}
	if ((my $pid = waitpid(-1, WNOHANG)) > 0) {
	    $procs--;
            $self->_send_progress('finish', delete $inprogress{$pid});
	}
    }
    while ($procs > 0) {
	if ((my $pid = wait()) > 0) {
	    $procs--;
            $self->_send_progress('finish', delete $inprogress{$pid});
	}
    }
    # progress done
    $self->_send_progress('done');
}

sub _send_progress {
    my ($self, $type, $arg) = @_;

    return unless $self->progress_cb;
    my $cb = $self->progress_cb->{$type};
    if (defined $cb)
    {
        $cb->($arg);
    }
}

1;
__END__

=head1 NAME

Parallel::Batch - Run a large number of similar processes using
bounded parallelism

=head1 SYNOPSIS

  use Parallel::Batch;
  
  my $batch = Parallel::Batch->new({code => \&frobnicate,
                                    jobs => [ ... ],
                                    maxprocs => 8});
  $batch->run();

=head1 DESCRIPTION

Parallel::Batch solves a common problem allowing modern multi-CPU
computers to be used efficiently: you have a large number of
independent pieces of data that all need to be processed somehow, and
can run several of these processes at the same time.

There are a few trivial ways to execute a large number of jobs. You
could run the entire set serially, but this will not use all the
available processing speed. You could also create I<n> processes at
once to run all jobs simultaneously, but this tends to quickly exhast
other resources like memory and I/O bandwidth, making the entire
process slower. Or you could divide the set into I<m> equally-sized
groups and have each processor run its subset serially, but this will
usually waste time at the end if some jobs take longer than others to
finish.

This module works by calling C<fork()> to create a new process,
invoking a user-specified function on the next piece of data within
this process, and returning once all data has been thusly processed
and all processes exited. It also keeps track of the total number of
jobs in progress, and will keep this under a set limit by delaying new
forks until existing processes terminate.

=head2 CONSTRUCTOR

=head3 new

Options:

The following options can be passed to the constructor in a hashref, or
retrieved or changed later using their own accessor methods

=over

=item code

coderef to be run on each piece of data. It will be passed a single
argument, which is an element of the C<jobs> array.

=item jobs

Array of data objects to be processed.

=item maxprocs

Maximum number of child processes that should be running at any time.

=item progress_cb

Hashref of progress callbacks

=back

=head2 METHODS

=head3 run

Start running the jobs, and return once all are completed.


=head2 PROGRESS NOTIFICATION

Parallel::Batch can report its progress through applicaton-defined
callbacks as it runs. If the C<progress_cb> argument is a hashref
containing any of the following keys, they will be called at the
places descibed:

=over

=item start

Will be called just before any processes are spawned.

=item new

Will be called after each new process has been created.

=item finish

Will be called when a child process exits.

=item done

Will be called after all jobs are completed and all child processes
have terminated.

=back

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Stephen Cavilia, E<lt>sac@atomicradi.us<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Stephen Cavilia

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
