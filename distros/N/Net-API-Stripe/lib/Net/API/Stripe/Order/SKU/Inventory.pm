##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Order/SKU/Inventory.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Order::SKU::Inventory;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.100.0';
};

use strict;
use warnings;

sub quantity { return( shift->_set_get_scalar( 'quantity', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

sub value { return( shift->_set_get_scalar( 'value', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Order::SKU::Inventory - A Stripe SKU Inventory Object

=head1 SYNOPSIS

    my $inv = $stripe->sku->inventory({
        quantity => 2,
        type => 'infinite',
        value => undef,
    });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

Description of the SKU’s inventory.

This is instantiated by method B<inventory> in module L<Net::API::Stripe::Order::SKU>

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Order::SKU::Inventory> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 quantity positive integer or zero

The count of inventory available. Will be present if and only if type is finite.

=head2 type string

Inventory type. Possible values are finite, bucket (not quantified), and infinite.

=head2 value string

An indicator of the inventory available. Possible values are in_stock, limited, and out_of_stock. Will be present if and only if type is bucket.

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

