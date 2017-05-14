package Net::Stripe::Subscription;
$Net::Stripe::Subscription::VERSION = '0.33';
use Moose;
use Kavorka;
use Net::Stripe::Token;
use Net::Stripe::Card;
use Net::Stripe::Plan;
use Net::Stripe::Coupon;


extends 'Net::Stripe::Resource';

# ABSTRACT: represent a Subscription object from Stripe

has 'id' => (is => 'ro', isa => 'Maybe[Str]');
has 'plan' => (is => 'rw', isa => 'Maybe[Net::Stripe::Plan|Str]');
has 'coupon'    => (is => 'rw', isa => 'Maybe[Net::Stripe::Coupon|Str]');
has 'prorate'   => (is => 'rw', isa => 'Maybe[Bool|Object]');
has 'card'      => (is => 'rw', isa => 'Maybe[Net::Stripe::Token|Net::Stripe::Card|Str]');
has 'quantity'  => (is => 'rw', isa => 'Maybe[Int]', default => 1);

# Other fields returned by the API
has 'customer'             => (is => 'ro', isa => 'Maybe[Str]');
has 'status'               => (is => 'ro', isa => 'Maybe[Str]');
has 'start'                => (is => 'ro', isa => 'Maybe[Int]');
has 'canceled_at'          => (is => 'ro', isa => 'Maybe[Int]');
has 'ended_at'             => (is => 'ro', isa => 'Maybe[Int]');
has 'current_period_start' => (is => 'ro', isa => 'Maybe[Int]');
has 'current_period_end'   => (is => 'ro', isa => 'Maybe[Int]');
has 'trial_start'          => (is => 'ro', isa => 'Maybe[Str]');
has 'trial_end'            => (is => 'rw', isa => 'Maybe[Str|Int]');
has 'cancel_at_period_end' => (is => 'rw', isa => 'Maybe[Bool]');


method form_fields {
    return (
        $self->fields_for('card'),
        $self->fields_for('plan'),
        map { ($_ => $self->$_) }
            grep { defined $self->$_ } qw/coupon prorate trial_end quantity/
    );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Net::Stripe::Subscription - represent a Subscription object from Stripe

=head1 VERSION

version 0.33

=head1 ATTRIBUTES

=head2 cancel_at_period_end

Reader: cancel_at_period_end

Writer: cancel_at_period_end

Type: Maybe[Bool]

=head2 canceled_at

Reader: canceled_at

Type: Maybe[Int]

=head2 card

Reader: card

Writer: card

Type: Maybe[Net::Stripe::Card|Net::Stripe::Token|Str]

=head2 coupon

Reader: coupon

Writer: coupon

Type: Maybe[Net::Stripe::Coupon|Str]

=head2 current_period_end

Reader: current_period_end

Type: Maybe[Int]

=head2 current_period_start

Reader: current_period_start

Type: Maybe[Int]

=head2 customer

Reader: customer

Type: Maybe[Str]

=head2 ended_at

Reader: ended_at

Type: Maybe[Int]

=head2 id

Reader: id

Type: Maybe[Str]

=head2 plan

Reader: plan

Writer: plan

Type: Maybe[Net::Stripe::Plan|Str]

=head2 prorate

Reader: prorate

Writer: prorate

Type: Maybe[Bool|Object]

=head2 quantity

Reader: quantity

Writer: quantity

Type: Maybe[Int]

=head2 start

Reader: start

Type: Maybe[Int]

=head2 status

Reader: status

Type: Maybe[Str]

=head2 trial_end

Reader: trial_end

Writer: trial_end

Type: Maybe[Int|Str]

=head2 trial_start

Reader: trial_start

Type: Maybe[Str]

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
