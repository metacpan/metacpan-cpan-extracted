##----------------------------------------------------------------------------
## Stripe API - ~/lib/HTTP/Promise/Exception.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/10/18
## Modified 2022/10/18
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Exception;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic::Exception );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{charge}                 = undef;
    $self->{decline_code}           = undef;
    $self->{http_code}              = undef;
    $self->{http_headers}           = undef;
    $self->{param}                  = undef;
    $self->{payment_intent}         = undef;
    $self->{payment_method}         = undef;
    $self->{payment_method_type}    = undef;
    $self->{request_log_url}        = undef;
    $self->{setup_intent}           = undef;
    $self->{source}                 = undef;
    return( $self->SUPER::init( @_ ) );
}

sub charge { return( shift->_set_get_scalar_as_object( 'charge', @_ ) ); }

sub decline_code { return( shift->_set_get_scalar_as_object( 'decline_code', @_ ) ); }

sub doc_url { return( shift->_set_get_uri( 'doc_url', @_ ) ); }

sub http_code { return( shift->_set_get_number( 'http_code', @_ ) ); }

sub http_headers { return( shift->_set_get_object( 'http_headers', 'HTTP::Promise::Headers', @_ ) ); }

sub param { return( shift->_set_get_scalar_as_object( 'param', @_ ) ); }

sub payment_intent { return( shift->_set_get_object_without_init( 'payment_intent', 'Net::API::Stripe::Payment::Intent', @_ ) ); }

sub payment_method { return( shift->_set_get_object_without_init( 'payment_method', 'Net::API::Stripe::Payment::Method', @_ ) ); }

sub payment_method_type { return( shift->_set_get_scalar_as_object( 'payment_method_type', @_ ) ); }

sub request_log_url { return( shift->_set_get_uri( 'request_log_url', @_ ) ); }

sub setup_intent { return( shift->_set_get_object_without_init( 'setup_intent', 'Net::API::Stripe::Payment::Intent::Setup', @_ ) ); }

sub source { return( shift->_set_get_object_without_init( 'source', 'Net::API::Stripe::Payment::Source', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::Stripe::Exception - Stripe Exception

=head1 SYNOPSIS

    use Net::API::Stripe::Exception;
    my $err = Net::API::Stripe::Exception->new( $error_message ) || 
        die( Net::API::Stripe::Exception->error, "\n" );
    # or
    my $err = Net::API::Stripe::Exception->new({
        code => 'resource_missing',
        doc_url => 'https://stripe.com/docs/error-codes/resource-missing',
        message => $error_message,
        param => 'payment_method',
        request_log_url => '//dashboard.stripe.com/test/logs/req_123456789qwerty?t=1673383344',
        type => 'invalid_request_error',
    }) || die( Net::API::Stripe::Exception->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class inherits all its methods from L<Module::Generic::Exception>

=head1 METHODS

Please see L<Module::Generic::Exception> for details.

=head2 charge

String. For card errors, sets or gets the ID of the failed charge.

=head2 code

String. Sets or gets the Stripe error code. See for more details of what they are: L<https://stripe.com/docs/error-codes>

=head2 decline_code

String. Sets or gets a short string for card errors resulting from a card issuer decline. This is a short string indicating the card issuer’s reason for the decline if they provide one.

=head2 doc_url

URI. Sets or gets the url of the Stripe documentation detailing that error code. For example: L<https://stripe.com/docs/error-codes/resource-missing>

=head2 http_code

The HTTP status code returned by Stripe. For example C<200> or C<400>

=over 4

=item C<200> - OK

Everything worked as expected.

=item C<400> - Bad Request

The request was unacceptable, often due to missing a required parameter.

=item C<401> - Unauthorised

No valid API key provided.

=item C<402> - Request Failed

The parameters were valid but the request failed.

=item C<403> - Forbidden

The API key doesn't have permissions to perform the request.

=item C<404> - Not Found

The requested resource doesn't exist.

=item C<409> - Conflict

The request conflicts with another request (perhaps due to using the same idempotent key).

=item C<429> - Too Many Requests

Too many requests hit the API too quickly. We recommend an exponential backoff of your requests.

=item C<500>, C<502>, C<503>, C<504> - Server Errors

Something went wrong on Stripe's end. (These are rare.)

=back

See: L<https://stripe.com/docs/api/errors>

=head2 http_headers

The L<HTTP headers object|HTTP::Promise::Headers> from the Stripe HTTP response.

=head2 message

String. Sets or gets the Stripe error message.

=head2 param

String. Sets or gets the error param. For example: C<payment_method>

If the error is parameter-specific, the parameter related to the error. For example, you can use this to display a message near the correct form field.

=head2 payment_intent

Sets or gets the L<PaymentIntent|Net::API::Stripe::Payment::Intent> object for errors returned on a request involving a L<PaymentIntent|Net::API::Stripe::Payment::Intent>.

=head2 payment_method

Sets or gets the L<PaymentMethod|Net::API::Stripe::Payment::Method> object for errors returned on a request involving a L<PaymentMethod|Net::API::Stripe::Payment::Method>.

=head2 payment_method_type

String. If the error is specific to the type of payment method, sets or gets the payment method type that had a problem. This field is only populated for invoice-related errors.

=head2 request_log_url

The uri in the dashboard to get details about the error that occurred.

=head2 setup_intent

Sets or gets the L<SetupIntent|Net::API::Stripe::Payment::Intent::Setup> object for errors returned on a request involving a L<SetupIntent|Net::API::Stripe::Payment::Intent::Setup>.

=head2 source

Sets or gets the L<source object|Net::API::Stripe::Payment::Source> for errors returned on a request involving a L<source|Net::API::Stripe::Payment::Source>.

=head2 type

String. Sets or gets the type of error returned. One of the following:

=over 4

=item * C<api_error>

API errors cover any other type of problem (e.g., a temporary problem with Stripe's servers), and are extremely uncommon.

=item * C<card_error>

Card errors are the most common type of error you should expect to handle. They result when the user enters a card that cannot be charged for some reason.

=item * C<idempotency_error>

Idempotency errors occur when an Idempotency-Key is re-used on a request that does not match the first request's API endpoint and parameters.

=item * C<invalid_request_error>

Invalid request errors arise when your request has invalid parameters.

=back

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Module::Generic::Exception>

L<Net::API::Stripe>

L<https://stripe.com/docs/api/errors>, L<https://stripe.com/docs/error-codes>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
