package Parallel::Supervisor;
# A module for managing children / forked processes
# used in a supervisor / worker pattern, eg Parallel::ForkManager

use strict;
use warnings;
use Carp qw(cluck carp);
use Symbol qw(geniosym);
use IO::Pipe;
use IO::Handle;

our $VERSION = "0.03";

sub new # create a new collection of processes
{
    my $class = shift;
    my $self = {
    # data
    'STRUCTS' => {}, # children ready to run (idx name)
    'PROCESSES' => {}, # children running (idx pid)
    'FINISHED' => {}, # children finished running (idx name)
    'NAMES' => {} # index on running child names (idx pid)
    };
    
    bless($self, $class);
    return $self;
}

#### Getters for dereferencing Object's data structures
sub structs # returns hash of all the jobs prepared but not attached
{ my $self = shift; return $self->{STRUCTS} }

sub processes # returns hash of all the jobs attached
{ my $self = shift; return $self->{PROCESSES} }

sub names # returns a hash of all pid->STRUCTS of attached processes (%NAMES)
{ my $self = shift; return $self->{NAMES} }

sub finished # returns a hash of all pid->STRUCTS of completed processes (%FINISHED)
{ my $self = shift; return $self->{FINISHED} }

sub prepare # (name, cmd_to_eval) create a child struct and add it to %structs
{
    my ($self, $name, @cmd_args) = @_;
    my $cmd = "@cmd_args";

    return undef unless defined $name;
    return undef if $self->is_ready($name);

    #### Setup IPC
    my ($child_writer, $parent_reader) = (geniosym, geniosym);
    eval {
        pipe( $parent_reader, $child_writer );
    } or cluck "Failed to create pipe for reading child output.";

    $parent_reader->autoflush(1);
    $child_writer->autoflush(1);

    $self->{STRUCTS}->{$name} = { id => $name,
                         cmd => "$cmd",
                         child_writer => $child_writer,
                         parent_reader => $parent_reader
     };
     
     return 1;
}

sub is_ready # check whether name is in %structs;
{
    my ($self,$name) =  @_;

    return undef unless (keys(%{$self->{STRUCTS}} ) );
    for ( keys %{$self->{STRUCTS}} ) {
        return 1 if $_ eq $name;
    }
    return undef ;
}

sub is_attached # check for a running process with this name
{
    my ($self,$name) =  @_;

    return undef unless ( $self->{NAMES} );
    return grep {$_ eq $name} (values( %{ $self->{NAMES} } ) );
}

# move from %structs to %processes with given pid, register @name
sub attach # ident, pid
{
    my ($self,$name,$pid) =  @_;

    return undef unless $pid =~ /^\d+$/;
    return undef if ( $self->is_attached( $name ) ) ;
    return undef unless ( $self->is_ready( $name ) );

    $self->{PROCESSES}{$pid} = $self->{STRUCTS}{$name};
    delete $self->{STRUCTS}{$name};
    $self->{NAMES}->{$pid} = $name;

    return $?;
}

# move from %processes to %structs (does not check whether process still exists)
sub detach # pid
{
    my ($self, $pid) = @_;

    if ( (! defined $pid) ||  ($pid !~ /^\d+$/) ) {
        carp "Error! Can't detach non-numeric pid $pid\n";
        return undef;
    }

    # TODO : verify actual running process with pid
    my $name = $self->{PROCESSES}{$pid}{id};
    if (! defined $name ) {
        carp "detach: could not find process record for pid $pid\n";
        return undef;
    }
    if ($self->is_ready($name) ) {
        carp "detach: name $name is ready, not running as $pid\n";
        return undef;
    }
    if ($self->{NAMES}) { 
        delete $self->{NAMES}->{$pid};
    }

    $self->{FINISHED}{$name} = $self->{PROCESSES}{$pid};
    delete ${$self->{PROCESSES}}{$pid};
    return 1;
}

# delete the struct
sub forget # ident 
{
    my ($self, $name) = @_;

    return undef unless defined $name;
    if ($self->is_attached($name) ) {
        carp "Cannot forget $name because it is alive.";
        return undef;
    }
    delete $self->{STRUCTS}->{$name};
    delete $self->{FINISHED}->{$name};
    return 1;
}

sub reset # delete all STRUCTS, PROCESSES, NAMES, FINISHED
{
    my $self = shift;
    $self->{STRUCTS} = {}; # children ready to run (idx name)
    $self->{PROCESSES} = {}; # children running (idx pid)
    $self->{FINISHED} = {}; # children finished running (idx n ame)
    $self->{NAMES} = {}; # index on running child names (idx pid)
}
# NOTE: an all numeric name could be confused with a PID!!!!
#  since both structs and processes are checked for a match
sub get_child # return the hash for child with this name

