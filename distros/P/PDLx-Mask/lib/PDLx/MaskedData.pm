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

package PDLx::MaskedData;

use strict;
use warnings;
use Carp;

use 5.10.0;

our $VERSION = '0.03';

use Params::Check qw[ check ];
use Ref::Util ':all';
use Scalar::Util qw[ refaddr ];
use Safe::Isa;
use Try::Tiny;

use PDL::Core ':Internal';
use Package::Stash;

use overload;

use Moo;
use MooX::ProtectedAttributes;
use namespace::clean 0.16;

extends 'PDLx::DetachedObject';

with 'PDLx::Role::RestrictedPDL';

sub _trigger_mask_subscription;

use overload
  map {
    my $mth = overload::Method( 'PDL', $_ );
    $_ => sub {
        # operator should work on base, not effective, value
        my $data = $_[0]->{PDL};
        $_[0]->{PDL} = $_[0]->base;
        my $r = &$mth;
        $_[0]->{PDL} = $data;
        $_[0]->_clear_summary;
        $_[0]->update;
        $_[0];
      }
  } (
    map {
        grep { $_ =~ /=$/ }
          split( ' ', $_ )
    } @{overload::ops}{ 'assign', 'binary' }
  ),
  ( map { split( ' ', $_ ) } $overload::ops{mutators} );

has base => (
    is       => 'ro',
    required => 1,
    coerce   => sub {
        return topdl( $_[0] );
    },
);

has mask => (
    is     => 'rw',
    lazy   => 1,
    coerce => sub {
        return $_[0] if $_[0]->$_isa( 'PDLx::Mask' );
        require PDLx::Mask;
        PDLx::Mask->new( $_[0] );
    },
    default => sub {

        my $self = shift;

        $self->mask(
              $self->data_mask
            ? $self->_data_mask
            : PDL->ones( PDL::byte, $self->shape ) );

        return $self->mask;
    },
    predicate => 1,
    clearer   => 1,
    trigger   => \&_trigger_mask_subscription,
);

has mask_value => (
    is      => 'rw',
    default => 0,
);

has data_mask => (
    is      => 'rw',
    default => 0,
    trigger => \&_trigger_mask_subscription,
);

has apply_mask => (
    is      => 'rw',
    default => 1,
    trigger => 1,
);

has dsum => (
    is        => 'lazy',
    init_args => undef,
    clearer   => 'clear_dsum',
);

has _pre_build => (
    is        => 'rwp',
    init_args => undef,
    default   => 1,
);

has _token => (
    is        => 'rwp',
    init_args => undef,
    predicate => 1,
    clearer   => 1,
);

# PDL requires subclasses to have a PDL attribute, but it shouldn't be
# generally accessible outside of this class
protected_has PDL => ( is => 'rwp' );

sub BUILDARGS {

    my $class = shift;

    my @args;

    # allow
    #    MaskedData->new( $data, $mask )
    #    MaskedData->new( data => $data, mask => $mask )
    #    MaskedData->new( { data => $data, mask => $mask } )

    if ( @_ == 1 && !is_hashref( $_[0] ) ) {

        unshift @_, 'base';
    }

    if ( @_ == 2 ) {

        if ( ref $_[0] && ref $_[1] ) {

            @_ = ( base => $_[0], mask => $_[1] );
        }

    }
    unshift @_, $class;

    return &Moo::Object::BUILDARGS;
}

sub BUILD {

    my $self = shift;

    $self->_set__pre_build( 0 );

    $self->_reset_effective_data_storage;
    $self->subscribe;

}

sub DEMOLISH {

    my ( $self, $in_global_destruction ) = @_;

    return if $in_global_destruction;

    $self->mask->unsubscribe( $self->_token )
      if $self->_has_token;
}

sub _trigger_apply_mask {

    my $self = shift;

    # don't trigger in the constructor
    return if $self->_pre_build;

    $self->subscribe;

}

sub _trigger_mask_subscription {

    my $self = shift;

    # don't trigger in the constructor
    return if $self->_pre_build;

    $self->subscribe;

    return;
}


