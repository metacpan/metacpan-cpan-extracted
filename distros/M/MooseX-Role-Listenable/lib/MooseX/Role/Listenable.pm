package MooseX::Role::Listenable;

# ABSTRACT: A parameterized role for observable objects

=head1 NAME

MooseX::Role::Listenable - A parameterized role for observable objects

=head1 SYNOPSIS

  # a class with an observable feature- notifies observers
  # when door opened
  package Car;
  use Moose;
  with 'MooseX::Role::Listenable' => {event => 'door_opened'};
  sub open_door {
      ... # actually open the door
      $self->door_opened; # notify observers
  }

  # an observer class that can listen to door_opened events
  package Dashboard;
  use Moose;
  sub door_opened { print "Got door_opened event!\n" }

  # attach observer to observable
  $car->add_door_opened_listener($dashboard);

  # detach
  $car->remove_door_opened_listener($dashboard);

=head1 DESCRIPTION

A simple implemenation of the observable pattern. By adding this to a class:

  with 'MooseX::Role::Listenable' => {event => 'some_event_name'};

You are making the class observable for the event 'some_event_name'. You
can call the method C<some_event_name()> on the object, and all listeners
added with C<add_some_event_name_listener()> will be notified. Listeners
will be notified by calling their method C<some_event_name()>.

Note the list of listeners is a C<Set::Object::Weak>, so be sure to keep
a reference to them somewhere else.

=head1 SEE ALSO

C<Class::Listener>, C<Class::Observable>, and C<Aspect::Library::Listenable>.

=head1 AUTHOR

Ran Eilam <eilara@cpan.org>

=head1 COPYRIGHT

Ran Eilam <eilara@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use MooseX::Role::Parameterized;
use Set::Object::Weak;

parameter event => (isa => 'Str', required => 1);

role {
    my $p = shift;
    my $event = $p->event;
    my $list = "_${event}_listeners";

    has $list => (
        is         => 'ro',
        lazy_build => 1,
        isa        => 'Set::Object::Weak',
    );

    method "_build_$list" => sub { Set::Object::Weak->new };

    method "add_${event}_listener" => sub {
        my ($self, $listener) = @_;
        $self->$list->insert($listener);
    };

    method "remove_${event}_listener" => sub {
        my ($self, $listener) = @_;
        $self->$list->remove($listener);
    };

    method $event => sub {
        my ($self, @args) = @_;
        $_->$event(@args) for $self->$list->members;
    };
};

1;
