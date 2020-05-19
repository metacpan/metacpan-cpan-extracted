##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Issuing/Authorization/VerificationData.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Issuing::Authorization::VerificationData;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = 'v0.100.0';
};

sub address_line1_check { return( shift->_set_get_scalar( 'address_line1_check', @_ ) ); }

sub address_postal_code_check { return( shift->_set_get_scalar( 'address_postal_code_check', @_ ) ); }

sub address_zip_check { return( shift->_set_get_scalar( 'address_zip_check', @_ ) ); }

sub authentication { return( shift->_set_get_scalar( 'authentication', @_ ) ); }

sub cvc_check { return( shift->_set_get_scalar( 'cvc_check', @_ ) ); }

sub expiry_check { return( shift->_set_get_scalar( 'expiry_check', @_ ) ); }

sub three_d_secure { return( shift->_set_get_hash( 'three_d_secure', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Issuing::Authorization::VerificationData - A Stripe Authorization Verification Date Object

=head1 SYNOPSIS

    my $data = $stripe->authorization->verification_data({
        address_line1_check => 'match',
        address_postal_code_check => 'match',
        address_zip_check => 'match',
        authentication => 'success',
        cvc_check => 'match',
        expiry_check => 'match',
        three_d_secure => { result => 'authenticated' },
    });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

Verification data used by method B<verification_data> in module L<Net::API::Stripe::Issuing::Authorization>

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Issuing::Authorization::VerificationData> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<address_line1_check> string

One of match, mismatch, or not_provided.

=item B<address_postal_code_check>

Whether the cardholder provided a postal code and if it matched the cardholder’s billing.address.postal_code.

Possible enum values

=over 4

=item I<match>

Verification succeeded, values matched.

=item I<mismatch>

Verification failed, values didn’t match.

=item I<not_provided>

Verification was not performed because no value was provided.

=back

=item B<address_zip_check> string

One of match, mismatch, or not_provided.

=item B<authentication> string

One of success, failure, exempt, or none.

=item B<cvc_check> string

One of match, mismatch, or not_provided.

=item B<expiry_check>

Whether the cardholder provided an expiry date and if it matched Stripe’s record.

Possible enum values

=over 4

=item I<match>

Verification succeeded, values matched.

=item I<mismatch>

Verification failed, values didn’t match.

=item I<not_provided>

Verification was not performed because no value was provided.

=back

=item B<three_d_secure> hash

3D Secure details on this authorization.

It has the one following property

=over 8

=item I<result>

With following possible enum values

=over 12

=item I<authenticated>

Authentication successful.

=item I<failed>

Authentication failed.

=item I<attempt_acknowledged>

The merchant attempted to authenticate the authorization, but the cardholder is not enrolled or was unable to reach Stripe. 

=back

=back

=back

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

L<https://stripe.com/docs/api/issuing/authorizations/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
