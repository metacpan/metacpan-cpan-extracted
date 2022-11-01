##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/SetupAttempt.pm
## Version v0.2.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2020/11/20
## Modified 2022/10/29
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::SetupAttempt;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.2.0';
};

use strict;
use warnings;

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub application { return( shift->_set_get_scalar_or_object( 'application', 'Net::API::Stripe::Connect::Account', @_ ) ); }

sub attach_to_self { return( shift->_set_get_boolean( 'attach_to_self', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub customer { return( shift->_set_get_scalar_or_object( 'customer', 'Net::API::Stripe::Customer', @_ ) ); }

sub flow_directions { return( shift->_set_get_array( 'flow_directions', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub on_behalf_of { return( shift->_set_get_scalar_or_object( 'on_behalf_of', 'Net::API::Stripe::Connect::Account', @_ ) ); }

sub payment_method { return( shift->_set_get_scalar_or_object( 'payment_method', 'Net::API::Stripe::Payment::Method', @_ ) ); }

sub payment_method_details { return( shift->_set_get_class( 'payment_method_details',
{
  bancontact => {
                  definition => {
                    bank_code => { type => "scalar" },
                    bank_name => { type => "scalar" },
                    bic => { type => "scalar" },
                    generated_sepa_debit => {
                      package => "Net::API::Stripe::Payment::Method",
                      type => "scalar_or_object",
                    },
                    generated_sepa_debit_mandate => { package => "Net::API::Stripe::Mandate", type => "scalar_or_object" },
                    iban_last4 => { type => "scalar" },
                    preferred_language => { type => "scalar" },
                    verified_name => { type => "scalar" },
                  },
                  type => "class",
                },
  card       => {
                  definition => {
                    three_d_secure => {
                      definition => {
                        authentication_flow => { type => "scalar" },
                        result => { type => "scalar" },
                        result_reason => { type => "scalar" },
                        version => { type => "scalar" },
                      },
                      type => "class",
                    },
                  },
                  type => "class",
                },
  ideal      => {
                  definition => {
                    bank => { type => "scalar" },
                    bic => { type => "scalar" },
                    generated_sepa_debit => {
                      package => "Net::API::Stripe::Payment::Method",
                      type => "scalar_or_object",
                    },
                    generated_sepa_debit_mandate => { package => "Net::API::Stripe::Mandate", type => "scalar_or_object" },
                    iban_last4 => { type => "scalar" },
                    verified_name => { type => "scalar" },
                  },
                  type => "class",
                },
  sofort     => {
                  definition => {
                    bank_code => { type => "scalar" },
                    bank_name => { type => "scalar" },
                    bic => { type => "scalar" },
                    generated_sepa_debit => {
                      package => "Net::API::Stripe::Payment::Method",
                      type => "scalar_or_object",
                    },
                    generated_sepa_debit_mandate => { package => "Net::API::Stripe::Mandate", type => "scalar_or_object" },
                    iban_last4 => { type => "scalar" },
                    preferred_language => { type => "scalar" },
                    verified_name => { type => "scalar" },
                  },
                  type => "class",
                },
  type       => { type => "scalar" },
}, @_ ) ); }

sub setup_error { return( shift->_set_get_class( 'setup_error',
{
  code => { type => "scalar" },
  decline_code => { type => "scalar" },
  doc_url => { type => "scalar" },
  message => { type => "scalar" },
  param => { type => "scalar" },
  payment_method => { package => "Net::API::Stripe::Payment::Method", type => "object" },
  payment_method_type => { type => "scalar" },
  type => { type => "scalar" },
}, @_ ) ); }

sub setup_intent { return( shift->_set_get_scalar_or_object( 'setup_intent', 'Net::API::Stripe::Payment::Intent::Setup', @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub usage { return( shift->_set_get_scalar( 'usage', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::SetupAttempt - The SetupAttempt object

=head1 SYNOPSIS

    my $setup = $stripe->setup_attempt({
        ## Net::API::Stripe::Connect::Account
        application => $connect_account_object,
        created => '2020-11-17T12:15:20',
        ## Net::API::Stripe::Customer
        customer => $customer_id_or_object,
        livemode => $stripe->true,
        on_behalf_of => $account_object,
        payment_method => $stripe_pm_id,
        payment_method_details => $hash,
        setup_error => $hash,
        ## Net::API::Stripe::Payment::Intent::Setup
        setup_intent => $intent_id_or_object,
        status => 'succeeded',
        usage => 'off_session',
    });

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

A SetupAttempt describes one attempted confirmation of a SetupIntent, whether that confirmation was successful or unsuccessful. You can use SetupAttempts to inspect details of a specific attempt at setting up a payment method using a SetupIntent.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string

String representing the object's type. Objects of the same type share the same value.

=head2 application expandable

The value of L<application|https://stripe.com/docs/api/setup_intents/object#setup_intent_object-application> on the SetupIntent at the time of this confirmation.

When expanded this is an L<Net::API::Stripe::Connect::Account> object.

=head2 attach_to_self boolean

If present, the SetupIntent's payment method will be attached to the in-context Stripe Account.

It can only be used for this Stripe Account’s own money movement flows like InboundTransfer and OutboundTransfers. It cannot be set to true when setting up a PaymentMethod for a Customer, and defaults to false when attaching a PaymentMethod to a Customer.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 customer expandable

The value of L<customer|https://stripe.com/docs/api/setup_intents/object#setup_intent_object-customer> on the SetupIntent at the time of this confirmation.

When expanded this is an L<Net::API::Stripe::Customer> object.

=head2 flow_directions array

Indicates the directions of money movement for which this payment method is intended to be used.

Include C<inbound> if you intend to use the payment method as the origin to pull funds from. Include C<outbound> if you intend to use the payment method as the destination to send funds to. You can include both if you intend to use the payment method for both purposes.

=head2 livemode boolean

Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.

=head2 on_behalf_of expandable

The value of L<on_behalf_of|https://stripe.com/docs/api/setup_intents/object#setup_intent_object-on_behalf_of> on the SetupIntent at the time of this confirmation.

When expanded this is an L<Net::API::Stripe::Connect::Account> object.

=head2 payment_method expandable

ID of the payment method used with this SetupAttempt.

When expanded this is an L<Net::API::Stripe::Payment::Method> object.

=head2 payment_method_details hash

Details about the payment method at the time of SetupIntent confirmation.

It has the following properties:

=over 4

=item I<bancontact> hash

If this is a C<bancontact> payment method, this hash contains confirmation-specific information for the C<bancontact> payment method.

=over 8

=item I<bank_code> string

Bank code of bank associated with the bank account.

=item I<bank_name> string

Name of the bank associated with the bank account.

=item I<bic> string

Bank Identifier Code of the bank associated with the bank account.

=item I<generated_sepa_debit> string expandable

The ID of the SEPA Direct Debit PaymentMethod which was generated by this SetupAttempt.

When expanded this is an L<Net::API::Stripe::Payment::Method> object.

=item I<generated_sepa_debit_mandate> string expandable

The mandate for the SEPA Direct Debit PaymentMethod which was generated by this SetupAttempt.

When expanded this is an L<Net::API::Stripe::Mandate> object.

=item I<iban_last4> string

Last four characters of the IBAN.

=item I<preferred_language> string

Preferred language of the Bancontact authorization page that the customer is redirected to.
Can be one of C<en>, C<de>, C<fr>, or C<nl>

=item I<verified_name> string

Owner's verified full name. Values are verified or provided by Bancontact directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.

=back

=item I<card> hash

If this is a C<card> payment method, this hash contains confirmation-specific information for the C<card> payment method.

=over 8

=item I<three_d_secure> hash

Populated if this authorization used 3D Secure authentication.

=over 12

=item I<authentication_flow> string

For authenticated transactions: how the customer was authenticated by the issuing bank.

=item I<result> string

Indicates the outcome of 3D Secure authentication.

=item I<result_reason> string

Additional information about why 3D Secure succeeded or failed based on the `result`.

=item I<version> string

The version of 3D Secure that was used.

=back

=back

=item I<ideal> hash

If this is a C<ideal> payment method, this hash contains confirmation-specific information for the C<ideal> payment method.

=over 8

=item I<bank> string

The customer's bank. Can be one of C<abn_amro>, C<asn_bank>, C<bunq>, C<handelsbanken>, C<ing>, C<knab>, C<moneyou>, C<rabobank>, C<regiobank>, C<sns_bank>, C<triodos_bank>, or C<van_lanschot>.

=item I<bic> string

The Bank Identifier Code of the customer's bank.

=item I<generated_sepa_debit> string expandable

The ID of the SEPA Direct Debit PaymentMethod which was generated by this SetupAttempt.

When expanded this is an L<Net::API::Stripe::Payment::Method> object.

=item I<generated_sepa_debit_mandate> string expandable

The mandate for the SEPA Direct Debit PaymentMethod which was generated by this SetupAttempt.

When expanded this is an L<Net::API::Stripe::Mandate> object.

=item I<iban_last4> string

Last four characters of the IBAN.

=item I<verified_name> string

Owner's verified full name. Values are verified or provided by iDEAL directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.

=back

=item I<sofort> hash

If this is a C<sofort> payment method, this hash contains confirmation-specific information for the C<sofort> payment method.

=over 8

=item I<bank_code> string

Bank code of bank associated with the bank account.

=item I<bank_name> string

Name of the bank associated with the bank account.

=item I<bic> string

Bank Identifier Code of the bank associated with the bank account.

=item I<generated_sepa_debit> string expandable

The ID of the SEPA Direct Debit PaymentMethod which was generated by this SetupAttempt.

When expanded this is an L<Net::API::Stripe::Payment::Method> object.

=item I<generated_sepa_debit_mandate> string expandable

The mandate for the SEPA Direct Debit PaymentMethod which was generated by this SetupAttempt.

When expanded this is an L<Net::API::Stripe::Mandate> object.

=item I<iban_last4> string

Last four characters of the IBAN.

=item I<preferred_language> string

Preferred language of the Sofort authorization page that the customer is redirected to.
Can be one of C<en>, C<de>, C<fr>, or C<nl>

=item I<verified_name> string

Owner's verified full name. Values are verified or provided by Sofort directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.

=back

=item I<type> string

The type of the payment method used in the SetupIntent (e.g., C<card>). An additional hash is included on C<payment_method_details> with a name matching this value. It contains confirmation-specific information for the payment method.

=back

=head2 setup_error hash

The error encountered during this attempt to confirm the SetupIntent, if any.

It has the following properties:

=over 4

=item I<code> string

For some errors that could be handled programmatically, a short string indicating the [error code](/docs/error-codes) reported.

=item I<decline_code> string

For card errors resulting from a card issuer decline, a short string indicating the L<card issuer's reason for the decline|https://stripe.com/docs/declines#issuer-declines> if they provide one.

=item I<doc_url> string

A URL to more information about the L<error code|https://stripe.com/docs/error-codes> reported.

=item I<message> string

A human-readable message providing more details about the error. For card errors, these messages can be shown to your users.

=item I<param> string

If the error is parameter-specific, the parameter related to the error. For example, you can use this to display a message near the correct form field.

=item I<payment_method> hash

The PaymentMethod object for errors returned on a request involving a PaymentMethod.

When expanded, this is a L<Net::API::Stripe::Payment::Method> object.

=item I<payment_method_type> string

If the error is specific to the type of payment method, the payment method type that had a problem. This field is only populated for invoice-related errors.

=item I<type> string

The type of error returned. One of C<api_connection_error>, C<api_error>, C<authentication_error>, C<card_error>, C<idempotency_error>, C<invalid_request_error>, or C<rate_limit_error>

=back

=head2 setup_intent expandable

ID of the SetupIntent that this attempt belongs to.

When expanded this is an L<Net::API::Stripe::Payment::Intent::Setup> object.

=head2 status string

Status of this SetupAttempt, one of C<requires_confirmation>, C<requires_action>, C<processing>, C<succeeded>, C<failed>, or C<abandoned>.

=head2 usage string

The value of L<usage|https://stripe.com/docs/api/setup_intents/object#setup_intent_object-usage> on the SetupIntent at the time of this confirmation, one of C<off_session> or C<on_session>.

=head1 API SAMPLE

    {
      "id": "setatt_1ErTsH2eZvKYlo2CI7ukcoF7",
      "object": "setup_attempt",
      "application": null,
      "created": 1562004309,
      "customer": null,
      "livemode": false,
      "on_behalf_of": null,
      "payment_method": "pm_1ErTsG2eZvKYlo2CH0DNen59",
      "payment_method_details": {
        "card": {
          "three_d_secure": null
        },
        "type": "card"
      },
      "setup_error": null,
      "setup_intent": "seti_1ErTsG2eZvKYlo2CKaT8MITz",
      "status": "succeeded",
      "usage": "off_session"
    }

=head1 HISTORY

=head2 v0.1.0

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api#setup_attempt_object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
