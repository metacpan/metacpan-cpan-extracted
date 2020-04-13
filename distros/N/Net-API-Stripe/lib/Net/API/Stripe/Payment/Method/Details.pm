##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Payment/Method/Details.pm
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
package Net::API::Stripe::Payment::Method::Details;
BEGIN
{
	use strict;
	use parent qw( Net::API::Stripe::Generic );
	our( $VERSION ) = '0.1';
};

sub ach_credit_transfer { return( shift->_set_get_object( 'ach_credit_transfer', 'Net::API::Stripe::Payment::Source::ACHCreditTransfer', @_ ) ); }

sub ach_debit { return( shift->_set_get_object( 'ach_debit', 'Net::API::Stripe::Payment::Source::ACHDebit', @_ ) ); }

sub alipay { return( shift->_set_get_hash_as_object( 'alipay', 'Net::API::Stripe::Payment::Method::Details::Alipay', @_ ) ); }

sub au_becs_debit { return( shift->_set_get_hash_as_object( 'au_becs_debit', 'Net::API::Stripe::Payment::Method::Details::AuBecsDebit', @_ ) ); }

sub bancontact { return( shift->_set_get_hash_as_object( 'bancontact', 'Net::API::Stripe::Payment::Method::Details::BanContact', @_ ) ); }

# sub card { return( shift->_set_get_hash_as_object( 'card', 'Net::API::Stripe::Payment::Method::Details::Card', @_ ) ); }
sub card { return( shift->_set_get_object( 'card', 'Net::API::Stripe::Payment::Card', @_ ) ); }

sub card_present { return( shift->_set_get_hash_as_object( 'card_present', 'Net::API::Stripe::Payment::Method::Details::CardPresent', @_ ) ); }

sub eps { return( shift->_set_get_hash_as_object( 'eps', 'Net::API::Stripe::Payment::Method::Details::EPS', @_ ) ); }

sub fpx { return( shift->_set_get_hash_as_object( 'fpx', 'Net::API::Stripe::Payment::Method::Details::FPX', @_ ) ); }

sub giropay { return( shift->_set_get_hash_as_object( 'giropay', 'Net::API::Stripe::Payment::Method::Details::Giropay', @_ ) ); }

sub ideal { return( shift->_set_get_hash_as_object( 'ideal', 'Net::API::Stripe::Payment::Method::Details::Ideal', @_ ) ); }

sub klarna { return( shift->_set_get_hash_as_object( 'klarna', 'Net::API::Stripe::Payment::Method::Details::Klarna', @_ ) ); }

sub multibanco { return( shift->_set_get_hash_as_object( 'multibanco', 'Net::API::Stripe::Payment::Method::Details::MultiBanco', @_ ) ); }

sub p24 { return( shift->_set_get_hash_as_object( 'p24', 'Net::API::Stripe::Payment::Method::Details::P24', @_ ) ); }

sub sepa_debit { return( shift->_set_get_hash( 'sepa_debit', @_ ) ); }

sub sofort { return( shift->_set_get_hash_as_object( 'sofort', 'Net::API::Stripe::Payment::Method::Details::Sofort', @_ ) ); }

