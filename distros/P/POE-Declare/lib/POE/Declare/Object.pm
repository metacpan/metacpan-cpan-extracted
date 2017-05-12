package POE::Declare::Object;

=pod

=head1 NAME

POE::Declare::Object - Base class for all POE::Declare classes

=head1 DESCRIPTION

L<POE::Declare::Object> provides the base package that delivers core
functionality for all instantiated L<POE::Declare> objects.

Functionality and methods defined here are available in all L<POE::Declare>
classes.

=head1 METHODS

=cut

use 5.008007;
use strict;
use warnings;
use attributes   ();
use Carp         ();
use Scalar::Util ();
use Params::Util ();
use POE;
use POE::Session ();
use POE::Declare ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.59';
}

# Inside-out storage of internal values
my %ID = ();

# Set default attributes
POE::Declare::declare( Alias => 'Param' );





#####################################################################
# Attribute Hooks

# Only events are supported for now
sub MODIFY_CODE_ATTRIBUTES {
	my ($class, $code, $name, @params) = @_;

	# Can't declare events for classes that are already compiled
	if ( $POE::Declare::META{$class} ) {
		Carp::croak("Can't declare event for finalized class $class");
	}

	# Register an event
	if ( $name eq 'Event' ) {
		# Add to the coderef event register
		$POE::Declare::EVENT{Scalar::Util::refaddr($code)} = [
			'POE::Declare::Meta::Event',
		];
		return ();
	}

	# Register a timeout
	if ( $name =~ /^Timeout\b/ ) {
		unless ( $name =~ /^Timeout\((.+)\)$/ ) {
			Carp::croak("Missing or invalid timeout");
		}
		my $delay    = $1;
		my $variance = 0;
		if ( defined Params::Util::_STRING($delay) ) {
			if ( $delay =~ /^(.+?)\+\-(.+?)\z/ ) {
				$delay    = $1;
				$variance = $2;
			}
		}
		unless ( Params::Util::_POSINT($delay) ) {
			Carp::croak("Missing or invalid timeout");
		}
		$POE::Declare::EVENT{Scalar::Util::refaddr($code)} = [
			'POE::Declare::Meta::Timeout',
			delay => $delay,
		];
		return ();
	}

	# Unknown method type
	Carp::croak("Unknown or unsupported attribute $name");
}

=pod

=head2 meta

The C<meta> method can be run on either a class or instances of that class,
and returns the L<POE::Declare::Meta> metadata object for that class.

=cut

# Moved to code generation
# sub meta ($) {
#     POE::Declare::meta( ref $_[0] || $_[0] );
# }





#####################################################################
# Constructor

=pod

=head2 new

  # Create an object, but do not spawn it
  my $object = My::Class->new(
      Param1 => 'value',
      Param2 => 'value',
  );

The C<new> constructor is used to create a L<POE::Declare> component
B<WITHOUT> immediately starting it up.

This is typically assemble to build heirachies of interlinked
components and services, without the need to start all of them
simultaneously.

Instead, a startup routine in the top object of the heirachy can
undertake a controlled startup process, bootstrapping each piece of
the overall application.

All constructors take a series of named params and return a new instance,
or throw an exception on error.

=cut

sub new {
	my $class = shift;
	my $meta  = $class->meta;
	my $self  = bless { }, $class;
	my %param = @_;

	# Check the Alias
	if ( exists $param{Alias} ) {
		unless ( Params::Util::_STRING($param{Alias}) ) {
			Carp::croak("Did not provide a valid Alias param, must be a string");
		}
		$self->{Alias} = delete $param{Alias};
	} else {
		$self->{Alias} = $meta->next_alias;
	}

	# Check and default params
	foreach ( $meta->_params ) {
		next unless exists $param{$_};
		$self->{$_} = delete $param{$_};
	}

	# Check for unsupported params
	if ( %param ) {
		my $names = join ', ', sort keys %param;
		die("Unknown or unsupported $class param(s) $names");
	}

	# Check and normalize message registration
	foreach ( $meta->_messages ) {
		next unless exists $self->{$_};
		$self->{$_} = _CALLBACK($self->{$_});
	}

	# Clear out any accidentally set internal values
	delete $ID{Scalar::Util::refaddr($self)};

	$self;
}

