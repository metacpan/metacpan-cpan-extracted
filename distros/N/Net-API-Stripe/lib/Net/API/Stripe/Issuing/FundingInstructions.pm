##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Issuing/FundingInstructions.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/10/29
## Modified 2022/10/29
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Issuing::FundingInstructions;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = 'v0.1.0';
};

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub bank_transfer { return( shift->_set_get_object( 'bank_transfer', 'Net::API::Stripe::Billing::TaxID', @_ ) ); }

sub currency { return( shift->_set_get_scalar( 'currency', @_ ) ); }

sub funding_type { return( shift->_set_get_scalar( 'funding_type', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Issuing::FundingInstructions - The FundingInstruction object

=head1 SYNOPSIS

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

Funding Instructions contain reusable bank account and routing information. Push funds to these addresses via bank transfer to L<top up Issuing Balances|https://stripe.com/docs/issuing/funding/balance>.

=head1 METHODS

=head2 object string

String representing the object's type. Objects of the same type share the same value.

=head2 bank_transfer object

Details to display instructions for initiating a bank transfer

This is a L<Net::API::Stripe::Billing::TaxID> object.

=head2 currency string

Three-letter L<ISO currency code|https://www.iso.org/iso-4217-currency-codes.html>, in lowercase. Must be a L<supported currency|https://stripe.com/docs/currencies>.

=head2 funding_type string

The C<funding_type> of the returned instructions

=head2 livemode boolean

Has the value C<true> if the object exists in live mode or the value C<false> if the object exists in test mode.

=head1 API SAMPLE

[
   {
      "bank_transfer" : {
         "country" : "DE",
         "financial_addresses" : [
            {
               "iban" : {
                  "account_holder_name" : "Stripe Technology Europe Limited",
                  "bic" : "SXPYDEHH",
                  "country" : "DE",
                  "iban" : "DE00000000000000000001"
               },
               "supported_networks" : [
                  "sepa"
               ],
               "type" : "iban"
            }
         ],
         "type" : "eu_bank_transfer"
      },
      "currency" : "eur",
      "funding_type" : "bank_transfer",
      "livemode" : 0,
      "object" : "funding_instructions"
   }
]

=head1 HISTORY

=head2 v0.1.0

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Stripe API documentation|https://stripe.com/docs/api/issuing/funding_instructions>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2022 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
