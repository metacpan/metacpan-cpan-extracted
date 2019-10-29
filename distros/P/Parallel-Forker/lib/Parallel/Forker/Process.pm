# See copyright, etc in below POD section.
######################################################################

package Parallel::Forker::Process;
require 5.006;
use Carp qw(carp croak confess);
use IO::File;
use POSIX qw(sys_wait_h :signal_h);
use Proc::ProcessTable;
use Scalar::Util qw(weaken);

use strict;
use vars qw($Debug $VERSION $HashId);

$VERSION = '1.252';

$Debug = $Parallel::Forker::Debug;
$HashId = 0;

sub _new {
    my $class = shift;
    my $self = {
	_forkref => undef,	# Upper Fork object
	name => $HashId++,	# ID for hashing.  User may override it
	label => undef,		# Label for run_after's
	_after_children => {},	# IDs that are waiting on this event
	_after_parents => {},	# IDs that we need to wait for
	_state => 'idle',	# 'idle', 'ready', 'runable', 'running', 'done', 'parerr'
	_ref_count => 0,        # number of people depending on us
	pid => undef,		# Pid # running as, undef=not running
	run_after => [],	# Process objects that are prereqs
	run_on_start => sub {confess "%Error: No run_on_start defined\n";},
	run_on_finish => sub {my ($procref,$status) = @_;},	# Routine taking child and exit status
	@_
    };
    $Debug = $Parallel::Forker::Debug;
    bless $self, ref($class)||$class;
    # Users need to delete the old one first, if they care.
    # We don't do that automatically, as generally this is a mistake, and
    # deleting the old one may terminate a process or have other nasty effects.
    (!exists $self->{_forkref}{_processes}{$self->{name}})
	or croak "%Error: Creating a new process under the same name as an existing process: $self->{name},";
    $self->{_forkref}{_processes}{$self->{name}} = $self;
    weaken($self->{_forkref});

    if (defined $self->{label}) {
	if (ref $self->{label}) {
	    foreach my $label (@{$self->{label}}) {
		push @{$self->{_forkref}{_labels}{$label}}, $self;
	    }
	} else {
	    push @{$self->{_forkref}{_labels}{$self->{label}}}, $self;
	}
    }
    $self->_calc_runable;  # Recalculate
    return $self;
}

sub DESTROY {
    my $self = shift;
    delete $self->{_forkref}{_processes}{$self->{name}};
}

##### ACCESSORS

sub name { return $_[0]->{name}; }
sub label { return $_[0]->{label}; }
sub pid { return $_[0]->{pid}; }
sub status { return $_[0]->{status}; }  # Maybe undef
sub status_ok { return defined $_[0]->{status} && $_[0]->{status}==0; }
sub forkref { return $_[0]->{_forkref}; }

sub state { return $_[0]->{_state}; }
sub is_idle    { return $_[0]->{_state} eq 'idle'; }
sub is_ready   { return $_[0]->{_state} eq 'ready'; }
sub is_runable { return $_[0]->{_state} eq 'runable'; }
sub is_running { return $_[0]->{_state} eq 'running'; }
sub is_done    { return $_[0]->{_state} eq 'done'; }
sub is_parerr  { return $_[0]->{_state} eq 'parerr'; }
sub is_reapable {
    my $self = shift;
    return $self->{_ref_count} == 0 && ($self->is_done || $self->is_parerr);
}

sub reference { $_[0]->{_ref_count}++ }
sub unreference { $_[0]->{_ref_count}-- }

##### METHODS

sub _calc_eqns {
    my $self = shift;

    # Convert references to names of the reference
    $self->{run_after} = [map
			  {
			      if (ref $_) { $_ = $_->{name} };
			      $_;
			  } @{$self->{run_after}} ];

    my $run_after = (join " & ", @{$self->{run_after}});
    $run_after =~ s/([&\|\!\^\---\(\)])/ $1 /g;
    print "  FrkRunafter $self->{name}: $run_after\n" if ($Debug||0)>=2;

    my $runable_eqn = "";
    my $parerr_eqn  = "";
    my $ignerr;
    my $flip_op = '';  # ~ or ^ or empty
    my $between_op     = '&&';
    my $between_op_not = '||';
    my $need_op_next = 0;
    my $any_refs = 0;
    foreach my $token (split /\s+/, " $run_after ") {
	next if $token =~ /^\s*$/;
	#print "TOKE $token\n" if $Debug;
	if ($token eq '!' || $token eq '^') {
	    $flip_op = $token;
	} elsif ($token eq '-') {
	    $ignerr = 1;
	} elsif ($token eq '(' || $token eq ')') {
	    if ($token eq '(') {
		$runable_eqn .= " ${between_op}" if $need_op_next;
		$parerr_eqn  .= " ${between_op_not}" if $need_op_next;
		$need_op_next = 0;
	    }
	    $runable_eqn .= " $token ";
	    $parerr_eqn.= " $token ";
	} elsif ($token eq '&') {
	    $between_op = '&&'; $between_op_not = '||';
	} elsif ($token eq '|') {
	    $between_op = '||'; $between_op_not = '&&';
	} elsif ($token =~ /^[a-z0-9_]*$/i) {
	    # Find it
	    my @found = $self->{_forkref}->find_proc_name($token);
	    if (defined $found[0]) {
		foreach my $aftref (@found) {
		    my $aftname = $aftref->{name};
		    ($aftref ne $self) or die "%Error: Id $self->{name} has a run_after on itself; it will never start\n";
		    $runable_eqn .= " ${between_op}" if $need_op_next;
		    $parerr_eqn  .= " ${between_op_not}" if $need_op_next;
		    # _ranok, _ranfail, _nofail
		    if ($flip_op eq '!') {
			$runable_eqn .= " (_ranfail('$aftname')||_parerr('$aftname'))";
			$parerr_eqn  .= " (_ranok('$aftname'))";
		    } elsif ($flip_op eq '^') {
			$runable_eqn .= " (_ranok('$aftname')||_ranfail('$aftname')||_parerr('$aftname'))";
			$parerr_eqn  .= " (0)";
		    } else {
			$runable_eqn .= " (_ranok('$aftname'))";
			$parerr_eqn  .= " (_ranfail('$aftname')||_parerr('$aftname'))";
		    }

		    $aftref->{_after_children}{$self->{name}} = $self;
		    $self->{_after_parents}{$aftref->{name}} = $aftref;
		    weaken($aftref->{_after_children}{$self->{name}});
		    weaken($self->{_after_parents}{$aftref->{name}});

		    my $apo = $flip_op; $apo ||= 'O' if $between_op eq '||';
		    $apo ||= '&';  $apo='E' if $apo eq '!';
		    $self->{_after_parents_op}{$aftref->{name}} = $apo;
		    $need_op_next = 1;
		    $any_refs = 1;
		}
	    } else {
		if ($ignerr) {
		    print "  FrkProc $self->{name} run_after process/label $token not found ignored.\n" if $Debug;
		} else {
		    croak "%Error: run_after process/label $token not found,";
		}
	    }
	    # Prep for next
	    $ignerr = 0;
	    $flip_op = '';
	} else {
	    croak "%Error: run_after parse error of $token in: $run_after,";
	}
    }
    $runable_eqn = "1" if !$any_refs;
    $parerr_eqn  = "0" if !$any_refs;
    $self->{_runafter_text} = $run_after;
    $self->{_runable_eqn_text} = $runable_eqn;
    $self->{_parerr_eqn_text}  = $parerr_eqn;
    my $set = ("\t\$self->{_runable_eqn} = sub { return $runable_eqn; };\n"
	       ."\t\$self->{_parerr_eqn} = sub { return $parerr_eqn; };1;\n");
    print "$set" if ($Debug||0)>=2;
    eval $set or die ("%Error: Can't eval:\n$@\n"
		      ."  $self->{_runafter_text}\n  $self->{_runable_eqn_text}\n  $self->{_parerr_eqn_text}\n");
}

