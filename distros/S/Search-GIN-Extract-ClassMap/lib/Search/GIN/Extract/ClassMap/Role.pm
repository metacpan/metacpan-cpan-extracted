use 5.006;    # our
use strict;
use warnings;

package Search::GIN::Extract::ClassMap::Role;

# ABSTRACT: A base role for maps containing classes and associated handlers.

our $VERSION = '1.000003';

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose::Role 0.90 qw( requires has );
use Search::GIN::Extract::ClassMap::Types qw( CoercedClassMap );
use namespace::autoclean;














requires 'matches';































































has classmap => (
  isa     => CoercedClassMap,
  coerce  => 1,
  is      => 'rw',
  default => sub { +{} },
  traits  => [qw( Hash )],
  handles => {
    'classmap_entries' => 'keys',
    'classmap_set'     => 'set',
    'classmap_get'     => 'get',
  },
);

no Moose::Role;









sub extract_values {
  my ( $self, $extractee ) = @_;
  return map { $_->extract_values($extractee) } $self->matches($extractee);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Search::GIN::Extract::ClassMap::Role - A base role for maps containing classes and associated handlers.

=head1 VERSION

version 1.000003

=head1 SYNOPSIS

  {
    package Foo;
    use MooseX::Role;
    with 'Search::GIN::Extract::ClassMap::Role';

    sub matches {
      my ( $self, $extractee ) = @_;
      my @m;

      for ( $self->classmap_entries ) {
        if( $extractee->some_criteria( $_ ) ) {
          push @m, $self->classmap_get( $_ );
        }
      }
      return @m;
    }

  }

=head1 REQUIRED METHODS

=head2 C<matches>

  my ( @extractors ) = $item->matches( $extractee )

Must take an object and return a list of
L<< C<Search::GIN::Extract>|Search::GIN::Extract >> items to use for it.

  for my $extractor ( @extractors ) {
    my $metadata = $extractor->extract_values( $extractee );
  }

=head1 METHODS

=head2 C<classmap_entries>

  my ( @classnames ) = $item->classmap_entries();

Fetches the C<Class> names ( C<keys> ) for all registered handlers in this
instance. ( Accessor for L<< C<classmap>|/classmap >> )

=head2 C<classmap_set>

  $item->classmap_set( $classname, $handler );

Sets the handler for class C<$classname> in this instance. ( Setter for
L<< C<classmap>|/classmap >> )

=head2 C<classmap_get>

  $item->classmap_get( $classname );

Gets the handler for class C<$classname> in this instance. ( Getter for
L<< C<classmap>|/classmap >> )

=head2 C<extract_values>

  my @values = $instance->extract_values( $extractee );

extracts values from all matching rules for the object

=head1 ATTRIBUTES

=head2 C<classmap>

  my $item = Thing::That::Does::ClassMap::Role->new(
    classmap => {
      classname => handler_for_objects_of_classname
    }
  );
  # or
  $item->classmap( classmap => { ... } );

This is a key => value pair set mapping classes to some Extractor to use for that class

  $item->classmap_entries # class names / keys

  $item->classmap_set( $classname, $handler );

  my $handler = $item->classmap_get( $classname );

=over 4

=item C<isa>: L<< C<CoercedClassMap>|Search::GIN::Extract::ClassMap::Types/CoercedClassMap >>

=item C<coerce>: C<< B<True> >>

=item C<provides>:

=over 4

=item * L<< C<classmap_entries>|/classmap_entries >>

=item * L<< C<classmap_set>|/classmap_set >>

=item * L<< C<classmap_get>|/classmap_get >>

=back

=back

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
