# --8<--8<--8<--8<--
#
# Copyright (C) 2016 Smithsonian Astrophysical Observatory
#
# This file is part of PDLx::Mask
#
# PDLx::Mask is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -->8-->8-->8-->8--

package PDLx::Mask;

use strict;
use warnings;
use Carp;

use v5.10;

our $VERSION = '0.03';

use Params::Check qw[ check ];
use Ref::Util ':all';
use Data::GUID;
use Safe::Isa;

use PDL::Core ':Internal';


use Moo;
use MooX::ProtectedAttributes;
use namespace::clean 0.16;

extends 'PDLx::DetachedObject';

with 'PDLx::Role::RestrictedPDL';

use overload
  map {
    my $mth = overload::Method( 'PDL', $_ );
    $_ => sub {
        # operator should work on base value, not
        # effective mask
        my $mask = $_[0]->{PDL};
        $_[0]->{PDL} = $_[0]->base;
        my $r = &$mth;
        $_[0]->{PDL} = $mask;
        $_[0]->clear_nvalid;
        $_[0]->update;
        $_[0];
      }
  } qw[ |= &= ^= .= ];

has base => (
    is       => 'ro',
    required => 1,
    coerce   => sub {
        return topdl( $_[0] )->byte;
    },
);

has nvalid => (

    is        => 'lazy',
    init_args => undef,
    clearer   => 'clear_nvalid',
);

# PDL requires subclasses to have a PDL attribute, but it shouldn't be
# generally accessible outside of this class
protected_has PDL => ( is => 'rwp' );

protected_has subscribers => (
    is      => 'ro',
    default => sub { {} },
);

sub BUILDARGS {

    my $class = shift;

    # if only one argument and it's not a hash ref, treat as the base argument
    unshift @_, 'base'
      if @_ == 1 && !is_plain_hashref( $_[0] );

    unshift @_, $class;

    return &Moo::Object::BUILDARGS;
}

sub BUILD {
    my $self = shift;
    $self->_set_PDL( $self->base );
}

sub subscribe {

    my $self = shift;

    state $tmpl = {
        apply_mask => {
            defined => 0,
            allow   => sub { is_coderef( $_[0] ) },
        },
        data_mask => {
            defined => 0,
            allow   => sub { is_coderef( $_[0] ) },
        },

        token => {
            default => undef,
          }
    };

    my $opts = check( $tmpl, {@_} )
      or die Params::Check::last_error();

    croak( "must specify one or more of <apply_mask> or <data_mask>\n" )
      unless defined $opts->{apply_mask} || defined $opts->{data_mask};

    my $token = delete $opts->{token};
    croak( "passed invalid token" )
      if defined $token && !exists $self->subscribers->{$token};

    $token //= Data::GUID->new->as_binary;
    $self->subscribers->{$token} = $opts;

    $self->update;

    return $token;
}

sub is_subscriber {

    my $self  = shift;
    my $token = shift;

    return defined $token && exists $self->subscribers->{$token};
}

sub unsubscribe {

    my $self  = shift;
    my $token = shift;

    croak( "passed invalid token" )
      unless $self->is_subscriber( $token );

    my $cb = delete $self->subscribers->{$token};

    $cb->{apply_mask}->()
      if $cb->{apply_mask};

    $self->update if $cb->{data_mask};

    return;
}



sub update {

    my $self = shift;

    my $mask;

    # first collect masks from subscribers
    foreach my $sub ( values %{ $self->subscribers } ) {

        $self->clear_nvalid;

        next unless defined $sub->{data_mask};

        $mask //= $self->{base}->copy;
        $mask &= $sub->{data_mask}->();
    }

    # In case there were no data masks, use original

    $mask //= $self->base;

    $mask = $self->base
      unless defined $mask;

    $self->_set_PDL( $mask );

    # now push new mask
    $_->{apply_mask}->( $self->PDL )
      foreach
	grep { defined $_->{apply_mask} }
	  values %{ $self->subscribers };

    return;
}

sub set {

    my $self = shift;

    my $mask = $self->PDL;
    $self->_set_PDL( $self->base );
    $self->SUPER::set( @_ );
    $self->_set_PDL( $mask );
    $self->clear_nvalid;
    $self->update;
    return;

}

sub mask {

    my $self = shift;

    if ( @_ ) {
        $self->{base} .= PDL->topdl( $_[0] );
        $self->clear_nvalid;
        $self->update;
    }

    return $self->PDL;

}

sub _build_nvalid {

    my $self = shift;

    return ( $self->mask != 0 )->sum;

}