sub _has_shared_data_storage {

    return refaddr( $_[0]->base ) == refaddr( $_[0]->PDL );

}


sub _reset_effective_data_storage {

    my ( $self, $is_subscribed ) = @_;

    $is_subscribed //= $self->is_subscribed;

    # don't trigger in the constructor
    return if $self->_pre_build;

    # if apply_mask is 1, $self->PDL must be set to a copy
    # of $self->base, but only if not already done.

    if ( $self->apply_mask && $is_subscribed ) {

        $self->_set_PDL( $self->base->copy )
          if $self->_has_shared_data_storage;
    }

    # otherwise, save some space.
    else {

        $self->_set_PDL( $self->base );
    }

    return;
}

sub is_subscribed {

    return $_[0]->has_mask && $_[0]->_has_token;

}

sub _reset_subscription_status {

    $_[0]->_clear_token;

}

sub _reset_subscription_state {

    my $self = shift;
    my $reset_data_storage = shift // 1;

    $self->_reset_subscription_status;

    $self->_reset_effective_data_storage
      if $reset_data_storage;

    $self->update;

    return;
}


sub subscribe {

    my $self = shift;

    return unless $self->has_mask;

    # override is_subscribed to ensure $self->PDL is a copy of
    # $self->base
    $self->_reset_effective_data_storage( 1 );

    my $token = $self->mask->subscribe( (
            $self->apply_mask
            ? (
                apply_mask => sub {

                    return unless $self->is_subscribed;

                    # if $mask is undef, we're being asked to unsubscribe
                    if ( @_ == 0 || !defined $_[0] ) {

                        # if mask has already unsubscribed us; don't
                        # ask it to do it twice
                        if ( $self->mask->is_subscriber( $self->_token ) ) {
                            $self->unsubscribe;
                        }

                        # mask doesn't know about us. just clean up locally
                        else {
                            $self->_reset_subscription_state;
                        }
                    }
                    else {
                        $self->_apply_mask( @_ );
                    }

                    return;
                },
              )
            : (),
        ),
        (
            $self->data_mask ? ( data_mask => sub { $self->_data_mask } )
            : ()
        ),
        ( $self->_has_token ? ( token => $self->_token ) : () ),
    );

    $self->_set__token( $token );

    $self->update;

    return;
}

sub unsubscribe {

    my $self = shift;

    return unless $self->is_subscribed;

    state $tmpl
      = {
        reset_data_storage => { default => 1, strict_type => 1, defined => 1 }
      };

    my $opts = check( $tmpl, {@_} )
      or die Params::Check::last_error();

    # make sure $self doesn't think it's subscribed, in case
    # $self->mask sends *us* an unsubscribe command via apply_mask
    # when we call mask->unsuscribe method
    my $token = $self->_token;
    $self->_reset_subscription_status;

    $self->mask->unsubscribe( $token );

    # now perform a reset of all subscription related state
    $self->_reset_subscription_state( $opts->{reset_data_storage} );

    return;
}

sub _apply_mask {

    my $self = shift;
    my $mask = shift;

    # reset effective piddle
    ( my $data = $self->PDL ) .= $self->base;

    if ( $self->base->badflag ) {
        # for now, must do this, as setbadif can't be done inplace,
        # and copybad requires the mask to have badvalues, which we don't
        $self->_set_PDL( $data->setbadif( !$mask ) );
    }

    else {
        $data->where( !$mask ) .= $self->mask_value;
    }

    return;
}

sub _data_mask {

    my $self = shift;

    return $self->base->badflag
      ? $self->base->isgood
      : ( $self->base != $self->mask_value )->byte;

}

sub update {

    my $self = shift;

    # a mask is involved
    if ( $self->is_subscribed ) {

        if ( $self->data_mask ) {

            # this will automatically apply the mask if required
            $self->mask->update;
        }

        elsif ( $self->apply_mask ) {

            $self->_apply_mask( $self->mask );
        }

    }

    # no mask, but PDL & base don't share storage

    elsif ( !$self->_has_shared_data_storage ) {

        $self->{PDL} .= $self->base;
    }

    return;
}


