package Mixin::Event::Dispatch;
# ABSTRACT: Mixin methods for simple event/message dispatch framework
use strict;
use warnings;

our $VERSION = '2.000';

# Key name to use for event handlers. Nothing should be
# accessing this directly so we don't mind something
# unreadable, it's only used in two methods which subclasses
# can override at will
use constant EVENT_HANDLER_KEY => '__MED_event_handlers';

# Legacy support, newer classes probably would turn this off
use constant EVENT_DISPATCH_ON_FALLBACK => 1;

=encoding utf8

=head1 NAME

Mixin::Event::Dispatch - mixin methods for simple event/message dispatch framework

=head1 VERSION

version 2.000

=head1 SYNOPSIS

 # Add a handler then invoke it
 package Some::Class;
 use parent qw(Mixin::Event::Dispatch);
 sub new { bless {}, shift }

 my $obj = Some::Class->new;

 # Subscribe to events - subscribers will be called with an event object,
 # and any event parameters, each time the event is raised.
 $obj->subscribe_to_event(another_event => (my $code = sub {
   my $ev = shift;
   warn "[] @_";
 }));
 $obj->invoke_event(another_event => 'like this');
 # should get output 'Event data: like this'
 $obj->unsubscribe_from_event(another_event => $code);

 # Note that handlers will be called for each instance of an event until they return false,
 # at which point the handler will be removed, so for a permanent handler, make sure to return 1.
 $obj->add_handler_for_event(some_event => sub { my $self = shift; warn "had some_event: @_"; 1; });
 $obj->invoke_event(some_event => 'message here');

 # Attach event handler for all on_XXX named parameters
 package Event::User;
 sub configure {
	my $self = shift;
	my %args = @_;
	$self->add_handler_for_event(
		map { (/^on_(.*)$/) ? ($1 => $args{$_}) : () } keys %args
	);
	return $self;
 }

=head1 DESCRIPTION

Add this in as a parent to your class, and it'll provide some methods for defining event handlers (L</subscribe_to_event> or L</add_handler_for_event>) and calling them (L</invoke_event>).

Note that handlers should return 0 for a one-off handler, and 1 if it should be called again on the next event.

=head1 SPECIAL EVENTS

A single event has been reserved for cases where a callback dies:

=over 4

=item * C< event_error > - if a handler is available, this will be called instead of dying whenever any other handler dies. If an C< event_error > handler also fails,
then this error will be re-thrown. As with the other handlers, you can have more than one C< event_error > handler.

=back

=cut

use List::UtilsBy ();
use Scalar::Util ();
use Mixin::Event::Dispatch::Event;

=head1 METHODS

=cut

=head2 invoke_event

Takes an C<event> parameter, and optional additional parameters that are passed to any callbacks.

 $self->invoke_event('new_message', from => 'fred', subject => 'test message');

Returns $self if a handler was found, undef if not.

=cut

sub invoke_event {
	my ($self, $event_name, @param) = @_;
	my $handlers = $self->event_handlers->{$event_name} || [];
	
	unless(@$handlers) {
		# Legacy flag - when set, pass control to on_$event_name
		# if we don't have a handler defined.
		if($self->can('EVENT_DISPATCH_ON_FALLBACK') && $self->EVENT_DISPATCH_ON_FALLBACK && (my $code = $self->can("on_$event_name"))) {
			local $@;
			eval {
				$code->($self, @_);
				1;
			} or do {
				die $@ if $event_name eq 'event_error';
				$self->invoke_event(event_error => $@) or die "$@ and no event_error handler found";
			};
		}
		return $self;
	}

# We should really do this...
#	my $ev = Mixin::Event::Dispatch::Event->new(
#		name => $event_name,
#		instance => $self,
#		handlers => [ @$handlers ],
#	);
#	$ev->dispatch;
# ... but this gives better performance (examples/benchmark.pl)
	(bless {
		name => $event_name,
		instance => $self,
		# Passing a copy since we might change these later and
		# we do not want those changes to affect any events
		# currently in flight
		handlers => [ @$handlers ],
	}, 'Mixin::Event::Dispatch::Event')->dispatch(@param);
	return $self;
}

=head2 subscribe_to_event

Subscribe the given coderef to the named event.

Called with a list of event name and handler pairs. An
event name can be any string value. The handler is one
of the following:

=over 4

=item * a coderef will be used directly as a handler,
and will be passed the L<Mixin::Event::Dispatch::Event>
object representing this event.

=item * a plain string will be used as a method name

=item * a subclass of L<Mixin::Event::Dispatch> will
be used to delegate the event - use this if you have
an object hierarchy and want the parent object to handle
events on the current object

=back

If you have an overloaded object which is both a
L<Mixin::Event::Dispatch> subclass and provides a
coderef overload, it will default to event delegation
behaviour. To ensure the overloaded coderef is used
instead, pass \&$obj instead.

All handlers will be given an event (a
L<Mixin::Event::Dispatch::Event> object) as the first
parameter, and any passed event parameters as the
remainder of @_.

Example usage:

 my $parent = $obj->parent;
 $obj->subscribe_to_event(
   connect => sub { warn shift->name }, # warns 'connect'
   connect => $parent, # $parent->invoke_event(connect => @_)
   connect => \&$parent, # $parent's overloaded &{}
   joined  => 'on_joined', # the on_joined method in $obj
 );

Note that multiple handlers can be assigned to the same
event name.

=cut

