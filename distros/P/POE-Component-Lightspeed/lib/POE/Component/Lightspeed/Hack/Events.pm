# Declare our package
package POE::Component::Lightspeed::Hack::Events;

# Standard stuff to catch errors
use strict qw(subs vars refs);				# Make sure we can't mess up
use warnings FATAL => 'all';				# Enable warnings to catch errors

# Initialize our version
our $VERSION = '1.' . sprintf( "%04d", (qw($Revision: 1082 $))[1] );

# These methods are folded into POE::Kernel;
package POE::Kernel;

# Standard stuff to catch errors
use strict qw(subs vars refs);				# Make sure we can't mess up
use warnings FATAL => 'all';				# Enable warnings to catch errors

my %event_count;
#  ( $session => $count,
#    ...,
#  );

my %post_count;
#  ( $session => $count,
#    ...,
#  );

### End-run leak checking.

sub _data_ev_finalize_31 {
	my $finalized_ok = 1;
	while (my ($ses, $cnt) = each(%event_count)) {
		$finalized_ok = 0;
		_warn("!!! Leaked event-to count: $ses = $cnt\n");
	}

	while (my ($ses, $cnt) = each(%post_count)) {
		$finalized_ok = 0;
		_warn("!!! Leaked event-from count: $ses = $cnt\n");
	}
	return $finalized_ok;
}

### Enqueue an event.

sub _data_ev_enqueue_31 {
	my ( $self, $session, $source_session, $event, $type, $etc, $file, $line, $fromstate, $time ) = @_;

	if (ASSERT_DATA) {
		unless ($self->_data_ses_exists($session)) {
			_trap( "<ev> can't enqueue event ``$event'' for nonexistent session $session\n" );
		}
	}

	# This is awkward, but faster than using the fields individually.
	my $event_to_enqueue = [ @_[1..8] ];

	my $old_head_priority = $self->[ KR_QUEUE ]->get_next_priority();
	my $new_id = $self->[ KR_QUEUE ]->enqueue($time, $event_to_enqueue);

	if (TRACE_EVENTS) {
		_warn(	"<ev> enqueued event $new_id ``$event'' from ",
			$self->_data_alias_loggable($source_session), " to ",
			$self->_data_alias_loggable($session),
			" at $time"
		);
	}

	if ($self->[ KR_QUEUE ]->get_item_count() == 1) {
		$self->loop_resume_time_watcher($time);
	}
	elsif ($time < $old_head_priority) {
		$self->loop_reset_time_watcher($time);
	}

	$self->_data_ses_refcount_inc($session);
	$event_count{$session}++;

	# Lightspeed stuff
	if ( ref( $source_session ) ne 'POE::Component::Lightspeed::Hack::Session' ) {
		$self->_data_ses_refcount_inc($source_session);
	}
	$post_count{$source_session}++;

	return $new_id;
}

### Remove events sent to or from a specific session.

sub _data_ev_clear_session_31 {
	my ($self, $session) = @_;

	my $my_event = sub {
		($_[0]->[EV_SESSION] == $session) || ($_[0]->[EV_SOURCE] == $session)
	};

	# TODO - This is probably incorrect.  The total event count will be
	# artificially inflated for events from/to the same session.  That
	# is, a yield() will count twice.
	my $total_event_count = (
		($event_count{$session} || 0) +
		($post_count{$session} || 0)
	);

	foreach ($self->[ KR_QUEUE ]->remove_items($my_event, $total_event_count)) {
		$self->_data_ev_refcount_dec(@{$_->[ITEM_PAYLOAD]}[EV_SOURCE, EV_SESSION]);
	}

	croak if delete $event_count{$session};
	croak if delete $post_count{$session};
}

### Decrement a post refcount

sub _data_ev_refcount_dec_31 {
	my ($self, $source_session, $dest_session) = @_;

	if (ASSERT_DATA) {
		_trap $dest_session unless exists $event_count{$dest_session};
		_trap $source_session unless exists $post_count{$source_session};
	}

	$self->_data_ses_refcount_dec($dest_session);
	$event_count{$dest_session}--;

	$post_count{$source_session}--;

	# Lightspeed stuff
	if ( ref( $source_session ) ne 'POE::Component::Lightspeed::Hack::Session' ) {
		$self->_data_ses_refcount_dec($source_session);
	} else {
		delete $post_count{$source_session} if $post_count{$source_session} == 0;
	}
}

### Fetch the number of pending events sent to a session.

sub _data_ev_get_count_to_31 {
	my ($self, $session) = @_;
	return $event_count{$session} || 0;
}

### Fetch the number of pending events sent from a session.

sub _data_ev_get_count_from_31 {
	my ($self, $session) = @_;
	return $post_count{$session} || 0;
}

# Scope our evil stuff :)
BEGIN {
	# Turn off strictness for our nasty stuff
	no strict 'refs';

	# Oh boy, no warnings too :(
	no warnings 'redefine';

	# Now, decide which version we should load...
	my %finalize_versions = (
		'0.31'		=>	\&_data_ev_finalize_31,
		'0.3101'	=>	\&_data_ev_finalize_31,
	);
	my %enqueue_versions = (
		'0.31'		=>	\&_data_ev_enqueue_31,
		'0.3101'	=>	\&_data_ev_enqueue_31,
	);
	my %clear_versions = (
		'0.31'		=>	\&_data_ev_clear_session_31,
		'0.3101'	=>	\&_data_ev_clear_session_31,
	);
	my %dec_versions = (
		'0.31'		=>	\&_data_ev_refcount_dec_31,
		'0.3101'	=>	\&_data_ev_refcount_dec_31,
	);
	my %count_to_versions = (
		'0.31'		=>	\&_data_ev_get_count_to_31,
		'0.3101'	=>	\&_data_ev_get_count_to_31,
	);
	my %count_from_versions = (
		'0.31'		=>	\&_data_ev_get_count_from_31,
		'0.3101'	=>	\&_data_ev_get_count_from_31,
	);

	# Make sure we have this version in the dispatch table
	if ( ! exists $finalize_versions{ $POE::VERSION } ) {
		die 'Your version of Lightspeed does not yet support POE-' . $POE::VERSION;
	}

	# Do our symbol table hackery
	*{'POE::Kernel::_data_ev_finalize'} = $finalize_versions{ $POE::VERSION };
	*{'POE::Kernel::_data_ev_enqueue'} = $enqueue_versions{ $POE::VERSION };
	*{'POE::Kernel::_data_ev_clear_session'} = $clear_versions{ $POE::VERSION };
	*{'POE::Kernel::_data_ev_refcount_dec'} = $dec_versions{ $POE::VERSION };
	*{'POE::Kernel::_data_ev_get_count_to'} = $count_to_versions{ $POE::VERSION };
	*{'POE::Kernel::_data_ev_get_count_from'} = $count_from_versions{ $POE::VERSION };
}

# End of module
1;
__END__
