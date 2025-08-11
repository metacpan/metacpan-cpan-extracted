package SPVM::Mojo::EventEmitter;



1;

=head1 Name

SPVM::Mojo::EventEmitter - Event emitter base class

=head1 Description

Mojo::EventEmitter class in L<SPVM> is a simple base class for event emitting objects.

=head1 Usage

  use Mojo::EventEmitter;
  
  class Cat extends Mojo::EventEmitter {
    # Emit events
    method poke : void () {
      $self->emit(roar => 3);
    }
  }
  
  # Subscribe to events
  my $tiger = Cat->new;
  $tiger->on(roar => method : void ($tiger : Cat, $times : Int) {
    for (my $i = 0; $i < (int)$times; $i++) {
      say "RAWR!";
    }
  });
  $tiger->poke;

=head1 Events

=head2 error

  $e->on(error => method : void ($e : Mojo::EventEmitter, $err : string) {});

This is a special event for errors, it will not be emitted directly by this class, but is fatal if unhandled.
Subclasses may choose to emit it, but are not required to do so.

  $e->on(error => method : void ($e : Mojo::EventEmitter, $err : string) { say "This looks bad: $err"; });

=head1 Instance Methods

=head2 catch

C<method catch : void ($cb : L<Mojo::EventEmitter::Callback|SPVM::Mojo::EventEmitter::Callback>);>

Subscribe to L</"error"> event.

  # Longer version
  $e->on(error => method : void ($e : MyClass, $err : string) {});

=head2 emit

C<method emit : void ($name : string, $arg1 : object = undef, $arg2 : object = undef, $arg3 : object = undef);>

Emit event.

Examples:

  $e->emit("foo");
  $e->emit("foo", 123);

=head2 has_subscribers

C<method has_subscribers : int ($name : string);>

Check if event has subscribers.

=head2 on

C<method on : void ($name : string, $cb : L<Mojo::EventEmitter::Callback|SPVM::Mojo::EventEmitter::Callback>);>

Subscribe to event.

Examples:

  $e->on(foo => method : void ($e : MyClass, $arg1 : Int, $arg2 : string) {});

=head2 once

C<method once : L<Mojo::EventEmitter::Callback|SPVM::Mojo::EventEmitter::Callback> ($name : string, $cb : L<Mojo::EventEmitter::Callback|SPVM::Mojo::EventEmitter::Callback>);>

Subscribe to event and unsubscribe again after it has been emitted once.

  $e->once(foo => method : void ($e : MyClass, $arg1 : Int, $arg2 : string) {});

=head2 subscribers

C<method subscribers : L<Mojo::EventEmitter::Callback|SPVM::Mojo::EventEmitter::Callback>[] ($name : string);>

All subscribers for event.

Note that this method returns the copy instead that Mojolicious's one returns itself.

  # Unsubscribe last subscriber
  my $subscribers = $e->subscribers("foo");
  $e->unsubscribe(foo => $subscribers->[@$subscribers - 1]);
  
  # Change order of subscribers
  my $subscribers = $e->subscribers("foo");
  $subscribers = (Mojo::EventEmitter::Callback[])Fn->reverse($subscribers);
  $e->unsubscribe("foo");
  $e->subscribe(foo => $subscribers);

=head2 unsubscribe

C<method unsubscribe : void ($name : string, $cb : L<Mojo::EventEmitter::Callback|SPVM::Mojo::EventEmitter::Callback> = undef);>

Unsubscribe from event.

Examples:

  $e->unsubscribe("foo");
  $e->unsubscribe(foo => $cb);

=head1 See Also

=over 2

=item * L<SPVM::Mojolicious>

=back

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License

