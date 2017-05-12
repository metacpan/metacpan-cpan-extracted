# See copyright, etc in below POD section.
######################################################################

package Parallel::Forker;
require 5.006;
use Carp qw(carp croak confess);
use IO::File;
use Time::HiRes qw(usleep);

use Parallel::Forker::Process;
use strict;
use vars qw($Debug $VERSION);

$VERSION = '1.234';

######################################################################
#### CONSTRUCTOR

sub new {
    my $class = shift;
    my $self = {
	_activity => 1,		# Optionally set true when a sig_child comes
	_processes => {},	# All process objects, keyed by id
	_labels => {},		# List of process objects, keyed by label
	_runable => {},		# Process objects runable now, keyed by id
	_running => {},		# Process objects running now, keyed *PID*
	_run_after_eqn => undef,# Equation to eval to determine if ready to launch
	_parent_pid => $$,	# PID of initial process creating the forker
	max_proc => undef,	# Number processes to launch, <1=any, +=that number
	use_sig_child => undef,	# Default to not using SIGCHLD handler
	@_
    };
    bless $self, ref($class)||$class;
    return $self;
}

#### ACCESSORS

sub in_parent {
    my $self = shift;
    return $self->{_parent_pid}==$$;
}

sub max_proc {
    my $self = shift;
    $self->{max_proc} = shift if $#_>=0;
    return $self->{max_proc};
}

sub use_sig_child {
    my $self = shift;
    $self->{use_sig_child} = shift if $#_>=0;
    return $self->{use_sig_child};
}

sub running {
    my $self = shift;
    return (values %{$self->{_running}});
}

sub running_sorted {
    my $self = shift;
    return (sort {$a->{name} cmp $b->{name}} values %{$self->{_running}});
}

sub process {
    my $self = shift;
    confess "usage: \$fork->process(\$name)" unless scalar(@_) == 1;
    return $self->{_processes}{$_[0]};
}

sub processes {
    my $self = shift;
    return (values %{$self->{_processes}});
}

sub processes_sorted {
    my $self = shift;
    return (sort {$a->{name} cmp $b->{name}} values %{$self->{_processes}});
}

sub state_stats {
    my $self = shift;
    my %stats = (idle=>0, ready=>0, running=>0, runable=>0,
		  done=>0, parerr=>0, reapable=>0);
    map {$stats{$_->state}++} $self->processes;
    return %stats;
}

#### METHODS

sub schedule {
    my $class = shift;
    return Parallel::Forker::Process->_new(_forkref=>$class,
					   @_);
}

sub sig_child {
    # Keep minimal to avoid coredumps
    return if !$_[0];
    $_[0]->{_activity} = 1;
}

sub wait_all {
    my $self = shift;
    while ($self->is_any_left) {
	#print "NRUNNING ", scalar ( (keys %{$self->{_running}}) ), "\n";
	$self->poll;
	usleep 100*1000;
    };
}

sub reap_processes {
    my $self = shift;

    my @reaped;
    foreach my $process ($self->processes) {
	next unless $process->is_reapable;
	$process->reap;
 	push @reaped, $process;
    }
    return @reaped;
}

sub is_any_left {
    my $self = shift;
    return 1 if ( (keys %{$self->{_runable}}) > 0 );
    return 1 if ( (keys %{$self->{_running}}) > 0 );
}

sub find_proc_name {
    my $self = shift;
    my $name = shift;
    # Returns list of processes matching the name or label
    if (exists $self->{_processes}{$name}) {
	return ($self->{_processes}{$name});
    } elsif (exists $self->{_labels}{$name}) {
	return @{$self->{_labels}{$name}};
    }
    return undef;
}

our $_Warned_Use_Sig_Child;

