##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Order/SKU/PackageDimensions.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Order::SKU::PackageDimensions;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Product::PackageDimension );
    our( $VERSION ) = 'v0.100.0';
};

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Order::SKU::PackageDimensions - A Stripe SKU Package Dimensions Object

=head1 SYNOPSIS

    # In inches
    my $pkg = $stripe->sku->package_dimensions({
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

    v0.100.0

=head1 DESCRIPTION

This module inherits completely from L<Net::API::Stripe::Product::PackageDimension>.

=head1 API SAMPLE

	{
	  "id": "sku_fake123456789",
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
	  "product": "prod_fake123456789",
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

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut

