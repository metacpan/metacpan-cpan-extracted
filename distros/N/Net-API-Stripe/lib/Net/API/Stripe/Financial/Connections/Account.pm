##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Financial/Connections/Account.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/10/29
## Modified 2022/10/29
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Financial::Connections::Account;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = 'v0.1.0';
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub account_holder { return( shift->_set_get_object( 'account_holder', 'Net::API::Stripe::Payment::Source', @_ ) ); }

sub balance { return( shift->_set_get_class( 'balance',
{
  as_of   => { type => "datetime" },
  cash    => { package => "Net::API::Stripe::Balance", type => "object" },
  credit  => { package => "Net::API::Stripe::Payment::Source", type => "object" },
  current => { type => "hash" },
  type    => { type => "scalar" },
}, @_ ) ); }

sub balance_refresh { return( shift->_set_get_class( 'balance_refresh',
{
  last_attempted_at => { type => "datetime" },
  status => { type => "scalar" },
}, @_ ) ); }

sub category { return( shift->_set_get_scalar( 'category', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub display_name { return( shift->_set_get_scalar( 'display_name', @_ ) ); }

sub institution_name { return( shift->_set_get_scalar( 'institution_name', @_ ) ); }

sub last4 { return( shift->_set_get_scalar( 'last4', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub ownership { return( shift->_set_get_scalar_or_object( 'ownership', 'Net::API::Stripe::Financial::Connections::AccountOwnership', @_ ) ); }

sub ownership_refresh { return( shift->_set_get_class( 'ownership_refresh',
{
  last_attempted_at => { type => "datetime" },
  status => { type => "scalar" },
}, @_ ) ); }

sub permissions { return( shift->_set_get_array( 'permissions', @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub subcategory { return( shift->_set_get_scalar( 'subcategory', @_ ) ); }

sub supported_payment_method_types { return( shift->_set_get_array( 'supported_payment_method_types', @_ ) ); }

sub transaction_refresh { return( shift->_set_get_object( 'transaction_refresh', 'Net::API::Stripe::Balance::Transaction', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Financial::Connections::Account - The Account object

=head1 SYNOPSIS

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

A Financial Connections Account represents an account that exists outside of Stripe, to which you have been granted some degree of access.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string

String representing the object's type. Objects of the same type share the same value.

=head2 account_holder object

The account holder that this account belongs to.

This is a L<Net::API::Stripe::Payment::Source> object.

=head2 balance hash

The most recent information about the account's balance.

It has the following properties:

=over 4

=item C<as_of> timestamp

The time that the external institution calculated this balance. Measured in seconds since the Unix epoch.

=item C<cash> hash

Information on a C<cash> balance. Only set if C<balance.type> is C<cash>.

When expanded, this is a L<Net::API::Stripe::Balance> object.

=item C<credit> hash

Information on a C<credit> balance. Only set if C<balance.type> is C<credit>.

When expanded, this is a L<Net::API::Stripe::Payment::Source> object.

=item C<current> hash

The balances owed to (or by) the account holder.

Each key is a three-letter L<ISO currency code|https://www.iso.org/iso-4217-currency-codes.html>, in lowercase.

Each value is a integer amount. A positive amount indicates money owed to the account holder. A negative amount indicates money owed by the account holder.

=item C<type> string

The C<type> of the balance. An additional hash is included on the balance with a name matching this value.

=back

=head2 balance_refresh hash

The state of the most recent attempt to refresh the account balance.

It has the following properties:

=over 4

=item C<last_attempted_at> timestamp

The time at which the last refresh attempt was initiated. Measured in seconds since the Unix epoch.

=item C<status> string

The status of the last refresh attempt.

=back

=head2 category string

The type of the account. Account category is further divided in C<subcategory>.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 display_name string

A human-readable name that has been assigned to this account, either by the account holder or by the institution.

=head2 institution_name string

The name of the institution that holds this account.

=head2 last4 string

The last 4 digits of the account number. If present, this will be 4 numeric characters.

=head2 livemode boolean

Has the value C<true> if the object exists in live mode or the value C<false> if the object exists in test mode.

=head2 ownership expandable

The most recent information about the account's owners.

When expanded this is an L<Net::API::Stripe::Financial::Connections::AccountOwnership> object.

=head2 ownership_refresh hash

The state of the most recent attempt to refresh the account owners.

It has the following properties:

=over 4

=item C<last_attempted_at> timestamp

The time at which the last refresh attempt was initiated. Measured in seconds since the Unix epoch.

=item C<status> string

The status of the last refresh attempt.

=back

=head2 permissions array

The list of permissions granted by this account.

=head2 status string

The status of the link to the account.

=head2 subcategory string

If C<category> is C<cash>, one of:

=over 4

=item - C<checking>

=item - C<savings>

=item - C<other>

=back

If C<category> is C<credit>, one of:

=over 4

=item - C<mortgage>

=item - C<line_of_credit>

=item - C<credit_card>

=item - C<other>

=back

If C<category> is C<investment> or C<other>, this will be C<other>.

=head2 supported_payment_method_types array

The L<PaymentMethod type|https://stripe.com/docs/api/payment_methods/object#payment_method_object-type>(s) that can be created from this account.

=head2 transaction_refresh object

The state of the most recent attempt to refresh the account transactions.

This is a L<Net::API::Stripe::Balance::Transaction> object.

=head1 API SAMPLE

[
   {
      "accountholder" : {
         "customer" : "cus_AJ78ZaALpqgiuZ",
         "type" : "customer"
      },
      "balance" : null,
      "balance_refresh" : null,
      "category" : "cash",
      "created" : "1662261086",
      "display_name" : "Sample Checking Account",
      "id" : "fca_1Le9F42eZvKYlo2Cboplw3LC",
      "institution_name" : "StripeBank",
      "last4" : "6789",
      "livemode" : 0,
      "object" : "linked_account",
      "ownership" : null,
      "ownership_refresh" : null,
      "permissions" : [],
      "status" : "active",
      "subcategory" : "checking",
      "supported_payment_method_types" : [
         "us_bank_account"
      ],
      "transaction_refresh" : null
   }
]

=head1 HISTORY

=head2 v0.1.0

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Stripe API documentation|https://stripe.com/docs/api/financial_connections/accounts>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2022 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
