##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Connect/ExternalAccount/Bank.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/external_account_bank_accounts/object
package Net::API::Stripe::Connect::ExternalAccount::Bank;
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

sub account { return( shift->_set_get_scalar_or_object( 'account', 'Net::API::Stripe::Connect::Account', @_ ) ); }

sub account_holder_name { return( shift->_set_get_scalar( 'account_holder_name', @_ ) ); }

sub account_holder_type { return( shift->_set_get_scalar( 'account_holder_type', @_ ) ); }

sub account_type { return( shift->_set_get_scalar( 'account_type', @_ ) ); }

sub available_payout_methods { return( shift->_set_get_array( 'available_payout_methods', @_ ) ); }

sub bank_name { return( shift->_set_get_scalar( 'bank_name', @_ ) ); }

sub country { return( shift->_set_get_scalar( 'country', @_ ) ); }

sub currency { return( shift->_set_get_scalar( 'currency', @_ ) ); }

sub customer { return( shift->_set_get_scalar_or_object( 'customer', 'Net::API::Stripe::Customer', @_ ) ); }

sub default_for_currency { return( shift->_set_get_boolean( 'default_for_currency', @_ ) ); }

sub fingerprint { return( shift->_set_get_scalar( 'fingerprint', @_ ) ); }

sub last4 { return( shift->_set_get_scalar( 'last4', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub routing_number { return( shift->_set_get_scalar( 'routing_number', @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Connect::ExternalAccount::Bank - A Stripe Bank Account Object

=head1 SYNOPSIS

    my $bank = $stripe->bank_account({
        account_holder_name => 'Big Corp, Inc',
        account_holder_type => 'company',
        bank_name => 'Big Bank, Corp'
        country => 'us',
        currency => 'usd',
        customer => $customer_object,
        default_for_currency => $stripe->true,
        fingerprint => 'kshfkjhfkjsjdla',
        last4 => 1234,
        metadata => { transaction_id => 2222 },
        routing_number => 123,
        status => 'new',
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects. For example:

    my $stripe = Net::API::Stripe->new( conf_file => 'settings.json' ) | die( Net::API::Stripe->error );
    my $stripe_bank = $stripe->bank_accounts( create =>
    {
    account => 'acct_fake123456789',
    external_account =>
        {
        object => 'bank_account',
        country => 'jp',
        currency => 'jpy',
        account_number => '012345678',
        },
    default_for_currency => $stripe->true,
    metadata => { transaction_id => 123, customer_id => 456 },
    }) || die( $stripe->error );

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

These External Accounts are transfer destinations on Account objects for Custom accounts (L<https://stripe.com/docs/connect/custom-accounts>). They can be bank accounts or debit cards.

Bank accounts (L<https://stripe.com/docs/api#customer_bank_account_object>) and debit cards (L<https://stripe.com/docs/api#card_object>) can also be used as payment sources on regular charges, and are documented in the links above.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Connect::ExternalAccount::Bank> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is "bank_account"

String representing the object’s type. Objects of the same type share the same value.

=head2 account string (expandable)

When expanded, this is a L<Net::API::Stripe::Connect::Account> object.

=head2 account_holder_name string

The name of the person or business that owns the bank account.

=head2 account_holder_type string

The type of entity that holds the account. This can be either individual or company.

=head2 account_type string

The bank account type. This can only be C<checking> or C<savings> in most countries. In Japan, this can only be C<futsu> or C<toza>.

=head2 available_payout_methods array

A set of available payout methods for this bank account. Only values from this set should be passed as the method when creating a payout.

=head2 bank_name string

Name of the bank associated with the routing number (e.g., WELLS FARGO).

=head2 country string

Two-letter ISO code representing the country the bank account is located in.

=head2 currency currency

Three-letter ISO code for the currency paid out to the bank account.

=head2 customer string (expandable)

When expanded, this is a L<Net::API::Stripe::Customer> object.

=head2 default_for_currency boolean

Whether this bank account is the default external account for its currency.

=head2 fingerprint string

Uniquely identifies this particular bank account. You can use this attribute to check whether two bank accounts are the same.

=head2 last4 string

The last four digits of the bank account number.

=head2 metadata hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 routing_number string

The routing transit number for the bank account.

=head2 status string

For bank accounts, possible values are C<new>, C<validated>, C<verified>, C<verification_failed>, or C<errored>. A bank account that hasn’t had any activity or validation performed is C<new>. If Stripe can determine that the bank account exists, its status will be C<validated>. Note that there often isn’t enough information to know (e.g., for smaller credit unions), and the validation is not always run. If customer bank account verification has succeeded, the bank account status will be C<verified>. If the verification failed for any reason, such as microdeposit failure, the status will be C<verification_failed>. If a transfer sent to this bank account fails, we’ll set the status to C<errored> and will not continue to send transfers until the bank details are updated.

For external accounts, possible values are C<new> and C<errored>. Validations aren’t run against external accounts because they’re only used for payouts. This means the other statuses don’t apply. If a transfer fails, the status is set to C<errored> and transfers are stopped until account details are updated.

=head1 API SAMPLE

    {
      "id": "ba_fake123456789",
      "object": "bank_account",
      "account": "acct_fake123456789",
      "account_holder_name": "Jane Austen",
      "account_holder_type": "individual",
      "bank_name": "STRIPE TEST BANK",
      "country": "US",
      "currency": "jpy",
      "fingerprint": "ksfkhfkjcchjkn",
      "last4": "6789",
      "metadata": {},
      "routing_number": "110000000",
      "status": "new"
    }

=head1 HISTORY

=head2 v0.1

Initial version

=head1 STRIPE HISTORY

=head2 2018-01-23

When being viewed by a platform, cards and bank accounts created on behalf of connected accounts will have a fingerprint that is universal across all connected accounts. For accounts that are not connect platforms, there will be no change.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/external_account_bank_accounts/object>, L<https://stripe.com/docs/connect/payouts>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
