##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Customer/TaxId.pm
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
package Net::API::Stripe::Customer::TaxId;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub id { shift->_set_get_scalar( 'id', @_ ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub country { shift->_set_get_scalar( 'country', @_ ); }

sub created { shift->_set_get_datetime( 'created', @_ ); }

## Customer id
sub customer { shift->_set_get_scalar_or_object( 'customer', 'Net::API::Stripe::Customer', @_ ); }

sub livemode { shift->_set_get_boolean( 'livemode', @_ ); }

## au_abn, ch_vat, eu_vat, in_gst, no_vat, nz_gst, unknown, or za_vat
sub type { shift->_set_get_scalar( 'type', @_ ); }

sub value { shift->_set_get_scalar( 'value', @_ ); }

# sub verification { shift->_set_get_object( 'verification', 'Net::API::Stripe::Customer::TaxInfoVerification', @_ ); }
sub verification { shift->_set_get_object( 'verification', 'Net::API::Stripe::Connect::Account::Verification', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Customer::TaxId - A Customer Tax ID object

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

You can add one or multiple tax IDs to a customer (C<Net::API::Stripe::Customer> / L<https://stripe.com/docs/api/customers>). A customer's tax IDs are displayed on invoices and credit notes issued for the customer.

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

=item B<object> string, value is "tax_id"

String representing the object’s type. Objects of the same type share the same value.

=item B<country> string

Two-letter ISO code representing the country of the tax ID.

=item B<created> timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=item B<customer> string (expandable)

ID of the customer. When expanded, this is a C<Net::API::Stripe::Customer> object.

=item B<livemode> boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<type> string

Type of the tax ID, one of au_abn, ch_vat, eu_vat, in_gst, no_vat, nz_gst, unknown, or za_vat

=item B<value> string

Value of the tax ID.

=item B<verification> object

Tax ID verification information. This is a C<Net::API::Stripe::Customer::TaxInfoVerification> object.

=back

=head1 API SAMPLE

	{
	  "id": "txi_123456789",
	  "object": "tax_id",
	  "country": "DE",
	  "created": 123456789,
	  "customer": "cus_Eky0BeTYmSj9pa",
	  "livemode": false,
	  "type": "eu_vat",
	  "value": "DE123456789",
	  "verification": {
		"status": "pending",
		"verified_address": null,
		"verified_name": null
	  }
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/customer_tax_ids>, L<https://stripe.com/docs/billing/taxes/tax-ids>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
