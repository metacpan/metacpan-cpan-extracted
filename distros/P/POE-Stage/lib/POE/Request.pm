# $Id: Request.pm 200 2009-07-27 05:01:45Z rcaputo $

=head1 NAME

POE::Request - a common message class for POE::Stage

=head1 SYNOPSIS

	# Note, this is not a complete program.
	# See the distribution's examples directory.

	my $req_subrequest = POE::Request->new(
		method    => "method_name",   # invoke this method
		stage     => $self,           # of this stage
		on_one    => "do_one",        # map a "one" response to method
		args      => {
			one => 123,         # with this parameter
			two => "abc",       # and this one
		}
	);

	# Handle a "one" response.
	sub do_one :Handler {
		my ($arg_one, $arg_two);
		print "$arg_one\n";  # 123
		print "$arg_two\n";  # abc
		...;
		my $req;
		$req->return( type => "one", moo => "retval" );
	}

	# Handle one's return value.
	sub do_one :Handler {
		my $arg_moo;
		print "$arg_moo\n";  # "retval"
	}

=head1 DESCRIPTION

POE::Request objects encapsulate messages passed between POE::Stage
objects.  Each request includes a destination (the stage and method to
call), optional data to be sent to the destination method (args), and
optional hints where to send responses (on_* mappings).  There may be
other parameters.

POE::Request includes methods that transmit responses when called.
These methods internally create instances of POE::Request subclasses.
The return() method creates a POE::Stage::Return object, which ends a
transaction and returns a final result.  There is also an emit()
method that creates a POE::Request::Emit object.  Emitted messages do
not terminate the transactions they're belong to, so they may act as
interim responses.

POE::Request::Emit has its own response method, recall().  The
recipient of an emitted interim response can recall the session at the
other end of the current transaction.  emit() and recall() may be used
together to extend a two-way dialog within the context of an original
request.

Each new POE::Request creates two closures, one for the sender and one
for the receiver.  Members of the sender's closure can be accessed
using POE::Stage's expose() function.  For example, to expose a
sub-request's "hostname" member as the lexical $subrequest_hostname
variable:

	use POE::Session qw(expose);
	my $req_subrequest = POE::Request->new(...);
	expose $req_subrequest, my $subrequest_hostname;
	$subrequest_hostname = "remote.host.name";

The request's destination may have its own "hostname" member, but it
will be separate from the caller's.  The special $req lexical refers
to the POE::Request object that called us, while $req_hostname refers
to the "hostname" member in the invocant's end of the request.

	sub on_request {
		my $req_hostname = Sys::Hostname::hostname();
		...;
		$req->return(
			type => "success",
			args => { retval => $something }
		);
	}

When the caller receives a response, either via an invocant's use of
emit() or return(), there are special $rsp and $rsp_membername
lexicals.  $rsp refers to the POE::Request::Emit or ::Return message
we're handling.  It's usually used to call $rsp->recall(...).
Lexicals prefixed by "rsp_", such as $rsp_hostname, refer to values
previously stored in the original request via expose().  In our
contrived example:

	sub on_resolver_success {
		my $arg_retval;  # contains the value of the "retval" argument
		my $rsp_hostname;  # contains "remote.host.name", assigned above
	}

This lexical magic only works with methods intended to be used as
message handlers.  They are identified by the :Handler attribute or by
method names beginning with "on_".

=cut

package POE::Request;

use warnings;
use strict;

use Carp qw(croak confess);
use POE::Kernel;
use Scalar::Util qw(weaken);

use constant DEBUG => 0;

