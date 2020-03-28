##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Customer/TaxInfo.pm
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
package Net::API::Stripe::Customer::TaxInfo;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub tax_id { shift->_set_get_scalar( 'tax_id', @_ ); }

sub type { shift->_set_get_scalar( 'type', @_ ); }

1;

__END__


=encoding utf8

=head1 NAME

Net::API::Stripe::Customer::TaxInfo - A Stripe Customer Tax Info (deprecated)

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

The customer’s tax information. Appears on invoices emailed to this customer. This parameter has been deprecated and will be removed in a future API version, for further information view the migration guide (L<https://stripe.com/docs/billing/migration/taxes#moving-from-taxinfo-to-customer-tax-ids>).

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

=item B<tax_id> required

The customer’s tax ID number.

=item B<type> required

The type of ID number. The only possible value is vat

=back

=head1 API SAMPLE

	{
	  "id": "cus_G4gOz1jqVe40Bg",
	  "object": "customer",
	  "address": null,
	  "balance": 0,
	  "created": 1572264551,
	  "currency": "jpy",
	  "default_source": null,
	  "delinquent": false,
	  "description": "Customer for jenny.rosen@example.com",
	  "discount": null,
	  "email": null,
	  "invoice_prefix": "BC0DE60",
	  "invoice_settings": {
		"custom_fields": null,
		"default_payment_method": null,
		"footer": null
	  },
	  "livemode": false,
	  "metadata": {},
	  "name": null,
	  "phone": null,
	  "preferred_locales": [],
	  "shipping": null,
	  "sources": {
		"object": "list",
		"data": [],
		"has_more": false,
		"url": "/v1/customers/cus_G4gOz1jqVe40Bg/sources"
	  },
	  "subscriptions": {
		"object": "list",
		"data": [],
		"has_more": false,
		"url": "/v1/customers/cus_G4gOz1jqVe40Bg/subscriptions"
	  },
	  "tax_exempt": "none",
	  "tax_ids": {
		"object": "list",
		"data": [],
		"has_more": false,
		"url": "/v1/customers/cus_G4gOz1jqVe40Bg/tax_ids"
	  },
	  "tax_info": null,
	  "tax_info_verification": null
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/customers/create>, L<>https://stripe.com/docs/billing/migration/taxes#moving-from-taxinfo-to-customer-tax-ids

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
