##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/TaxID.pm
## Version 0.1
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/12/19
## Modified 2019/12/19
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/customer_tax_ids
package Net::API::Stripe::Billing::TaxID;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub country { return( shift->_set_get_scalar( 'country', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub customer { return( shift->_set_get_scalar_or_object( 'customer', 'Net::API::Stripe::Customer', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

sub value { return( shift->_set_get_scalar( 'value', @_ ) ); }

sub verification { return( shift->_set_get_hash( 'verification', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Billing::TaxID - A Stripe Customer Tax ID Object

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

You can add one or multiple tax IDs to a customer. A customer's tax IDs are displayed on invoices and credit notes issued for the customer.

See Customer Tax Identification Numbers L<https://stripe.com/docs/billing/taxes/tax-ids> for more information.

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

Type of the tax ID, one of au_abn, ch_vat, eu_vat, in_gst, mx_rfc, no_vat, nz_gst, za_vat, or unknown

=item B<value> string

Value of the tax ID.

=item B<verification> hash

Tax ID verification information.

=over 8

=item I<status> string

Verification status, one of pending, unavailable, unverified, or verified.

=item I<verified_address> string

Verified address

=item I<verified_name> string

Verified name.

=back

=back

=head1 API SAMPLE

	{
	  "id": "txi_123456789",
	  "object": "tax_id",
	  "country": "DE",
	  "created": 123456789,
	  "customer": "cus_G7ucGt79A501bC",
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

=head1 STRIPE HISTORY

=head2 2019-12-19

Initially introduced by Stripe in December 2019.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/customer_tax_ids/object>, L<https://stripe.com/docs/billing/migration/taxes#moving-from-taxinfo-to-customer-tax-ids>,
L<https://stripe.com/docs/billing/taxes/tax-ids>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut

