##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Error.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Error;
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

sub charge { return( shift->_set_get_scalar( 'charge', @_ ) ); }

sub code { return( shift->_set_get_scalar( 'code', @_ ) ); }

sub decline_code { return( shift->_set_get_scalar( 'decline_code', @_ ) ); }

sub doc_url { return( shift->_set_get_uri( 'doc_url', @_ ) ); }

sub message { return( shift->_set_get_scalar( 'message', @_ ) ); }

sub param { return( shift->_set_get_scalar( 'param', @_ ) ); }

sub payment_intent { return( shift->_set_get_object( 'payment_intent', 'Net::API::Stripe::Payment::Intent', @_ ) ); }

sub payment_method { return( shift->_set_get_object( 'payment_method', 'Net::API::Stripe::Payment::Method', @_ ) ); }

sub payment_method_type { return( shift->_set_get_scalar( 'payment_method_type', @_ ) ); }

sub setup_intent { return( shift->_set_get_object( 'setup_intent', 'Net::API::Stripe::Payment::Intent::Setup', @_ ) ); }

sub source { return( shift->_set_get_object( 'source', 'Net::API::Stripe::Payment::Source', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Error - A Stripe Error Object

=head1 SYNOPSIS

    my $err = $stripe->payment_intent->last_payment_error({
        type => 'card_error',
        charge => 'ch_fake1234567890',
        code => 402,
        doc_url => 'https://stripe.com/docs/api/errors',
        message => 'Some human readable message',
        payment_intent => $payment_intent_object,
        source => $source_object,
    });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

This is a Stripe Error object instantiated by method B<last_setup_error> in module L<Net::API::Stripe::Payment::Intent::Setup>, and method B<last_payment_error> in module L<Net::API::Stripe::Payment::Intent>

This is different from the error generated elsewhere in L<Net::API::Stripe>

=head1 CONSTRUCTOR

=head2 new

Creates a new L<Net::API::Stripe::Error> object.

It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 type string

The type of error returned. One of api_connection_error, api_error, authentication_error, card_error, idempotency_error, invalid_request_error, or rate_limit_error

=head2 charge string

For card errors, the ID of the failed charge. Not always present. Exists in L<Net::API::Stripe::Payment::Intent>, but not in L<Net::API::Stripe::Payment::Intent::Setup>

=head2 code string

For some errors that could be handled programmatically, a short string indicating the error code reported.

=head2 decline_code string

For card errors resulting from a card issuer decline, a short string indicating the card issuer’s reason for the decline if they provide one.

=head2 doc_url string

A URL to more information about the error code reported. This is a C<URI> object.

=head2 message string

A human-readable message providing more details about the error. For card errors, these messages can be shown to your users.

=head2 param string

If the error is parameter-specific, the parameter related to the error. For example, you can use this to display a message near the correct form field.

=head2 payment_intent hash

The PaymentIntent object for errors returned on a request involving a PaymentIntent.

When set, this is a L<Net::API::Stripe::Payment::Intent> object.

=head2 payment_method hash

The PaymentMethod object for errors returned on a request involving a PaymentMethod.

When set, this is a L<Net::API::Stripe::Payment::Method> object.

=head2 payment_method_type string

If the error is specific to the type of payment method, the payment method type that had a problem. This field is only populated for invoice-related errors.

=head2 setup_intent hash

The SetupIntent object for errors returned on a request involving a SetupIntent.

When set, this is a L<Net::API::Stripe::Payment::Intent::Setup> object.

=head2 source hash

The source object for errors returned on a request involving a source.

When set this is a L<Net::API::Stripe::Payment::Source> object.

=head2 type string

The type of error returned. One of C<api_connection_error>, C<api_error>, C<authentication_error>, C<card_error>, C<idempotency_error>, C<invalid_request_error>, or C<rate_limit_error>

=head1 HISTORY

=head2 v0.100.0

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/errors>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut

