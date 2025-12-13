package Net::Stripe::PaymentMethod;
$Net::Stripe::PaymentMethod::VERSION = '0.43';
use Moose;
use Moose::Util::TypeConstraints qw(enum);
use Kavorka;
extends 'Net::Stripe::Resource';

# ABSTRACT: represent a PaymentMethod object from Stripe

# Args for posting to PaymentMethod endpoints
has 'billing_details' => (is => 'ro', isa => 'Maybe[HashRef]');
has 'card'            => (is => 'ro', isa => 'Maybe[Net::Stripe::Card|StripeTokenId]');
has 'fpx'             => (is => 'ro', isa => 'Maybe[HashRef]');
has 'ideal'           => (is => 'ro', isa => 'Maybe[HashRef]');
has 'metadata'        => (is => 'ro', isa => 'Maybe[HashRef[Str]|EmptyStr]');
has 'sepa_debit'      => (is => 'ro', isa => 'Maybe[HashRef]');
has 'type'            => (is => 'ro', isa => 'StripePaymentMethodType');

# Args returned by the API
has 'id'            => (is => 'ro', isa => 'StripePaymentMethodId');
has 'card_present'  => (is => 'ro', isa => 'Maybe[HashRef]');
has 'created'       => (is => 'ro', isa => 'Int');
has 'customer'      => (is => 'ro', isa => 'Maybe[StripeCustomerId]');
has 'livemode'      => (is => 'ro', isa => 'Bool');

method form_fields {
    return $self->form_fields_for(qw/
        billing_details card customer expand fpx ideal metadata sepa_debit type
    /);
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Net::Stripe::PaymentMethod - represent a PaymentMethod object from Stripe

=head1 VERSION

version 0.43

=head1 ATTRIBUTES

=head2 billing_details

Reader: billing_details

Type: Maybe[HashRef]

=head2 boolean_attributes

Reader: boolean_attributes

Type: ArrayRef[Str]

=head2 card

Reader: card

Type: Maybe[Net::Stripe::Card|StripeTokenId]

=head2 card_present

Reader: card_present

Type: Maybe[HashRef]

=head2 created

Reader: created

Type: Int

=head2 customer

Reader: customer

Type: Maybe[StripeCustomerId]

=head2 fpx

Reader: fpx

Type: Maybe[HashRef]

=head2 id

Reader: id

Type: StripePaymentMethodId

=head2 ideal

Reader: ideal

Type: Maybe[HashRef]

=head2 livemode

Reader: livemode

Type: Bool

=head2 metadata

Reader: metadata

Type: Maybe[EmptyStr|HashRef[Str]]

=head2 sepa_debit

Reader: sepa_debit

Type: Maybe[HashRef]

=head2 type

Reader: type

Type: StripePaymentMethodType

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
