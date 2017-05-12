package POE::Watcher::Wheel::SocketFactory;

use warnings;
use strict;
use POE::Watcher::Wheel;
use POE::Wheel::SocketFactory;
use base qw(POE::Watcher::Wheel);

# Map wheel "event" parameters to event numbers.  POE::Stage currently
# can handle events 0..4.  It should be extended if you need more.

__PACKAGE__->wheel_param_event_number( {
  SuccessEvent => 0,
  FailureEvent => 1,
} );

# Map events (by number) to parameter names for the callback method's
# $args parameter.

__PACKAGE__->wheel_event_param_names( [
	# 0 = SuccessEvent
  # see POE::Wheel::SocketFactory for these; 'address' is troublesome. -- hdp,
  # 2006-09-05
	[ "socket", "address", "port", "wheel_id" ],

	# 1 = FailureEvent
	[ "operation", "errnum", "errstr", "wheel_id" ],
] );

# What wheel class are we wrapping?

sub get_wheel_class {
	return "POE::Wheel::SocketFactory";
}

1;

__END__

For the BUGS section:

POE::Stage is too young for production use.  For example, its syntax
is still changing.  You probably know what you don't like, or what you
need that isn't included, so consider fixing or adding that, or at
least discussing it with the people on POE's mailing list or IRC
channel.  Your feedback and contributions will bring POE::Stage closer
to usability.  We appreciate it.