sub poll {
    my $self = shift;
    return if $self->use_sig_child && !$self->{_activity};
    if (!defined $self->use_sig_child) {
	carp "%Warning: Forker object should be new'ed with use_sig_child=>0 or 1, "
	    if ($^W && !$_Warned_Use_Sig_Child);
	$_Warned_Use_Sig_Child = 1;
	$self->use_sig_child(0);
    }

    # We don't have a loop around this any more, as we want to allow
    # applications to do other work.  We'd also need to be careful not to
    # set _activity with no one runnable, as it would potentially cause a
    # infinite loop.

    $self->{_activity} = 0;
    my $nrunning = grep { not $_->poll } (values %{$self->{_running}});

    if (!($self->{max_proc} && $nrunning >= $self->{max_proc})) {
	foreach my $procref (sort {$a->{name} cmp $b->{name}}   # Lanch in named order
			     values %{$self->{_runable}}) {
	    last if ($self->{max_proc} && $nrunning >= $self->{max_proc});
	    $procref->run;
	    $nrunning++;
	}
    }
    # If no one's running, we need _activity set to check for runable -> running
    # transitions during the next call to poll().
    $self->{_activity} = 1 if !$nrunning;
}

sub ready_all {
    my $self = shift;
    foreach my $procref ($self->processes) {
	$procref->ready() if $procref->is_idle();
    };
}

sub kill_all {
    my $self = shift;
    my $signal = shift || 9;
    foreach my $procref ($self->running_sorted) {
	$procref->kill($signal);
    };
}

sub kill_tree_all {
    my $self = shift;
    my $signal = shift || 9;
    foreach my $procref ($self->running_sorted) {
	$procref->kill_tree($signal);
    };
}

sub write_tree {
    my $self = shift;
    my %params = (@_);
    defined $params{filename} or croak "%Error: filename not specified,";

    my %did_print;
    my $another_loop = 1;
    my $level = 0;
    my $line = 4;
    my @lines;
    while ($another_loop) {
	$another_loop = 0;
	$level++;
      proc:
	foreach my $procref ($self->processes_sorted) {
	    foreach my $ra (values %{$procref->{_after_parents}}) {
		next proc if (($did_print{$ra->{name}}{level}||999) >= $level);
	    }
	    if (!$did_print{$procref->{name}}{level}) {
		$did_print{$procref->{name}}{level} = $level;
		$did_print{$procref->{name}}{line} = $line;
		$another_loop = 1;
		$lines[$line][0] = $procref->_write_tree_line($level,0);
		$lines[$line+1][0] = $procref->_write_tree_line($level,1);
		foreach my $ra (values %{$procref->{_after_parents}}) {
		    $lines[$line][$did_print{$ra->{name}}{line}]
			= $procref->{_after_parents_op}{$ra->{name}};
		}
		$line+=2;
		if ($Debug) {
		    $lines[$line++][0] = $procref->_write_tree_line($level,2);
		    $lines[$line++][0] = $procref->_write_tree_line($level,3);
		    $lines[$line++][0] = $procref->_write_tree_line($level,4);
		}
		$line++;
	    }
	}
    }
    $line++;

    if (0) {
	for (my $row=1; $row<$line; $row++) {
	    for (my $col=1; $col<$line; $col++) {
		print ($lines[$row][$col]?1:0);
	    }
	    print "\n";
	}
    }

    for (my $col=1; $col<=$#lines; $col++) {
	my $col_used_row_min;
	my $col_used_row_max;
	for (my $row=1; $row<=$#lines; $row++) {
	    if ($lines[$row][$col]) {
		$col_used_row_min = min($col_used_row_min, $row);
		$col_used_row_max = max($col_used_row_max, $row);
	    }
	}
	if ($col_used_row_min) {
	    $col_used_row_min = min($col_used_row_min, $col);
	    $col_used_row_max = max($col_used_row_max, $col);
	    for (my $row=$col_used_row_min; $row<=$col_used_row_max; $row++) {
		$lines[$row][$col] ||= '<' if $row==$col;
		$lines[$row][$col] ||= '|';
	    }
	    for (my $row=1; $row<=$#lines; $row++) {
		if (($lines[$row][0]||" ") !~ /^ /) {  # Line with text on it
		    $lines[$row][$col] ||= '-';
		    #$lines[$row][$col-1] ||= '-';
		}

		$lines[$row][$col] ||= ' ';
		#$lines[$row][$col-1] ||= ' ';
	    }
	}
    }

    my $fh = IO::File->new($params{filename},"w") or die "%Error: $! $params{filename},";
    print $fh "Tree of process spawn requirements:\n";
    print $fh "  &  Indicates the program it connects to must complete with ok status\n";
    print $fh "     before the command on this row is allowed to become RUNABLE\n";
    print $fh "  E  As with &, but with error status\n";
    print $fh "  ^  As with &, but with error or ok status\n";
    print $fh "  O  Ored condition, either completing starts proc\n";
    print $fh "\n";
    for (my $row=1; $row<=$#lines; $row++) {
	my $line = "";
	for (my $col=1; $col<$#lines; $col++) {
	    $line .= ($lines[$row][$col]||"");
	}
	$line .= $lines[$row][0]||"";
	$line =~ s/\s+$//;
	print $fh "$line\n"; #if $line !~ /^\s*$/;
    }

    $fh->close();
}