sub copy { return $_[0]->mask->copy }


1;


__END__

=head1 NAME

PDLx::Mask - Mask multiple piddles with automatic two way feedback


=head1 SYNOPSIS

  use 5.10.0;
  use PDLx::Mask;
  use PDLx::MaskedData;

  $pdl = sequence( 9 );

  $mask = PDLx::Mask->new( $pdl->ones );
  say $mask;    # [1 1 1 1 1 1 1 1 1]

  $data1 = PDLx::MaskedData->new( $pdl, $mask );
  say $data1;    # [0 1 2 3 4 5 6 7 8]

  $data2 = PDLx::MaskedData->new( $pdl + 1, $mask );
  say $data2;    # [1 2 3 4 5 6 7 8 9]

  # update the mask
  $mask->set( 3, 0 );
  say $mask;     # [1 1 1 0 1 1 1 1 1]

  # and see it propagate
  say $data1;    # [0 1 2 0 4 5 6 7 8]
  say $data2;    # [1 2 3 0 5 6 7 8 9]

  # use bad values for $data1
  $data1->badflag(1);
  # notice that the invalid element is now bad
  say $data1;    # [0 1 2 BAD 4 5 6 7 8]

  # push invalid values upstream to the shared mask
  $data1->upstream_mask(1);
  $data1->setbadat(0);
  say $data1;    # [BAD 1 2 BAD 4 5 6 7 8]

  # see the mask change
  say $mask;     # [0 1 1 0 1 1 1 1 1]

  # and see the other piddle change
  say $data2;    # [0 2 3 0 5 6 7 8 9]


=head1 DESCRIPTION

Typically L<PDL> uses L<bad values|PDL::Bad> to mark elements in a piddle which
contain invalid data.  When multiple piddles should have the same elements
marked as invalid, a separate I<mask> piddle (whose values are true for valid data
and false otherwise) is often used.

B<PDLx::Mask> in concert with L<PDLx::MaskedData> simplifies the management of
mutiple piddles sharing the same mask.  B<PDLx::Mask> is the shared mask,
and B<PDLx::MaskedData> is a specialized piddle which will dynamically respond
to changes in the mask, so that they are always up-to-date.

Additionally, invalid elements in the data piddles may automatically
be added to the shared mask, so that there is a consistent view of
valid elements across all piddles.

=head2 Details

B<PDLx::Mask> is a subclass of B<PDL> which manages a mask across on
or more piddles.  It can be used directly as a piddle, but be careful
not to change its contents inadvertently. I<It should only be
manipulated via the provided methods or overloaded operators.>

It maintains two views of the mask:

=over

=item 1

the original I<base> mask; and

=item 2

the I<effective> mask, which is the base mask combined with additional
invalid elements from the data piddles.

=back

The L<< B<subscribe>|/subscribe >> method is used to register callbacks to be invoked
when the mask has been changed. Multiple subscriptions are allowed; each
can register two callbacks:

=over

=item *

A subroutine invoked when the mask has changed.  It is passed a piddle
containing the mask.  It should not alter it.

=item *

A subroutine which will return a data mask.  If the data mask changes,
the mask's L<< B<update>|/update >> method I<must> be called.

=back


=head1 INTERFACE

=head2 Methods specific to B<PDLx::Mask>

=head3 new

  $mask = PDLx::Mask->new( $base_mask );
  # or
  $mask = PDLx::Mask->new( base => $base_mask );

Create a mask using the passed mask as the base mask.  It does not
copy the passed piddle.

=head3 base

  $base = $mask->base;

This returns the I<base> mask.
B<Don't alter the returned piddle!>

=head3 mask

  $pdl = $mask->mask;
  $pdl = $mask->mask( $new_mask );

Return the I<effective> mask as a plain piddle.
B<Don't alter the returned piddle!>

If passed a piddle, it is copied to the I<base> mask and the
L<< B<update>|/update >> method is called.

Note that the C<$mask> object can also be used directly without
calling this method.

=head3 nvalid

  $nvalid_elements = $mask->nvalid;

The number of valid elements in the I<effective> mask.  This is lazily evaluated
and cached.

=head3 subscribe

  $token = $mask->subscribe( apply_mask => $code_ref, %options );

Register the passed subroutines to be called when the I<effective>
mask is changed.  The returned token may be used to unsubscribe the
callbacks using L<< B<unsubscribe>|/unsubscribe >>.

The following options are available:

=over

=item C<apply_mask> => I<code reference>

This subroutine should expect a single argument (a mask piddle) and
apply it.  It should I<not> alter the mask piddle.  It is optional.

