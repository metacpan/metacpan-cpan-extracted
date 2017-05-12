package Mixin::Event::Dispatch::Event;
$Mixin::Event::Dispatch::Event::VERSION = '2.000';
use strict;
use warnings;

use List::UtilsBy ();
use Scalar::Util qw(reftype);

use constant DEBUG => $ENV{MIXIN_EVENT_DISPATCH_DEBUG};

=encoding utf8

=head1 NAME

Mixin::Event::Dispatch::Event - an event object

=head1 VERSION

version 2.000

=head1 SYNOPSIS

 my $self = shift;
 my $ev = Mixin::Event::Dispatch::Event->new(
   name => 'some_event',
   instance => $self,
 );
 $ev->dispatch;

=head1 DESCRIPTION

Provides an object with which to interact with the current
event.

=head1 METHODS

=cut

=head2 new

Takes the following (named) parameters:

=over 4

=item * name - the name of this event

=item * instance - the originating instance

=item * parent - another L<Mixin::Event::Dispatch::Event>
object if we were invoked within an existing handler

=item * handlers - the list of handlers for this event

=back

We're assuming that time is of the essence,
hence the peculiar implementation. Also note that this
constructor is rarely called in practice -
L<Mixin::Event::Dispatch> uses bless directly.

Returns $self.

=cut

sub new { bless { @_[1..$#_] }, $_[0] }

=head1 READ-ONLY ACCESSORS

=cut

=head2 name

Returns the name of this event.

=cut

sub name { $_[0]->{name} }

=head2 is_deferred

Returns true if this event has been deferred. This means
another handler is active, and has allowed remaining handlers
to take over the event - once those other handlers have
finished the original handler will be resumed.

=cut

sub is_deferred { $_[0]->{is_deferred} ? 1 : 0 }

=head2 is_stopped

Returns true if this event has been stopped. This means
no further handlers will be called.

=cut

sub is_stopped { $_[0]->{is_deferred} ? 1 : 0 }

=head2 instance

Returns the original object instance upon which the
L<Mixin::Event::Dispatch/invoke_event> method was called.

This may be different from the instance we're currently
handling, for cases of event delegation for example.

=cut

sub instance { $_[0]->{instance} }

=head2 parent

Returns the parent L<Mixin::Event::Dispatch::Event>, if there
was one. Usually there wasn't.

=cut

sub parent { $_[0]->{parent} }

=head2 handlers

Returns a list of the remaining handlers for this event.
Any that have already been called will be removed from this
list.

=cut

sub handlers {
	my $self = shift;
	@{$self->{remaining}||[]}
}

=head2 stop

Stop processing for this event. Prevents any further event
handlers from being called.

=cut

sub stop {
	my $self = shift;
	$self->debug_print('Stopping') if DEBUG;
	$self->{is_stopped} = 1;
	$self
}

=head2 dispatch

Dispatches this event. Takes the parameters originally passed to
L<Mixin::Event::Dispatch/invoke_event> (with the exception of
the event name), and passes it on to the defined handlers.

Returns $self.

=cut

sub dispatch {
	my $self = shift;
	$self->debug_print("Dispatch with [@_]") if DEBUG;
	# Support pre-5.14 Perl versions. The main reason for not using
	# Try::Tiny here is performance; 10k events/sec with Try::Tiny on
	# an underpowered system, vs. 30k+ with plain eval.
	eval {
		while(!$self->{is_deferred} && @{$self->{handlers}}) {
			local $self->{current_handler} = my $h = shift @{$self->{handlers}};
			if(ref $h) {
				if(reftype($h) eq 'CODE') {
					$h->($self, @_)
				} else {
					$h->invoke_event($self->name, @_)
				}
			} else {
				$self->instance->$h($self, @_)
			}
		}
		1;
	} or do {
		my $err = $@;
		$self->debug_print("Exception $err from [@_]") if DEBUG;
		die $err;
	};
	$self
}

=head2 play

Continue the current event. Do not use.

Semantics are subject to change so avoid this and consider
L</defer> instead. Currently does nothing anyway.

Returns $self.

=cut

sub play { shift }

=head2 defer

Defers this event.

Causes remaining handlers to be called, and marks as
L</is_deferred>.

 sub {
  my $ev = shift;
  print "Deferring\n";
  $ev->defer(@_);
  print "Finished deferring\n";
 }

Returns $self.

=cut

sub defer {
	my $self = shift;
	$self->debug_print("Deferring with [@_]") if DEBUG;
	$self->{is_deferred} = 1;
	my $handler = $self->{current_handler};
	$self->dispatch(@_);
	$self->{current_handler} = $handler;
	$self;
}

=head2 unsubscribe

Unsubscribes the current handler from the event that we're
processing at the moment.

Can be used to implement one-shot or limited-lifetime event
handlers:

 my $count = 0;
 $obj->subscribeto_event(
   som_event => sub {
     my $ev = shift;
     return $ev->unsubscribe if ++$count > 3;
     print "Current count: $count\n";
   }
 );
 $obj->invoke_event('some_event') for 1..5;

Returns $self.

=cut

sub unsubscribe {
	my $self = shift;
	$self->debug_print("Unsubscribing") if DEBUG;
	die "Cannot unsubscribe if we have no handler" unless $self->{current_handler};
	$self->instance->unsubscribe_from_event(
		$self->name => $self->{current_handler}
	);
	$self
}

=head2 debug_print

Show a debug message, should only be called if the appropriate
(compile-time) flag is set:

 $self->debug_print(...) if DEBUG;

rather than expecting

 $self->debug_print(...);

to check for you.

Returns $self.

=cut

sub debug_print {
	my $self = shift;
	printf "[%s] %s\n", $self->name, join ' ', @_;
	$self
}

*DESTROY = sub {
	my $self = shift;
	$self->debug_print("Destroying");
} if DEBUG;

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2012-2014. Licensed under the same terms as Perl itself.
