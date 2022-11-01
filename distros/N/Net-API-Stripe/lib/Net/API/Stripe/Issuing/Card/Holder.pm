##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Issuing/Card/Holder.pm
## Version v0.200.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/issuing/cardholders/object
package Net::API::Stripe::Issuing::Card::Holder;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.200.0';
};

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub authorization_controls { return( shift->_set_get_object( 'authorization_controls', 'Net::API::Stripe::Issuing::Card::AuthorizationsControl', @_ ) ); }

sub billing { return( shift->_set_get_object( 'billing', 'Net::API::Stripe::Billing::Details', @_ ) ); }

sub company { return( shift->_set_get_object( 'company', 'Net::API::Stripe::Connect::Account::Company', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub email { return( shift->_set_get_scalar( 'email', @_ ) ); }

sub individual { return( shift->_set_get_object( 'individual', 'Net::API::Stripe::Connect::Person', @_ ) ); }

sub is_default { return( shift->_set_get_boolean( 'is_default', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub name { return( shift->_set_get_scalar( 'name', @_ ) ); }

sub phone_number { return( shift->_set_get_scalar( 'phone_number', @_ ) ); }

sub requirements { return( shift->_set_get_object( 'requirements', 'Net::API::Stripe::Connect::Account::Requirements', @_ ) ); }

sub spending_controls
{
    return( shift->_set_get_class( 'spending_controls',
    {
    allowed_categories => { type => 'array' },
    blocked_categories => { type => 'array' },
    spending_limits => 
        {
        type => 'class', definition =>
            {
            amount => { type => 'number' },
            categories => { type => 'array' },
            interval => { type => 'scalar' },
            }
        },
    spending_limits_currency => { type => 'scalar' },
    }, @_ ) );
}

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Issuing::Card::Holder - A Stripe Card Holder Object

=head1 SYNOPSIS

    my $holder = $stripe->card_holder({
        authorization_controls => 
        {
            allowed_categories => [],
            blocked_categories => [],
            spending_limits => 
            [
                {
                amount => 2000000,
                categories => '',
                interval => 'monthly',
                },
                {
                amount => 200000,
                categories => '',
                interval => 'weekly',
                },
            ],
            spending_limits_currency => 'jpy',
        },
        billing => $billing_details_object,
        company => $account_company_object,
        created => '2020-04-12T07:30:10',
        email => 'john.doe@example.com',
        individual => $account_individual_object,
        is_default => $stripe->true,
        livemode => $stripe->false,
        name => 'John Doe',
        phone_number => '+81-(0)90-1234-5678',
        requirements => $account_requirements_object,
        status => 'active',
        type => 'individual',
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    v0.200.0

=head1 DESCRIPTION

An Issuing Cardholder object represents an individual or business entity who is issued (L<https://stripe.com/docs/issuing>) cards.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Issuing::Card::Holder> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is "issuing.cardholder"

String representing the object’s type. Objects of the same type share the same value.

=head2 authorization_controls hash

This is a L<Net::API::Stripe::Issuing::Card::AuthorizationsControl> object.

=head2 billing hash

The cardholder’s billing address.

This is a L<Net::API::Stripe::Billing::Details> object.

=head2 company hash preview feature

Additional information about a business_entity cardholder.

This is a L<Net::API::Stripe::Connect::Account::Company> object.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

This is a C<DateTime> object.

=head2 email string

The cardholder’s email address.

=head2 individual hash preview feature

Additional information about an individual cardholder.

This is a L<Net::API::Stripe::Connect::Person> object.

=head2 is_default boolean

Whether or not this cardholder is the default cardholder.

=head2 livemode boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=head2 metadata hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 name string

The cardholder’s name. This will be printed on cards issued to them.

=head2 phone_number string

The cardholder’s phone number.

=head2 requirements hash

Information about verification requirements for the cardholder, including what information needs to be collected.

This is a L<Net::API::Stripe::Connect::Account::Requirements> object.

=head2 spending_controls hash

This is a hash whose properties are accessible as a dynamic class methods

=over 4

=item I<amount> positive integer

Maximum amount allowed to spend per time interval.

=item I<categories> array

Array of strings containing categories on which to apply the spending limit. Leave this blank to limit all charges.

=item I<interval> enum

The time interval or event with which to apply this spending limit towards.

=over 8

=item I<per_authorization>

A maximum amount for each authorization.

=item I<daily>

A maximum within a day. A day start at midnight UTC.

=item I<weekly>

A maximum within a week. The first day of a week is Monday.

=item I<monthly>

A maximum within a month. Starts on the first of that month.

=item I<yearly>

A maximum amount within a year. Starts January 1st.

=item I<all_time>

A maximum amount for all transactions.

=back

=item I<spending_limits_currency> currency

Currency for the amounts within spending_limits. Locked to the currency of the card.

=back

=head2 status string

One of active, inactive, or blocked.

=head2 type string

One of individual or business_entity.

=head1 API SAMPLE

    {
      "id": "ich_fake123456789",
      "object": "issuing.cardholder",
      "authorization_controls": {
        "allowed_categories": [],
        "blocked_categories": [],
        "spending_limits": [],
        "spending_limits_currency": null
      },
      "billing": {
        "address": {
          "city": "Beverly Hills",
          "country": "US",
          "line1": "123 Fake St",
          "line2": "Apt 3",
          "postal_code": "90210",
          "state": "CA"
        },
        "name": "Jenny Rosen"
      },
      "company": null,
      "created": 1540111055,
      "email": "jenny@example.com",
      "individual": null,
      "is_default": false,
      "livemode": false,
      "metadata": {},
      "name": "Jenny Rosen",
      "phone_number": "+18008675309",
      "requirements": {
        "disabled_reason": null,
        "past_due": []
      },
      "status": "active",
      "type": "individual"
    }

=head1 HISTORY

=head2 v0.1

Initial version

=head2 v0.2

Added method L</"spending_controls"> that was added on Stripe api.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/issuing/cardholders>, L<https://stripe.com/docs/issuing/cards#create-cardholder>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
