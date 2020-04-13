##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Payment/Source/Redirect.pm
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
package Net::API::Stripe::Payment::Source::Redirect;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub failure_reason { return( shift->_set_get_scalar( 'failure_reason', @_ ) ); }

sub return_url { return( shift->_set_get_uri( 'return_url', @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub url { return( shift->_set_get_uri( 'url', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Payment::Source::Redirect - A Stripe Payment Redirect

=head1 SYNOPSIS

    my $redirect = $stripe->source->redirect({
        failure_reason => 'user_abort',
        return_url => 'https://example.com/return',
        status => 'failed',
        url => 'https://example.com/auth',
    });

=head1 VERSION

    0.1

=head1 DESCRIPTION

Information related to the redirect flow. Present if the source is authenticated by a redirect (flow is redirect).

This is part of the L<Net::API::Stripe::Payment::Source> object

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Payment::Source::Redirect> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<failure_reason> string

The failure reason for the redirect, either user_abort (the customer aborted or dropped out of the redirect flow), declined (the authentication failed or the transaction was declined), or processing_error (the redirect failed due to a technical error). Present only if the redirect status is failed.

=item B<return_url> string

The URL you provide to redirect the customer to after they authenticated their payment.

This is a L<URI> object.

=item B<status> string

The status of the redirect, either pending (ready to be used by your customer to authenticate the transaction), succeeded (succesful authentication, cannot be reused) or not_required (redirect should not be used) or failed (failed authentication, cannot be reused).

=item B<url> string

The URL provided to you to redirect a customer to as part of a redirect authentication flow.

This is a L<URI> object.

=back

=head1 API SAMPLE

	{
	  "id": "src_fake123456789",
	  "object": "source",
	  "ach_credit_transfer": {
		"account_number": "test_52796e3294dc",
		"routing_number": "110000000",
		"fingerprint": "ecpwEzmBOSMOqQTL",
		"bank_name": "TEST BANK",
		"swift_code": "TSTEZ122"
	  },
	  "amount": null,
	  "client_secret": "src_client_secret_fake123456789",
	  "created": 1571314413,
	  "currency": "jpy",
	  "flow": "receiver",
	  "livemode": false,
	  "metadata": {},
	  "owner": {
		"address": null,
		"email": "jenny.rosen@example.com",
		"name": null,
		"phone": null,
		"verified_address": null,
		"verified_email": null,
		"verified_name": null,
		"verified_phone": null
	  },
	  "receiver": {
		"address": "121042882-38381234567890123",
		"amount_charged": 0,
		"amount_received": 0,
		"amount_returned": 0,
		"refund_attributes_method": "email",
		"refund_attributes_status": "missing"
	  },
	  "statement_descriptor": null,
	  "status": "pending",
	  "type": "ach_credit_transfer",
	  "usage": "reusable"
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/sources/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
