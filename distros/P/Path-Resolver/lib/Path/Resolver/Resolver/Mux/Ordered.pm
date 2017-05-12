package Path::Resolver::Resolver::Mux::Ordered;
{
  $Path::Resolver::Resolver::Mux::Ordered::VERSION = '3.100454';
}
# ABSTRACT: multiplex resolvers by checking them in order
use Moose;

use namespace::autoclean;

use MooseX::Types;
use MooseX::Types::Moose qw(Any ArrayRef);


has resolvers => (
  is  => 'ro',
  isa => ArrayRef[ role_type('Path::Resolver::Role::Resolver') ],
  required   => 1,
  auto_deref => 1,
  traits => ['Array'],
  handles  => {
    push_resolver => 'push',
    unshift_resolver => 'unshift',
  },
);

has native_type => (
  is  => 'ro',
  isa => class_type('Moose::Meta::TypeConstraint'),
  default  => sub { Any },
  required => 1,
);

with 'Path::Resolver::Role::Resolver';

sub entity_at {
  my ($self, $path) = @_;

  for my $resolver ($self->resolvers) {
    my $entity = $resolver->entity_at($path);
    next unless defined $entity;
    return $entity;
  }

  return;
}
  
1;

__END__

=pod

=head1 NAME

Path::Resolver::Resolver::Mux::Ordered - multiplex resolvers by checking them in order

=head1 VERSION

version 3.100454

=head1 SYNOPSIS

  my $resolver = Path::Resolver::Resolver::Mux::Ordered->new({
    resolvers => [
      $resolver_1,
      $resolver_2,
      ...
    ],
  });

  my $simple_entity = $resolver->entity_at('foo/bar.txt');

This resolver looks in each of its resolvers in order and returns the result of
the first of its sub-resolvers to find the named entity.  If no entity is
found, it returns false as usual.

The default native type of this resolver is Any, meaning that is is much more
lax than other resolvers.  A C<native_type> can be specified while creating the
resolver.

=head1 ATTRIBUTES

=head2 resolvers

This is an array of other resolvers.  When asked for content, the Mux::Ordered
resolver will check each resolver in this array and return the first found
content, or false if none finds any content.

=head1 METHODS

=head2 unshift_resolver

This method will add a resolver to the beginning of the list of consulted
resolvers.

=head2 push_resolver

This method will add a resolver to the end of the list of consulted resolvers.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
