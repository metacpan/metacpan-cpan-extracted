package MooX::PDL::Role::Proxy;

# ABSTRACT: treat a container of ndarrays (piddles) as if it were an ndarray (piddle)

use v5.10;
use strict;
use warnings;

our $VERSION = '0.07';

use Types::Standard -types;

use PDL::Primitive ();
use Hash::Wrap;
use Scalar::Util ();

use Moo::Role;
use Lexical::Accessor;

use namespace::clean;

use constant {
    INPLACE_SET   => 1,
    INPLACE_STORE => 2,
};

use MooX::TaggedAttributes -tags => [qw( piddle ndarray )];

my $croak = sub {
    require Carp;
    goto \&Carp::croak;
};

my $can_either = sub {
    my $self = shift;
    for ( @_ ) {
        return $self->can( $_ ) // next;
    }
};

lexical_has clone_v2 => (
    is       => 'lazy',
    weak_ref => 1,
    reader   => \( my $clone_v2 ),
    default  => sub { $_[0]->can( '_clone_with_ndarrays' ) },
);

lexical_has clone_v1 => (
    is       => 'lazy',
    weak_ref => 1,
    reader   => \( my $clone_v1 ),
    default  => sub { $_[0]->can( 'clone_with_piddles' ) },
);

lexical_has clone_args => (
    is        => 'rw',
    reader    => \( my $get_clone_args ),
    clearer   => \( my $clear_clone_args ),
    writer    => \( my $set_clone_args ),
    predicate => \( my $has_clone_args ),
);

lexical_has attr_subs => (
    is      => 'ro',
    isa     => HashRef,
    reader  => \( my $attr_subs ),
    default => sub { {} },
);

lexical_has 'is_inplace' => (
    is      => 'rw',
    clearer => \( my $clear_inplace ),
    reader  => \( my $is_inplace ),
    writer  => \( my $set_inplace ),
    default => 0
);


my $clone = sub {
    my ( $self, $attrs ) = @_;

    if ( my $func = $self->$clone_v2 ) {
        $self->$func( $attrs, $self->$has_clone_args ? $self->$get_clone_args : () );
    }
    elsif ( $func = $self->$clone_v1 ) {
        $self->$func( %$attrs );
    }
    else {
        $croak->( "couldn't find clone method for class '@{[ ref $self ]}'" );
    }
};


















has _ndarrays => (
    is       => 'lazy',
    isa      => ArrayRef [Str],
    init_arg => undef,
    clearer  => 1,
    builder  => sub {
        my $self = shift;
        my $tags = $self->_tags->tag_hash;
        # make backwards compatible with 'piddle'.  the returned hash
        # is locked, so only access keys known to exist
        [
            map  { keys %{ $tags->{$_} } }
            grep { /^ndarray|piddle$/ } keys %$tags
        ];
    },
);

# alias for backwards compatibility
*_piddles       = \&_ndarrays;
*_clear_piddles = \&_clear_ndarrays;
*_build_piddles = \&_build__ndarrays;


















sub _apply_to_tagged_attrs {
    my ( $self, $action ) = @_;

    my $inplace = $self->$is_inplace;

    my %attr = map {
        my $field = $_;
        $field => $action->( $self->$field, $inplace );
    } @{ $self->_ndarrays };

    if ( $inplace ) {
        $self->$clear_inplace;

        if ( $inplace == INPLACE_SET ) {
            $self->_set_attr( %attr );
        }

        elsif ( $inplace == INPLACE_STORE ) {
            for my $attr ( keys %attr ) {
                # $attr{$attr} may be linked to $self->$attr,
                # so if we reshape $self->$attr, it really
                # messes up $attr{$attr}.  sever it to be sure.
                my $pdl = $attr{$attr}->sever;
                ( my $tmp = $self->$attr->reshape( $pdl->dims ) ) .= $pdl;
            }
        }

        else {
            $croak->( "unrecognized inplace flag value: $inplace\n" );
        }

        return $self;
    }

    return $self->$clone( \%attr );
}




















