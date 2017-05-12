=head1 NAME

Phaylon::Class::Cloner - Experimental Customizable Cloning Device

=cut

package Phaylon::Class::Cloner;
use warnings;
use strict;

use Carp;
use Storable qw/ dclone /;
use vars qw/ $VERSION /;

$VERSION = 0.01;

=head1 SYNOPSIS

  use Phaylon::Class::Cloner;

  #  that's what I needed
  my $cloner = Phaylon::Class::Cloner->new ({
  
      CODE => sub { 
          my ( $self, $coderef ) = @_;
          return $coderef;
      },
  });

  #  cloning something
  my $cloned = $cloner->clone( $structure );

=head1 DESCRIPTION

I had problems with cloning of structures that contain coderefs. I didn't
need to clone coderefs, just array and hash references. This module enables
one to define custom specific and default cloning functionalities.

=head1 PUBLIC METHODS

=cut

sub new {
    my ( $class, $options ) = @_;
    croak 'First argument should be option hash reference'
      unless ref $options eq 'HASH';

    $options->{HASH}         ||= \&_clone_HASH;
    $options->{ARRAY}        ||= \&_clone_ARRAY;
    $options->{ '' }         ||= \&_clone_plain_scalar;
    $options->{ ':default' } ||= \&_clone_default;

    my $self = bless $options, $class;
    return $self;
}

=head2 new( I<options hashref> )

Creates a new cloning object. Here's a quick example to show what can
be passed:

  my $cloner = Phaylon::Class::Cloner->new ({

      #  if the module finds a coderef
      CODE => sub { ... },

      #  module ran into an object
      MyClass => sub {
          my ( $self, $object ) = @_;
          return $object->some_cloning_mechanism;
      },

      #  what to do for non-refs. default is just to 
      #  return the value
      '' => sub { ... },

      #  if nothing's found for this type. preset to use
      #  Storage::dclone()
      ':default' => sub { ... },
  });

=cut

sub clone {
    my ( $self, $struct ) = @_;

    my $key   = ( ref $struct || '' );
    my $code  = $self->{ $key }
             || $self->{ ':default' };

    croak "No coderef behind $key" unless ref $code eq 'CODE';
    
    return $self->$code( $struct );
}

=head2 clone( I<data> )

Dispatcher for cloning functionality.

=head1 INTERNAL METHODS

=cut

sub _clone_default {
    my ( $self, $struct ) = @_;
    return dclone( $struct );
}

=head2 _clone_default

Preset default cloning. Uses L<Storage>'s C<dclone>

=cut

sub _clone_plain_scalar {
    my ( $self, $struct ) = @_;
    return $struct;
}

=head2 _clone_plain_scalar

Cloning for non-reference scalars. Defaults to return the value.

=cut

sub _clone_HASH {
    my ( $self, $struct ) = @_;

    return {
        map  { ( $_ => $self->clone( $struct->{ $_ } ) ) } 
        keys %$struct
    };
}

=head2 _clone_HASH

Default for hash references. Clones first level with redispatching
values to C<clone>.

=cut

sub _clone_ARRAY {
    my ( $self, $struct ) = @_;
    return [ map { $self->clone( $_ ) } @$struct ];
}

=head2 _clone_ARRAY

Same as C<_clone_HASH> just for arrays.

=head1 REQUIRES

L<Carp>, L<Storable>

=head1 SEE ALSO

L<Storable>

=head1 NAMESPACE

Due to the specific and experimental nature of this module, it's trying not to waste
namespaces and therefore lies under C<Phaylon::>.

=head1 LICENSE

This module is free software. It may be used, redistributed and/or modified under the same 
terms as Perl itself.

=head1 AUTHOR AND COPYRIGHT

Copyright (c) 2005: Robert Sedlacek C<phaylon@dunkelheit.at>

=cut

1;

