package MooX::PDL::Role::Proxy;

# ABSTRACT: treat a container of piddles as if it were a piddle

use strict;
use warnings;

our $VERSION = '0.04';

use Types::Standard -types;

use PDL::Primitive ();
use Hash::Wrap;
use Scalar::Util ();

use Moo::Role;

use namespace::clean;

use MooX::TaggedAttributes -tags => [qw( piddle )];

# requires 'clone_with_piddles';










has _piddles => (
    is       => 'lazy',
    isa      => ArrayRef [Str],
    init_arg => undef,
    builder  => sub {
        my $self = shift;
        [ keys %{ $self->_tags->{piddle} } ];
    },
);

has _set_attr_subs => (
    is       => 'ro',
    isa      => HashRef,
    init_arg => undef,
    default  => sub { {} },
);


has _piddle_op_inplace => (
    is       => 'rwp',
    init_arg => undef,
    clearer  => 1,
    default  => 0
);

















sub _apply_to_tagged_attrs {
    my ( $self, $action ) = @_;

    my $inplace = $self->_piddle_op_inplace;

    my %attr = map {
        my $field = $_;
        $field => $action->( $self->$field, $inplace );
    } @{ $self->_piddles };

    if ( $self->_piddle_op_inplace ) {
        $self->_clear_piddle_op_inplace;
        $self->_set_attr( %attr );
        return $self;
    }

    return $self->clone_with_piddles( %attr );
}










sub inplace {
    my $self = shift;
    $self->_set__piddle_op_inplace( 1 );
    return $self;
}









sub is_inplace { !! $_[0]->__piddle_op_inplace }












sub copy {
    my $self = shift;
    return $self->clone_with_piddles( map { $_ => $self->$_->copy }
          @{ $self->_piddles } );
}









sub sever {
    my $self = shift;
    $self->$_->sever for @{ $self->_piddles };
}









sub index {
    my ( $self, $index ) = @_;
    return $self->_apply_to_tagged_attrs( sub { $_[0]->index( $index ) } );
}

# is there a use for this?
# sub which {
#     my ( $self, $which ) = @_;
#     return PDL::Primitive::which(
#         'CODE' eq ref $which
#         ? do { local $_ = $self; $which->() }
#         : $which
#     );
# }











sub at {
    my ( $self, @idx ) = @_;
    wrap_hash( { map { $_ => $self->$_->at( @idx ) } @{ $self->_piddles } } );
}









sub where {
    my ( $self, $where ) = @_;

    return $self->_apply_to_tagged_attrs( sub { $_[0]->where( $where ) } );
}












