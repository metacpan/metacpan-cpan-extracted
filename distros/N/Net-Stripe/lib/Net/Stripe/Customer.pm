package Net::Stripe::Customer;
$Net::Stripe::Customer::VERSION = '0.42';
use Moose;
use Kavorka;
use Net::Stripe::Plan;
use Net::Stripe::Token;
use Net::Stripe::Card;
use Net::Stripe::Discount;
use Net::Stripe::List;
extends 'Net::Stripe::Resource';

# ABSTRACT: represent a Customer object from Stripe

# Customer creation args
has 'email'       => (is => 'rw', isa => 'Maybe[Str]');
has 'description' => (is => 'rw', isa => 'Maybe[Str]');
has 'trial_end'   => (is => 'rw', isa => 'Maybe[Int|Str]');
has 'card'        => (is => 'rw', isa => 'Maybe[Net::Stripe::Token|Net::Stripe::Card|StripeTokenId]');
has 'source'      => (is => 'rw', isa => 'Maybe[Net::Stripe::Card|StripeTokenId|StripeSourceId]');
has 'quantity'    => (is => 'rw', isa => 'Maybe[Int]');
has 'plan'        => (is => 'rw', isa => 'Maybe[Net::Stripe::Plan|Str]');
has 'coupon'      => (is => 'rw', isa => 'Maybe[Net::Stripe::Coupon|Str]');
has 'discount'    => (is => 'rw', isa => 'Maybe[Net::Stripe::Discount]');
has 'metadata'    => (is => 'rw', isa => 'Maybe[HashRef]');
has 'account_balance' => (is => 'rw', isa => 'Maybe[Int]', trigger => \&_account_balance_trigger);
has 'balance'     => (is => 'rw', isa => 'Maybe[Int]', trigger => \&_balance_trigger);
has 'default_card' => (is => 'rw', isa => 'Maybe[Net::Stripe::Token|Net::Stripe::Card|Str]');
has 'default_source' => (is => 'rw', isa => 'Maybe[StripeCardId|StripeSourceId]');

# API object args

has 'id'           => (is => 'ro', isa => 'Maybe[Str]');
has 'cards'        => (is => 'ro', isa => 'Net::Stripe::List');
has 'deleted'      => (is => 'ro', isa => 'Maybe[Bool|Object]', default => 0);
has 'sources'      => (is => 'ro', isa => 'Net::Stripe::List');
has 'subscriptions' => (is => 'ro', isa => 'Net::Stripe::List');
has 'subscription' => (is => 'ro',
                       lazy => 1,
                       builder => '_build_subscription');

sub _build_subscription {
    my $self = shift;
    return $self->subscriptions->get(0);
}

method _account_balance_trigger(
    Maybe[Int] $new_value!,
    Maybe[Int] $old_value?,
) {
    return unless defined( $new_value );
    return if defined( $old_value ) && $old_value eq $new_value;
    return if defined( $self->balance ) && $self->balance == $new_value;
    $self->balance( $new_value );
}

method _balance_trigger(
    Maybe[Int] $new_value!,
    Maybe[Int] $old_value?,
) {
    return unless defined( $new_value );
    return if defined( $old_value ) && $old_value eq $new_value;
    return if defined( $self->account_balance ) && $self->account_balance == $new_value;
    $self->account_balance( $new_value );
}

method form_fields {
    $self->account_balance( undef ) if
        defined( $self->account_balance ) &&
        defined( $self->balance ) &&
        $self->account_balance == $self->balance;
    return $self->form_fields_for(
        qw/email description trial_end account_balance balance quantity card plan coupon
            metadata default_card source default_source/
    );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Net::Stripe::Customer - represent a Customer object from Stripe

=head1 VERSION

version 0.42

=head1 ATTRIBUTES

=head2 account_balance

Reader: account_balance

Writer: account_balance

Type: Maybe[Int]

=head2 balance

Reader: balance

Writer: balance

Type: Maybe[Int]

=head2 boolean_attributes

Reader: boolean_attributes

Type: ArrayRef[Str]

=head2 card

Reader: card

Writer: card

Type: Maybe[Net::Stripe::Card|Net::Stripe::Token|StripeTokenId]

=head2 cards

Reader: cards

Type: Net::Stripe::List

=head2 coupon

Reader: coupon

Writer: coupon

Type: Maybe[Net::Stripe::Coupon|Str]

=head2 default_card

Reader: default_card

Writer: default_card

Type: Maybe[Net::Stripe::Card|Net::Stripe::Token|Str]

=head2 default_source

Reader: default_source

Writer: default_source

Type: Maybe[StripeCardId|StripeSourceId]

=head2 deleted

Reader: deleted

Type: Maybe[Bool|Object]

=head2 description

Reader: description

Writer: description

Type: Maybe[Str]

=head2 discount

Reader: discount

Writer: discount

Type: Maybe[Net::Stripe::Discount]

=head2 email

Reader: email

Writer: email

Type: Maybe[Str]

=head2 id

Reader: id

Type: Maybe[Str]

=head2 metadata

Reader: metadata

Writer: metadata

Type: Maybe[HashRef]

=head2 plan

Reader: plan

Writer: plan

Type: Maybe[Net::Stripe::Plan|Str]

=head2 quantity

Reader: quantity

Writer: quantity

Type: Maybe[Int]

=head2 source

Reader: source

Writer: source

Type: Maybe[Net::Stripe::Card|StripeSourceId|StripeTokenId]

=head2 sources

Reader: sources

Type: Net::Stripe::List

=head2 subscription

Reader: subscription

=head2 subscriptions

Reader: subscriptions

Type: Net::Stripe::List

=head2 trial_end

Reader: trial_end

Writer: trial_end

Type: Maybe[Int|Str]

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