sub stripe_account { return( shift->_set_get_hash_as_object( 'stripe_account', 'Net::API::Stripe::Payment::Method::Details::StripeAccount', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

sub wechat { return( shift->_set_get_hash_as_object( 'wechat', 'Net::API::Stripe::Payment::Method::Details::WeChat', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Payment::Method::Details - A Stripe Payment Method Details

=head1 SYNOPSIS

    my $details = $stripe->charge->payment_method_details({
        card => $card_object,
        type => 'card',
    });

=head1 VERSION

    0.1

=head1 DESCRIPTION

Transaction-specific details of the payment method used in the payment.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Payment::Method::Details> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<ach_credit_transfer> hash

If this is a ach_credit_transfer payment, this hash contains a snapshot of the transaction specific details of the ach_credit_transfer payment method.

This is a L<Net::API::Stripe::Payment::Source::ACHCreditTransfer> object

=item B<ach_debit> hash

If this is a ach_debit payment, this hash contains a snapshot of the transaction specific details of the ach_debit payment method.

This is a L<Net::API::Stripe::Payment::Source::ACHDebit> object.

=item B<alipay> hash

If this is a alipay payment, this hash contains a snapshot of the transaction specific details of the alipay payment method.

Data can be accessed as objectified hash reference, ie each key / value pair can be accessed as virtual methods as a L<Net::API::Stripe::Payment::Method::Details::Alipay> object.

=item B<au_becs_debit> hash

If this is a au_becs_debit payment, this hash contains a snapshot of the transaction specific details of the au_becs_debit payment method.

=over 8

=item I<bsb_number> string

Bank-State-Branch number of the bank account.

=item I<fingerprint> string

Uniquely identifies this particular bank account. You can use this attribute to check whether two bank accounts are the same.

=item I<last4> string

Last four digits of the bank account number.

=item I<mandate> string

ID of the mandate used to make this payment.

=back

=item B<bancontact> hash

If this is a bancontact payment, this hash contains a snapshot of the transaction specific details of the bancontact payment method.

This is a virtual package L<Net::API::Stripe::Payment::Method::Details::BanContact> object.

The methods are:

=over 8

=item B<bank_code> string

Bank code of bank associated with the bank account.

=item B<bank_name> string

Name of the bank associated with the bank account.

=item B<bic> string

Bank Identifier Code of the bank associated with the bank account.

=item B<iban_last4> string

Last four characters of the IBAN.

=item B<preferred_language> string

Preferred language of the Bancontact authorization page that the customer is redirected to. Can be one of en, de, fr, or nl

=item B<verified_name> string

Owner’s verified full name. Values are verified or provided by Bancontact directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.

=back

=item B<card> hash

If this is a card payment, this hash contains a snapshot of the transaction specific details of the card payment method.

This is a L<Net::API::Stripe::Payment::Card> object.

=item B<card_present> hash

If this is a card_present payment, this hash contains a snapshot of the transaction specific details of the card_present payment method.

This is a L<Net::API::Stripe::Payment::Method::Details::CardPresent> object.

=over 8

=item I<brand> string

Card brand. Can be amex, diners, discover, jcb, mastercard, unionpay, visa, or unknown.

=item I<country> string

Two-letter ISO code representing the country of the card. You could use this attribute to get a sense of the international breakdown of cards you’ve collected.

=item I<emv_auth_data> string

Authorization response cryptogram.

=item I<exp_month> integer

Two-digit number representing the card’s expiration month.

=item I<exp_year> integer

Four-digit number representing the card’s expiration year.

=item I<fingerprint> string

Uniquely identifies this particular card number. You can use this attribute to check whether two customers who’ve signed up with you are using the same card number, for example.

=item I<funding> string

Card funding type. Can be credit, debit, prepaid, or unknown.

=item I<generated_card> string

ID of a card PaymentMethod generated from the card_present PaymentMethod that may be attached to a Customer for future transactions. Only present if it was possible to generate a card PaymentMethod.

=item I<last4> string

The last four digits of the card.

=item I<network> string preview feature

Identifies which network this charge was processed on. Can be amex, diners, discover, interac, jcb, mastercard, unionpay, visa, or unknown.

=item I<read_method> string

How were card details read in this transaction. Can be contact_emv, contactless_emv, magnetic_stripe_fallback, magnetic_stripe_track2, or contactless_magstripe_mode

=item I<receipt> hash

A collection of fields required to be displayed on receipts. Only required for EMV transactions.

=over 12

=item I<application_cryptogram> string

EMV tag 9F26, cryptogram generated by the integrated circuit chip.

=item I<application_preferred_name> string

Mnenomic of the Application Identifier.

=item I<authorization_code> string

Identifier for this transaction.

=item I<authorization_response_code> string

EMV tag 8A. A code returned by the card issuer.

=item I<cardholder_verification_method> string

How the cardholder verified ownership of the card.

=item I<dedicated_file_name> string

EMV tag 84. Similar to the application identifier stored on the integrated circuit chip.

=item I<terminal_verification_results> string

The outcome of a series of EMV functions performed by the card reader.

=item I<transaction_status_information> string

An indication of various EMV functions performed during the transaction.

=back

=back

=item B<eps> hash

If this is a eps payment, this hash contains a snapshot of the transaction specific details of the eps payment method.

This is a L<Net::API::Stripe::Payment::Method::Details::EPS> object.

=over 8

=item I<verified_name> string

Owner’s verified full name. Values are verified or provided by EPS directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.

=back

=item B<fpx>

If this is a fpx payment, this hash contains a snapshot of the transaction specific details of the fpx payment method.

=over 8

=item I<bank> string

The customer’s bank. Can be one of affin_bank, alliance_bank, ambank, bank_islam, bank_muamalat, bank_rakyat, bsn, cimb, hong_leong_bank, hsbc, kfh, maybank2u, ocbc, public_bank, rhb, standard_chartered, uob, deutsche_bank, maybank2e, or pb_enterprise.

=item I<transaction_id> string

Unique transaction id generated by FPX for every request from the merchant

=back

=item B<giropay> hash

If this is a giropay payment, this hash contains a snapshot of the transaction specific details of the giropay payment method.

This is a L<Net::API::Stripe::Payment::Method::Details::Giropay> object.

=over 8

=item I<bank_code> string

Bank code of bank associated with the bank account.

=item I<bank_name> string

Name of the bank associated with the bank account.

=item I<bic> string

Bank Identifier Code of the bank associated with the bank account.

=item I<verified_name> string

Owner’s verified full name. Values are verified or provided by Giropay directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.

=back

=item B<ideal> hash

If this is a ideal payment, this hash contains a snapshot of the transaction specific details of the ideal payment method.

This is a L<Net::API::Stripe::Payment::Method::Details::Ideal> object.

=over 8

=item I<bank> string

The customer’s bank. Can be one of abn_amro, asn_bank, bunq, handelsbanken, ing, knab, moneyou, rabobank, regiobank, sns_bank, triodos_bank, or van_lanschot.

=item I<bic> string

The Bank Identifier Code of the customer’s bank.

=item I<iban_last4> string

Last four characters of the IBAN.

=item I<verified_name> string

Owner’s verified full name. Values are verified or provided by iDEAL directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.

=back

=item B<klarna> hash

If this is a klarna payment, this hash contains a snapshot of the transaction specific details of the klarna payment method.

This is a L<Net::API::Stripe::Payment::Method::Details::Klarna> object.

=item B<multibanco> hash

If this is a multibanco payment, this hash contains a snapshot of the transaction specific details of the multibanco payment method.

This is a L<Net::API::Stripe::Payment::Method::Details::MultiBanco> object.

=over 8

=item I<entity> string

Entity number associated with this Multibanco payment.

=item I<reference> string

Reference number associated with this Multibanco payment.

=back

=item B<p24> hash

If this is a p24 payment, this hash contains a snapshot of the transaction specific details of the p24 payment method.

This is a L<Net::API::Stripe::Payment::Method::Details::P24> object.

=over 8

=item I<reference> string

Unique reference for this Przelewy24 payment.

=item I<verified_name> string

Owner’s verified full name. Values are verified or provided by Przelewy24 directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.

=back

=item B<sepa_debit> hash

If this is a sepa_debit payment, this hash contains a snapshot of the transaction specific details of the sepa_debit payment method.

=over 8

=item I<bank_code> string

Bank code of bank associated with the bank account.

=item I<branch_code> string

Branch code of bank associated with the bank account.

=item I<country> string

Two-letter ISO code representing the country the bank account is located in.

=item I<fingerprint> string

Uniquely identifies this particular bank account. You can use this attribute to check whether two bank accounts are the same.

=item I<last4> string

Last four characters of the IBAN.

=item I<mandate> string

ID of the mandate used to make this payment.

=back

=item B<sofort> hash

If this is a sofort payment, this hash contains a snapshot of the transaction specific details of the sofort payment method.

This is a L<Net::API::Stripe::Payment::Method::Details::Sofort> object.

=over 8

=item I<bank_code> string

Bank code of bank associated with the bank account.

=item I<bank_name> string

Name of the bank associated with the bank account.

=item I<bic> string

Bank Identifier Code of the bank associated with the bank account.

=item I<country> string

Two-letter ISO code representing the country the bank account is located in.

=item I<iban_last4> string

Last four characters of the IBAN.

=item I<verified_name> string

Owner’s verified full name. Values are verified or provided by SOFORT directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.

=back

=item B<stripe_account> hash

If this is a stripe_account payment, this hash contains a snapshot of the transaction specific details of the stripe_account payment method.

This is a L<Net::API::Stripe::Payment::Method::Details::StripeAccount> object.

=item B<type> string

The type of transaction-specific details of the payment method used in the payment, one of ach_credit_transfer, ach_debit, alipay, bancontact, card, card_present, eps, giropay, ideal, klarna, multibanco, p24, sepa_debit, sofort, stripe_account, or wechat. An additional hash is included on payment_method_details with a name matching this value. It contains information specific to the payment method.

=item B<wechat> hash

If this is a wechat payment, this hash contains a snapshot of the transaction specific details of the wechat payment method.

This is a L<Net::API::Stripe::Payment::Method::Details::WeChat> object.

=back

=head1 HISTORY

=head2 v0.1

Initial version

=head1 STRIPE HISTORY

=head2 2019-12-24

Stripe added the property B<sepa_debit>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/charges/object#charge_object-payment_method_details>

L<https://stripe.com/docs/api/payment_methods/object>, L<https://stripe.com/docs/api/charges/object#charge_object-payment_method_details>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
