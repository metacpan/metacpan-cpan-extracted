##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Product/PackageDimension.pm
## Version v0.100.1
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/11/02
## Modified 2020/05/16
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Product::PackageDimension;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    use Module::Generic;
    our( $VERSION ) = 'v0.100.1';
};

sub init
{
	my $self = shift( @_ );
	## Default to using the imperial measurement, ie default measurement system in the U.S.
	## User needs to activate the metric system
	$self->{use_metric} = 0;
	$self->SUPER::init( @_ );
	return( $self );
}

sub height { shift->_set_get_convert_number( 'height', @_ ); }

sub length { shift->_set_get_convert_weight( 'length', @_ ); }

sub use_metric
{
    my $self = shift( @_ );
    if( @_ )
    {
    	## Check provided and convert data on the fly
    	my $val = shift( @_ );
    	$self->{use_metric} = $val;
    	## Convert all data to metric, so it can be converted back after into inch and ounces when used for Stripe api calls
		foreach my $k ( qw( height length width ) )
		{
			next if( !length( $self->{ $k } ) );
			my $v = $self->_set_get_convert_size( $k, $self->{ $k } );
			$self->{ $k } = $v;
		}
		if( length( $self->{weight} ) )
		{
			my $v = $self->_set_get_convert_weight( 'weight', $self->{weight} );
			$self->{weight} = $v;
		}
    }
    return( $self->{use_metric} );
}

sub weight { shift->_set_get_number( 'weight', @_ ); }

sub width { shift->_set_get_convert_size( 'width', @_ ); }

sub _set_get_convert_size
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    if( @_ )
    {
		my $num = shift( @_ );
		return( $self->_set_get_number( $field, $num ) ) if( !$self->{use_metric} );
		## Helper method from Net::API::Stripe::Generic
		## If metric option is on, convert the metric value into inch to be compliant with Stripe
		my $new = $self->_convert_measure({ from => 'cm', value => "$num" });
		return( $self->_set_get_number( $field, $new ) );
    }
    ## No argument, just retrieving the value
    else
    {
    	my $val = $self->{ $field };
    	return( $val ) if( !$self->{use_metric} );
    	my $new = $self->_convert_measure({ from => 'inch', value => "$val" });
    	return( Module::Generic::Number->new( $new ) );
    }
}

sub _set_get_convert_weight
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    if( @_ )
    {
		my $num = shift( @_ );
		return( $self->_set_get_number( $field, $num ) ) if( !$self->{use_metric} );
		## Helper method from Net::API::Stripe::Generic
		## If metric option is on, convert the metric value into inch to be compliant with Stripe
		my $new = $self->_convert_measure({ from => 'gram', value => "$num" });
		return( $self->_set_get_number( $field, $new ) );
    }
    ## No argument, just retrieving the value
    else
    {
    	my $val = $self->{ $field };
    	return( $val ) if( !$self->{use_metric} );
    	my $new = $self->_convert_measure({ from => 'gram', value => "$val" });
    	return( Module::Generic::Number->new( $new ) );
    }
}

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Product::PackageDimension - A Stripe Product Package Dimension Object

=head1 SYNOPSIS

    # In inches
    my $pkg = $stripe->product->package_dimensions({
        height => 6,
        length => 20,
        # Ounce
        weight => 21
        width => 12
    });
    
    # Then, because we are in EU
    $pkg->use_metric( 1 );
    my $width = $pkg->width;
    # returns in centimetres: 30.48

=head1 VERSION

    v0.100.1

=head1 DESCRIPTION

The dimensions of this SKU for shipping purposes.

This is instantiated by method B<package_dimensions> in module L<Net::API::Stripe::Product>

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Order::SKU::PackageDimensions> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<height> decimal

Height, in inches.

=item B<length> decimal

Length, in inches.

=item B<use_metric> Boolean

By providing a boolean value, you can change the value returned to you.

Stripe uses and requires, unfortunately, the use of C<inch> and C<ounce> although the vast majority of the word uses the metric system. So this feature makes it possible to get the proper value while still sending Stripe the values in the proper measurement system.

If on, this will convert all values from inch to metric, or ounce to gram or vice versa.

Internally the values will always be in C<inch> and C<ounce>.

So, after having retrieved a L<Net::API::Stripe::Order::SKU> object from Stripe you could do something like this:

	my $sku = $stripe->skus( retrieve => $id ) || die( $stripe->error );
	$sku->package_dimensions->use_metric( 1 );
	# Width in centimetres
    my $width = $skup->package_dimensions->width;

=item B<weight> decimal

Weight, in ounces.

=item B<width> decimal

Width, in inches.

=back

=head1 API SAMPLE

	{
	  "id": "prod_fake123456789",
	  "object": "product",
	  "active": true,
	  "attributes": [],
	  "caption": null,
	  "created": 1541833574,
	  "deactivate_on": [],
	  "description": null,
	  "images": [],
	  "livemode": false,
	  "metadata": {},
	  "name": "Provider, Inc investor yearly membership",
	  "package_dimensions": null,
	  "shippable": null,
	  "statement_descriptor": null,
	  "type": "service",
	  "unit_label": null,
	  "updated": 1565089803,
	  "url": null
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/products/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
