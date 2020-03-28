##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Customer/TaxIds.pm
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
package Net::API::Stripe::Customer::TaxIds;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::List );
    our( $VERSION ) = '0.1';
};

# Inherite
# sub object { shift->_set_get_scalar( 'object', @_ ); }

## An array of Net::API::Stripe::Billing::Subscription
## sub data { shift->_set_get_object_array( 'data', 'Net::API::Stripe::Customer::TaxId', @_ ); }

# Inherite
# sub has_more { shift->_set_get_scalar( 'has_more', @_ ); }

# Inherite
# sub total_count { shift->_set_get_scalar( 'total_count', @_ ); }

# Inherite
# sub url { shift->_set_get_uri( 'url', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Customer::TaxIds - A Customer Tax IDs List Object

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

You can add one or multiple tax IDs to a customer. A customer's tax IDs are displayed on invoices and credit notes issued for the customer.

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

=item B<object> string, value is "list"

String representing the object’s type. Objects of the same type share the same value. Always has the value list.

=item B<data> array of hashes

=item B<has_more> boolean

True if this list has another page of items after this one that can be fetched.

=item B<url> string

The URL where this list can be accessed.

=back

=head1 API SAMPLE

	{
	  "id": "cus_Fzxuz7ZDVaAWy9",
	  "object": "customer",
	  "account_balance": 0,
	  "address": null,
	  "balance": 0,
	  "created": 1571176460,
	  "currency": "jpy",
	  "default_source": null,
	  "delinquent": false,
	  "description": null,
	  "discount": null,
	  "email": null,
	  "invoice_prefix": "0822CFA",
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
		"url": "/v1/customers/cus_Fzxuz7ZDVaAWy9/sources"
	  },
	  "subscriptions": {
		"object": "list",
		"data": [],
		"has_more": false,
		"url": "/v1/customers/cus_Fzxuz7ZDVaAWy9/subscriptions"
	  },
	  "tax_exempt": "none",
	  "tax_ids": {
		"object": "list",
		"data": [],
		"has_more": false,
		"url": "/v1/customers/cus_Fzxuz7ZDVaAWy9/tax_ids"
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

L<https://stripe.com/docs/api/customers>, L<https://stripe.com/docs/billing/taxes/tax-ids>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
