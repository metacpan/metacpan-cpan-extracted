##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Customer/TaxId.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Customer::TaxId;
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

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub country { return( shift->_set_get_scalar( 'country', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

## Customer id
sub customer { return( shift->_set_get_scalar_or_object( 'customer', 'Net::API::Stripe::Customer', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

## au_abn, ch_vat, eu_vat, in_gst, no_vat, nz_gst, unknown, or za_vat
sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

sub value { return( shift->_set_get_scalar( 'value', @_ ) ); }

# sub verification { return( shift->_set_get_object( 'verification', 'Net::API::Stripe::Customer::TaxInfoVerification', @_ ) ); }
sub verification { return( shift->_set_get_object( 'verification', 'Net::API::Stripe::Connect::Account::Verification', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Customer::TaxId - A Customer Tax ID object

=head1 SYNOPSIS

    my $tax_id = $stripe->tax_id({
        country => 'jp',
        customer => $customer_object,
        type => 'eu_vat',
        value => 'EU123456789',
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

You can add one or multiple tax IDs to a customer (L<Net::API::Stripe::Customer> / L<https://stripe.com/docs/api/customers>). A customer's tax IDs are displayed on invoices and credit notes issued for the customer.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Customer::TaxId> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is "tax_id"

String representing the object’s type. Objects of the same type share the same value.

=head2 country string

Two-letter ISO code representing the country of the tax ID.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 customer string (expandable)

ID of the customer. When expanded, this is a L<Net::API::Stripe::Customer> object.

=head2 livemode boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=head2 type string

Type of the tax ID, one of au_abn, ch_vat, eu_vat, in_gst, no_vat, nz_gst, unknown, or za_vat

=head2 value string

Value of the tax ID.

=head2 verification object

Tax ID verification information. This is a L<Net::API::Stripe::Customer::TaxInfoVerification> object.

=head1 API SAMPLE

    {
      "id": "txi_fake123456789",
      "object": "tax_id",
      "country": "DE",
      "created": 123456789,
      "customer": "cus_fake123456789",
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

L<https://stripe.com/docs/api/customer_tax_ids>, L<https://stripe.com/docs/billing/taxes/tax-ids>, L<https://en.wikipedia.org/wiki/VAT_identification_number>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
