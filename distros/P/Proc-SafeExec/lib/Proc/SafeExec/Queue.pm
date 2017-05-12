package Proc::SafeExec::Queue;

use 5.006;
use strict;
use warnings;

our $VERSION = "1.5";

=pod

=head1 NAME

Proc::SafeExec::Queue - Uses Proc::SafeExec to manage a group of concurrent processes.

=head1 SYNOPSIS

	use Proc::SafeExec::Queue;
	my $queue = Proc::SafeExec::Queue->new({
		"soft_limit" => 4,  # Default is 4.
		"hard_limit" => 8,  # Default is soft_limit * 2.
	});

To add a task to the queue:

	my $id = $queue->add({
		# Options describing when to execute.
		"exec_order" => 1,  # Default is 1.
		"callback_prefork" => \&callback_prefork,  # Default is undef.
		"callback_postfork" => \&callback_postfork,  # Default is undef.
		"callback_postwait" => \&callback_postwait,  # Default is undef.
		"callback_error" => \&callback_error,  # Default is undef.
		"exec" => {
			# Options to new Proc::SafeExec.
		},
		"data" => {
			# Space for the caller to store any ancillary information, for example, to be
			# used in the callback functions.
		},
	});

To cancel a task before it starts (okay during prefork):

	$queue->cancel($id);

To wait on exited children and begin executing pending children:

	my $did_something = $queue->do_events();

To get a list of children that haven't finished yet:

	my @list = $queue->remaining_children();

=head1 DESCRIPTION

Proc::SafeExec::Queue provides a way of managing a group of concurrent
processes.

Here's a logical description of what happens. Processes are added to the queue
and execute when appropriate. The parent can enqueue them and forget about
them. Immediately before a child executes, before forking, the prerun function
executes. Immediately after a child is waited on, the postrun function
executes.

This decides when to execute a child based on exec_order, soft_limit, and
hard_limit. The exec_order option describes the ideal order the children should
be executed in, however, it's not strictly enforced, since children may be
added with a lower exec_order after one with a higher exec_order began
execution. When a new child is added to the queue, it always begins executing
immediately if there are fewer than soft_limit already executing. Otherwise,
it begins executing only if the number of children with an exec_order lower or
equal to the new child is lower than soft_limit and there are fewer than
hard_limit children executing. The number of children will never exceed
hard_limit. Whenever a child exits, this checks the queue to see if any more
should be started. If there is a tie when deciding which child to execute next,
the first one added to the queue wins.

Note that setting soft_limit to undef or greater than hard_limit is the same as
setting it to the same value as hard_limit, and both must be an integer greater
than zero. exec_order may be any numerical value, including negative and
floating point values (although it may be most intuitive to limit it to
integers greater than zero). Setting soft_limit or hard_limit to 0 means
infinity, but this can be dangerous because no computer can handle an infinite
number of processes.

=head1 USAGE

The parent should call $queue->do_events() whenever it receives SIGCHLD, but
should never call it directly from the signal handler, because signal handlers
may be invoked at times when it is not safe to do anything but set a variable.
It is safe to call $queue->do_events() when there is nothing to do. Thus,
alternatively to trapping SIGCHLD, the parent may simply call
$queue->do_events() whenever it is convenient, such as at the beginning of an
event loop. If you choose to do this, consider the loop:

	1 while $queue->do_events();

This is not the default because it starve the parent of time to do other work.

$queue->do_events() first waits on any children that exited and calls the
associated callback_postwait functions, then for each child scheduled for
execution, it calls the associated callback_prefork function, executes it, and
calls the associated callback_postfork function. If there is an error executing
a child, it calls callback_error; callback_postfork and callback_postwait are
never called. callback_prefork, callback_postfork, and callback_postwait may be
undef to indicate a null-op. If callback_error is set to undef and an error
occurs, a warning is issued via warn().

$queue->add() adds a child to the queue and, if appropriate, begins executing
it. It returns a unique ID representing the child.

The callback functions always receive the original options hash that was passed
to $queue->add(), with some additional elements. The callback functions can
inspect this hash to find out some things about the child, however this hash is
not to be meddled with, except as documented here. If you need to associate
your own information with the child, use the "data" subhash, which is entirely
reserved for the caller's use and may be modified at any time.

If the child began execution, the element "Proc::SafeExec" is set to the
Proc::SafeExec object. (This is always set in callback_postfork and
callback_postwait, never in callback_prefork, and sometimes in callback_error.)
The query methods of Proc::SafeExec may be called, specifically child_pid,
stdin, stdout, stderr, exit_status. The caller may B<not> call the wait method
because it affects the execution state. If an error occurred, the element
"error" is set to $@ for the duration of the callback_error function. The "id"
element is always set to the unique ID assigned to this child. The
callback_prefork function may modify the exec hash.

The method $queue->cancel() removes a child from the queue, but only if it
hasn't started yet. This may be called during callback_prefork, but no later.

The method $queue->remaining_children() returns the hashes of the children
remaining in the queue (including those that are running). (These are the same
hashes that are passed to the callback functions.) They're listed in the order
they would be started if none were running yet. The ones that are running might
not be the first ones in the list if the exec_order decreased in the sequence
that children were added.

When used as documented, this module never has an error to report directly to
the caller; all errors are reported through callback_error functions. If it
does die, there's a good chance the bug or misuse will leave things in an
inconsistent state that can't be recovered from automatically. This may be
worth improving.

XXX: What to do with running children when the queue is destroyed?


=head1 CAVEATS


=head1 EXAMPLES


=head1 INSTALLATION


=head1 VERSION AND HISTORY

See Proc::SafeExec.

=head1 SEE ALSO

See also Proc::SafeExec, the package containing this.

=head1 AUTHOR

Leif Pedersen, E<lt>bilbo@hobbiton.orgE<gt>

