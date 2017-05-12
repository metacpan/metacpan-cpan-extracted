package Path::Resolver::Resolver::Mux::Prefix;
{
  $Path::Resolver::Resolver::Mux::Prefix::VERSION = '3.100454';
}
# ABSTRACT: multiplex resolvers by using path prefix
use Moose;

use namespace::autoclean;

use MooseX::Types;
use MooseX::Types::Moose qw(Any HashRef);


has prefixes => (
  is  => 'ro',
  isa => HashRef[ role_type('Path::Resolver::Role::Resolver') ],
  required => 1,
  traits   => ['Hash'],
  handles  => {
    get_resolver_for => 'get',
    set_resolver_for => 'set',
    add_resolver_for => 'set',
    has_resolver_for => 'exists',
    delete_resolver_for => 'delete',
  },
);

before add_resolver_for => sub {
  confess "a resolver for $_[1] already exists"
    if $_[0]->has_resolver_for($_[1]);
};

has native_type => (
  is  => 'ro',
  isa => class_type('Moose::Meta::TypeConstraint'),
  required => 1,
  default  => sub { Any },
);

with 'Path::Resolver::Role::Resolver';

sub entity_at {
  my ($self, $path) = @_;
  my @path = @$path;

  shift @path if $path[0] eq '';

  if (my $resolver = $self->prefixes->{ $path[0] }) {
    shift @path;
    return $resolver->entity_at(\@path);
  }

  return unless my $resolver = $self->prefixes->{ '' };

  return $resolver->entity_at(\@path);
}

1;

__END__

=pod

=head1 NAME

Path::Resolver::Resolver::Mux::Prefix - multiplex resolvers by using path prefix

=head1 VERSION

version 3.100454

=head1 SYNOPSIS

  my $resolver = Path::Resolver::Resolver::Mux::Prefix->new({
    prefixes => {
      foo => $foo_resolver,
      bar => $bar_resolver,
    },
  });

  my $simple_entity = $resolver->entity_at('foo/bar.txt');

This resolver looks at the first part of paths it's given to resolve.  It uses
that part to find a resolver (by looking it up in the C<prefixes>) and then
uses that resolver to resolver the rest of the path.

The default native type of this resolver is Any, meaning that is is much more
lax than other resolvers.  A C<native_type> can be specified while creating the
resolver.

=head1 ATTRIBUTES

=head2 prefixes

This is a hashref of path prefixes with the resolver that should be used for
paths under that prefix.  If a resolver is given for the empty prefix, it will
be used for content that did not begin with registered prefix.

=head1 METHODS

=head2 get_resolver_for

This method gets the resolver for the named prefix.

=head2 set_resolver_for

This method sets the resolver for the named prefix, replacing any that already
existed.

=head2 add_resolver_for

This method sets the resolver for the named prefix, throwing an exception if
one already exists.

=head2 has_resolver_for

This method returns true if a resolver exists for the given prefix.

=head2 delete_resolver_for

This method deletes the resolver for the named prefix.

=head1 WHAT'S THE POINT?

This multiplexer allows you to set up a virtual filesystem in which each
subtree is handled by a different resolver.  For example:

  my $resolver = Path::Resolver::Resolver::Mux::Prefix->new({
    config   => Path::Resolver::Resolver::FileSystem->new({
      root => '/etc/my-app',
    }),

    template => Path::Resolver::Resolver::Mux::Ordered->new({
      Path::Resolver::Resolver::DistDir->new({ module => 'MyApp' }),
      Path::Resolver::Resolver::DataSection->new({ module => 'My::Framework' }),
    }),
  });

The path F</config/main.cf> would be looked for on disk as
F</etc/my-app/main.cf>.  The path F</template/main.html> would be looked for
first as F<main.html> in the sharedir for MyApp and failing that in the DATA
section of My::Framework.

This kind of resolver allows you to provide a very simple API (that is,
filenames) to find all manner of resources, either files or otherwise.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