# Check the validity of a provided message handler.
sub _CALLBACK {
	my $it = $_[0];

	# The callback is an anonymous subroutine
	return $it if Params::Util::_CODE($it);

	# Otherwise, we also allow a reference to an array,
	# which contains two identifiers (like foo_bar).
	# This will be converted to a call to the relevant
	# POE session.event
	if (
		Params::Util::_ARRAY0($it)
		and
		scalar(@$it) == 2
		and
		_ALIAS($it->[0])
		and
		Params::Util::_IDENTIFIER($it->[1])
	) {
		# Create a closure for the call
		my $session = $it->[0];
		my $event   = $it->[1];
		my $closure = sub {
			$poe_kernel->call( $session, $event, @_ );
		};
		return $closure;
	}

	# Otherwise, not valid
	Carp::croak('Invalid message event handler');
}

# Check the format of an alias
sub _ALIAS {
	Params::Util::_IDENTIFIER($_[0])
	or (
		defined(Params::Util::_STRING($_[0]))
		and
		$_[0] =~ /\.\d+$/
	) ? $_[0] : undef;
}

=pod

=head2 Alias

The C<Alias> method returns the L<POE::Session> alias that will be used with
this object instance.

These will typically be of the form C<'My::Class.123'> but may be a different
value if a custom C<Alias> param has been explicitly passed to the constructor.

=cut

# This is auto-generated
# sub Alias {
#     $_[0]->{Alias};
# }

=pod

=head2 spawn

  # Spawn (i.e. startup) an existing object
  $object->spawn;
  
  # Create the start the object in one call
  my $alias = My::Class->spawn(
      Param1 => 'value',
      Param2 => 'value',
  );

The C<spawn> method is used to create the L<POE::Session> for this object.

It returns the session alias as a convenience, or throws an exception on error.

When called on the class instead of an object, it provides a shortcut method
for a one-shot construction and spawning of an object, returning the object
instead of the session alias.

Throws an exception on error.

=cut

sub spawn {
	# Handle the class context
	unless ( ref $_[0] ) {
		my $class = shift;
		my $self  = $class->new( @_ );
		$self->spawn;
		return $self;
	}

	# Create the session
	my $self = shift;
	my $meta = $self->meta;
	POE::Session->create(
		heap           => $self,
		package_states => [
			$meta->name => [ $meta->_package_states ],
		],
	)->ID;

	# Return the alias
	$self->Alias;
}

=pod

=head2 spawned

The C<spawned> method returns true if the L<POE::Session> for a B<POE::Declare>
object has been created, or false if not.

=cut

sub spawned {
	!! $ID{Scalar::Util::refaddr($_[0])};

}

=pod

=head2 session_id

The C<session_id> accessor finds and returns the internal L<POE::Session>
id for this instance, or C<undef> if the object has not been spawned.

=cut

sub session_id {
	$ID{Scalar::Util::refaddr($_[0])};
}

=pod

=head2 session

The C<session> accessor finds and returns the internal L<POE::Session>
object for this instance, or C<undef> if the object has not been spawned.

=cut

sub session {
	my $id = $ID{Scalar::Util::refaddr($_[0])} or return undef;
	$poe_kernel->ID_id_to_session($id)         or return undef;
}

=pod

=head2 kernel

The C<kernel> method is provided as a convenience. It returns the
L<POE::Kernel> object that objects of this class will run in.

=cut

use constant kernel => $poe_kernel;





#####################################################################
# POE::Session Wrappers

=pod

=head2 ID

The C<ID> is a wrapper for the equivalent L<POE::Session> method, and
returns the id number for the L<POE::Session>.

Returns an integer, or C<undef> if the heap object has not spawned.

=cut

sub ID {
	$ID{Scalar::Util::refaddr($_[0])};
}

=pod

=head2 postback

  my $handler = $object->postback(
      'event_name',
      $first_param,
      'second_param',
  );
  $handler->( $third_param, $first_param );

