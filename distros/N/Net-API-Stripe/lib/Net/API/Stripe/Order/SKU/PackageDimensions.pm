##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Order/SKU/PackageDimensions.pm
## Version 0.1
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2019/11/02
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Order::SKU::PackageDimensions;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub height { shift->_set_get_number( 'height', @_ ); }

sub length { shift->_set_get_number( 'length', @_ ); }

sub weight { shift->_set_get_number( 'weight', @_ ); }

sub width { shift->_set_get_number( 'width', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Order::SKU::PackageDimensions - A Stripe SKU Package Dimensions Object

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

The dimensions of this SKU for shipping purposes.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new C<Net::API::Stripe> objects.
It may also take an hash like arguments, that also are method of the same name.

=over 8

=item I<verbose>

Toggles verbose mode on/off

=item I<debug>

Toggles debug mode on/off

=back

=head1 METHODS

=over 4

=item B<height> decimal

Height, in inches.

=item B<length> decimal

Length, in inches.

=item B<weight> decimal

Weight, in ounces.

=item B<width> decimal

Width, in inches.

=back

=head1 API SAMPLE

	{
	  "id": "sku_G1HcdqsCPOkGA7",
	  "object": "sku",
	  "active": true,
	  "attributes": {
		"size": "Medium",
		"gender": "Unisex"
	  },
	  "created": 1571480453,
	  "currency": "jpy",
	  "image": null,
	  "inventory": {
		"quantity": 50,
		"type": "finite",
		"value": null
	  },
	  "livemode": false,
	  "metadata": {},
	  "package_dimensions": null,
	  "price": 1500,
	  "product": "prod_Dwk1FH8ifmrGgw",
	  "updated": 1571480453
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut

