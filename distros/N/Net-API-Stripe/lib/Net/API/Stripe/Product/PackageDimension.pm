##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Product/PackageDimension.pm
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
package Net::API::Stripe::Product::PackageDimension;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub height { shift->_set_get_scalar( 'height', @_ ); }

sub length { shift->_set_get_scalar( 'length', @_ ); }

sub weight { shift->_set_get_scalar( 'weight', @_ ); }

sub width { shift->_set_get_scalar( 'width', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Product::PackageDimension - A Stripe Product Package Dimension Object

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

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
	  "id": "prod_Dwk1FH8ifmrGgw",
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
	  "name": "Angels, Inc investor yearly membership",
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

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
