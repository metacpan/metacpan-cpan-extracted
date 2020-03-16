package Net::Stripe::PaymentIntent;
$Net::Stripe::PaymentIntent::VERSION = '0.42';
use Moose;
use Moose::Util::TypeConstraints qw(enum);
use Kavorka;
extends 'Net::Stripe::Resource';

# ABSTRACT: represent an PaymentIntent object from Stripe

# Args for posting to PaymentIntent endpoints
has 'amount'                      => (is => 'ro', isa => 'Maybe[Int]');
has 'amount_to_capture'           => (is => 'ro', isa => 'Maybe[Int]');
has 'application_fee_amount'      => (is => 'ro', isa => 'Maybe[Int]');
has 'cancellation_reason'         => (is => 'ro', isa => 'Maybe[StripeCancellationReason]');
has 'capture_method'              => (is => 'ro', isa => 'Maybe[StripeCaptureMethod]');
has 'client_secret'               => (is => 'ro', isa => 'Maybe[Str]');
has 'confirm'                     => (is => 'ro', isa => 'Maybe[Bool]');
has 'confirmation_method'         => (is => 'ro', isa => 'Maybe[StripeConfirmationMethod]');
has 'currency'                    => (is => 'ro', isa => 'Maybe[Str]');
has 'customer'                    => (is => 'ro', isa => 'Maybe[StripeCustomerId]');
has 'description'                 => (is => 'ro', isa => 'Maybe[Str]');
has 'error_on_requires_action'    => (is => 'ro', isa => 'Maybe[Bool]');
has 'mandate'                     => (is => 'ro', isa => 'Maybe[Str]');
has 'mandate_data'                => (is => 'ro', isa => 'Maybe[HashRef]');
has 'metadata'                    => (is => 'ro', isa => 'Maybe[HashRef[Str]|EmptyStr]');
has 'off_session'                 => (is => 'ro', isa => 'Maybe[Bool]');
has 'on_behalf_of'                => (is => 'ro', isa => 'Maybe[Str]');
has 'payment_method'              => (is => 'ro', isa => 'Maybe[StripePaymentMethodId]');
has 'payment_method_options'      => (is => 'ro', isa => 'Maybe[HashRef]');
has 'payment_method_types'        => (is => 'ro', isa => 'Maybe[ArrayRef[StripePaymentMethodType]]');
has 'receipt_email'               => (is => 'ro', isa => 'Maybe[Str]');
has 'return_url'                  => (is => 'ro', isa => 'Maybe[Str]');
has 'save_payment_method'         => (is => 'ro', isa => 'Maybe[Bool]');
has 'setup_future_usage'          => (is => 'ro', isa => 'Maybe[Str]');
has 'shipping'                    => (is => 'ro', isa => 'Maybe[HashRef]');
has 'statement_descriptor'        => (is => 'ro', isa => 'Maybe[Str]');
has 'statement_descriptor_suffix' => (is => 'ro', isa => 'Maybe[Str]');
has 'transfer_data'               => (is => 'ro', isa => 'Maybe[HashRef]');
has 'transfer_group'              => (is => 'ro', isa => 'Maybe[Str]');
has 'use_stripe_sdk'              => (is => 'ro', isa => 'Maybe[Bool]');

# Args returned by the API
has 'id'                  => (is => 'ro', isa => 'StripePaymentIntentId');
has 'amount_capturable'   => (is => 'ro', isa => 'Int');
has 'amount_received'     => (is => 'ro', isa => 'Int');
has 'application'         => (is => 'ro', isa => 'Maybe[Str]');
has 'cancellation_reason' => (is => 'ro', isa => 'Maybe[StripeCancellationReason]');
has 'canceled_at'         => (is => 'ro', isa => 'Maybe[Int]');
has 'charges'             => (is => 'ro', isa => 'Net::Stripe::List');
has 'client_secret'       => (is => 'ro', isa => 'Maybe[Str]');
has 'created'             => (is => 'ro', isa => 'Int');
has 'invoice'             => (is => 'ro', isa => 'Maybe[Str]');
has 'last_payment_error'  => (is => 'ro', isa => 'Maybe[HashRef]');
has 'livemode'            => (is => 'ro', isa => 'Bool');
has 'next_action'         => (is => 'ro', isa => 'Maybe[HashRef]');
has 'review'              => (is => 'ro', isa => 'Maybe[Str]');
has 'status'              => (is => 'ro', isa => 'Str');

