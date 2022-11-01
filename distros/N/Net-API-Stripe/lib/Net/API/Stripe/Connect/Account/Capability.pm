##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Connect/Account/Capability.pm
## Version v0.101.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2022/10/29
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Connect::Account::Capability;
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

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub account { return( shift->_set_get_scalar_or_object( 'account', 'Net::API::Stripe::Connect::Account', @_ ) ); }

sub future_requirements { return( shift->_set_get_object( 'future_requirements', 'Net::API::Stripe::Connect::Account::Requirements', @_ ) ); }

sub requested { return( shift->_set_get_boolean( 'requested', @_ ) ); }

sub requested_at { return( shift->_set_get_datetime( 'requested_at', @_ ) ); }

sub requirements { return( shift->_set_get_object( 'requirements', 'Net::API::Stripe::Connect::Account::Requirements', @_ ) ); }

## active, inactive, pending, or unrequested.

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Connect::Account::Capability - A Stripe Account Capability Object

=head1 SYNOPSIS

    my $capa = $stripe->=capability({
        account => $account_object,
        requested => $stripe->true,
        requested_at => '2020-04-01',
        status => 'active',
    });

=head1 VERSION

    v0.101.0

=head1 DESCRIPTION

A hash containing the set of capabilities that was requested for this account and their associated states. Keys are names of capabilities. You can see the full list here (L<https://stripe.com/docs/api/capabilities/list>). Values may be I<active>, I<inactive>, or I<pending>.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Connect::Account::Capability> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 id string

The identifier for the capability.

=head2 object string, value is "capability"

String representing the object’s type. Objects of the same type share the same value.

=head2 account string (expandable)

The account for which the capability enables functionality.

When expanded, this is a L<Net::API::Stripe::Connect::Account> object.

=head2 future_requirements object

Information about the upcoming new requirements for the capability, including what information needs to be collected, and by when.

This is a L<Net::API::Stripe::Connect::Account::Requirements> object.

=head2 requested boolean

Whether the capability has been requested.

=head2 requested_at timestamp

Time at which the capability was requested. Measured in seconds since the Unix epoch.

=head2 requirements hash

Information about the requirements for the capability, including what information needs to be collected, and by when.

This is a L<Net::API::Stripe::Connect::Account::Requirements> object.

=head2 status string

The status of the capability. Can be active, inactive, pending, or unrequested.

=head1 API SAMPLE

    {
      "id": "card_payments",
      "object": "capability",
      "account": "acct_fake123456789",
      "requested": true,
      "requested_at": 1571480455,
      "requirements": {
        "current_deadline": null,
        "currently_due": [],
        "disabled_reason": null,
        "eventually_due": [],
        "past_due": [],
        "pending_verification": []
      },
      "status": "active"
    }
=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/accounts/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
