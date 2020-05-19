##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Connect/Account/Capability.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Connect::Account::Capability;
BEGIN
{
	use strict;
	use parent qw( Net::API::Stripe::Generic );
	our( $VERSION ) = 'v0.100.0';
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub account { return( shift->_set_get_scalar_or_object( 'account', 'Net::API::Stripe::Connect::Account', @_ ) ); }

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

    v0.100.0

=head1 DESCRIPTION

A hash containing the set of capabilities that was requested for this account and their associated states. Keys are names of capabilities. You can see the full list here (L<https://stripe.com/docs/api/capabilities/list>). Values may be I<active>, I<inactive>, or I<pending>.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Connect::Account::Capability> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<id> string

The identifier for the capability.

=item B<object> string, value is "capability"

String representing the object’s type. Objects of the same type share the same value.

=item B<account> string (expandable)

The account for which the capability enables functionality.

When expanded, this is a L<Net::API::Stripe::Connect::Account> object.

=item B<requested> boolean

Whether the capability has been requested.

=item B<requested_at> timestamp

Time at which the capability was requested. Measured in seconds since the Unix epoch.

=item B<requirements> hash

Information about the requirements for the capability, including what information needs to be collected, and by when.

This is a L<Net::API::Stripe::Connect::Account::Requirements> object.

=item B<status> string

The status of the capability. Can be active, inactive, pending, or unrequested.

=back

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