The C<postback> method is a wrapper for the equivalent L<POE::Session>
method, and creates an anonymous subroutine that triggers a C<post> for
a named event of the heap object.

Returns a C<CODE> reference, or dies if the heap object has not been
spawned.

=cut

sub postback {
	shift->session->postback(@_);
}

=pod

=head2 callback

  my $handler = $object->callback(
      'event_name',
      $first_param,
      'second_param',
  );
  $handler->( $third_param, $first_param );

The C<callback> method is a wrapper for the equivalent L<POE::Session>
method, and creates an anonymous subroutine that triggers a C<post> for
a named event of the heap object.

Please don't confuse this for a method relating to "callback events"
mentioned earlier, it is not related to them.

Returns a C<CODE> reference, or dies if the heap object has not been
spawned.

=cut

sub callback {
	shift->session->callback(@_);
}

=pod

=head2 lookback

  sub create_foo {
      my $self  = shift;
      my $thing = Other::Class->new(
           ConnectEvent => $self->lookback('it_connected'),
           ConnectError => $self->lookback('it_failed'),
      );
  
      ...
  }

The C<lookback> method is a safe alias for C< [ $self-E<gt>Alias, 'event_name' ] >.

When creating the lookback, the name will be double checked to verify that
the handler actually exists and is registered.

Returns a reference to an C<ARRAY> containing the heap object's alias and
the event name.

=cut

sub lookback {
	my $self  = shift;
	my $class = ref($self);
	my $name  = Params::Util::_IDENTIFIER($_[0]);
	unless ( $name ) {
		Carp::croak("Invalid identifier name '$_[0]'");
	}

	# Does the event exist?
	my $attr = $self->meta->attr($name);
	unless ( $attr and $attr->isa('POE::Declare::Meta::Event') ) {
		Carp::croak("$class does not have the event '$name'");
	}

	return [ $self->Alias, $name ];
}





#####################################################################
# POE::Kernel Wrappers

=pod

=head2 post

The C<post> method runs a POE kernel C<post> for a named event for the
heap object's session.

Returns void.

=cut

sub post {
	$poe_kernel->post( shift->Alias, @_ );
}

=pod

=head2 call

The C<call> method runs a POE kernel C<call> for a named event for the
heap object's session.

Returns as for the particular event handler, but generally returns void.

=cut

sub call {
	$poe_kernel->call( shift->Alias, @_ );
}

### Wrapper for the (new) POE timer API

=pod

=head2 alarm_set

The C<alarm_set> method is equivalent to the L<POE::Kernel> method
of the same name, setting an alarm for a named event of the heap object's
session.

=cut

sub alarm_set {
	shift;
	$poe_kernel->alarm_set( @_ );
}

=pod

=head2 alarm_adjust

The C<alarm_adjust> method is equivalent to the L<POE::Kernel> method
of the same name, adjusting an alarm for a named event of the heap
object's session.

=cut

sub alarm_adjust {
	shift;
	$poe_kernel->alarm_adjust( @_ );
}

=pod

=head2 alarm_clear

The C<alarm_clear> method is a convenience method. It takes the name of
a hash key for the object, containing a timer id. If the ID is set, it
is cleared. If not, the method shortcuts.

=cut

sub alarm_clear {
	$_[0]->{$_[1]} or return 1;
 	$_[0]->alarm_remove(delete $_[0]->{$_[1]});
}

=pod

=head2 alarm_remove

The C<alarm_remove> method is equivalent to the L<POE::Kernel> method
of the same name, removing an alarm for a named event of the heap
object's session.

=cut

sub alarm_remove {
	shift;
	$poe_kernel->alarm_remove( @_ );
}

=pod

=head2 alarm_remove_all

The C<alarm_remove_all> method is equivalent to the L<POE::Kernel> method
of the same name, removing all alarms for the heap object's session.

=cut

sub alarm_remove_all {
	shift;
	$poe_kernel->alarm_remove_all( @_ );
}


=pod

=head2  delay_set

The C<delay_set> method is equivalent to the L<POE::Kernel> method
of the same name, setting a delayed alarm for a named event of the
heap object's session.

