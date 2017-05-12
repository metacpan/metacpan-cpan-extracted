# $Id: Upward.pm 184 2009-06-11 06:44:27Z rcaputo $

=head1 NAME

POE::Request::Upward - internal base class for POE::Stage response messages

=head1 SYNOPSIS

	This module isn't meant to be used directly.

=head1 DESCRIPTION

POE::Stage messages are generally asynchronous, which means that
multiple "calls" can be in play at once.  To track them, POE::Stage
uses a call tree rather than a call stack.

POE::Request::Upward is a base class for POE::Request messages that
flow up from sub-stages (closer to leaf nodes) to their parents
(closer to the root node).  Both POE::Request::Emit and
POE::Request::Returns are subclasses of POE::Request::Upward.

The Emit and Return message classes share a lot of common code.  That
code has been hoisted into this base class.

Upward messages are automatically created and dispatched as a side
effect of calling POE::Request's emit() and return() methods.

=cut

package POE::Request::Upward;

use warnings;
use strict;

use POE::Request qw(
	REQ_CREATE_STAGE
	REQ_DELIVERY_REQ
	REQ_DELIVERY_RSP
	REQ_ID
	REQ_PARENT_REQUEST
	REQ_TARGET_METHOD
	REQ_TARGET_STAGE
	REQ_TYPE
	@EXPORT_OK
);

use base qw(POE::Request);
use Carp qw(croak confess);
use Scalar::Util qw(weaken);

use constant DEBUG => 0;

=head1 PUBLIC METHODS

These methods are called directly on the class or object.

=head2 new ARGUMENT_PAIRS

POE::Request::Upward's new() constructor is almost always called
internally by POE::Request->emit() or POE::Request->return().  Most
parameters to emit() and return() are passed directly to this
constructor.

POE::Request::Upward has one mandatory parameter: "type".  This
defines the type of response being created.  If specified, the
optional "args" parameter must contain a hashref with response
payloads.  The contents of "args" are passed unchanged to the
response's handler as lexicals with names prefixed by "arg_".

Response types are mapped to methods in the original requester's stage
through POE::Request's "on_$type" parameters.  In this example,
responses of type "success" are mapped to the requester's
continue_on() method.  Likewise "error" responses are mapped to the
requester's log_and_stop() method.

	my $req_connect = POE::Request->new(
		stage       => $tcp_client,
		method      => "connect",
		on_success  => "continue_on",
		on_error    => "log_and_stop",
	);

How an asynchronous TCP connector might return success and error
messages (although we're not sure yet):

	my $req;
	$req->return(
		type      => "success",
		args      => {
			socket  => $socket,
		},
	);

	$req->return(
		type        => "error",
		args        => {
			function  => "connect",
			errno     => $!+0,
			errstr    => "$!",
		},
	);

Optionally, POE::Request objects may contain roles.  Responses come
back as "on_${role}_${type}" messages.  For example, one stage might
call another (a socket "factory") to create a TCP client socket.  In
this example, the call's role is "connect", and the two previous
return() calls are used to return a socket on success or error info on
failure:

	my $req_connect = POE::Request->new(
		stage       => $tcp_client,
		method      => "connect",
		role        => "connect",
	);

If the factor returns "success", the on_connect_success() method will
be called upon to handle it:

	sub on_connect_success {
		my $arg_socket;  # contains the "socket" argument
	}

Likewise, on_connect_failure() will be called if the connection
failed:

	sub on_connect_failure {
		my ($arg_function, $arg_errno, $arg_errstr);
	}

=cut

sub new {
	my ($class, %args) = @_;

	# Instantiate the base request.
	my $self = $class->_request_constructor(\%args);

	# Upward requests are in response to downward ones.  Therefore a
	# current request must exist.
	#
	# XXX - Only for the reference.
	my $current_request = POE::Request->_get_current_request();
	confess "should always have a current request" unless $current_request;

	# Record the stage that created this request.
	$self->[REQ_CREATE_STAGE] = $current_request->[REQ_TARGET_STAGE];
	weaken $self->[REQ_CREATE_STAGE];

	# Upward requests target the current request's parent request.
	$self->[REQ_DELIVERY_REQ] = $current_request->[REQ_PARENT_REQUEST];

	# Upward requests' "rsp" values point to the current request at the
	# time the upward one is created.
	$self->[REQ_DELIVERY_RSP] = $self;

	# The main difference between upward requests is their parents.
	$self->_init_subclass($current_request);

	# Context is the delivery req's context.  It may not always exist,
	# as in the case of an upward request leaving the top-level
	# "application" stage and returning to the outside.
	if ($self->[REQ_DELIVERY_REQ]) {
		my $delivery_data = $self->[REQ_DELIVERY_REQ];
#		$self->[REQ_CONTEXT] = $current_request->[REQ_CONTEXT];
	}
#	else {
#		$self->[REQ_CONTEXT] = { };
#	}

	$self->[REQ_ID] = $self->_reallocate_request_id(
		$current_request->[REQ_ID]
	);

	# Upward requests can be of various types.
	$self->[REQ_TYPE] = delete $args{type};

	DEBUG and warn(
		"$current_request created ", ref($self), " $self:\n",
		"\tMy parent request = $self->[REQ_PARENT_REQUEST]\n",
		"\tDelivery request  = $self->[REQ_DELIVERY_REQ]\n",
		"\tDelivery response = $self->[REQ_DELIVERY_RSP]\n",
	);

	$self->_assimilate_args($args{args} || {});
	$self->_send_to_target();

	return $self;
}

# Deliver the request to its destination.  This happens when the event
# carrying the request is dispatched.
# TODO - It's not public.  Consider prefixing it with an underscore.

sub deliver {
	my $self = shift;

	my $target_stage = $self->[REQ_TARGET_STAGE];
	$target_stage->_set_req_rsp(
		$self->[REQ_DELIVERY_REQ],
		$self->[REQ_DELIVERY_RSP],
	);

	$self->_push(
		$self->[REQ_DELIVERY_REQ],
		$self->[REQ_TARGET_STAGE],
		$self->[REQ_TARGET_METHOD],
	);

	$self->_invoke($self->[REQ_TARGET_METHOD]);

	$self->_pop(
		$self->[REQ_DELIVERY_REQ],
		$self->[REQ_TARGET_STAGE],
		$self->[REQ_TARGET_METHOD],
	);

	$target_stage->_set_req_rsp(0, 0);

	# Break circular references.
	$self->[REQ_DELIVERY_RSP] = undef;
	$self->[REQ_DELIVERY_REQ] = undef;
}

# Rules for all upward messages.  These methods are not supported by
# POE::Request::Upward.  The guard methods here are required to ensure
# that POE::Request's versions are inaccessible.

sub return {
	my $class = ref(shift());
	croak "cannot return from upward $class";
}

sub cancel {
	my $class = ref(shift());
	croak "cannot cancel upward $class";
}

sub emit {
	my $class = ref(shift());
	croak "cannot emit from upward $class";
}

sub recall {
	my $class = ref(shift());
	croak "cannot recall from upward $class";
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

POE::Request::Upward has two subclasses: L<POE::Request::Emit> for
emitting multiple responses to a single request, and
L<POE::Request::Return> for sending a final response to end a request.

POE::Request::Upward inherits from L<POE::Request>.

=head1 AUTHORS

Rocco Caputo <rcaputo@cpan.org>.

=head1 LICENSE

POE::Request::Upward is Copyright 2005-2006 by Rocco Caputo.  All
rights are reserved.  You may use, modify, and/or distribute this
module under the same terms as Perl itself.

=cut