sub _set_attr {
    my ( $self, %attr ) = @_;
    my $subs = $self->_set_attr_subs;

    for my $key ( keys %attr ) {
        my $sub = $subs->{$key};

        if ( !defined $sub ) {
            Scalar::Util::weaken( $subs->{$key} = $self->can( "_set_${key}" )
                  // $self->can( $key ) );
            $sub = $subs->{$key};
        }

        $sub->( $self, $attr{$key} );
    }

    return $self;
}


1;

#
# This file is part of MooX-PDL-Role-Proxy
#
# This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

MooX::PDL::Role::Proxy - treat a container of piddles as if it were a piddle

=head1 VERSION

version 0.04

=head1 SYNOPSIS

  package My::Class;

  use Moo;
  use MooX::PDL::Role::Proxy;

  use PDL;

  has p1 => (
      is      => 'rw',
      default => sub { sequence( 10 ) },
      piddle  => 1
  );

  has p2 => (
      is      => 'rw',
      default => sub { sequence( 10 ) + 1 },
      piddle  => 1
  );


  sub clone_with_piddles {
      my ( $self, %piddles ) = @_;

      $self->new->_set_attr( %piddles );
  }


  my $obj = My::Class->new;

  # clone $obj and filter piddles.
  my $new = $obj->where( $obj->p1 > 5 );

=head1 DESCRIPTION

B<MooX::PDL::Role::Proxy> is a L<Moo::Role> which turns its
consumer into a proxy object for some of its attributes, which are
assumed to be B<PDL> objects (or other proxy objects). A subset of
B<PDL> methods applied to the proxy object are applied to the selected
attributes. (See L<PDL::QuckStart> for more information on B<PDL> and
its objects (piddles)).

As an example, consider an object representing a set of detected
events (think physics, not computing), which contains metadata
describing the events as well as piddles representing event position,
energy, and arrival time.  The structure might look like this:

  {
      metadata => \%metadata,
      time   => $time,         # piddle
      x      => $x,            # piddle
      y      => $y,            # piddle
      energy => $energy        # piddle
  }

To filter the events on energy would traditionally be performed
explicitly on each element in the structure, e.g.

  my $mask = which( $obj->{energy} > 20 );

  my $copy = {};
  $copy->{time}   = $obj->{time}->where( $mask );
  $copy->{x}      = $obj->{x}->where( $mask );
  $copy->{y}      = $obj->{y}->where( $mask );
  $copy->{energy} = $obj->{energy}->where( $mask );

Or, more succinctly,

  $new->{$_} = $obj->{$_}->where( $mask ) for qw( time x y energy );

With B<MooX::PDL::Role::Proxy> this turns into

  my $copy = $obj->where( $mask );

Or, if the results should be stored in the same object,

  $obj->inplace->where( $mask );

=head2 Usage and Class requirements

Each attribute to be operated on by the common C<PDL>-like
operators should be given a C<piddle> option, e.g.

  has p1 => (
      is      => 'rw',
      default => sub { sequence( 10 ) },
      piddle  => 1,
  );

(Treat the option value as an identifier for the group of piddles
which should be operated on, rather than as a boolean).

To support non-inplace operations, the class must provide a
C<clone_with_piddles> method with the following signature:

   sub clone_with_piddles ( $self, %piddles )

It should clone C<$self> and assign the values in C<%piddles>
to the attributes named by its keys.  To assist with the latter
operation, see the provided L</_set_attrs> method.

To support inplace operations, attributes tagged with the C<piddle>
option must have write accessors.  They may be public or private.

=head2 Nested Proxy Objects

A class with the applied role should respond equivalently to a true
piddle when the supported methods are called on it (it's a bug
otherwise).  Thus, it is possible for a proxy object to contain
another, and as long as the contained object has the C<piddle>
attribute set, the supported method will be applied to the
contained object appropriately.

=head1 METHODS

=head2 _piddles

  @piddle_names = $self->_piddles;

This returns a list of the names of the object's attributes with
a C<piddle> tag set.

=head2 _apply_to_tagged_attrs

   $self->_apply_to_tagged_attrs( \&sub );

Execute the passed subroutine on all of the attributes tagged with the
C<piddle> option. The subroutine will be invoked as

   sub->( $attribute, $inplace )

where C<$inplace> will be true if the operation is to take place inplace.

The subroutine should return the piddle to be stored.

=head2 inplace

  $self->inplace

Indicate that the next I<inplace aware> operation should be done inplace

=head2 is_inplace

  $bool = $self->is_inplace;

Test if the next I<inplace aware> operation should  be done inplace

=head2 copy

  $new = $self->copy;

Create a copy of the object and its piddles.  It is exactly equivalent to

  $self->clone_with_piddles( map { $_ => $self->$_->copy } @{ $self->_piddles } );

=head2 sever

  $self->sever;

Call L<PDL::Core/sever> on tagged attributes.  This is done inplace.

=head2 index

   $new = $self->index( PIDDLE );

Call L<PDL::Slices/index> on tagged attributes.  This is inplace aware.

=head2 at

   $obj = $self->at( @indices );

Returns a simple object containing the results of running
L<PDL::Core/index> on tagged attributes.  The object's attributes are
named after the tagged attributes.

=head2 where

   $obj = $self->where( $mask );

Apply L<PDL::Primitive/where> to the tagged attributes.  It is inplace aware.

=head2 _set_attr

   $self->_set_attr( %attr )

Set the object's attributes to the values in the C<%attr> hash.

Returns C<$self>.

=head1 LIMITATIONS

There are significant limits to this encapsulation.

=over

=item *

The piddles operated on must be similar enough in structure so that
the ganged operations make sense (and are valid!).

=item *

There is (currently) no way to indicate that there are different sets
of piddles contained within the object.

=item *

The object must be able to be cloned relatively easily, so that
non-inplace operations can create copies of the original object.

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=MooX-PDL-Role-Proxy>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
