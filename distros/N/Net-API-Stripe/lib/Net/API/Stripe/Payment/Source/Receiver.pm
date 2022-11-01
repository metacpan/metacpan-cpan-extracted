##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Payment/Source/Receiver.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Payment::Source::Receiver;
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

sub address { return( shift->_set_get_scalar( 'address', @_ ) ); }

sub amount_charged { return( shift->_set_get_number( 'amount_charged', @_ ) ); }

sub amount_received { return( shift->_set_get_number( 'amount_received', @_ ) ); }

sub amount_returned { return( shift->_set_get_number( 'amount_returned', @_ ) ); }

sub refund_attributes_method { return( shift->_set_get_scalar( 'refund_attributes_method', @_ ) ); }

sub refund_attributes_status { return( shift->_set_get_scalar( 'refund_attributes_status', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Payment::Source::Receiver - A Stripe Payment Receiver Object

=head1 SYNOPSIS

    my $rcv = $stripe->source->receiver({
        address => '1-2-3 Kudan-Minami, Chiyoda-ku, Tokyo 123-4567 Japan',
        amount_charged => 2000,
    });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

Information related to the receiver flow. Present if the source is a receiver (flow is receiver).

This is part of the L<Net::API::Stripe::Payment::Source> object

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Payment::Source::Receiver> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 address string

The address of the receiver source. This is the value that should be communicated to the customer to send their funds to.

=head2 amount_charged integer

The total amount that was charged by you. The amount charged is expressed in the source’s currency.

=head2 amount_received integer

The total amount received by the receiver source. amount_received = amount_returned + amount_charged is true at all time. The amount received is expressed in the source’s currency.

=head2 amount_returned integer

The total amount that was returned to the customer. The amount returned is expressed in the source’s currency.

=head2 refund_attributes_method string

Type of refund attribute method, one of email, manual, or none.

=head2 refund_attributes_status string

Type of refund attribute status, one of missing, requested, or available.

=head1 API SAMPLE

    {
      "id": "src_fake123456789",
      "object": "source",
      "ach_credit_transfer": {
        "account_number": "test_52796e3294dc",
        "routing_number": "110000000",
        "fingerprint": "avmabmnabvmnvb",
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
