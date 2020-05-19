package Mojo::Base::Role::PromiseClass 0.009;

# ABSTRACT: Add promise_class attribute to Mojo class

use Mojo::Base -role;

has promise_class => sub {'Mojo::Promise'};

sub promise_roles {
    my $self   = shift;
    my $pclass = $self->promise_class;
    my @roles  =
      grep { !Role::Tiny::does_role($pclass, $_) }
      map  { /^\+(.+)$/ ? "Mojo::Promise::Role::$1" : $_ }
      @_;
    $self->promise_class($pclass->with_roles(@roles)) if @roles;
    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojo::Base::Role::PromiseClass - Add promise_class attribute to Mojo class

=head1 VERSION

version 0.009

=head1 SYNOPSIS

  package MyRole;

  use Mojo::Base -role;
  with 'Mojo::Base::Role::PromiseClass';

  sub give_me_a_promise {
     my $p = $_[0]->promise_class->new;
     #
     # ... do stuff to $p
     #
     return $p;
  }

Elsewhere

  # mix MyRole in to something
  $object = MyThing->new(...)->with_roles('MyRole');

  # get promise_class, add features
  $object->promise_class;            # -> Mojo::Promise
  $object->promise_roles('+Repeat'); # -> $object
  $object->promise_class;            # -> Mojo::Promise__WITH__...Repeat

  # use them
  $object->give_me_a_promise->repeat(sub {...} );

=head1 DESCRIPTION

L<Mojo::Base::Role::PromiseClass> is a role that adds a promise_class attribute to a given class.

This role only provides methods to access and manipulate the promise_class; it does not, by itself, have any provision for the class being actually used anywhere or for any particular purpose.

=head1 ATTRIBUTES

L<Mojo::Base::Role::PromiseClass> implements the following attributes.

=head2 promise_class

  $pclass = $object->promise_class;
  $object = $object->promise_class('Mojo::Promise');

Get or set the C<$object>'s preferred promise class.

=head1 METHODS

L<Mojo::Base::Role::PromiseClass> supplies the following methods:

=head2 promise_roles

  $object->promise_roles(@roles);

This is a shortcut to add the specified C<@roles> to the promise class, returning the original object for method chains, equivalent to

  $object->promise_class($object->promise_class->with_roles(@roles));

For roles following the naming scheme C<Mojo::Promise::Role::RoleName> you can use the shorthand C<+RoleName>.

Note that using this method is slightly safer than setting L</promise_class> directly in that if the object's existing promise_class is derived from L<Mojo::Promise> (which it will be by default) then you won't be changing that, which is typically what you want.

=head1 SEE ALSO

L<Mojo::Promise>, L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=head1 AUTHOR

Roger Crew <wrog@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Roger Crew.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
