##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Payment/Source/Receiver.pm
## Version 0.1
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2019/11/02
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Payment::Source::Receiver;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub address { shift->_set_get_scalar( 'address', @_ ); }

sub amount_charged { shift->_set_get_number( 'amount_charged', @_ ); }

sub amount_received { shift->_set_get_number( 'amount_received', @_ ); }

sub amount_returned { shift->_set_get_number( 'amount_returned', @_ ); }

sub refund_attributes_method { shift->_set_get_scalar( 'refund_attributes_method', @_ ); }

sub refund_attributes_status { shift->_set_get_scalar( 'refund_attributes_status', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Payment::Source::Receiver - A Stripe Payment Receiver Object

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

Information related to the receiver flow. Present if the source is a receiver (flow is receiver).

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new C<Net::API::Stripe> objects.
It may also take an hash like arguments, that also are method of the same name.

=over 8

=item I<verbose>

Toggles verbose mode on/off

=item I<debug>

Toggles debug mode on/off

=back

=head1 METHODS

=over 4

=item B<address> string

The address of the receiver source. This is the value that should be communicated to the customer to send their funds to.

=item B<amount_charged> integer

The total amount that was charged by you. The amount charged is expressed in the source’s currency.

=item B<amount_received> integer

The total amount received by the receiver source. amount_received = amount_returned + amount_charged is true at all time. The amount received is expressed in the source’s currency.

=item B<amount_returned> integer

The total amount that was returned to the customer. The amount returned is expressed in the source’s currency.

=item B<refund_attributes_method> string

Type of refund attribute method, one of email, manual, or none.

=item B<refund_attributes_status> string

Type of refund attribute status, one of missing, requested, or available.

=back

=head1 API SAMPLE

	{
	  "id": "src_1FUXrFCeyNCl6fY2Fk07erzD",
	  "object": "source",
	  "ach_credit_transfer": {
		"account_number": "test_52796e3294dc",
		"routing_number": "110000000",
		"fingerprint": "ecpwEzmBOSMOqQTL",
		"bank_name": "TEST BANK",
		"swift_code": "TSTEZ122"
	  },
	  "amount": null,
	  "client_secret": "src_client_secret_G0YzRXUMP1IJhwBBA4dW38It",
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

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