sub data {

    my $self = shift;

    if ( @_ ) {
        $self->{base} .= PDL->topdl( $_[0] );
        $self->clear_dsum;
        $self->update;
    }

    return $self->PDL;
}

sub nvalid { $_[0]->mask->nvalid }

sub _build_dsum {

    my $self = shift;

    return $self->data->dsum;
}

sub _clear_summary {

    $_[0]->clear_dsum;

}

before 'mask' => sub {

    my $self = shift;

    $self->unsubscribe( reset_data_storage => 0 )
      if @_;
};

# override methods

sub copy { return $_[0]->data->copy }

sub _override {

    my ( $mth ) = shift;

    my $code = sprintf(
        q[
sub {
    my $self = shift;
    my $data = $self->PDL;
    $self->_set_PDL( $self->base );
    my $result = $self->SUPER::%s( @_ );
    $self->_set_PDL( $data );

    $self->clear_dsum;
    $self->update;

}
], $mth
    );

    ## no critic (ProhibitStringyEval)
    return eval $code;
}

my $stash = Package::Stash->new( __PACKAGE__ );

$stash->add_symbol( '&' . $_, _override( $_ ) ) foreach qw[
  set
  badflag
  setbadat
];

1;


__END__

=head1 NAME

PDLx::MaskedData - Automatically synchronize data and valid data masks

=head1 SYNOPSIS

  use 5.10.0;

  use PDLx::MaskedData;

  $data1 = PDLx::MaskedData->new( sequence(9) );
  say $data1;    # [0 1 2 3 4 5 6 7 8]

  # grab the mask
  $mask = $data1->mask;
  say $mask;    # [1 1 1 1 1 1 1 1 1]


  # create another masked piddle with the same mask
  my $pdl = $data1 + 1;

  $data2 = PDLx::MaskedData->new( $pdl, $mask );

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
  $data1->data_mask(1);
  $data1->setbadat(0);
  say $data1;    # [BAD 1 2 BAD 4 5 6 7 8]

  # see the mask change
  say $mask;     # [0 1 1 0 1 1 1 1 1]

  # and see the other piddle change
  say $data2;    # [0 2 3 0 5 6 7 8 9]

=head1 DESCRIPTION

Typically L<PDL> uses L<bad values|PDL::Bad> to mark elements in a
piddle which contain invalid data.  When multiple piddles should have
the same elements marked as invalid, a separate I<mask> piddle (whose
values are true for valid data and false otherwise) is often used.

B<PDLx::MaskedData> (in concert with L<PDLx::Mask>) simplifies the
management of mutiple piddles sharing the same mask.  B<PDLx::Mask> is
the shared mask, and B<PDLx::MaskedData> is a specialized piddle which
will dynamically respond to changes in the mask, so that they are
always up-to-date.

Additionally, invalid elements in a data piddle may automatically be
added to the shared mask, so that there is a consistent view of valid
elements across all data piddles.

=head2 Details

B<PDLx::MaskedData> is a subclass of B<PDL> which manages a masked
piddle.  It can be used directly as a piddle, but be careful not to
change its contents inadvertently. I<It should only be manipulated via
the provided methods or overloaded operators.>

It maintains two views of the data:

=over

=item 1

the original I<base> data; and

=item 2

the I<effective> data, which is the base data with an applied mask. The
invalid data elements may either be set as L<bad values|PDL::Bad>, or may
be set to any other value (e.g. 0).

=back

=head1 INTERFACE

=head2 Methods specific to B<PDLx::MaskedData>

=head3 new

  $data = PDLx::MaskedData->new( $base_data );
  $data = PDLx::MaskedData->new( $base_data, $mask );
  $data = PDLx::MaskedData->new( base => $base_data, %options );

Create a masked piddle using the passed data piddle as the base data.
It does not copy the passed piddle.

An optional mask may be provided (see below for details). If not
provided, one will be created.  The newly created object will be
subscribed to the mask object;

=over

=item C<base>