{
    my ($self, $name) = @_;

    my %ret = ();
    return \%ret unless defined $name;
    if ( $self->is_ready( $name ) ) {
        # print STDERR "get_child: $name is ready\n";
        %ret = $self->{STRUCTS}->{$name};
    }
    if ( $self->is_attached( $name ) ) {
        # print STDERR "get_child: $name is alive\n";
        %ret = $self->{PROCESSES}->{$name};
        $ret{ACTIVE} = 1;
        return \%ret;
    }
    # print STDERR "Could not find the process $name\n";
    return \%ret;
}

# avoid iterating through %processes just to look at each id
sub get_names # return array of alive processes by name
{
    my $self = shift;
    my @ret = ();
    if ($self->{NAMES}) {
        @ret = values(%{$self->{NAMES}} );
    }
    return \@ret;
}

sub get_pids # returns a list with pid of all alive processes
{
    my $self = shift;
    my @ret = keys %{$self->{PROCESSES}};
    return wantarray ? @ret : \@ret; #cheating a bit here
}

# NOTE: will retrun fh refs to the read end of the pipe
#       for all processes which have been attached or detached
#       check keys($self->processes) to see if any children are running
sub get_readers # hash of name=>parent_reader_ IO handles
{
    my $self = shift;
    my %handles = ();
    while ( my ($k,$v) = each(%{$self->{PROCESSES}} ) ) {
        $handles{$v->{id} } = $v->{parent_reader};
    }
    while ( my ($k,$v) = each(%{$self->{FINISHED}} ) ) {
        $handles{$v->{id} } = $v->{parent_reader};
    }
    return \%handles;
}

sub get_all_ready # return list of ready STRUCTS
{
    my $self = shift;
    my %ret = ();
    return \%ret unless ($self->{STRUCTS}) ;
    %ret = %{ $self->{STRUCTS} };
    # print STDERR "get_all_ready found ". keys(%ret) . " elements\n";
    return \%ret;
}

# exercise caution when looping through children:
# this can be used to test if child is acivated, otherwise leads to infinite loop
sub get_next_ready # returns a hash of a ready child process, or an empty hash
{
    my $self = shift;
    my %ret = ();
    return \%ret unless defined $self->{STRUCTS};
    return \%ret unless (keys(%{$self->{STRUCTS}} ) );
    my @ids = keys(%{$self->{STRUCTS}} );
    # ensure sort order enforced so caller can plan ahead
    @ids = sort @ids;

    return \%ret unless defined $ids[0];
    my $idx = $ids[0];
    %ret = %{$self->{STRUCTS}{$idx}} ;
    return \%ret;
}

# methods after =cut are processed by the autosplit program and only compiled on demand


1;

__END__

=head1 NAME

Parallel::Supervisor - Manage a collection of child (worker) processes

=head1 SYNOPSIS

    use Parallel::Supervisor;
    
    my $supervisor = Parallel::Supervisor->new;
    
    $supervisor->prepare("Child-1", "pwd");
    $supervisor->prepare("Child-2", "ls -lh");
    
    LAUNCH: while (my %child = %{$supervisor->get_next_ready} ) {
        $childpid = fork();
        if ($childpid == 0) { # child process
            close $child{parent_reader};
            select $child{child_writer};
            # do the work
            system($child{cmd});
            exit ; # don't let children play in the LAUNCH loop
        } else { # parent process
            next LAUNCH unless $childpid;
            $supervisor->attach($child{id},$childpid);
            close $child{child_writer};
            open STDIN, "<", $child{parent_reader};
        }
    }
    
    CLEANUP: foreach ( @{$supervisor->get_pids} ) {
        $supervisor->detach($_);
    }

=head1 DESCRIPTION

This module provides a simple way to manage a collection of jobs and
monitor their output. The Supervisor will track whether each job has
been launched and provide a pipe to allow the parent to read from the
child. Each record has a name (id) which must be unique, and an
associated command, in addition to a pair of non-blocking IO handles
forming the pipe.

It is up to the caller to attach the pipe ends, run the command, and
ensure it completes (see SEE ALSO below for modules to assist with this
aspect). Once a job is launched, its pid is passed to the supervisor
via the attach method, marking the job as active. When the job is
completed, the calling code should detach the job (i.e. remove its pid
and move it to the "finished" state).

The command associated with the job is a scalar, and it is up to the
caller to determine how it is invoked. The example above uses fork() 
and system(), but the module has been tested with Parallel::Jobs and
Parallel::ForkManager.