sub inplace {
    $_[0]->$set_inplace( @_ > 1 ? $_[1] : INPLACE_SET );
    $_[0];
}



















sub inplace_store {
    $_[0]->$set_inplace( INPLACE_STORE );
    $_[0];
}



















sub inplace_set {
    $_[0]->$set_inplace( INPLACE_SET );
    $_[0];
}
























sub set_inplace {
    2 == @_ or $croak->( "set_inplace requires two arguments" );
    $_[1] >= 0
      && $_[0]->$set_inplace( $_[1] );
    return;
}









sub is_inplace { goto &$is_inplace }













sub copy {
    my $self = shift;

    if ( $self->is_inplace ) {
        $self->set_inplace( 0 );
        return $self;
    }
    my %attr = map { $_ => $self->$_->copy } @{ $self->_ndarrays };
    return $self->$clone( \%attr );
}










sub sever {
    my $self = shift;
    $self->$_->sever for @{ $self->_ndarrays };
    return $self;
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
    wrap_hash( { map { $_ => $self->$_->at( @idx ) } @{ $self->_ndarrays } } );
}










sub where {
    my ( $self, $where ) = @_;

    return $self->_apply_to_tagged_attrs( sub { $_[0]->where( $where ) } );
}











sub _set_clone_args {
    $_[0]->$set_clone_args( $_[1] );
}










sub _clear_clone_args {
    $_[0]->$clear_clone_args;
}