sub min {
    my $rtn = shift;
    foreach my $v (@_) {
	$rtn = $v if !defined $rtn || (defined $v && $v < $rtn);
    }
    return $rtn;
}
sub max {
    my $rtn = shift;
    foreach my $v (@_) {
	$rtn = $v if !defined $rtn || (defined $v && $v > $rtn);
    }
    return $rtn;
}

1;
######################################################################
=pod

=head1 NAME

Parallel::Forker - Parallel job forking and management

=head1 SYNOPSIS

   use Parallel::Forker;
   $Fork = new Parallel::Forker (use_sig_child=>1);
   $SIG{CHLD} = sub { Parallel::Forker::sig_child($Fork); };
   $SIG{TERM} = sub { $Fork->kill_tree_all('TERM') if $Fork && $Fork->in_parent; die "Quitting...\n"; };

   $Fork->schedule
      (run_on_start => sub {print "child work here...";},
       # run_on_start => \&child_subroutine,  # Alternative: call a named sub.
       run_on_finish => sub {print "parent cleanup here...";},
       )->run();

   $Fork->wait_all();   # Wait for all children to finish

   # More processes
   my $p1 = $Fork->schedule(...)->ready();
   my $p2 = $Fork->schedule(..., run_after=>[$p1])->ready();
   $Fork->wait_all();   # p1 will complete before p2 starts

   # Other functions
   $Fork->poll();       # Service any active children
   foreach my $proc ($Fork->running()) {   # Loop on each running child

   while ($Fork->is_any_left) {
       $Fork->poll;
       usleep(10*1000);
   }

=head1 DESCRIPTION

Parallel::Forker manages parallel processes that are either subroutines or
system commands.  Forker supports most of the features in all the other
little packages out there, with the addition of being able to specify
complicated expressions to determine which processes run after others, or
run when others fail.

Function names are loosely based on Parallel::ForkManager.

The unique property of Parallel::Forker is the ability to schedule
processes based on expressions that are specified when the processes are
defined. For example:

   my $p1 = $Fork->schedule(..., label=>'p1');
   my $p2 = $Fork->schedule(..., label=>'p2');
   my $p3 = $Fork->schedule(..., run_after => ["p1 | p2"]);
   my $p4 = $Fork->schedule(..., run_after => ["p1 & !p2"]);

Process p3 is specified to run after process p1 *or* p2 have completed
successfully.  Process p4 will run after p1 finishes successfully, and
process p2 has completed with bad exit status.

For more examples, see the tests.

=head1 METHODS

=over 4

=item $self->find_proc_name (<name>)

Returns one or more Parallel::Forker::Process objects for the given name (one
object returned) or label (one or more objects returned).  Returns undef if no
processes are found.

=item $self->in_parent

Return true if and only if called from the parent process (the one that
created the Forker object).

=item $self->is_any_left

Return true if any processes are running, or runnable (need to run).

=item $self->kill_all (<signal>)

Send a signal to all running children.  You probably want to call this only
from the parent process that created the Parallel::Forker object, wrap the
call in "if ($self->in_parent)."

=item $self->kill_tree_all (<signal>)

Send a signal to all running children and their subchildren.

=item $self->max_proc (<number>)

Specify the maximum number of processes that the poll method will run at
any one time.  Defaults to undef, which runs all possible jobs at once.
Max_proc takes effect when you schedule processes and mark them "ready,"
then rely on Parallel::Forker's poll method to move the processes from the
ready state to the run state.  (You should not call ->run yourself, as this
starts a new process immediately, ignoring max_proc.)

=item $self->new (<parameters>)

Create a new manager object.  There may be more than one manager in any
application, but applications taking advantage of the sig_child handler
should call every manager's C<sig_child> method in the application's
C<SIGCHLD> handler.

Parameters are passed by name as follows:

=over 4

=item max_proc => (<number>)

See the C<max_proc> object method.

=item use_sig_child => ( 0 | 1 )

See the C<use_sig_child> object method.  This option must be specified to
prevent a warning.

=back

=item $self->poll

See if any children need work, and service them.  Start up to max_proc
processes that are "ready" by calling their run method.  Non-blocking;
always returns immediately.

=item $self->process (<process_name>)

Return Parallel::Forker::Process object for the specified process name, or
undef if none is found.  See also find_proc_name.

=item $self->processes

Return Parallel::Forker::Process objects for all processes.

=item $self->processes_sorted

Return Parallel::Forker::Process objects for all processes, sorted by name.

=item $self->ready_all

Mark all processes as ready for scheduling.

=item $self->reap_processes

Reap all processes which have no other processes waiting for them, and the
process is is_done or is_parerr.  Returns list of processes reaped.  This
reclaims memory for when a large number of processes are being created,
run, and destroyed.

=item $self->running

Return Parallel::Forker::Process objects for all processes that are
currently running.

=item $self->schedule (<parameters>)

Register a new process perhaps for later running.  Returns a
Parallel::Forker::Process object.  Parameters are passed by name as
follows:

=over 4

=item label

Optional name to use in C<run_after> commands.  Unlike C<name>, this may be
reused, in which case C<run_after> will wait on all commands with the given
label.  Labels must contain only [a-zA-Z0-9_].

=item name

Optional name to use in C<run_after> commands.  Note that names MUST be
unique!  When not specified, a unique number will be assigned
automatically.

=item run_on_start

Subroutine reference to execute when the job begins, in the forked process.
The subroutine is called with one argument, a reference to the
Parallel::Forker::Process that is starting.

If your callback is going to fork, you'd be advised to have the child:

	$SIG{ALRM} = 'DEFAULT';
	$SIG{CHLD} = 'DEFAULT';

This will prevent the child from inheriting the parent's handlers, and
possibly confusing any child calls to waitpid.

=item run_on_finish

Subroutine reference to execute when the job ends, in the master process.
The subroutine is called with two arguments, a reference to the
Parallel::Forker::Process that is finishing, and the exit status of the
child process.  Note the exit status will only be correct if a CHLD signal
handler is installed.

=item run_after

A list reference of processes that must be completed before this process
can be runnable.  You may pass a process object (from schedule), a process
name, or a process label.  You may use "|" or "&" in a string to run this
process after ANY processes exit, or after ALL exit (the default.)
! in front of a process name indicates to run if that process fails with
bad exit status.  ^ in front of a process indicates to run if that process
succeeds OR fails.

=back

=item $self->sig_child

Must be called in a C<$SIG{CHLD}> handler by the parent process if
C<use_sig_child> was called with a "true" value.  If there are multiple
Parallel::Forker objects each of their C<sig_child> methods must be called
in the C<$SIG{CHLD}> handler.

=item $self->state_stats

Return hash containing statistics with keys of state names, and values with
number of processes in each state.

=item $self->use_sig_child ( 0 | 1 )

This should always be called with a 0 or 1.  If you install a C<$SIG{CHLD}>
handler which calls your Parallel::Forker object's C<sig_child> method, you
should also turn on C<use_sig_child>, by calling it with a "true" argument.
Then, calls to C<poll()> will do less work when there are no children
processes to be reaped.  If not using the handler call with 0 to prevent a
warning.

=item $self->wait_all

Wait until there are no running or runable jobs left.

=item $self->write_tree (filename => <filename>)

Print a dump of the execution tree.

=back

=head1 DISTRIBUTION

The latest version is available from CPAN and from
L<http://www.veripool.org/>.

Copyright 2002-2017 by Wilson Snyder.  This package is free software; you
can redistribute it and/or modify it under the terms of either the GNU
Lesser General Public License Version 3 or the Perl Artistic License
Version 2.0.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=head1 SEE ALSO

L<Parallel::Forker::Process>

=cut
######################################################################