use constant REQ_TARGET_STAGE   =>  0;  # Stage to be invoked.
use constant REQ_TARGET_METHOD  =>  1;  # Method to invoke on the stage.
use constant REQ_CHILD_REQUESTS =>  2;  # Requests begotten from this one.
use constant REQ_RESOURCES      =>  3;  # Resources created in this request.
use constant REQ_CREATE_PKG     =>  4;  # Debugging.
use constant REQ_CREATE_FILE    =>  5;  # ... more debugging.
use constant REQ_CREATE_LINE    =>  6;  # ... more debugging.
use constant REQ_CREATE_STAGE   =>  7;  # ... more debugging.
use constant REQ_ARGS           =>  8;  # Parameters of this request.
use constant REQ_ROLE           =>  9;  # Request role.
use constant REQ_RETURNS        => 10;  # Return type/method map.
use constant REQ_PARENT_REQUEST => 11;  # The request that begat this one.
use constant REQ_DELIVERY_REQ   => 12;  # "req" to deliver to the method.
use constant REQ_DELIVERY_RSP   => 13;  # "rsp" to deliver to the method.
use constant REQ_TYPE           => 14;  # Request type?
use constant REQ_ID             => 15;  # Request ID.

use Exporter;
use base qw(Exporter);
BEGIN {
	@POE::Request::EXPORT_OK = qw(
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
}

my $last_request_id = 0;
my %active_request_ids;

sub _allocate_request_id {
	1 while (
		exists $active_request_ids{++$last_request_id} or $last_request_id == 0
	);
	$active_request_ids{$last_request_id} = 1;
	return $last_request_id;
}

sub _reallocate_request_id {
	my ($self, $id) = @_;
	croak "id $id can't be reallocated if it isn't allocated" unless (
		$active_request_ids{$id}++
	);
	return $id;
}

# Returns true if the ID is freed.
sub _free_request_id {
	my $id = shift;

	# This croak() actually seems to help with a memory leak.
	croak "$id isn't allocated" unless $active_request_ids{$id};

	return 0 if --$active_request_ids{$id};
	delete $active_request_ids{$id};
	return 1;
}

sub get_id {
	my $self = shift;
	return $self->[REQ_ID];
}

sub DESTROY {
	my $self = shift;
	my $id = $self->[REQ_ID];

	if (_free_request_id($id)) {
		if ($self->[REQ_CREATE_STAGE]) {
			$self->[REQ_CREATE_STAGE]->_request_context_destroy($id);
		}

		if ($self->[REQ_TARGET_STAGE]) {
			$self->[REQ_TARGET_STAGE]->_request_context_destroy($id);
		}
	}
}

use constant RS_REQUEST => 0;
use constant RS_STAGE   => 1;
use constant RS_METHOD  => 2;

my @request_stack;

sub _get_current_request {
	return 0 unless @request_stack;
	return $request_stack[-1][RS_REQUEST];
}

sub _get_current_stage {
	return 0 unless @request_stack;
	return $request_stack[-1][RS_STAGE];
}

# Push the request on the request stack, making this one active or
# current.

# TODO - Leolo suggests using true globals and localizing them at
# dispatch time.  This might be faster despite the penalty of using a
# true global.  It may also be possible to make $req and $rsp magic
# variables that POE::Stage exports, but would the exported versions
# of globals refer to the global or the localized value?  It appears
# that localization's not an option.  See lab/local-scoped-state.perl
# for a test case.

sub _push {
	my ($self, $request, $stage, $method) = @_;
	push @request_stack, [
		$request,     # RS_REQUEST
		$stage,       # RS_STAGE
		$method,      # RS_METHOD
	];
}

sub _invoke {
	my ($self, $method, $override_args) = @_;

	DEBUG and do {
		my $target = $self->[REQ_TARGET_STAGE];

		warn(
			"\t$self invoking $self->[REQ_TARGET_STAGE] method $method:\n",
			"\t\tMy req  = ", $target->_get_request(), "\n",
			"\t\tMy rsp  = ", $target->_get_response(), "\n",
			"\t\tPar req = $self->[REQ_PARENT_REQUEST]\n",
		);
	};

	$self->[REQ_TARGET_STAGE]->$method(
		$override_args || $self->[REQ_ARGS]
	);
}

sub _pop {
	my ($self, $request, $stage, $method) = @_;
	confess "not defined?!" unless defined $request;
	my ($pop_request, $pop_stage, $pop_method) = @{pop @request_stack};
#	confess "bad pop($pop_request) not request($request)" unless (
#		$pop_request == $request
#	};
}

sub _request_constructor {
	my ($class, $args) = @_;
	my ($package, $filename, $line) = caller(1);

	foreach my $param (qw(stage method)) {
		next if exists $args->{$param};
		croak "$class is missing the '$param' parameter";
	}

	# Wrap the on_foo arguments.  At least the coderef ones.

	foreach (keys %$args) {
		next unless /^on_(\S+)$/;
		if (ref($args->{$_}) eq 'CODE') {
			$args->{$_} = POE::Callback->new(
				{
					name => $_,
					code => $args->{$_},
				},
			);
		}
	}

	# TODO - What's the "right" way to make fields inheritable without
	# clashing in Perl?

	my $self = bless [
		delete $args->{stage},        # REQ_TARGET_STAGE
		delete $args->{method},       # REQ_TARGET_METHOD
		{ },                          # REQ_CHILD_REQUESTS
		{ },                          # REQ_RESOURCES
		$package,                     # REQ_CREATE_PKG
		$filename,                    # REQ_CREATE_FILE
		$line,                        # REQ_CREATE_LINE
		0,                            # REQ_CREATE_STAGE
		{ },                          # REQ_ARGS
		delete $args->{role},         # REQ_ROLE
	], $class;

	return $self;
}

sub _weaken_target_stage {
	weaken $_[0]->[REQ_TARGET_STAGE];
}

# Send the request to its destination.
# TODO - Can we decide whether the target has a method?  Currently
# doing that in deliver().

sub _send_to_target {
	my $self = shift;
	Carp::confess "whoops" unless $self->[REQ_TARGET_STAGE];
	$poe_kernel->post(
		$self->[REQ_TARGET_STAGE]->_get_session_id(), "stage_request", $self
	);
}

sub pass_to {
	my ($self, $arg) = @_;

	my $sub_arg = delete $arg->{args} || { };
	my $method = delete $arg->{method} or croak "method required";

	$self->deliver($method, $sub_arg);
}

=head1 PUBLIC METHODS

Request methods are called directly on the objects themselves.

=head2 new PARAM => VALUE, PARAM => VALUE, ...

Create a new POE::Request object.  The request will automatically be
sent to its destination, currently asynchronously, but the exact
implementation has not solidified yet.  In the future we hope that
factors on the local or remote process, or pertaining to the network
between them, may prevent requests from being delivered
immediately.

POE::Request->new() requires at least two parameters.  "stage"
contains the POE::Stage object that will receive the request, and
"method" is the method to call when the remote stage handles the
request.  For remote calls, the stage may merely be a local proxy for
a remote object, but this feature has yet to be defined.

Parameters for the message's destination can be supplied in the
optional "args" parameter.  These parameters will be passed untouched
to the message's destination via lexical variables with the $arg_
prefix.

POE::Request->new() returns an object which must be saved.  Destroying
a request object will cancel the request and automatically free all
data and resources associated with it, including those allocated by
sub-stages and sub-requests on behalf of the original request.  This
can be ensured by storing sub-stages and sub-requests within the
context of higher-level requests.

Instances of POE::Request subclasses, such as those created by
$request->return(), do not need to be saved.  They are ephemeral
responses and/or re-requests, and their lifespans do not control the
lifetime duration of the transaction they belong to.

TODO - on_foo
TODO - role

=cut

sub new {
	my ($class, %args) = @_;

	my $self = $class->new_without_send(%args);
	$self->_send_to_target();

	return $self;
}

=head2 new_without_send SAME_AS_NEW

A "friend" method used internally to create POE::Request objects
without automatically sending them to their targets.

=cut

sub new_without_send {
	my ($class, %args) = @_;

	my $self = $class->_request_constructor(\%args);

	# Gather up the type/method mapping for any responses to this
	# request.

	my %returns;
	foreach (keys %args) {
		next unless /^on_(\S+)$/;
		my $return = delete $args{$_};
		$returns{$1} = $return;
	}

	$self->[REQ_RETURNS] = \%returns;

	# Set the parent request to be the currently active request.
	# New request = new context.

	# XXX - Only used for the request object?
	$self->[REQ_PARENT_REQUEST] = POE::Request->_get_current_request();
	$self->[REQ_ID] = $self->_allocate_request_id();

	# If we have a parent request, then we need to associate this new
	# request with it.  The references between parent and child requests
	# are all weak because it's up to the creator to decide when
	# destruction happens.

	if ($self->[REQ_PARENT_REQUEST]) {
		my $parent_data = $self->[REQ_PARENT_REQUEST];
		$self->[REQ_CREATE_STAGE] = $parent_data->[REQ_TARGET_STAGE];
		weaken $self->[REQ_CREATE_STAGE];

		$parent_data->[REQ_CHILD_REQUESTS]{$self} = $self;
		weaken $parent_data->[REQ_CHILD_REQUESTS]{$self};
	}

	DEBUG and warn(
		"$self->[REQ_PARENT_REQUEST] created $self:\n",
		"\tMy parent request = $self->[REQ_PARENT_REQUEST]\n",
		"\tDelivery request  = $self\n",
		"\tDelivery response = 0\n",
	);

	$self->_assimilate_args($args{args} || {});

	return $self;
}

sub _assimilate_args {
	my ($self, $args) = @_;

	# Process additional arguments.  The subclass should remove all
	# adorned arguments it uses.  Any remaining are considered a usage
	# error.

	$self->init($args);

	# Copy the remaining arguments into the object.

	$self->[REQ_ARGS] = { %$args };
}

=head2 init HASHREF

init() is a callback that subclasses receive as part of the request's
construction.  It's used to perform final initialization before
requests are transmitted.

The init() method receives the request's constructor 'args' before
they are processed and stored in the request.  This timing allows
init() to modify the arguments, adding, removing or altering them
before the request is sent.  To do this properly, however, one must
manipulate the entire hash directly.  Fortunately POE::Stage provides
that through @_ and the $args variable:

	sub init {
		my ($self, $my_args) = @_;

		# Changing $my_args or $args will alter the same, original
		# argument hash.
	}

Custom POE::Request subclasses may use init() to verify that
parameters are correct.  Currently init() must throw an exeception
with die() to signal some form of failure.

=cut

sub init {
	# Virtual base method.  Do nothing by default.
}

# Deliver the request to its destination.  Requesting down into a
# stage, so req is the request that invoked the method, and rsp is
# zero because there's no downward path from here.
#
# The $method parameter seems to be used mainly by watchers and stuff
# with particular methods in mind.
#
# TODO - Rename _deliver since this is a friend method.

sub deliver {
	my ($self, $method, $override_args) = @_;

	my $target_stage = $self->[REQ_TARGET_STAGE];

	my $delivery_req = $self->[REQ_DELIVERY_REQ] || $self;

	$target_stage->_set_req_rsp($delivery_req, 0);

	# At this point we decide the final method.
	my $target_method;
	if ($method) {
		$target_method = $method;
	}
	else {
		$target_method = $self->[REQ_TARGET_METHOD];
	}

	$target_method =~ s/^(on_)?/on_/;
#	unless ($target_stage->can($target_method)) {
#		warn "can't find the $target_method handler";
#	}

	$self->_push($self, $target_stage, $target_method);

	$self->_invoke($target_method, $override_args);

	$self->_pop($self, $target_stage, $target_method);

	$target_stage->_set_req_rsp(undef, undef);
}

# Return a response to the requester.  The response occurs in the
# requester's original context, somehow.

=head2 return type => RETURN_TYPE, args => \%RETURN_VALUES

return() cancels the current POE::Request object, and returns a
message with an optional RETURN_TYPE and some optional RETURN_VALUES.
The response is encapsulated in a POE::Request::Return object and
automatically sent back to the caller---the POE::Stage that created
the POE::Request that triggered this return().

Please see POE::Request::Return for details about return messages.

The type of message defaults to "return" if not specified.

=cut

sub return {
	my ($self, %args) = @_;

	# Default return type
	$args{type} ||= "return";

	$self->_emit("POE::Request::Return", %args);
	$self->cancel();
}

=head2 emit type => EMIT_TYPE, args => \%EMIT_VALUES

emit() sends a message to the caller, using an optional EMIT_TYPE and
optional EMIT_VALUES.  emit() does not cancel the current transaction,
unlike return().  The response is encapsulated in a POE::Request::Emit
object, and it's automatically sent to the caller.

emit() was created to send back interim or ongoing statuses, possibly
as part of a two-way dialog between a caller and callee.

The type of message defaults to "emit" if not specified.

=cut

sub emit {
	my ($self, %args) = @_;
	# Default return type
	$args{type} ||= "emit";

	$self->_emit("POE::Request::Emit", %args);
}

=head2 cancel

Explicitly cancel a request.  It's intended for use by the invoked
stage, since the caller is free to destroy its request at any time.
The callee doesn't have that ability, so cancel() grants it
explicitly.

A canceled request cannot generate a response.  If you are tempted to
precede cancel() with emit(), then use return() instead.  The return()
method is essentially an emit() followed by a cancel().

As mentioned earlier, canceling a request frees up the data associated
with that request.  Cancellation and destruction cascade through the
data associated with a request and any sub-stages and sub-requests.
This efficiently and automatically releases all resources associated
with the entire request tree rooted with the canceled request.

For example:

	App creates a request for an http client.
		HTTP client creates a request for a socket.
			Socket factory creates a request for a DNS resolver.

At any point in the hierarchy, a cancellation clears its context and
cancels the lower-level requests.  For example, if the App cancels the
HTTP request, the cancelation cascades to the socket factory, and then
to the DNS resolver.

This happens because of one recursive rule:  When a request is
canceled, the data members on both sides of the transaction are
destroyed.  This only works when stages consistently store subrequests
within their own requests.  Here the socket factory request is stored
in the main HTTP fetch request.  If the HTTP fetch is canceled before
the socket factory can create a connection, then the socket factory's
request is also canceled.

	sub on_http_fetch {
		...;
		my $req_socket = POE::Request->new(
			stage => $socket_factory,
			method => "open_socket",
		);

This behavior can be nested arbitrarily deep.

=cut

sub cancel {
	my $self = shift;

	# Cancel all the children first.

	foreach my $child (values %{$self->[REQ_CHILD_REQUESTS]}) {
		eval {
			$child->cancel();
		};
	}

	# A little sanity check.  We should have no children once they're
	# canceled.
	die "canceled parent has children left" if (
		keys %{$self->[REQ_CHILD_REQUESTS]}
	);

	# Disengage from our parent.
	# TODO - Use a mutator rather than grope inside the parent object.

	if ($self->[REQ_PARENT_REQUEST]) {
		my $parent_data = $self->[REQ_PARENT_REQUEST];
		delete $parent_data->[REQ_CHILD_REQUESTS]{$self};
		$self->[REQ_PARENT_REQUEST] = 0;
	}

	# Weaken the target stage?
	# TODO - Why is this already weak sometimes?
	weaken $self->[REQ_TARGET_STAGE];
}

sub _emit {
	my ($self, $class, %args) = @_;

	# Where does the message go?
	# TODO - Have croak() reference the proper package/file/line.

	# The message type is important for finding the appropriate method,
	# either on the sending stage or its destination.

	my $message_type = delete $args{type};
	croak "Message must have a type parameter" unless defined $message_type;

	# If the caller has an on_my_$mesage_type method, deliver there
	# immediately.  NB - Roles are not known by the callee, so they
	# really cannot be included here.
	my $emitter = $self->[REQ_TARGET_STAGE];
	my $emitter_method = "on_my_$message_type";
	if ($emitter->can($emitter_method)) {
		# TODO - This is probably wrong.  For example, do we need
		# _push/_pop around _invoke.
		return $self->_invoke($emitter_method, \%args);
	}

	# Otherwise we propagate the message back to the request's sender.
	my $parent_stage = $self->[REQ_CREATE_STAGE];
	confess "Can't emit message: Requester is not a POE::Stage class" unless (
		$parent_stage
	);

	# At this point we know the class and message type.  If a specific
	# "on_$message_type" mapping has been declared, then use it.
	# Otherwise look for an "on_${message_type}_lc($class)" method.  Use
	# that if it's available.

	# TODO - Method names are looked up and/or created in multiple
	# places.  This should be unified and standardized.

	my $message_method;
	if (exists $self->[REQ_RETURNS]{$message_type}) {
		$message_method = $self->[REQ_RETURNS]{$message_type};
	}
	else {
		if (defined $self->[REQ_ROLE]) {
			$message_method = "on_$self->[REQ_ROLE]_$message_type";
			unless ($parent_stage->can($message_method)) {
				$message_method = "unknown type=$message_type";
			}
		}
		else {
			$message_method = "no role for message type=$message_type";
			# "POE::Request::" = 14
			my $message_class = lc(substr($class, 14));

		}
	}

	# Reconstitute the parent's context.
	my $parent_request = $self->[REQ_PARENT_REQUEST];
	croak "Cannot emit message: The requester has no context" unless (
		$parent_request
	);

	my $response = $class->new(
		args    => { %{ $args{args} || {} } },
		stage   => $parent_stage,
		method  => $message_method,
		type    => $message_type,
	);
}

1;

=head1 DESIGN GOALS

Requests are designed to encapsulate messages passed between stages,
so you don't have to roll your own message-passing schemes.  It's our
hope that providing a standard, effective message passing system will
maximize interoperability between POE stages.

Requests may be subclassed, incorporating specific features and
defaults to make their use easier.

Future plans:

At some point in the future, request classes may be used as message
types rather than C<<type => $type>> parameters.  More formal
POE::Stage interfaces may take advantage of explicit message typing in
the future.

We'd also like to incorporate a standard form of interprocess
communication within POE::Request, possibly with the use of proxy
stages that represent remote code.  In theory, a stage doesn't need to
know its peers are off-world.

=head1 BUGS

See http://thirdlobe.com/projects/poe-stage/report/1 for known issues.
See http://thirdlobe.com/projects/poe-stage/newticket to report one.

POE::Stage is too young for production use.  For example, its syntax
is still changing.  You probably know what you don't like, or what you
need that isn't included, so consider fixing or adding that, or at
least discussing it with the people on POE's mailing list or IRC
channel.  Your feedback and contributions will bring POE::Stage closer
to usability.  We appreciate it.

=head1 SEE ALSO

POE::Request has subclasses that are used internally.  While they
share the same interface as POE::Request, not all of its methods are
appropriate in all its subclasses.

Please see POE::Request::Upward for a discussion of response events
(emit and return), and how they are mapped to method calls by the
requesting stage.  POE::Request::Return and POE::Request::Emit are
specific kinds of upward-facing response messages.

L<POE::Request::Return>, L<POE::Request::Recall>,
L<POE::Request::Emit>, and L<POE::Request::Upward>.

=head1 AUTHORS

Rocco Caputo <rcaputo@cpan.org>.

=head1 LICENSE

POE::Request is Copyright 2005-2006 by Rocco Caputo.  All rights are
reserved.  You may use, modify, and/or distribute this module under
the same terms as Perl itself.

=cut