This callback will be invoked I<no> arguments if the mask has
been directed to unsubscribe the callbacks. See L</unsubscribe>

=item C<data_mask> => I<code reference>

This subroutine should return a piddle which encodes the intrinsic
valid elements of the object's data.  It is optional.

The mask object does not monitor this piddle for changes.  If the data
mask changes, the mask's L<< B<update>|/update >> method I<must> be
called.

=item token => I<scalar>

Instead of creating a new subscription, update the entry with the
given token, which was returned by a previous invocation of
L<< B<subscribe>|/subscribe >>.

=back

=head3 is_subscriber

  $bool = $mask->is_subscriber( $token );

Returns true if the passed token refers to an active subscriber.

=head3 unsubscribe

  $mask->unsubscribe( $token );

Unsubscribe the callbacks with the given token (returned by L<<
B<subscribe>|/subscribe >>).

If the callbacks for C<$token> include the C<apply_mask> callback, it
will be invoked with no arguments, indicating that it is being
unsubscribed. At that time C<< $mask->is_subscriber($token) >> will
return I<false>.

=head3 update

  $mask->update;

This performs the following:

=over

=item 1

subscribers with L<< C<data_mask>|/data_mask >> callbacks are queried for their masks;

=item 2

the I<effective> mask is constructed from the I<base> mask and the data masks; and

=item 3

subscribers' L<< C<apply_mask>|/apply_mask >> callbacks are invoked
with the I<effective> mask.

=back


=head2 Overridden methods

=head3 C<copy>

Returns a copy of the I<effective> mask as an ordinary piddle.

=head3 C<inplace>

This is a fatal operation.

=head3 C<set_inplace()>

This is a fatal operation if the passed value is non-zero.

=head3 set

   $mask->set( $pos, $value);

This updates the I<base> mask at position C<$pos> to C<$value> and
calls the L<< B<update>|/update >> method.

=head2 Overloaded Operators

Use of assignment operators (but I<not> the underlying B<PDL> methods or subroutines) other than the following
I<should> be fatal.

=head3 C<|=> C<&=> C<^=> C<.=>

These operators may be used to update the I<base> mask.  The
I<effective> mask will automatically be updated.

=head1 EXAMPLES

=head2 Secondary Masks

Sometimes the primary mask should incorporate a secondary mask that's
not associated with a data set. Here's how to do that:

  $pmask = PDLx::Mask->new( pdl( byte, 1, 1, 1 ) );
  $smask = PDLx::MaskedData->new( base => pdl( byte, 0, 1, 0 ),
                                  mask => $pmask,
                                  apply_mask => 0,
                                  data_mask => 1
                                );

The key difference between this and an ordinary dependency on a data
mask, is that by turning off C<apply_mask>, changes in the primary
mask won't be replicated in the secondary.

  say $smask;       # [ 0 1 0 ]
  say $pmask->base; # [ 1 1 1 ]
  say $pmask;       # [ 0 1 0 ]

  $smask->set( 0, 1 );
  say $smask;       #  [ 1 1 0 ]
  say $pmask->base; #  [ 1 1 1 ]
  say $pmask;       #  [ 1 1 0 ]

  $pmask->set( 0, 0 );
  say $smask;       #  [ 1 1 0 ]
  say $pmask->base; #  [ 0 1 1 ]
  say $pmask;       #  [ 0 1 0 ]

=head2 Intermittant Secondary Masks

Building upon the previous example, let's say the secondary mask is
used intermittently.  For example

  $pmask = PDLx::Mask->new( [ 1, 1, 1 ] );

  $smask = PDLx::MaskedData->new( base => [ 0, 1, 0 ],
                                  mask => $pmask,
                                  apply_mask => 0,
                                  data_mask => 1
                                );

  $data = PDLx::MaskedData->new( [ 33, 22, 44 ], $pmask );

  say $data         #  [ 0, 22, 0 ]

  # now want to ignore secondary mask
  $smask->unsubscribe;

  say $data         #  [ 33, 22, 44 ]

  # and now stop ignoring it
  $smask->subscribe;
  say $data         #  [ 0, 22, 0 ]


=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-pdlx-mask@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=PDLx-Mask>.

=head1 VERSION

Version 0.01

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2016 The Smithsonian Astrophysical Observatory

PDLx::Mask is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 AUTHOR

Diab Jerius  E<lt>djerius@cpan.orgE<gt>

=cut

=begin fakeout_pod_coverage

=head3 BUILD

=head3 BUILDARGS

=head3 PDL

=head3 subscribers

=end fakeout_pod_coverage


