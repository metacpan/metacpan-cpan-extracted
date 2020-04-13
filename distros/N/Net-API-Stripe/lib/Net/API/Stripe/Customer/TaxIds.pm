##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Customer/TaxIds.pm
## Version 0.1
## Copyright(c) 2019-2020 DEGUEST Pte. Ltd.
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

This module inherits completely from L<Net::API::Stripe::List> and may be removed in the future.

You can add one or multiple tax IDs to a customer. A customer's tax IDs are displayed on invoices and credit notes issued for the customer.

=head1 API SAMPLE

	{
	  "id": "cus_fake123456789",
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
		"url": "/v1/customers/cus_fake123456789/sources"
	  },
	  "subscriptions": {
		"object": "list",
		"data": [],
		"has_more": false,
		"url": "/v1/customers/cus_fake123456789/subscriptions"
	  },
	  "tax_exempt": "none",
	  "tax_ids": {
		"object": "list",
		"data": [],
		"has_more": false,
		"url": "/v1/customers/cus_fake123456789/tax_ids"
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

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
