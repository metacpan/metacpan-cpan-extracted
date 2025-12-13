package Net::Stripe::Source;
$Net::Stripe::Source::VERSION = '0.43';
use Moose;
use Kavorka;
extends 'Net::Stripe::Resource';

# ABSTRACT: represent a Source object from Stripe

# Object creation
has 'amount'                => (is => 'ro', isa => 'Maybe[Int]');
has 'currency'              => (is => 'ro', isa => 'Maybe[Str]');
has 'flow'                  => (is => 'ro', isa => 'Maybe[StripeSourceFlow]');
has 'mandate'               => (is => 'ro', isa => 'Maybe[HashRef]');
has 'metadata'              => (is => 'ro', isa => 'Maybe[HashRef[Str]|EmptyStr]');
has 'owner'                 => (is => 'ro', isa => 'Maybe[HashRef]');
has 'receiver'              => (is => 'ro', isa => 'Maybe[HashRef]');
has 'redirect'              => (is => 'ro', isa => 'Maybe[HashRef]');
has 'source_order'          => (is => 'ro', isa => 'Maybe[HashRef]');
has 'statement_descriptor'  => (is => 'ro', isa => 'Maybe[Str]');
has 'token'                 => (is => 'ro', isa => 'Maybe[StripeTokenId]');
has 'type'                  => (is => 'ro', isa => 'Maybe[StripeSourceType]');
has 'usage'                 => (is => 'ro', isa => 'Maybe[StripeSourceUsage]');

# API response
has 'id'                    => (is => 'ro', isa => 'Maybe[StripeSourceId]');
has 'client_secret'         => (is => 'ro', isa => 'Maybe[Str]');
has 'created'               => (is => 'ro', isa => 'Maybe[Int]');
has 'livemode'              => (is => 'ro', isa => 'Maybe[Bool]');
has 'status'                => (is => 'ro', isa => 'Maybe[Str]');
has 'card'                  => (is => 'ro', isa => 'Maybe[Net::Stripe::Card]');

method form_fields {
    return $self->form_fields_for(
        qw/amount currency flow mandate metadata owner receiver redirect source_order statement_descriptor token type usage/
    );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Net::Stripe::Source - represent a Source object from Stripe

=head1 VERSION

version 0.43

=head1 ATTRIBUTES

=head2 amount

Reader: amount

Type: Maybe[Int]

=head2 boolean_attributes

Reader: boolean_attributes

Type: ArrayRef[Str]

=head2 card

Reader: card

Type: Maybe[Net::Stripe::Card]

=head2 client_secret

Reader: client_secret

Type: Maybe[Str]

=head2 created

Reader: created

Type: Maybe[Int]

=head2 currency

Reader: currency

Type: Maybe[Str]

=head2 flow

Reader: flow

Type: Maybe[StripeSourceFlow]

=head2 id

Reader: id

Type: Maybe[StripeSourceId]

=head2 livemode

Reader: livemode

Type: Maybe[Bool]

=head2 mandate

Reader: mandate

Type: Maybe[HashRef]

=head2 metadata

Reader: metadata

Type: Maybe[EmptyStr|HashRef[Str]]

=head2 owner

Reader: owner

Type: Maybe[HashRef]

=head2 receiver

Reader: receiver

Type: Maybe[HashRef]

=head2 redirect

Reader: redirect

Type: Maybe[HashRef]

=head2 source_order

Reader: source_order

Type: Maybe[HashRef]

=head2 statement_descriptor

Reader: statement_descriptor

Type: Maybe[Str]

=head2 status

Reader: status

Type: Maybe[Str]

=head2 token

Reader: token

Type: Maybe[StripeTokenId]

=head2 type

Reader: type

Type: Maybe[StripeSourceType]

=head2 usage

Reader: usage

Type: Maybe[StripeSourceUsage]

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
