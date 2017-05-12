# $Id: Recall.pm 184 2009-06-11 06:44:27Z rcaputo $

=head1 NAME

POE::Request::Recall - encapsulates responses to POE::Request::Emit

=head1 SYNOPSIS

	# Note, this is not a complete program.
	# See the distribution's examples directory.

	my $rsp;
	$rsp->recall(
		method  => "method_name",     # invoke this method on Emit's creator
		args      => {
			param_1 => 123,               # with this parameter
			param_2 => "abc",             # and this one, too
		},
	);

=head1 DESCRIPTION

POE::Request::Recall objects encapsulate responses to
POE::Request::Emit objects.  They are created internally by
POE::Request::Emit's recall() method.

They are quite like POE::Request objects, except that they are not
created with a "stage" parameter.  Rather, the destination stage is
the one that originally created the previous POE::Request::Emit
object.

Consider this persistent dialogue between two stages:

	Requester               Servicer
	----------------------- -------------------------
	POE::Request->new(...)
	:                       (receives the request)
	:                       $req->emit(...)
	(receives the emit)
	$rsp->recall(...)
	:                       (receives the recall)
	:                       $req->return(...)
	(receives the return)

A stage requests a service from another stage.  The servicer stage
emits an intermediate response, which is handled by the requester.
The requester uses recall() to send more information.  The servicer
stage handles the new message by calling return(), ending the
dialogue.

POE::Request::Emit and POE::Request::Recall reuse the original
POE::Request closure rather than create new ones.  This allows each
side of the dialog to store state that persists for the life of the
dialog.

=cut

package POE::Request::Recall;

use warnings;
use strict;
use Carp qw(croak confess);
use Scalar::Util qw(weaken);

use POE::Request qw(
	REQ_CREATE_STAGE
	REQ_DELIVERY_REQ
	REQ_DELIVERY_REQ
	REQ_PARENT_REQUEST
	REQ_TARGET_STAGE
	REQ_ID
);

use base qw(POE::Request);

use constant DEBUG => 0;

=head2 new PAIRS

Create a new POE::Request::Recall object, specifying the "method" to
call in the POE::Stage object on the other end of the dialog.  An
optional "args" parameter should contain a hashref of key/value pairs
that are passed to the destination method as its $arg_ parameters.

=cut

sub new {
	my ($class, %args) = @_;

	my $self = $class->_request_constructor(\%args);

	# Recalling downward, there should always be a current request.
	# TODO: Does this always hold true?  For example, wehn recalling
	# from "main" back into the main application stage?
	#
	# XXX - Only getting the current request for its tied object.
	my $current_request = POE::Request->_get_current_request();
	confess "should always have a current request" unless $current_request;

	# Current RSP is a POE::Request::Emit.
	my $current_rsp = $current_request->[REQ_TARGET_STAGE]->_get_response();
	confess "should always have a current rsp" unless $current_rsp;

	# Recall's parent is RSP's delivery REQ.
	$self->[REQ_PARENT_REQUEST] = $current_rsp->[REQ_DELIVERY_REQ];
	confess "rsp should always have a delivery request" unless (
		$self->[REQ_PARENT_REQUEST]
	);

	# Recall targets the current response's parent request.
	$self->[REQ_DELIVERY_REQ] = $current_rsp->[REQ_PARENT_REQUEST];
	confess "rsp should always have a parent request" unless (
		$self->[REQ_DELIVERY_REQ]
	);

	# Record the stage that created this request.
	$self->[REQ_CREATE_STAGE] = $current_request->[REQ_TARGET_STAGE];
	weaken $self->[REQ_CREATE_STAGE];

	# Context is the delivery req's context.
	my $delivery_request = $self->[REQ_DELIVERY_REQ];
#	$self->[REQ_CONTEXT] = $delivery_request->[REQ_CONTEXT];
#	confess "delivery request should always have a context" unless (
#		$self->[REQ_CONTEXT]
#	);
	$self->[REQ_ID] = $self->_reallocate_request_id(
		$delivery_request->[REQ_ID]
	);

	DEBUG and warn(
		"$self->[REQ_PARENT_REQUEST] created $self:\n",
		"\tMy parent request = $self->[REQ_PARENT_REQUEST]\n",
		"\tDelivery request  = $self\n",
		"\tDelivery response = 0\n",
#		"\tDelivery context  = $self->[REQ_CONTEXT]\n",
	);

	$self->_assimilate_args($args{args} || {});
	$self->_send_to_target();

	return $self;
}

sub recall {
	croak "Cannot recall a recalled message";
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

L<POE::Request>, L<POE::Request::Emit>, and probably L<POE::Stage>.

=head1 AUTHORS

Rocco Caputo <rcaputo@cpan.org>.

=head1 LICENSE

POE::Request::Recall is Copyright 2005-2006 by Rocco Caputo.  All
rights are reserved.  You may use, modify, and/or distribute this
module under the same terms as Perl itself.

=cut