=cut

sub delay_set {
	shift;
	$poe_kernel->delay_set( @_ );
}

=pod

=head2  delay_adjust

The C<delay_adjust> method is equivalent to the L<POE::Kernel> method
of the same name, adjusting a delayed alarm for a named event of the
heap object's session.

=cut

sub delay_adjust {
	shift;
	$poe_kernel->delay_adjust( @_ );
}





#####################################################################
# Events

=pod

=head1 EVENTS

The following POE events are provided for all classes

=head2 _start

The default C<_start> implementation is used to register the alias for
the heap object with the kernel. As such, if you need to do your own
tasks in C<_start> you MUST call it first.

  sub _start {
      my $self = $_[HEAP];
      $_[0]->SUPER::_start(@_[1..$#_]);
  
      # Additional tasks here
      ...
  }

Please note though that the super call will break @_ in the current
subroutine, and so you should not use C<$_[KERNEL]> style expressions
after the SUPER call.

=cut

sub _start : Event {
	# Set the session alias in the POE kernel.
	# Check to see if there is an accidental clash between
	# this session's desired alias and any existing alias.
	my $alias = $_[HEAP]->Alias;
	if ( defined $poe_kernel->alias_resolve($alias) ) {
		die("Fatal alias name clash, '$alias' already in use");
	}
	if ( $poe_kernel->alias_set($alias) ) {
		# Failed to set alias
		die("Failed to set alias '$alias'");
	}

	# Register our session id with the session index
	$ID{Scalar::Util::refaddr($_[HEAP])} = $_[SESSION]->ID;

	# Because POE::Declare maintains its own session start/stop
	# management, the default POE parent/child feature will just
	# get in the way.
	# For each created session, ensure it will never have a parent
	# in the eyes of the POE::Kernel.
	SCOPE: {
		local $!; 
		$poe_kernel->detach_myself;
	}

	return;
}

=pod

=head2 _stop

The default C<_stop> implementation is used to clean up our resources
and aliases in the kernel. As such, if you need to do your own
tasks in C<_stop> you should always do them first and then call the
SUPER last.

  sub _stop {
      my $self = $_[HEAP];
  
      # Additional tasks here
      ...
  
      $_[0]->SUPER::_stop(@_[1..$#_]);
  }

=cut

sub _stop : Event {
	delete $ID{Scalar::Util::refaddr($_[HEAP])};
}

=pod

=head2 finish

The C<finish> method is a convenience provided to simplify the process of
shutting down the current object/session.

It will automatically clean up as many things as possible from your
session, leaving it in a state where the session will shut down as
soon as the final outstanding event is processed.

Currently, this consists of removing any pending alarms and removing
the session alias.

=cut

sub finish {
	my $self = shift;

	# Are we running
	my $alias   = $self->Alias;
	my $self_id = $ID{Scalar::Util::refaddr($self)};
	my $session = $poe_kernel->alias_resolve($alias);
	unless ( $self_id ) {
		# Trying to finish a session when we aren't even spawned in
		# POE::Declare terms should be treated strictly.
		Carp::croak("Called 'finish' for $alias on unspawned session");
	}
	unless ( $session ) {
		# Show some lenience for now and allow double-finishing of an
		# active POE session (to allow a class to be sure it has
		# finished everything if there is any doubt).
		return;
	}

	# Check we are in the correct session
	my $current    = $poe_kernel->get_active_session;
	my $session_id = $session->ID;
	my $current_id = $current->ID;
	unless ( $session_id == $current_id ) {
		Carp::croak("Called 'finish' for $alias from a different session");
	}

	# Remove all timers
	$poe_kernel->alarm_remove_all;

	# Remove the session alias.
	unless ( $session_id == $self_id ) {
		die("Session id mismatch error");
	}

	$poe_kernel->alias_remove($alias);
}





#####################################################################
# Compile the POE::Declare form of POE::Declare::Object itself

POE::Declare::compile;

=pod

=head1 SUPPORT

Bugs should be always be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Declare>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<POE>, L<POE::Declare>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2006 - 2012 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