The above example is given as a simple illustration of the module's
semantics. In a more practical setting (e.g. using Parallel::Jobs),
the parent could launch a series of long-running jobs and continuously
monitor all workers' output and / or process status, and respond to 
the results by spawning new workers, or sending a signal to a child by
pid. The detach() and forget() methods could be called from the 
run_on_finish() callback of Parallel::Jobs, for example.

Only one pipe is created, to allow the parent to read the output from
the child. Bidirectional IPC might be a nice enhancement, but is 
currently considered beyond the scope of this module. If you find this
a drawback, you might be looking for a more robust solution, such as 
POE, which provides a full-featured event driven multitasking framework.

=head1 METHODS

=over 4

=head2 new

instantiate your collection with an empty list of jobs

=head2 prepare($name, $cmd)

Add a job to your collection with the given name and command. The job
is considered "ready" until it is attached or forgotten (see below).

$name can be used for tracking the task - for example 
Parallel::JobManager can use this identifier in its callbacks.

$cmd will be invoked by your code - so it can be anything you want to
 execute in a standardized way. Eg, within eval() or system() or using
Parallel::Jobs::start_job.

Passing a $name to prepare() which has already been passed will not
replace the current child (after all, it may be running!), but will
return undef. See the forget method, below.

=head2 is_ready($name)

Returns 1 if the command name has been prepared but not yet attached, 
undef if there is no such name or if the process is running.

=head2 is_attached($name)

Looks for a running process with the given name and returns the pid if 
the process has been attached, or undef.

=head2 attach($name, $pid)

Associate the given name with the given pid and consider this child to
be "alive" or running.

=head2 detach($pid)

Consider the child with the given pid to no longer be alive - change
job state from attached to finished.

=head2 forget($name)

Delete the child with the given name entirely. This allows a new child
to be created with a previously-used name, for example. Returns undef
if the child is attached.

=head2 reset

Like calling new all over again: deletes all records.

=head2 get_child($name)

Return hashref to the record for the given name. The record consists
of:

    id			- the name identifying this unique child
    cmd			- the command this child will run
    child_writer	- the write-end of the pipe
    parent_reader	- the read-end of the pipe

=head2 get_names

Returns an arrayref of all the names(the id field) for all attached
children. See CAVEATS, below.

=head2 get_pids

Return a hashref of id => pid of all attached children.

=head2 get_readers

Return a hashref of id => parent_reader filehandles for all attached or
finished children. Useful for iterating through all children to read
their output.

=head2 get_all_ready

Return a hashref of all the prepared children which have not yet been
attached. The hash keys are the names of each record (i.e. "id"), while
the record itself also contains the id (as above), for consistency.

=head2 get_next_ready

The most useful way of iterating through the collection. Returns only
one record for a ready child (i.e. prepared but not attached). Children
are sorted according to the system's default sort() behaviour and the 
first record is returned. This does NOT pop() the record from the 
collection - you must call attach() for the child and provide its pid.
Failure to do so while iterating in a while loop will continue
infinitely.

=back

=head1 CAVEATS

Undocumented getters are defined to directly access the object's data
structures, but they are mainly for internal use. The methods described
above should be sufficient for interacting with the module. The method
names() should not be confused with get_names(). The former returns a
hash of pid => name pairs, while the latter returns an array of job
names (aka "id"). In either case, only attached processes are
returned.

The method get_next_ready() is useful for iterating through the 
collection, but, unlike a true iterator, it does not traverse elements 
in the collection simply by calling it. For the `next ready' item to 
change, the item must be taken out of the `ready' pool using attach()
(or forget()). For this reason, use caution - calling get_next_ready() 
without attaching or forgetting that process could cause an infinite
loop.

This module was written primarily for POSIX systems. It may run on
Win32, but has not been tested extensively on that platform. Feedback
and patches are welcome.

=head1 SEE ALSO

The following may be helpful reading for users of this module, or
considering doing so:

=over 4

perldoc perlipc

perldoc perlfork

Parallel::Jobs

Parallel::ForkManager

Parallel::Runner

subs::Parallel

http://perl.plover.com/FAQs/Buffering.html

=back

The following may be of interest as alternatives to this module, or as
part of a different approach to executing parallel jobs:

=over 4

POE

Parallel::Simple

Supervisor

IPC::Run

Proc::Launcher

Parallel::Iterator

Parallel::Workers

Qudo::Parallel::Manager

=back

=head1 COPYRIGHT

 (c) 2010, Kevin Semande
 This program is free software; you can redistribute it and/or
 modify it under the same terms as Perl itself.

=head1 AUTHOR

 Kevin Semande <perldev@26a.net>

 With thanks to Nadim Khemir and others for feedback and corrections.
