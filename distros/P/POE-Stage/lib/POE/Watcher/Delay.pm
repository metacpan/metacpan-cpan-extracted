# $Id: Delay.pm 155 2007-02-15 05:09:17Z rcaputo $

=head1 NAME

POE::Watcher::Delay - wait for a length of time to pass

=head1 SYNOPSIS

	# Note, this is not a complete program.
	# See the distribution's examples directory.

	# Request a delay notification.
	my $watcher :Req = POE::Watcher::Delay->new(
		seconds     => 10,            # wait 10 seconds, then
		on_success  => "time_is_up",  # call $self->time_is_up()
		args        => {
			param_1   => 123,           # with $args->{param_1}
			param_2   => "abc",         # and $args->{param_2}
		},
	);

	# Handle the delay notification.
	sub time_is_up {
		my ($self, $args) = @_;
		print "$args->{param_1}\n";   # 123
		print "$args->{param_2}\n";   # abc
		my $watcher :Req = undef;     # Destroy the watcher.
	}

=head1 DESCRIPTION

A POE::Watcher::Delay object waits a certain amount of time before
invoking a method on the current Stage object.  Both the time to wait
and the method to invoke are given as constructor parameters.
Parameters included in the C<args> hash are passed unchanged to the
desired callback method after the specified time has elapsed.

=cut

package POE::Watcher::Delay;

use warnings;
use strict;

use POE::Watcher;
use base qw(POE::Watcher);

use Scalar::Util qw(weaken);
use Carp qw(croak);
use POE::Kernel;

=head1 PUBLIC METHODS

These methods are invoked directly on the watcher object.

=head2 new seconds => SECONDS, on_success => METHOD_NAME

Construct a new POE::Watcher::Delay object.  The constructor takes two
parameters: "seconds" is the number of seconds to wait.  "on_success"
is the name of the mothod in the current Stage to invoke when length
seconds have elapsed.

Like every other watcher object, this one must be saved in order to
remain active.  Destroy this object to cancel it.

=cut

sub init {
	my ($class, %args) = @_;

	my $seconds = delete $args{seconds};
	croak "$class requires a 'seconds' parameter" unless defined $seconds;

	my $on_success = delete $args{on_success};
	croak "$class requires an 'on_success' parameter" unless defined $on_success;

	# XXX - Only used for the request object.
	my $request = POE::Request->_get_current_request();
	croak "Can't create a $class without an active request" unless $request;

	# TODO - Make sure no other class arguments exist.

	# Wrap a weak copy of the request reference in a strong envelope so
	# it can be passed around.

	my $req_envelope = [ $request ];
	weaken $req_envelope->[0];

	my $self = bless {
		request     => $req_envelope,
		on_success  => $on_success,
		args        => { %{ $args{args} || {} } },
	}, $class;

	# Post out a timer.
	# Wrap a weak $self in a strong envelope for passing around.

	my $self_envelope = [ $self ];
	weaken $self_envelope->[0];

	$self->{delay_id} = $poe_kernel->delay_set(
		stage_timer => $seconds, $self_envelope
	);

	# Owner gets a strong reference.
	return $self;
}

sub DESTROY {
	my $self = shift;

	if (exists $self->{delay_id}) {
		$poe_kernel->alarm_remove(delete $self->{delay_id});
	}
}

# Resource delivery redelivers the request the resource was created
# in, but to a new method.
# TODO - Rename to _deliver, since this is an internal method.

sub deliver {
	my ($self, %args) = @_;

	# Open the envelope.
	my $request = $self->{request}[0];
	$request->deliver($self->{on_success}, $self->{args});
}

1;

=head1 BUGS

See L<http://thirdlobe.com/projects/poe-stage/report/1> for known
issues.  See L<http://thirdlobe.com/projects/poe-stage/newticket> to
report one.

POE::Stage is too young for production use.  For example, its syntax
is still changing.  You probably know what you don't like, or what you
need that isn't included, so consider fixing or adding that, or at
least discussing it with the people on POE's mailing list or IRC
channel.  Your feedback and contributions will bring POE::Stage closer
to usability.  We appreciate it.

=head1 SEE ALSO

L<POE::Watcher> describes concepts that are common to all POE::Watcher
classes.  It's required reading if you want to fully understand what's
going on.

=head1 AUTHORS

Rocco Caputo <rcaputo@cpan.org>.

=head1 LICENSE

POE::Watcher::Delay is Copyright 2005-2006 by Rocco Caputo.  All
rights are reserved.  You may use, modify, and/or distribute this
module under the same terms as Perl itself.

=cut