sub _set_attr {
    my ( $self, %attr ) = @_;
    my $subs = $self->$attr_subs;

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























sub qsort {

    $_[0]->index( $_[0]->qsorti );
}












sub qsort_on {

    my ( $self, $attr ) = @_;

    $self->index( $attr->qsorti );
}















sub clip_on {

    my ( $self, $attr, $min, $max ) = @_;

    my $mask;

    if ( defined $min ) {
        $mask = $attr >= $min;
        $mask &= $attr < $max
          if defined $max;
    }
    elsif ( defined $max ) {
        $mask = $attr < $max;
    }
    else {
        $croak->( "one of min or max must be defined\n" );
    }

    $self->where( $mask );
}













sub slice {

    my ( $self, $slice ) = @_;

    return $self->_apply_to_tagged_attrs( sub { $_[0]->slice( $slice ) } );
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

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory ndarray ndarrays

=head1 NAME

MooX::PDL::Role::Proxy - treat a container of ndarrays (piddles) as if it were an ndarray (piddle)

=head1 VERSION

version 0.07

=head1 SYNOPSIS

  package My::Class;

  use Moo;
  use MooX::PDL::Role::Proxy;

  use PDL;

  has p1 => (
      is      => 'rw',
      default => sub { sequence( 10 ) },
      ndarray  => 1
  );

  has p2 => (
      is      => 'rw',
      default => sub { sequence( 10 ) + 1 },
      ndarray  => 1
  );


  sub clone_with_ndarrays {
      my ( $self, %ndarrays ) = @_;

      $self->new->_set_attr( %ndarrays );
  }


  my $obj = My::Class->new;

  # clone $obj and filter ndarrays.
  my $new = $obj->where( $obj->p1 > 5 );

=head1 DESCRIPTION

B<MooX::PDL::Role::Proxy> is a L<Moo::Role> which turns its
consumer into a proxy object for some of its attributes, which are
assumed to be B<PDL> objects (or other proxy objects). A subset of
B<PDL> methods applied to the proxy object are applied to the selected
attributes. (See L<PDL::QuckStart> for more information on B<PDL> and
its objects (ndarrays)).

As an example, consider an object representing a set of detected
events (think physics, not computing), which contains metadata
describing the events as well as ndarrays representing event position,
energy, and arrival time.  The structure might look like this:

  {
      metadata => \%metadata,
      time   => $time,         # ndarray
      x      => $x,            # ndarray
      y      => $y,            # ndarray
      energy => $energy        # ndarray
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
operators should be given a C<ndarray> option, e.g.

  has p1 => (
      is      => 'rw',
      default => sub { sequence( 10 ) },
      ndarray  => 1,
  );

(Treat the option value as an identifier for the group of ndarrays
which should be operated on, rather than as a boolean).

=head2 Results of Operations

The results of operations may either be stored L</In Place> or returned
in L</Cloned Objects>.  By default, operations return cloned objects.

=head3 In Place

Use one of the following methods, L</inplace>, L</inplace_store>, L</inplace_set>.
to indicate that the next in-place aware operation should be performed in-place.
After the operation is completed, the in-place flag will be reset.

To support inplace operations, attributes tagged with the C<ndarray>
option must have write accessors.  They may be public or private.

=head3 Cloned Objects

The class must provide a a clone method.  If cloning an object
requires extra arguments, use L</_set_clone_args> and
L</_clear_clone_args> to set or reset the arguments.

If the class provides the L<_clone_with_ndarrays> method, then it will be called as

   $object->_clone_with_ndarrays( \%ndarrays, ?$arg);

where C<$arg> will only be passed if L</_set_clone_args> was called.

For backwards compatibility, the L<clone_with_piddles> method is supported, but
it is not possible to pass in extra arguments. It will be called as

   $object->clone_with_piddles ( %ndarrays );

=head2 Nested Proxy Objects

A class with the applied role should respond equivalently to a true
ndarray when the supported methods are called on it (it's a bug
otherwise).  Thus, it is possible for a proxy object to contain
another, and as long as the contained object has the C<ndarray>
attribute set, the supported method will be applied to the
contained object appropriately.

=head1 METHODS

=head2 _ndarrays

  @ndarray_names = $obj->_ndarrays;

This returns a list of the names of the object's attributes with a
C<ndarray> (or for backwards compatibility, C<piddle> ) tag set.  The
list is lazily created by the C<_build__ndarrays> method, which can be
modified or overridden if required. The default action is to find all
tagged attributes with tags C<ndarray> or C<piddle>.

=head2 _clear_ndarrays

Clear the list of attributes which have been tagged as ndarrays.  The
list will be reset to the defaults when C<_ndarrays> is next invoked.

=head2 _apply_to_tagged_attrs

   $obj->_apply_to_tagged_attrs( \&sub );

Execute the passed subroutine on all of the attributes tagged with
C<ndarray> (or C<piddle>). The subroutine will be invoked as

   sub->( $attribute, $inplace )

where C<$inplace> will be true if the operation is to take place inplace.

The subroutine should return the ndarray to be stored.

Returns C<$obj> if applied in-place, or a new object if not.

=head2 inplace

  $obj->inplace( ?$how )

Indicate that the next I<inplace aware> operation should be done inplace.

An optional argument indicating how the ndarrays should be updated may be
passed (see L</set_inplace> for more information).  This API differs from
from the L<inplace|PDL::Core/inplace> method.

It defaults to using the attributes' accessors to store the results,
which will cause triggers, etc. to be called.

Returns C<$obj>.
See also L</inplace_direct> and L</inplace_accessor>.

=head2 inplace_store

  $obj->inplace_store

Indicate that the next I<inplace aware> operation should be done
inplace.  NDarrays are changed inplace via the C<.=> operator, avoiding
any side-effects caused by using the attributes' accessors.

It is equivalent to calling

  $obj->set_inplace( MooX::PDL::Role::Proxy::INPLACE_STORE );

Returns C<$obj>.
See also L</inplace> and L</inplace_accessor>.

=head2 inplace_set

  $obj->inplace_set

Indicate that the next I<inplace aware> operation should be done inplace.
The object level attribute accessors will be used to store the results (which
may be the same ndarray).  This will cause L<Moo> triggers, etc to be
called.

It is equivalent to calling

  $obj->set_inplace( MooX::PDL::Role::Proxy::INPLACE_SET );

Returns C<$obj>.
See also L</inplace_store> and L</inplace>.

=head2 set_inplace

  $obj->set_inplace( $value );

Change the value of the inplace flag.  Accepted values are

=over

=item MooX::PDL::Role::Proxy::INPLACE_SET

Use the object level attribute accessors to store the results (which
may be the same ndarray).  This will cause L<Moo> triggers, etc to be
called.

=item MooX::PDL::Role::Proxy::INPLACE_STORE

Store the results directly in the existing ndarray using the C<.=> operator.

=back

=head2 is_inplace

  $bool = $obj->is_inplace;

Test if the next I<inplace aware> operation should  be done inplace

=head2 copy

  $new = $obj->copy;

Create a copy of the object and its ndarrays.  If the C<inplace> flag
is set, it returns C<$obj> otherwise it is exactly equivalent to

  $obj->clone_with_ndarrays( map { $_ => $obj->$_->copy } @{ $obj->_ndarrays } );

=head2 sever

  $obj = $obj->sever;

Call L<PDL::Core/sever> on tagged attributes.  This is done inplace.
Returns C<$obj>.

=head2 index

   $new = $obj->index( NDARRAY );

Call L<PDL::Slices/index> on tagged attributes.  This is inplace aware.
Returns C<$obj> if applied in-place, or a new object if not.

=head2 at

   $obj = $obj->at( @indices );

Returns a simple object containing the results of running
L<PDL::Core/index> on tagged attributes.  The object's attributes are
named after the tagged attributes.

=head2 where

   $obj = $obj->where( $mask );

Apply L<PDL::Primitive/where> to the tagged attributes.  It is in-place aware.
Returns C<$obj> if applied in-place, or a new object if not.

=head2 _set_clone_args

   $obj->_set_clone_args( $args );

Pass the given value to the C<_clone_with_args_ndarrays> method when
an object must be implicitly cloned.

=head2 _clear_clone_args

   $obj->_clear_clone_args;

Clear out any value set by L<_set_clone_args>.

=head2 _set_attr

   $obj->_set_attr( %attr )

Set the object's attributes to the values in the C<%attr> hash.

Returns C<$obj>.

=head2 qsort

  $obj->qsort;

Sort the ndarrays.  This requires that the object has a C<qsorti> method, which should
return an ndarray index of the elements in ascending order.

For example, to designate the C<radius> attribute as that which should be sorted
on by qsort, include the C<handles> option when declaring it:

  has radius => (
      is      => 'ro',
      ndarray  => 1,
      isa     => Piddle1D,
      handles => ['qsorti'],
  );

It is in-place aware. Returns C<$obj> if applied in-place, or a new object if not.

=head2 qsort_on

  $obj->sort_on( $ndarray );

Sort on the specified C<$ndarray>.

It is in-place aware.
Returns C<$obj> if applied in-place, or a new object if not.

=head2 clip_on

  $obj->clip_on( $ndarray, $min, $max );

Clip on the specified C<$ndarray>, removing elements which are outside
the bounds of [C<$min>, C<$max>).  Either bound may be C<undef> to indicate
it should be ignore.

It is in-place aware.

Returns C<$obj> if applied in-place, or a new object if not.

=head2 slice

  $obj->slice( $slice );

Slice.  See L<PDL::Slices/slice> for more information.

It is in-place aware.
Returns C<$obj> if applied in-place, or a new object if not.

=head1 LIMITATIONS

There are significant limits to this encapsulation.

=over

=item *

The ndarrays operated on must be similar enough in structure so that
the ganged operations make sense (and are valid!).

=item *

There is (currently) no way to indicate that there are different sets
of ndarrays contained within the object.

=item *

The object must be able to be cloned relatively easily, so that
non-inplace operations can create copies of the original object.

=back

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to   or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=MooX-PDL-Role-Proxy

=head2 Source

Source is available at

  https://gitlab.com/djerius/moox-pdl-role-proxy

and may be cloned from

  https://gitlab.com/djerius/moox-pdl-role-proxy.git

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
