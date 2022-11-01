##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Tax/Rate.pm
## Version v0.102.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2022/10/29
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Tax::Rate;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.102.0';
};

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub active { return( shift->_set_get_boolean( 'active', @_ ) ); }

sub country { return( CORE::shift->_set_get_scalar( 'country', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub description { return( shift->_set_get_scalar( 'description', @_ ) ); }

sub display_name { return( shift->_set_get_scalar( 'display_name', @_ ) ); }

sub inclusive { return( shift->_set_get_boolean( 'inclusive', @_ ) ); }

sub jurisdiction { return( shift->_set_get_scalar( 'jurisdiction', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub percentage { return( shift->_set_get_number( 'percentage', @_ ) ); }

sub state { return( CORE::shift->_set_get_scalar( 'state', @_ ) ); }

sub tax_type { return( shift->_set_get_scalar( 'tax_type', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Tax::Rate - A Stripe Tax Rate Object

=head1 SYNOPSIS

    my $rate = $stripe->tax_rate({
        active => $stripe->true,
        created => '2020-04-12T17:12:10',
        description => 'Japan VAT applicable to customers',
        display_name => 'Japan VAT',
        inclusive => $stripe->false,
        jurisdiction => 'jp',
        livemode => $stripe->false,
        metadata => { tax_id => 123, customer_id => 456 },
        percentage => 10,
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    v0.102.0

=head1 DESCRIPTION

This is used in L<Net::API::Stripe::Billing::Invoice> to describe a list of tax rates, and also in L<Net::API::Stripe::Billing::Subscription::Schedule> in B<phases>->I<default_tax_rates>.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Tax::Rate> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is "tax_rate"

String representing the object’s type. Objects of the same type share the same value.

=head2 active boolean

Defaults to true. When set to false, this tax rate cannot be applied to objects in the API, but will still be applied to subscriptions and invoices that already have it set.

=head2 country string

Two-letter country code (L<ISO 3166-1 alpha-2|https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)>.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 description string

An arbitrary string attached to the tax rate for your internal use only. It will not be visible to your customers.

=head2 display_name string

The display name of the tax rates as it will appear to your customer on their receipt email, PDF, and the hosted invoice page.

=head2 inclusive boolean

This specifies if the tax rate is inclusive or exclusive.

=head2 jurisdiction string

The jurisdiction for the tax rate.

=head2 livemode boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=head2 metadata hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 percentage decimal

This represents the tax rate percent out of 100.

=head2 state string

L<ISO 3166-2 subdivision code|https://en.wikipedia.org/wiki/ISO_3166-2:US>, without country prefix. For example, "NY" for New York, United States.

=head2 tax_type string

The high-level tax type, such as C<vat> or C<sales_tax>.

=head1 API SAMPLE

    {
      "id": "txr_1GWkAHCeyNCl6fY2QtB0BbzC",
      "object": "tax_rate",
      "active": true,
      "created": 1586614713,
      "description": "VAT Germany",
      "display_name": "VAT",
      "inclusive": false,
      "jurisdiction": "DE",
      "livemode": false,
      "metadata": {},
      "percentage": 19.0
    }

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/tax_rates>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
