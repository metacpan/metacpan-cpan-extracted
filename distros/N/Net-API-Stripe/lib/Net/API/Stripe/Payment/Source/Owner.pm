##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Payment/Source/Owner.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Payment::Source::Owner;
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

sub address { return( shift->_set_get_object( 'address', 'Net::API::Stripe::Address', @_ ) ); }

sub email { return( shift->_set_get_scalar( 'email', @_ ) ); }

sub name { return( shift->_set_get_scalar( 'name', @_ ) ); }

sub phone { return( shift->_set_get_scalar( 'phone', @_ ) ); }

sub verified_address { return( shift->_set_get_object( 'verified_address', 'Net::API::Stripe::Address', @_ ) ); }

sub verified_email { return( shift->_set_get_scalar( 'verified_email', @_ ) ); }

sub verified_name { return( shift->_set_get_scalar( 'verified_name', @_ ) ); }

sub verified_phone { return( shift->_set_get_scalar( 'verified_phone', @_ ) ); }

sub receiver { return( shift->_set_get_object( 'receiver', 'Net::API::Stripe::Payment::Source::Receiver', @_ ) ); }

sub redirect { return( shift->_set_get_object( 'redirect', 'Net::API::Stripe::Payment::Source::Redirect', @_ ) ); }

sub statement_descriptor { return( shift->_set_get_scalar( 'statement_descriptor', @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

sub usage { return( shift->_set_get_scalar( 'usage', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Payment::Source::Owner - A Stripe Payment Source Owner Object

=head1 SYNOPSIS

    my $owner = $stripe->source->owner({
        address => $address_object,
        email => 'john.doe@example.com',
        name => 'john.doe@example.com',
        phone => '+81-(0)90-1234-5678',
    });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

Information about the owner of the payment instrument that may be used or required by particular source types.

This is part of the L<Net::API::Stripe::Payment::Source> object

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Payment::Source::Owner> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 address hash

Owner’s address.

This is a L<Net::API::Stripe::Address> object.

=head2 email string

Owner’s email address.

=head2 name string

Owner’s full name.

=head2 phone string

Owner’s phone number (including extension).

=head2 receiver obsolete?

This is a L<Net::API::Stripe::Payment::Source::Receiver> object, but it seems it was removed from the documentation.

=head2 redirect obsolete?

This is a L<Net::API::Stripe::Payment::Source::Redirect> object, but it seems it was removed from the documentation.

=head2 verified_address hash

Verified owner’s address. Verified values are verified or provided by the payment method directly (and if supported) at the time of authorization or settlement. They cannot be set or mutated.

This is a L<Net::API::Stripe::Address> object.

=head2 verified_email string

Verified owner’s email address. Verified values are verified or provided by the payment method directly (and if supported) at the time of authorization or settlement. They cannot be set or mutated.

=head2 verified_name string

Verified owner’s full name. Verified values are verified or provided by the payment method directly (and if supported) at the time of authorization or settlement. They cannot be set or mutated.

=head2 verified_phone string

Verified owner’s phone number (including extension). Verified values are verified or provided by the payment method directly (and if supported) at the time of authorization or settlement. They cannot be set or mutated.

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