method form_fields {
    return $self->form_fields_for(qw/
        amount amount_to_capture application_fee_amount cancellation_reason
        capture_method client_secret confirm confirmation_method currency
        customer description error_on_requires_action expand mandate
        mandate_data metadata off_session on_behalf_of payment_method
        payment_method_options payment_method_types receipt_email return_url
        save_payment_method setup_future_usage shipping statement_descriptor
        statement_descriptor_suffix transfer_data transfer_group use_stripe_sdk
    /);
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Net::Stripe::PaymentIntent - represent an PaymentIntent object from Stripe

=head1 VERSION

version 0.42

=head1 ATTRIBUTES

=head2 amount

Reader: amount

Type: Maybe[Int]

=head2 amount_capturable

Reader: amount_capturable

Type: Int

=head2 amount_received

Reader: amount_received

Type: Int

=head2 amount_to_capture

Reader: amount_to_capture

Type: Maybe[Int]

=head2 application

Reader: application

Type: Maybe[Str]

=head2 application_fee_amount

Reader: application_fee_amount

Type: Maybe[Int]

=head2 boolean_attributes

Reader: boolean_attributes

Type: ArrayRef[Str]

=head2 canceled_at

Reader: canceled_at

Type: Maybe[Int]

=head2 cancellation_reason

Reader: cancellation_reason

Type: Maybe[StripeCancellationReason]

=head2 capture_method

Reader: capture_method

Type: Maybe[StripeCaptureMethod]

=head2 charges

Reader: charges

Type: Net::Stripe::List

=head2 client_secret

Reader: client_secret

Type: Maybe[Str]

=head2 confirm

Reader: confirm

Type: Maybe[Bool]

=head2 confirmation_method

Reader: confirmation_method

Type: Maybe[StripeConfirmationMethod]

=head2 created

Reader: created

Type: Int

=head2 currency

Reader: currency

Type: Maybe[Str]

=head2 customer

Reader: customer

Type: Maybe[StripeCustomerId]

=head2 description

Reader: description

Type: Maybe[Str]

=head2 error_on_requires_action

Reader: error_on_requires_action

Type: Maybe[Bool]

=head2 id

Reader: id

Type: StripePaymentIntentId

=head2 invoice

Reader: invoice

Type: Maybe[Str]

=head2 last_payment_error

Reader: last_payment_error

Type: Maybe[HashRef]

=head2 livemode

Reader: livemode

Type: Bool

=head2 mandate

Reader: mandate

Type: Maybe[Str]

=head2 mandate_data

Reader: mandate_data

Type: Maybe[HashRef]

=head2 metadata

Reader: metadata

Type: Maybe[EmptyStr|HashRef[Str]]

=head2 next_action

Reader: next_action

Type: Maybe[HashRef]

=head2 off_session

Reader: off_session

Type: Maybe[Bool]

=head2 on_behalf_of

Reader: on_behalf_of

Type: Maybe[Str]

=head2 payment_method

Reader: payment_method

Type: Maybe[StripePaymentMethodId]

=head2 payment_method_options

Reader: payment_method_options

Type: Maybe[HashRef]

=head2 payment_method_types

Reader: payment_method_types

Type: Maybe[ArrayRef[StripePaymentMethodType]]

=head2 receipt_email

Reader: receipt_email

Type: Maybe[Str]

=head2 return_url

Reader: return_url

Type: Maybe[Str]

=head2 review

Reader: review

Type: Maybe[Str]

=head2 save_payment_method

Reader: save_payment_method

Type: Maybe[Bool]

=head2 setup_future_usage

Reader: setup_future_usage

Type: Maybe[Str]

=head2 shipping

Reader: shipping

Type: Maybe[HashRef]

=head2 statement_descriptor

Reader: statement_descriptor

Type: Maybe[Str]

=head2 statement_descriptor_suffix

Reader: statement_descriptor_suffix

Type: Maybe[Str]

=head2 status

Reader: status

Type: Str

=head2 transfer_data

Reader: transfer_data

Type: Maybe[HashRef]

=head2 transfer_group

Reader: transfer_group

Type: Maybe[Str]

=head2 use_stripe_sdk

Reader: use_stripe_sdk

Type: Maybe[Bool]

=head1 AUTHORS

=over 4

=item *

Luke Closs

=item *

Rusty Conover

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Prime Radiant, Inc., (c) copyright 2014 Lucky Dinosaur LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
