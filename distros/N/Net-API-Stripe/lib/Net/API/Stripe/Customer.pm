##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Customer.pm
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
package Net::API::Stripe::Customer;
## https://stripe.com/docs/api/customers/object
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub account_balance { return( shift->_set_get_number( 'account_balance', @_ ) ); }

# sub address { shift->_set_get_scalar( 'address', @_ ); }
sub address { return( shift->_set_get_object( 'address', 'Net::API::Stripe::Address', @_ ) ); }

sub balance { return( shift->_set_get_scalar( 'balance', @_ ) ); }

sub cards { return( shift->_set_get_object( 'cards', 'Net::API::Stripe::Customer::Sources', @_ ) ); }

## Used when creating a customer object
sub coupon { return( shift->_set_get_scalar( 'coupon', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub currency { return( shift->_set_get_scalar( 'currency', @_ ) ); }

sub default_card { return( shift->_set_get_scalar( 'default_card', @_ ) ); }

sub default_source { return( shift->_set_get_scalar_or_object( 'default_source', 'Net::API::Stripe::Payment::Source', @_ ) ); }

sub deleted { return( shift->_set_get_scalar( 'deleted', @_ ) ); }

sub delinquent { return( shift->_set_get_boolean( 'delinquent', @_ ) ); }

sub description { return( shift->_set_get_scalar( 'description', @_ ) ); }

sub discount { return( shift->_set_get_object( 'discount', 'Net::API::Stripe::Billing::Discount', @_ ) ); }

sub email { return( shift->_set_get_scalar( 'email', @_ ) ); }

sub invoice_prefix { return( shift->_set_get_scalar( 'invoice_prefix', @_ ) ); }

# sub invoice_settings  { return( shift->_set_get_hash( 'invoice_settings', @_ ) ); }
sub invoice_settings { return( shift->_set_get_object( 'invoice_settings', 'Net::API::Stripe::Billing::Invoice::Settings', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub name { return( shift->_set_get_scalar( 'name', @_ ) ); }

sub next_invoice_sequence { return( shift->_set_get_scalar( 'next_invoice_sequence', @_ ) ); }

sub payment_method { return( shift->_set_get_scalar( 'payment_method', @_ ) ); }

sub phone { return( shift->_set_get_scalar( 'phone', @_ ) ); }

sub preferred_locales { return( shift->_set_get_array( 'preferred_locales', @_ ) ); }

sub shipping { return( shift->_set_get_object( 'shipping', 'Net::API::Stripe::Shipping', @_ ) ); }

sub source { return( shift->_set_get_scalar( 'source', @_ ) ); }

sub sources { return( shift->_set_get_object( 'sources', 'Net::API::Stripe::List', @_ ) ); }

sub subscriptions { return( shift->_set_get_object( 'subscriptions', 'Net::API::Stripe::List', @_ ) ); }

sub tax_exempt { return( shift->_set_get_scalar( 'tax_exempt', @_ ) ); }

sub tax_id_data { return( shift->_set_get_object_array( 'tax_id_data', 'Net::API::Stripe::Customer::TaxId', @_ ) ); }

sub tax_ids { return( shift->_set_get_object( 'tax_ids', 'Net::API::Stripe::Customer::TaxIds', @_ ) ); }

sub tax_info { return( shift->_set_get_object( 'tax_info', 'Net::API::Stripe::Customer::TaxInfo', @_ ) ); }

# sub tax_info_verification { return( shift->_set_get_object( 'tax_info_verification', 'Net::API::Stripe::Customer::TaxInfoVerification', @_ ) ); }
sub tax_info_verification { return( shift->_set_get_object( 'tax_info_verification', 'Net::API::Stripe::Connect::Account::Verification', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Customer - A Customer object in Stripe API

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

From the documentation:

Stripe Customer objects allow you to perform recurring charges, and to track multiple charges, that are associated with the same customer. The API allows you to create, delete, and update your customers. You can retrieve individual customers as well as a list of all your customers.

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

=item B<id> string

Unique identifier for the object.

=item B<object> string, value is "customer"

String representing the object’s type. Objects of the same type share the same value.

=item B<account_balance>

It seems not in use anymore as of 2019-10-16, at least by the look of the API documentation.

=item B<address> hash

The customer’s address. This is a C<Net::API::Stripe::Address> object.

=item B<balance> integer

Current balance, if any, being stored on the customer. If negative, the customer has credit to apply to their next invoice. If positive, the customer has an amount owed that will be added to their next invoice. The balance does not refer to any unpaid invoices; it solely takes into account amounts that have yet to be successfully applied to any invoice. This balance is only taken into account as invoices are finalized.

=item B<cards>

This represents a C<Net::API::Stripe::Customer::Sources> object.

It seems that as of 2019-10-16, it is not in Stripe API, but it was seen in Stripe response.

=item B<coupon> optional

If you provide a coupon code, the customer will have a discount applied on all recurring charges. Charges you create through the API will not have the discount.

This is used only when creating a customer object.

=item B<created> timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=item B<currency> string

Three-letter ISO code for the currency the customer can be charged in for recurring billing purposes.

=item B<default_card>

The API does not mention this, but it was part of some response. Deprecated or omission?

=item B<default_source> string (expandable)

ID of the default payment source for the customer. This is a C<Net::API::Stripe::Payment::Source> object.

=item B<deleted>

A flag that is being used, but not part of the API documentation.

=item B<delinquent> boolean

When the customer’s latest invoice is billed by charging automatically, delinquent is true if the invoice’s latest charge is failed. When the customer’s latest invoice is billed by sending an invoice, delinquent is true if the invoice is not paid by its due date.

=item B<description> string

An arbitrary string attached to the object. Often useful for displaying to users.

=item B<discount> hash, discount object

Describes the current discount active on the customer, if there is one. This is a C<Net::API::Stripe::Billing::Discount> object.

=item B<email> string

The customer’s email address.

=item B<invoice_prefix> string

The prefix for the customer used to generate unique invoice numbers.

=item B<invoice_settings> hash

The customer’s default invoice settings. This is a C<Net::API::Stripe::Billing::Invoice::Settings> object.

=over 8

=item B<custom_fields> array of hashes

Default custom fields to be displayed on invoices for this customer. This is an array of C<Net::API::Stripe::CustomField> object.

=over 12

=item I<name> string

The name of the custom field.

=item I<value> string

The value of the custom field.

=back

=item B<default_payment_method> string (expandable)

ID of the default payment method used for subscriptions and invoices for the customer. When expanded, this is a C<Net::API::Stripe::Payment::Method> object.

=item B<footer> string

Default footer to be displayed on invoices for this customer.

=back

=item B<livemode> boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<metadata> hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=item B<name> string

The customer’s full name or business name.

=item B<next_invoice_sequence> string

The sequence to be used on the customer’s next invoice. Defaults to 1.

=item B<payment_method> optional

The ID of the PaymentMethod to attach to the customer.

This is used when creating a customer object.

=item B<phone> string

The customer’s phone number.

=item B<preferred_locales> array containing strings

The customer’s preferred locales (languages), ordered by preference.

=item B<shipping> hash

Mailing and shipping address for the customer. Appears on invoices emailed to this customer. This is a C<Net::API::Stripe::Shipping> object.

=item B<source> optional

A Token’s (L<https://stripe.com/docs/api#tokens>) or a Source’s (L<https://stripe.com/docs/api#sources>) ID, as returned by Elements (L<https://stripe.com/docs/elements>). Passing source will create a new source object, make it the new customer default source, and delete the old customer default if one exists. If you want to add additional sources instead of replacing the existing default, use the card creation API (L<https://stripe.com/docs/api#create_card>). Whenever you attach a card to a customer, Stripe will automatically validate the card.

This is used when creating a customer object.

=item B<sources> list

The customer’s payment sources, if any. This is a C<Net::API::Stripe::Customer::Sources> object.

=item B<subscriptions> list

The customer’s current subscriptions, if any. This is a C<Net::API::Stripe::List> object of C<Net::API::Stripe::Billing::Subscription> objects.

=item B<tax_exempt> string

Describes the customer’s tax exemption status. One of none, exempt, or reverse. When set to reverse, invoice and receipt PDFs include the text “Reverse charge”.

=item B<tax_id_data> optional array of hashes

The customer’s tax IDs.

This is used when creating a customer object.

=over 8

=item I<type> required

Type of the tax ID, one of au_abn, ch_vat, eu_vat, in_gst, mx_rfc, no_vat, nz_gst, or za_vat

=item I<value> required

Value of the tax ID.

=back

=item B<tax_ids> list

The customer’s tax IDs. This is represented by a C<Net::API::Stripe::Customer::TaxIds> object.

=over 8

=item B<object> string, value is "list"

String representing the object's type. Objects of the same type share the same value. Always has the value list.

=item B<data> array of C<Net::API::Stripe::Customer::TaxId> object

=item B<has_more> boolean

True if this list has another page of items after this one that can be fetched.

=item B<url> string

The URL where this list can be accessed.

=back

=item B<tax_info> deprecated hash

The customer’s tax information. Appears on invoices emailed to this customer. This field has been deprecated and will be removed in a future API version, for further information view the migration guide.

This is a C<Net::API::Stripe::Customer::TaxInfo> object.

=item B<tax_info_verification> deprecated hash

Describes the status of looking up the tax ID provided in tax_info. This field has been deprecated and will be removed in a future API version, for further information view the migration guide.

This is a C<Net::API::Stripe::Customer::TaxInfoVerification> object

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

=head1 STRIPE HISTORY

=head2 2019-12-03

Deprecated tax information for Customers have been removed.

=over 4

=item The deprecated tax_info and tax_info_verification fields on the Customer object are now removed in favor of tax_ids.

=item The deprecated tax_info parameter on the Customer create and update methods are removed in favor of tax_id_data.

=item For more information, view the migration guide.

=back

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/customers>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
