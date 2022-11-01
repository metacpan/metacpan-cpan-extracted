##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Issuing/MerchantData.pm
## Version v0.101.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2022/10/29
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Issuing::MerchantData;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.101.0';
};

use strict;
use warnings;

sub category { return( shift->_set_get_scalar( 'category', @_ ) ); }

sub category_code { return( CORE::shift->_set_get_scalar( 'category_code', @_ ) ); }

sub city { return( shift->_set_get_scalar( 'city', @_ ) ); }

sub country { return( shift->_set_get_scalar( 'country', @_ ) ); }

sub name { return( shift->_set_get_scalar( 'name', @_ ) ); }

sub network_id { return( shift->_set_get_scalar( 'network_id', @_ ) ); }

sub postal_code { return( shift->_set_get_scalar( 'postal_code', @_ ) ); }

sub state { return( shift->_set_get_scalar( 'state', @_ ) ); }

sub url { return( shift->_set_get_uri( 'url', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Issuing::MerchantData - A Stripe Merchant Data Object

=head1 SYNOPSIS

    my $data = $stripe->authorization->merchant_data({
        # https://stripe.com/docs/issuing/categories
        category => '8111',
        city => 'Tokyo',
        country => 'jp',
        name => 'Big Corp, Inc',
        network_id => $some_id,
        postal_code => '123-4567',
        state => undef,
        url => 'https://store.example.com/12/service/advisory',
    });

=head1 VERSION

    v0.101.0

=head1 DESCRIPTION

This is used in L<Net::API::Stripe::Issuing::Authorization> object.

This is instantiated by method B<merchant_data> in module L<Net::API::Stripe::Issuing::Authorization>, L<Net::API::Stripe::Issuing::Authorization::Transaction> and L<Net::API::Stripe::Issuing::Transaction>

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Issuing::MerchantData> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 category string

A categorization of the seller’s type of business. See Stripe merchant categories guide (L<https://stripe.com/docs/issuing/categories>) for a list of possible values.

=head2 category_code string

The merchant category code for the seller’s business

=head2 city string

City where the seller is located

=head2 country string

Country where the seller is located

=head2 name string

Name of the seller

=head2 network_id string

Identifier assigned to the seller by the card brand

=head2 postal_code string

Postal code where the seller is located

=head2 state string

State where the seller is located

=head2 url string

The url an online purchase was made from

=head1 API SAMPLE

    {
      "id": "iauth_fake123456789",
      "object": "issuing.authorization",
      "approved": true,
      "authorization_method": "online",
      "authorized_amount": 500,
      "authorized_currency": "usd",
      "balance_transactions": [],
      "card": null,
      "cardholder": null,
      "created": 1540642827,
      "held_amount": 0,
      "held_currency": "usd",
      "is_held_amount_controllable": false,
      "livemode": false,
      "merchant_data": {
        "category": "taxicabs_limousines",
        "city": "San Francisco",
        "country": "US",
        "name": "Rocket Rides",
        "network_id": "1234567890",
        "postal_code": "94107",
        "state": "CA",
        "url": null
      },
      "metadata": {},
      "pending_authorized_amount": 0,
      "pending_held_amount": 0,
      "request_history": [],
      "status": "reversed",
      "transactions": [
        {
          "id": "ipi_fake123456789",
          "object": "issuing.transaction",
          "amount": -100,
          "authorization": "iauth_fake123456789",
          "balance_transaction": null,
          "card": "ic_fake123456789",
          "cardholder": null,
          "created": 1540642827,
          "currency": "usd",
          "dispute": null,
          "livemode": false,
          "merchant_amount": null,
          "merchant_currency": null,
          "merchant_data": {
            "category": "taxicabs_limousines",
            "city": "San Francisco",
            "country": "US",
            "name": "Rocket Rides",
            "network_id": "1234567890",
            "postal_code": "94107",
            "state": "CA",
            "url": null
          },
          "metadata": {},
          "type": "capture"
        },
        {
          "id": "ipi_fake123456789",
          "object": "issuing.transaction",
          "amount": -100,
          "authorization": "iauth_fake123456789",
          "balance_transaction": null,
          "card": "ic_fake123456789",
          "cardholder": null,
          "created": 1540642827,
          "currency": "usd",
          "dispute": null,
          "livemode": false,
          "merchant_amount": null,
          "merchant_currency": null,
          "merchant_data": {
            "category": "taxicabs_limousines",
            "city": "San Francisco",
            "country": "US",
            "name": "Rocket Rides",
            "network_id": "1234567890",
            "postal_code": "94107",
            "state": "CA",
            "url": null
          },
          "metadata": {},
          "type": "capture"
        }
      ],
      "verification_data": {
        "address_line1_check": "not_provided",
        "address_zip_check": "match",
        "authentication": "none",
        "cvc_check": "match"
      },
      "wallet_provider": null
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
