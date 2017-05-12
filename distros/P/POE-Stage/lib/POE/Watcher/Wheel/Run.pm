# $Id: Run.pm 136 2006-11-18 23:49:30Z rcaputo $

# TODO - Documentation.

package POE::Watcher::Wheel::Run;

use warnings;
use strict;
use POE::Watcher::Wheel;
use POE::Wheel::Run;
use base qw(POE::Watcher::Wheel);

# Map wheel "event" parameters to event numbers.  POE::Stage currently
# can handle events 0..4.  It should be extended if you need more.

__PACKAGE__->wheel_param_event_number( {
	StdinEvent  => 0,
	StdoutEvent => 1,
	StderrEvent => 2,
	ErrorEvent  => 3,
	CloseEvent  => 4,
} );

# Map events (by number) to parameter names for the callback method's
# $args parameter.

__PACKAGE__->wheel_event_param_names( [
	# 0 = StdinEvent
	[ "wheel_id" ],

	# 1 = StdoutEvent
	[ "output", "wheel_id" ],

	# 2 = StderrEvent
	[ "output", "wheel_id" ],

	# 3 = ErrorEvent
	[ "operation", "errnum", "errstr", "wheel_id", "handle_name" ],

	# 4 = CloseEvent
	[ "wheel_id" ],
] );

# What wheel class are we wrapping?

sub get_wheel_class {
	return "POE::Wheel::Run";
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