sub subscribe_to_event {
	my $self = shift;

# Init if we haven't got a valid event_handlers yet
	$self->clear_event_handlers unless $self->event_handlers;

# Add the defined handlers
	while(@_) {
		my ($ev, $code) = splice @_, 0, 2;
		die 'Undefined event?' unless defined $ev;
		push @{$self->event_handlers->{$ev}}, $code;
		Scalar::Util::weaken($self->event_handlers->{$ev}[-1]) if ref($code) && Scalar::Util::reftype($code) ne 'CODE'
	}
	return $self;
}

=head2 unsubscribe_from_event

Removes the given coderef from the list of handlers for this event.

Expects pairs of (event name, coderef) entries for the events to
unsubscribe from.

Example usage:

 $obj->subscribe_to_event(
   some_event => (my $code = sub { }),
 );
 $obj->unsubscribe_from_event(
   some_event => $code,
 );

If you need to unsubscribe from the event currently being
handled, try the L<Mixin::Event::Dispatch::Event/unsubscribe>
method.

Returns $self.

=cut

sub unsubscribe_from_event {
	my $self = shift;

# Init if we haven't got a valid event_handlers yet
	$self->clear_event_handlers unless $self->event_handlers;

# Add the defined handlers
	while(@_) {
		my ($ev, $code) = splice @_, 0, 2;
		die 'Undefined event?' unless defined $ev;
		List::UtilsBy::extract_by {
			Scalar::Util::refaddr($code) == Scalar::Util::refaddr($_)
		} @{$self->event_handlers->{$ev}} or die "Was not subscribed to $ev for $code";
	}
	return $self;
}

=head2 add_handler_for_event

Adds handlers to the stack for the given events.

 $self->add_handler_for_event(
   new_message => sub { warn @_; 1 },
   login => sub { warn @_; 1 },
   logout => sub { warn @_; 1 },
 );

=cut

sub add_handler_for_event {
	my $self = shift;

# Init if we haven't got a valid event_handlers yet
	$self->clear_event_handlers unless $self->event_handlers;

# Add the defined handlers
	while(@_) {
		my ($ev, $code) = splice @_, 0, 2;
		# Support legacy interface via wrapper
		# * handler is passed $self
		# * returning false means we want to unsubscribe
		push @{$self->event_handlers->{$ev}}, sub {
			my $ev = shift;
			return if $code->($ev->instance, @_);
			$ev->unsubscribe;
		};
	}
	return $self;
}

=head2 event_handlers

Accessor for the event stack itself - should return a hashref which maps event names to arrayrefs for
the currently defined handlers.

=cut

sub event_handlers { shift->{+EVENT_HANDLER_KEY} ||= {} }

=head2 clear_event_handlers

Removes all queued event handlers.

Will also be called when defining the first handler to create the initial L</event_handlers> entry, should
be overridden by subclass if something other than $self->{event_handlers} should be used.

=cut

sub clear_event_handlers {
	my $self = shift;
	$self->{+EVENT_HANDLER_KEY} = { };
	return $self;
}

1;

__END__

=head1 API HISTORY

Version 2.000 (will) implement the L<Mixin::Event::Dispatch::Methods> class.

Version 1.000 implemented L</subscribe_to_event> and L<Mixin::Event::Dispatch::Event>.

Version 0.002 changed to use L</event_handlers> instead of C< event_stack > for storing the available handlers (normally only L<invoke_event> and
L<add_handler_for_event> are expected to be called directly).

=head1 ROLE vs. MIXIN

Role systems might work using the L<Mixin::Event::Dispatch::Methods> module, which allows
import of the relevant methods. Try combing this with a thin wrapper using L<Role::Tiny> / L<Moo::Role> /
L<Moose> for that. The C<t/moo-role.t> and C<t/role-tiny.t> tests may provide some
inspiration.

Alternatively, you could perhaps use this as a component via L<Class::C3::Componentised>.

(I haven't really used any of the above options myself, please let me know if I'm spreading
disinformation here)

=head1 SEE ALSO

There are at least a dozen similar modules already on CPAN, here's a small sample:

=over 4

=item * L<Event::Distributor> - uses L<Future> to sequence callbacks, implementing
the concepts discussed in
L<Event-Reflexive programming|http://leonerds-code.blogspot.co.uk/search/label/event-reflexive>

=item * L<Object::Event> - event callback interface used in several L<AnyEvent> modules.

=item * L<Ambrosia::Event> - part of the L<Ambrosia> web application framework

=item * L<Net::MessageBus> - event subscription via TCP-based message bus

=item * L<Event::Wrappable> - wrapping for event listeners

=item * L<MooseX::Event> - node.js-inspired events, for Moose users

=item * L<Beam::Emitter> - a L<Moo::Role> for event handling

=back

Note that some frameworks such as L<Reflex>, L<POE> and L<Mojolicious> already have comprehensive message-passing
and callback interfaces.

If you're looking for usage examples, try the following:

=over 4

=item * L<Adapter::Async>

=item * L<Net::Async::AMQP>

=item * L<EntityModel> - uses this as the underlying event-passing mechanism, with some
support in L<EntityModel::Class> for indicating event usage metadata

=item * L<Protocol::PostgreSQL> - mostly an adapter converting PostgreSQL database messages
to/from events using this class

=item * L<Protocol::IMAP> - the same, but for the IMAPv4bis protocol

=item * L<Protocol::XMPP> - and again for Jabber/XMPP

=back

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

with thanks to various helpful people on freenode #perl who suggested making L</event_handlers> into an
accessor (to support non-hashref objects) and who patiently tried to explain about roles.

L<Mixin::Event::Dispatch::Methods> suggested by mst, primarily for better integration with object
systems such as Moo(se).

=head1 LICENSE

Copyright Tom Molesworth 2011-2015, based on code originally part of L<EntityModel>.
Licensed under the same terms as Perl itself.
