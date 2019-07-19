package Net::Stripe::Customer;
$Net::Stripe::Customer::VERSION = '0.39';
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
has 'card'        => (is => 'rw', isa => 'Maybe[Net::Stripe::Token|Net::Stripe::Card|Str]');
has 'quantity'    => (is => 'rw', isa => 'Maybe[Int]');
has 'plan'        => (is => 'rw', isa => 'Maybe[Net::Stripe::Plan|Str]');
has 'coupon'      => (is => 'rw', isa => 'Maybe[Net::Stripe::Coupon|Str]');
has 'discount'    => (is => 'rw', isa => 'Maybe[Net::Stripe::Discount]');
has 'metadata'    => (is => 'rw', isa => 'Maybe[HashRef]');
has 'cards'       => (is => 'ro', isa => 'Net::Stripe::List');
has 'account_balance' => (is => 'ro', isa => 'Maybe[Int]', default => 0);

# API object args

has 'id'           => (is => 'ro', isa => 'Maybe[Str]');
has 'deleted'      => (is => 'ro', isa => 'Maybe[Bool|Object]', default => 0);
has 'default_card' => (is => 'ro', isa => 'Maybe[Net::Stripe::Token|Net::Stripe::Card|Str]');
has 'subscriptions' => (is => 'ro', isa => 'Net::Stripe::List');
has 'subscription' => (is => 'ro',
                       lazy => 1,
                       builder => '_build_subscription');

sub _build_subscription {
    my $self = shift;
    return $self->subscriptions->get(0);
}

method form_fields {
    return (
        (($self->card && ref($self->card) eq 'Net::Stripe::Token') ?
            (card => $self->card->id) : $self->fields_for('card')),
        $self->fields_for('plan'),
        $self->fields_for('coupon'),
        $self->form_fields_for_metadata(),
        map { ($_ => $self->$_) }
            grep { defined $self->$_ } qw/email description trial_end account_balance quantity/
    );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Net::Stripe::Customer - represent a Customer object from Stripe

=head1 VERSION

version 0.39

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