A data piddle.  If the piddle has the L<bad data
flag|PDL::Bad/badflag> set, masked elements are set to the piddle's
bad value. Otherwise masked elements are set to the value of the
L<< C<mask_value>|/mask_value >> option.

=item C<mask> => I<scalar> | I<piddle> | I<< B<PDLx::Mask> object >>

An optional initial mask.  If it is a piddle, it will be used as a
base mask for a new B<PDLx::Mask> object; it will not be copied.  If
not specified, all data elements are valid.

=item C<mask_value> => I<scalar>

If the piddle's bad flag is not set, this specifies the value of
invalid elements in the I<effective> data.  It defaults to C<0>.

=item C<apply_mask> => I<boolean>

If true, the mask is applied to the data.  This defaults to true.
See L<PDlx::Mask/EXAMPLES/Secondary Masks> for an application.

=item C<data_mask> => I<boolean>

If true, any invalid elements in the I<base> data are replicated
in the mask.  It defaults to false.

=back

=head3 base

  $base = $data->base;

This returns the I<base> data.
B<Don't alter the returned piddle!>

=head3 data

  $pdl = $data->data;
  $pdl = $data->data( $new_data );


Return the I<effective> data, optionally altering the I<base> data.
B<Don't alter the returned piddle!>

If passed a piddle, it is copied to the I<base> data and the
L<< B<update>|/update >> method is called.

Note that the C<$data> object can also be used directly without
calling this method.

=head3 mask

  $mask = $data->mask;

This returns the mask as a B<PDLx::Mask> object.

  $data->mask( $new_mask );

This I<replaces> the mask, detaching C<$data> from the previous mask
object.  To instead I<alter> the mask object, use the mask object's
methods, e.g.:

  $data->mask->mask( $new_mask );


=head3 nvalid

  $nvalid_elements = $data->nvalid;

The number of valid elements in the I<effective> data.  This is lazily evaluated
and cached.

=head3 update

  $data->update;

Update the I<effective> data. This should never be required by user code.

If C<< $data->data_mask >> is true, C<< $data->mask->update >> is called,
otherwise the result of applying the mask to the I<base> data is
stored as the I<effective> data.

=head3 subscribe

  $data->subscribe;

Subscribe to C<$data>'s mask.  Usually this is not necessary; see
L<PDLx-Mask/EXAMPLES/Intermittant Secondary Masks> for why this might be useful.

=head3 unsubscribe

  $data->unsubscribe( %options );

Subscribe to C<$data>'s mask.  Usually this is not necessary; see
L<PDLx-Mask/EXAMPLES/Intermittant Secondary Masks> for why this might be useful.

Options:

=over

=item C<reset_data_storage> => I<boolean>

If true (the default), memory used to store the I<effective> data is
reclaimed if possible.  If C<$data> will be resubscribed to a mask,
it's more efficient to not perform this step.

=back

=head3 is_subscribed

  $bool = $data->is_subscribed;

Returns true if C<$data> is subscribed to its mask.

=head2 Overridden methods

=head3 copy

  $pdl = $data->copy;

Returns a copy of the I<effective> data as an ordinary piddle.

=head3 inplace

This is a fatal operation.

=head3 set_inplace

This is a fatal operation if the passed value is non-zero.

=head3 set

   $data->set( $pos, $value);

This updates the I<base> data at position C<$pos> to C<$value> and
invokes the L<< B<update>|/update >> method.

=head3 set

   $data->setbadat( $pos );

This sets the I<base> data at position C<$pos> to the bad value and
invokes the L<< B<update>|/update >> method.

=head3 dsum

  $data->dsum;

This is a lazily evaluated and cached version of the L<< B<PDL>
dsum|PDL::Ufunc/dsum >> method.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-pdlx-mask@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=PDLx-Mask>.

=head1 SEE ALSO

=head1 VERSION

Version 0.01

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2016 The Smithsonian Astrophysical Observatory

PDLx::MaskedData is free software: you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

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

=head3 DEMOLISH

=head3 PDL

=head3 has_mask

=end fakeout_pod_coverage