sub ready {
    my $self = shift;
    # User is indicating ready.
    ($self->{_state} eq 'idle') or croak "%Error: Signalling ready to already ready process,";

    $self->_calc_eqns;

    # Transition: idle -> 'ready'
    print "  FrkProc $self->{name} $self->{_state} -> ready\n" if $Debug;
    if (not $self->is_ready) {
        $_->reference for values %{$self->{_after_parents}};
    }
    $self->{_state} = 'ready';
    $self->_calc_runable;
}

sub parerr {
    my $self = shift;
    # Mark process as never to be run
    if ($self->is_idle || $self->is_ready) {
	print "  FrkProc $self->{name} $self->{_state} -> parerr\n" if $Debug;
	$self->{_state} = 'parerr';  # "can't run due to parent status" is more accurate
    } else {
	croak "%Error: process isn't ready\n";
    }
    # May need to spawn/kill children
    foreach my $ra (values %{$self->{_after_children}}) {
	$ra->_calc_runable;
    }
}

sub run {
    my $self = shift;
    # Transition: Any state -> 'running', ignoring run_after's
    !$self->{pid} or croak "%Error: process is already running,";
    !$self->is_running or croak "%Error: process is already running,";

    print "  FrkProc $self->{name} $self->{_state} -> running\n" if $Debug;
    $self->{_state} = 'running';
    $self->{start_time} = time();
    if (my $pid = fork()) {
	$self->{pid} = $pid;
	$self->{pid_last_run} = $pid;
	$self->{_forkref}{_running}{$self->{pid}} = $self;
	delete $self->{_forkref}{_runable}{$self->{name}};
    } else {
	$self->{run_on_start}->($self);
	exit(0);  # Don't close anything
    }
    return $self;  # So can chain commands
}

sub run_after {
    my $self = shift;
    # @_ = objects to add as prereqs
    ($self->{_state} eq 'idle') or croak "%Error: Must set run_after's before marking the process ready,";
    push @{$self->{run_after}}, @_;
    return $self;  # So can chain commands
}

sub reap {
    my $self = shift;

    $self->is_reapable or croak "%Error: process is not reapable,";
    delete $self->{_forkref}{_processes}{$self->{name}};
    if (defined $self->{label}) {
	if (ref $self->{label}) {
	    foreach my $label (@{$self->{label}}) {
		@{$self->{_forkref}{_labels}{$label}} =
		    grep { $_->{name} ne $self->{name} }
		@{$self->{_forkref}{_labels}{$label}};
	    }
	} else {
            @{$self->{_forkref}{_labels}{$self->{label}}} =
		grep { $_->{name} ne $self->{name} }
	    @{$self->{_forkref}{_labels}{$self->{label}}};
	}
    }
}

use vars qw($_Calc_Runable_Fork);

sub _calc_runable {
    my $self = shift;
    # @_ = objects to add as prereqs
    return if ($self->{_state} ne 'ready');
    #use Data::Dumper; print "CR ",Dumper($self),"\n";

    # Used by the callbacks
    local $_Calc_Runable_Fork = $self->{_forkref};
    sub _ranok {
	my $procref = $_Calc_Runable_Fork->{_processes}{$_[0]};
	print "   _ranok   $procref->{name}  State $procref->{_state}\n" if ($Debug||0)>=2;
	return ($procref->is_done && $procref->status_ok);
    }
    sub _ranfail {
	my $procref = $_Calc_Runable_Fork->{_processes}{$_[0]};
	print "   _ranfail $procref->{name}  State $procref->{_state}\n" if ($Debug||0)>=2;
	return ($procref->is_done && !$procref->status_ok);
    }
    sub _parerr {
	my $procref = $_Calc_Runable_Fork->{_processes}{$_[0]};
	print "   _parerr  $procref->{name}  State $procref->{_state}\n" if ($Debug||0)>=2;
	return ($procref->is_parerr);
    }

    if (&{$self->{_runable_eqn}}) {
	# Transition: ready -> runable
	print "  FrkProc $self->{name} $self->{_state} -> runable\n" if $Debug;
	$self->{_state} = 'runable';  # No dependencies (yet) so can launch it
	$self->{_forkref}{_runable}{$self->{name}} = $self;
    } elsif (&{$self->{_parerr_eqn}}) {
 	$_->unreference for values %{$self->{_after_parents}};
 	$self->parerr;
    }
}

