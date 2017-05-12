# $Id: Input.pm 155 2007-02-15 05:09:17Z rcaputo $

=head1 NAME

POE::Watcher::Input - watch a socket or other handle for input readiness

=head1 SYNOPSIS

	# Note, this is not a complete program.
	# See the distribution's examples directory.

	sub some_other :Handler {
		# Request a delay notification.
		my $req_socket = $socket_handle;
		my $req_input  = POE::Watcher::Input->new(
			handle    => $req_socket,
			on_input  => "read_from_socket",
			args      => \%passed_to_callbacks,
		);
	}

	# Handle the delay notification.
	sub read_from_socket {
		my $req_socket;
		my $octets = sysread($req_socket, my $buf = "", 65536);
		...;
	}

=head1 DESCRIPTION

POE::Watcher::Input watches a socket or other handle and delivers a
message whenever the handle becomes ready to be read.  Both the handle
and the method to call are passed to POE::Watcher::Input objects at
construction time.

=cut

package POE::Watcher::Input;

use warnings;
use strict;

use POE::Watcher;
use base qw(POE::Watcher);

use Scalar::Util qw(weaken);
use Carp qw(croak);
use POE::Kernel;

=head1 PUBLIC METHODS

=head2 new handle => HANDLE, on_input => METHOD_NAME

Construct a new POE::Watcher::Input object.  The constructor takes two
parameters: "handle" is the socket or other file handle to watch for
input readiness.  "on_input" is the name of the method in the current
Stage to invoke when the handle is ready to be read from.

Destroy this object to cancel it.

=cut

sub init {
	my ($class, %args) = @_;

	my $handle = delete $args{handle};
	croak "$class requires a 'handle' parameter" unless defined $handle;

	my $input_method = delete $args{on_input};
	croak "$class requires an 'on_input' parameter" unless defined $input_method;

	# XXX - Only used for the request object.
	my $request = POE::Request->_get_current_request();
	croak "Can't create a $class without an active request" unless $request;

	# TODO - Make sure no other adorned arguments exist.

	# Wrap a weak copy of the request reference in a strong envelope so
	# it can be passed around.

	my $req_envelope = [ $request ];
	weaken $req_envelope->[0];

	my $self = bless {
		request   => $req_envelope,
		on_input  => $input_method,
		handle    => $handle,
		args      => { %{ $args{args} || {} }},
	}, $class;

	# Wrap a weak $self in a strong envelope for passing around.

	my $self_envelope = [ $self ];
	weaken $self_envelope->[0];

	$poe_kernel->select_read($handle, "stage_io", $self_envelope);

	# Owner gets a strong reference.
	return $self;
}

sub DESTROY {
	my $self = shift;
	if (exists $self->{handle}) {
		$poe_kernel->select_read(delete($self->{handle}), undef);
	}
}

# Resource delivery redelivers the request the resource was created
# in, but to a new method.

sub deliver {
	my ($self, %args) = @_;
	# Open the envelope.
	my $request = $self->{request}[0];
	$request->deliver($self->{on_input}, { handle => $self->{handle} });
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
classes.  It's required reading in order to understand fully what's
going on.

=head1 AUTHORS

Rocco Caputo <rcaputo@cpan.org>.

=head1 LICENSE

POE::Watcher::Input is Copyright 2005-2006 by Rocco Caputo.  All
rights are reserved.  You may use, modify, and/or distribute this
module under the same terms as Perl itself.

=cut
