# $Id: Wheel.pm 155 2007-02-15 05:09:17Z rcaputo $

=head1 NAME

POE::Watcher::Wheel - watch a POE::Wheel rather than reinvent it

=head1 SYNOPSIS

	# Note, this is not a complete program.
	# See the distribution's examples directory.

	my $wheel :Req = POE::Watcher::Wheel->new(
		wheel_class => "POE::Wheel::Run",
		wheel_parameters => {
			Program => "...",
			StdoutMethod
TODO - Finish.

=head1 DESCRIPTION

TODO - Write.

=cut

package POE::Watcher::Wheel;

use warnings;
use strict;

use POE::Watcher;
use base qw(POE::Watcher);

use Scalar::Util qw(weaken);
use Carp qw(croak);
use POE::Kernel;
use base qw(Class::Data::Inheritable);

BEGIN {
  __PACKAGE__->mk_classdata('wheel_param_event_number');
  __PACKAGE__->wheel_param_event_number( {} );
  __PACKAGE__->mk_classdata('wheel_event_param_names');
  __PACKAGE__->wheel_event_param_names( [] );
}

sub wheel_param_to_event_number {
	my ($self, $param) = @_;
  my $num = $self->wheel_param_event_number->{$param};
	die $param unless defined $num;
	return $num;
}

sub wheel_param_names {
	my ($class, $event_number) = @_;
  my $names = $class->wheel_event_param_names->[$event_number];
	die unless $names;
	return $names;
}

sub get_wheel_class {
  croak "virtual method get_wheel_class called";
}

=head1 PUBLIC METHODS

=head2 new wheel_class => NAME, wheel_parameters => HASHREF

Create a new POE::Watcher::Wheel, encapsulating a CLASS_NAME type of
wheel object.  The wheel is constructed using WHEEL_PARAMS, which are
translated into POE::Wheel parameters and passed to the wheel's
constructor.

The CLASS_NAME wheel should be loaded ahead of time.

Since POE::Watcher classes invoke callbacks rather than emit events,
use /.*Method$/ parameters wherever you would normally use /.*Event$/
parameters in the Wheel constructor.  The SYNOPSIS might shed some
light on this if it were complete.

Destroy this object to cancel it.

=cut

my %wheel_id_to_object;

sub init {
	my ($class, %args) = @_;

	my $wheel_class = $class->get_wheel_class();

	# XXX - Only used for the request object.
	my $request = POE::Request->_get_current_request();
	croak "Can't create a $class without an active request" unless $request;

	# Wrap a weak copy of the request reference in a strong envelope so
	# it can be passed around.

	my $req_envelope = [ $request ];
	weaken $req_envelope->[0];

	my $self = bless {
		wheel_class => $wheel_class,
		on_methods  => [ ],
		request     => $req_envelope,
		args        => { %{ $args{args} || {} }},
		wheel       => undef,
	}, $class;

	# Map methods to events in the wheel parameters.
	foreach my $orig_name (keys %args) {
		next unless $orig_name =~ /^(.+)Method$/;
		my $wheel_param_name = $1 . "Event";
		my $event_number = $self->wheel_param_to_event_number($wheel_param_name);

		$self->{on_methods}[$event_number] = delete $args{$orig_name};
		$args{$wheel_param_name} = "wheel_event_$event_number";
	}

	my $wheel = $self->{wheel} = $wheel_class->new( %args );

	$wheel_id_to_object{$wheel->ID()} = $self;

	# Support user destruction.
	weaken $wheel_id_to_object{$wheel->ID()};

	# Owner gets a strong reference.
	return $self;
}

# Make it easier (or possible) to correlate events from this watcher's wheel to
# itself.

sub wheel_id {
  my $self = shift;
  return unless $self->{wheel};
  return $self->{wheel}->ID;
}

sub DESTROY {
	my $self = shift;

	if (defined $self->{wheel}) {
		delete $wheel_id_to_object{ $self->{wheel}->ID };
		$self->{wheel} = undef;
	}
}

# Resource delivery redelivers the request the resource was created
# in, but to a new method.

sub deliver {
	my ($class, $event_number, @event_args) = @_;

	# 1. Find the watcher for a given wheel ID.

	# Map parameter offsets to named parameters.
	my $param_names = $class->wheel_param_names($event_number);

	my $i = 0;
	my %event_args = map { $_ => $event_args[$i++] } @$param_names;

	# Get the wheel that sent us an event.
	my $wheel_id = $event_args{wheel_id};

	# Get the watcher that owns the wheel.
	my $self = $wheel_id_to_object{$wheel_id};
	die unless $self;

	# Get the method associated with this event.
	my $method = $self->{on_methods}[$event_number];

	# Open the envelope.
	my $request = $self->{request}[0];
	$request->deliver($method, \%event_args);
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