##### STATE TRANSITIONS

our $_Warned_Waitpid;

sub poll {
    my $self = shift;
    return undef if !$self->{pid};

    my $got = waitpid($self->{pid}, WNOHANG);
    if ($got!=0) {
	if ($got>0) {
	    $self->{status} = $?;  # convert wait return to status
	} else {
	    $self->{status} = undef;
	    carp "%Warning: waitpid($self->{pid}) returned -1 instead of status; perhaps you're ignoring SIG{CHLD}?"
		if ($^W && !$_Warned_Waitpid);
	    $_Warned_Waitpid = 1;
	}
	# Transition: running -> 'done'
	print "  FrkProc $self->{name} $self->{_state} -> done ($self->{status})\n" if $Debug;
	delete $self->{_forkref}{_running}{$self->{pid}};
	$self->{pid} = undef;
	$self->{_state} = 'done';
	$self->{end_time} = time();
	$self->{run_on_finish}->($self, $self->{status});
	# Transition children: ready -> runable
	foreach my $ra (values %{$self->{_after_children}}) {
	    $ra->_calc_runable;
	}
 	$_->unreference for values %{$self->{_after_parents}};
	# Done
	return $self;
    }
    return undef;
}

sub kill {
    my $self = shift;
    my $signal = shift || 9;
    CORE::kill($signal, $self->{pid}) if $self->{pid};
    # We don't remove it's pid, we'll get a child exit that will do it
}

sub kill_tree {
    my $self = shift;
    my $signal = shift || 9;
    return if !$self->{pid};
    my @proc = (_subprocesses($self->{pid}), $self->{pid});
    foreach my $pid (@proc) {
	print "  Fork Kill -$signal $pid (child of $pid)\n" if $Debug;
	CORE::kill($signal, $pid);
    }
    # We don't remove it's pid, we'll get a child exit that will do it
}

sub format_time {
    my $secs = shift;
    return sprintf("%02d:%02d:%02d", int($secs/3600), int(($secs%3600)/60), $secs % 60);
}

sub format_loctime {
    my $time = shift;
    my ($sec,$min,$hour) = localtime($time);
    return sprintf("%02d:%02d:%02d", $hour, $min, $sec);
}

sub _write_tree_line {
    my $self = shift;
    my $level = shift;
    my $linenum = shift;
    my $cmt = "";
    if (!$linenum) {
	my $state = uc $self->{_state};
	$state .= "-ok"  if $self->is_done && $self->status_ok;
	$state .= "-err" if $self->is_done && !$self->status_ok;
	return sprintf("%s %-27s  %-8s  %s\n",
		       "--", #x$level
		       $self->{name},
		       $state,  # DONE-err is longest
		       ($self->{comment}||""));
    } elsif ($linenum == 1) {
	if ($self->{start_time}) {
	    $cmt .= "Start ".format_loctime($self->{start_time});
	    if ($self->{end_time}) {
		$cmt .= ", End ".format_loctime($self->{end_time});
		$cmt .= ", Took ".format_time(($self->{end_time}-$self->{start_time}));
		$cmt .= ", Pid ".$self->{pid_last_run};
	    }
	}
    } elsif ($linenum == 2) {
	$cmt .= "Runaft = ".$self->{_runafter_text}    if defined $self->{_runafter_text};
    } elsif ($linenum == 3) {
	$cmt .= "RunEqn = ".$self->{_runable_eqn_text} if defined $self->{_runable_eqn_text} ;
    } elsif ($linenum == 4) {
	$cmt .= "ErrEqn = ".$self->{_parerr_eqn_text}  if defined $self->{_parerr_eqn_text} ;
    }
    return sprintf("%s %-27s  %-8s  %s\n",
		   "  ", #x$level
		   "",
		   "",
		   $cmt);
}