=head1 COPYRIGHT AND LICENSE

 This may be distributed under the terms below (BSD'ish) or under the GPL.
 
 Copyright (c) 2007
 All Rights Reserved
 Meridian Environmental Technology, Inc.
 4324 University Avenue, Grand Forks, ND 58203
 http://meridian-enviro.com
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are
 met:
 
  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.
 
  2. Redistributions in binary form must reproduce the above copyright
     notice, this list of conditions and the following disclaimer in the
     documentation and/or other materials provided with the
     distribution.
 
 THIS SOFTWARE IS PROVIDED BY AUTHORS AND CONTRIBUTORS "AS IS" AND ANY
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL AUTHORS OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

use Proc::SafeExec;

sub new {
	my ($package, $options) = @_;

	my $class_name = (ref($package) or $package);
	my $self = {};
	bless $self, $class_name;

	# Usage checks; set defaults.
	if(defined $options->{"soft_limit"}) {
		$self->{"soft_limit"} = $options->{"soft_limit"};
	} else {
		$self->{"soft_limit"} = 4;
	}
	if(defined $options->{"hard_limit"}) {
		$self->{"hard_limit"} = $options->{"hard_limit"};
	} else {
		$self->{"hard_limit"} = $self->{"soft_limit"} * 2;
	}

	$self->{"queue"} = {};
	$self->{"next_unique_id"} = 1;
	$self->{"num_executing"} = 0;

	return $self;
}

sub do_events {
	my ($self) = @_;
	my $did_something;

	# Make it okay to call $self->do_events() from within a callback handler. A
	# common case of this is when the callback_postexit function needs to call
	# $self->add().
	return () if $self->{"do_events_executing"};
	local $self->{"do_events_executing"} = 1;

	# First, wait for exited children so we know how many more to start. For each,
	# call callback_postwait.
	foreach my $child (values %{$self->{"queue"}}) {
		next unless $child->{"Proc::SafeExec"};  # Not yet started.
		next unless $child->{"Proc::SafeExec"}->wait({"nonblock" => 1});  # Didn't finish yet.
		$did_something = 1;

		eval {
			$child->{"callback_postwait"}->($child) if defined $child->{"callback_postwait"};
		};
		if($@) {
			$child->{"error"} = $@;
			if(defined $child->{"callback_error"}) {
				$child->{"callback_error"}->($child);
			} else {
				warn "Child ID $child->{'id'} had an error: $child->{'error'}";
			}
			$child->{"error"} = undef;
		}
		delete $self->{"queue"}{$child->{"id"}};
		$self->{"num_executing"} -= 1;
	}

	my $soft_num_executing = 0;  # Counting the current iteration because it increments at the top of the loop. Sorry.
	foreach my $child ($self->remaining_children()) {
		$soft_num_executing++;
		next if $child->{"Proc::SafeExec"};  # Already running

		# Honor cancel requests before and immediately after callback_prefork.
		if($child->{"cancel"}) {
			delete $self->{"queue"}{$child->{"id"}};
			$soft_num_executing--;
			next;
		}

		# Not yet executed. Should we start it?
		next if $self->{"hard_limit"} and $self->{"num_executing"} >= $self->{"hard_limit"};  # Too many running.
		next if $self->{"soft_limit"} and $soft_num_executing > $self->{"soft_limit"};  # Too many running with lower exec_order.
		$did_something = 1;

		# Call callback_prefork, then Proc::SafeExec, then callback_postfork. On error,
		# call callback_error.
		eval {
			$child->{"callback_prefork"}->($child) if defined $child->{"callback_prefork"};
		};
		if($@) {
			$child->{"error"} = $@;
			if(defined $child->{"callback_error"}) {
				$child->{"callback_error"}->($child);
			} else {
				warn "Child ID $child->{'id'}} had an error: $child->{'error'}";
			}
			$child->{"error"} = undef;
		}

		# Honor cancel requests before and immediately after callback_prefork.
		if($child->{"cancel"}) {
			delete $self->{"queue"}{$child->{"id"}};
			$soft_num_executing--;
			next;
		}

		eval {
			$child->{"Proc::SafeExec"} = new Proc::SafeExec($child->{"exec"});
			$self->{"num_executing"} += 1;
			$child->{"callback_postfork"}->($child) if defined $child->{"callback_postfork"};
		};
		if($@) {
			$child->{"error"} = $@;
			if(defined $child->{"callback_error"}) {
				$child->{"callback_error"}->($child);
			} else {
				warn "Child ID $child->{'id'}} had an error: $child->{'error'}";
			}
			$child->{"error"} = undef;
		}
	}

	return $did_something;
}

sub add {
	my ($self, $options) = @_;

	$options->{"id"} = $self->{"next_unique_id"}++;
	$options->{"exec_order"} = 1 unless defined $options->{"exec_order"};
	$options->{"Proc::SafeExec"} = undef;  # Safety.
	$options->{"error"} = undef;  # Safety.

	$self->{"queue"}{$options->{"id"}} = $options;

	$self->do_events();

	return $options->{"id"};
}

sub cancel {
	my ($self, $id) = @_;
	$self->{"queue"}{$id}{"cancel"} = 1;
	return ();
}

sub remaining_children {
	my ($self) = @_;

	unless(wantarray) {
		return 1 if %{$self->{"queue"}};
		return undef;
	}

	# Sort first by exec_order, then by the order they were added.
	return sort {
	  $a->{"exec_order"} <=> $b->{"exec_order"} or
	  $a->{"id"} <=> $b->{"id"}
	  } values %{$self->{"queue"}};
}

sub DESTROY {
	my ($self) = @_;

	# XXX: Not sure what to do here.
	my @children = $self->remaining_children();
	@children = map {$_->{"id"}} @children;
	warn("The following child IDs haven't finished yet, and may not have executed: @children") if @children;
}

# XXX: Add a test function.

1
