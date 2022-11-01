##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Customer/Card.pm
## Version v0.2.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/09/30
## Modified 2022/10/29
## 
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/customer_bank_accounts
package Net::API::Stripe::Customer::Card;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Connect::ExternalAccount::Card );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.2.0';
};

use strict;
use warnings;

sub mandate { return( shift->_set_get_scalar( 'mandate', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Customer::Card - A Stripe Customer Card Object

=head1 SYNOPSIS

    my $card = $stripe->customer_card({
        account => 'acct_fake123456789',
        # Or you can also simply pass a Net::API::Stripe::Address object
        # address => $address_object
        address_line1 => '1-2-3 Kudan-Minami, Chiyoda-ku',
        address_line2 => 'Big bldg. 12F',
        address_city => 'Tokyo',
        address_zip => '123-4567',
        address_country => 'jp',
        brand => 'visa',
        country => 'jp',
        currency => 'jpy',
        customer => $customer_object,
        cvc => 123,
        # Boolean
        default_for_currency => 1,
        exp_month => 12,
        exp_year => 2030,
        funding => 'debit',
        metadata => { transaction_id => 123, customer_id => 456 },
        name => 'John Doe',
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This class represents a customer card. It is almost the same as the L<external account|Net::API::Stripe::Connect::ExternalAccount::Card>, and it actually inherits all of its methods from it.

=head1 API SAMPLE

    {
      "id": "card_1LnbQv2eZvKYlo2ClaAC0Zy9",
      "object": "card",
      "address_city": null,
      "address_country": null,
      "address_line1": null,
      "address_line1_check": null,
      "address_line2": null,
      "address_state": null,
      "address_zip": null,
      "address_zip_check": null,
      "brand": "Visa",
      "country": "US",
      "customer": null,
      "cvc_check": "pass",
      "dynamic_last4": null,
      "exp_month": 8,
      "exp_year": 2023,
      "fingerprint": "Xt5EWLLDS7FJjR1c",
      "funding": "credit",
      "last4": "4242",
      "metadata": {},
      "name": null,
      "redaction": null,
      "tokenization_method": null
    }

=head1 HISTORY

=head2 v0.1.0

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/cards>, L<https://stripe.com/docs/sources/cards>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2022 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