sub _subprocesses {
    my $parent = shift || $$;
    # All pids under the given parent
    # Used by testing module
    # Same function in Schedule::Load::_subprocesses
    my $pt = new Proc::ProcessTable( 'cache_ttys' => 1);
    my %parent_pids;
    foreach my $p (@{$pt->table}) {
	$parent_pids{$p->pid} = $p->ppid;
    }
    my @out;
    my @search = ($parent);
    while ($#search > -1) {
	my $pid = shift @search;
	push @out, $pid if $pid ne $parent;
	foreach (keys %parent_pids) {
	    push @search, $_ if $parent_pids{$_} == $pid;
	}
    }
    return @out;
}

######################################################################
#### Package return
1;
=pod

=head1 NAME

Parallel::Forker::Process - Single parallel fork process object

=head1 SYNOPSIS

   $obj->run;
   $obj->poll;
   $obj->kill(<"SIGNAL">);
   $obj->kill_tree(<"SIGNAL">);

=head1 DESCRIPTION

Manage a single process under the control of Parallel::Forker.

Processes are created by calling a Parallel::Forker object's schedule
method, and retrieved by various methods in that class.

Processes transition over 6 states.  They begin in idle state, and are
transitioned by the user into ready state.  As their dependencies complete,
Parallel::Forker transitions them to the runable state.  As the
Parallel::Forker object's C<max_proc> limit permits, they transition to the
running state, and get executed.  On completion, they transition to the
done state.  If a process depends on another process, and that other
process fails, the dependant process transitions to the parerr (parent
error) state, and is never run.

=head1 METHODS

=over 4

=item forkref

Return the parent Parallel::Forker object this process belongs to.

=item is_done

Returns true if the process is in the done state.

=item is_idle

Returns true if the process is in the idle state.

=item is_parerr

Returns true if the process is in the parent error state.

=item is_ready

Returns true if the process is in the ready state.

=item is_reapable

Returns true if the process is reapable (->reap may be called on it).

=item is_runable

Returns true if the process is in the runable state.

=item is_running

Returns true if the process is in the running state.

=item kill(<signal>)

Send the specified signal to the process if it is running.  If no signal is
specified, send a SIGKILL (9).

=item kill_tree(<signal>)

Send the specified signal to the process (and its subchildren) if it is
running.  If no signal is specified, send a SIGKILL (9).

=item kill_tree_all(<signal>)

Send a signal to this child (and its subchildren) if it is running.  If no
signal is specified, send a SIGKILL (9).

=item label

Return the label of the process, if any, else undef.

=item name

Return the name of the process.

=item pid

Return the process ID if this job is running, else undef.

=item poll

Check the process for activity, invoking callbacks if needed.
Generally Parallel::Forker's object method C<poll()> is used instead.

=item ready

Mark this process as being ready for execution when all C<run_after>'s are
ready and CPU resources permit.  When that occurs, run will be called on
the process automatically.

=item reap

When the process has no other processes waiting for it, and the process is
is_done or is_parerr, remove the data structures for it.  This reclaims
memory for when a large number of processes are being created, run, and
destroyed.

=item run

Unconditionally move the process to the "running" state and start it.

=item run_after

Add a new (or list of) processes that must be completed before this process
can be runnable.  You may pass a process object (from schedule), a process
name, or a process label.  You may use "|" or "&" in a string to run this
process after ANY processes exit, or after ALL exit (the default.)
! in front of a process name indicates to run if that process fails with
bad exit status.  ^ in front of a process indicates to run if that process
succeeds OR fails.

=item state

Returns the name of the current state, 'idle', 'ready', 'runable',
'running', 'done' or 'parerr'.  For forward compatibility, use the is_idle
etc. methods instead of comparing this accessor's value to a constant
string.

=item status

Return the exit status of this process if it has completed.  The exit
status will only be correct if a CHLD signal handler is installed,
otherwise it may be undef.

=item status_ok

Return true if the exit status of this process was zero.  Return false if
not ok, or if the status has not been determined, or if the status was
undef.

=back

=head1 DISTRIBUTION

The latest version is available from CPAN and from
L<https://www.veripool.org/parallel-forker>.

Copyright 2002-2019 by Wilson Snyder.  This package is free software; you
can redistribute it and/or modify it under the terms of either the GNU
Lesser General Public License Version 3 or the Perl Artistic License
Version 2.0.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=head1 SEE ALSO

L<Parallel::Forker>

=cut
######################################################################
