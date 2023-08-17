package MooX::Role::EventEmitter;
use Moo::Role 2;
use 5.020; # signatures
use feature 'signatures';
no warnings 'experimental::signatures';
use Try::Tiny;
use Carp 'croak';

use Scalar::Util 'weaken';
# Basically modeled after Mojo::EventEmitter

our $VERSION = '0.04';

=head1 NAME

MooX::Role::EventEmitter - Event emitter role

=head1 SYNOPSIS

  package My::Thing;
  use 5.020;
  use feature 'signatures';
  no warnings 'experimental::signatures';
  use Moo 2;
  with 'MooX::Role::EventEmitter';

  sub event_received( $self, $ev ) {
      $self->emit( myevent => $ev );
  }

  # ... later, in your client

  package main;
  my $foo = My::Thing->new();
  $foo->on( myevent => sub( $ev ) {
      say "I receivend an event";
  });

=cut

has 'events' => (
    is => 'lazy',
    default => sub { +{} },
);

=head1 METHODS

=head2 C<< $obj->emit $name, @args >>

Emit an event

=cut

sub emit($self, $name, @args) {
  if (my $s = $self->events->{$name}) {
    #warn "-- Emit $name in @{[blessed $self]} (@{[scalar @$s]})\n" if DEBUG;
    for my $cb (@$s) {

        try { $self->$cb(@args) }
        catch { warn "on $name callback died: $_" }
    }
  }
  #else {
  #  warn "-- Emit $name in @{[blessed $self]} (0)\n" if DEBUG;
  #  die "@{[blessed $self]}: $_[0]"                  if $name eq 'error';
  #}
  return $self;
}

=head2 C<< $obj->has_subscribers $name >>

Check if an event has subscribers.

=cut

sub has_subscribers( $self, $name ) {
    !!$self->events->{$name}
}

=head2 C<< $obj->on $name, @args >>

  my $cb = $obj->on( myevent => sub { ... });

Subscribe to an event.

=cut

sub on($self, $name, $cb) {
    push @{$self->events->{$name}}, $cb and return $cb
}

=head2 C<< $obj->once $name, @args >>

  my $cb = $obj->once( myevent => sub { ... });

Subscribe to an event for just one event.

=cut

sub once($self, $name, $cb) {
  weaken $self;
  my $wrapper = sub {
    $self->unsubscribe($name => __SUB__);
    goto &$cb;
  };
  $self->on($name => $wrapper);

  return $wrapper;
}

=head2 C<< $obj->subscribers( $name ) >>

  my $s = $obj->subscribers( 'myevent' );

Return an arrayref of the subscribers for an event.

=cut

sub subscribers($self,$name) {
    $self->events->{ $name } //= []
}

=head2 C<< $obj->unsubscribe( $name => $cb ) >>

  $obj->unsubscribe('myevent', $cb); # a specific callback
  $obj->unsubscribe('myevent');      # all callbacks

Unsubscribe from event.

=cut

sub unsubscribe($self, $name, $cb=undef) {
  # One
  if ($cb) {
      @{$self->events->{$name}} = grep { $cb ne $_ } @{$self->events->{$name}};
      delete $self->events->{$name} unless @{$self->events->{$name}};
  } else {
      delete $self->events->{$name}
  }

  return $self;
}

1;

=head1 SEE ALSO

L<Mojo::EventEmitter> - the module this API is based on

=cut
