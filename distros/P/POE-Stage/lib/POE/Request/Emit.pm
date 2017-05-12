# $Id: Emit.pm 145 2006-12-25 19:09:56Z rcaputo $

=head1 NAME

POE::Request::Emit - encapsulates non-terminal replies to POE::Request

=head1 SYNOPSIS

	# Note, this is not a complete program.
	# See the distribution's examples directory.

	sub do_something :Handler {
		my $req; # current request
		$req->emit(
			type    => "pending",
			args    => {
				retry => $retry_number,
			}
		);
	}

=head1 DESCRIPTION

POE::Request::Emit objects are used to send intermediate responses to
stages that have requested something.  It's used internally by
POE::Request's emit() method.

Emitted replies do not cancel the requests they respond to.  A stage
may therefore emit() multiple messages for a single request, finally
calling return() or cancel() to end the request.

=cut

package POE::Request::Emit;

use warnings;
use strict;
use Carp qw(croak confess);

use POE::Request::Upward qw(
	REQ_DELIVERY_RSP
	REQ_PARENT_REQUEST
	REQ_CREATE_STAGE
);

use base qw(POE::Request::Upward);

# Emitted requests may be recall()ed.  Therefore they need parentage.

sub _init_subclass {
	my ($self, $current_request) = @_;
	$self->[REQ_PARENT_REQUEST] = $current_request;
}

=head2 recall PAIRS

The stage receiving an emit()ted message may invoke recall() on that
message.  The recall() method sends another message back to the
session that called emit().  Both emit() and recall() may be used
multiple times to implement an ongoing, two-way dialogue between a
requesting stage and the stage it's called.

Once constructed, the recall message is automatically sent to the
source of the POE::Request::Emit object.

recall() creates and automatically sends a POE::Request::Recall object
to the session that sent the POE::Request::Emit object.  The PAIRS are
named parameters, which will be received as arguments to the
receiving stage's handler method.

See POE::Request::Recall for more discussion about recall messages.

=cut

sub recall {
	my ($self, %args) = @_;

	# Where does the message go?
	# TODO - Have croak() reference the proper package/file/line.

	my $parent_stage = $self->[REQ_CREATE_STAGE];
	unless ($parent_stage) {
		confess "Cannot recall message: The requester is not a POE::Stage class";
	}

	# Validate the method.
	my $message_method = delete $args{method};
	croak "Message must have a 'method' parameter" unless(
		defined $message_method
	);

	# Reconstitute the parent's context.
	my $parent_context;
	my $parent_request = $self->[REQ_PARENT_REQUEST];
	croak "Cannot recall message: The requester has no context" unless (
		$parent_request
	);

	my $response = POE::Request::Recall->new(
		stage   => $parent_stage,
		method  => $message_method,
		args    => { %{ $args{args} || {} } },    # copy for safety?
	);
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

L<POE::Request>, L<POE::Request::Upward>, L<POE::Request::Recall>, and
probably L<POE::Stage>.

=head1 AUTHORS

Rocco Caputo <rcaputo@cpan.org>.

=head1 LICENSE

POE::Request::Emit is Copyright 2005-2006 by Rocco Caputo.  All rights
are reserved.  You may use, modify, and/or distribute this module
under the same terms as Perl itself.

=cut
