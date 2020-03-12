package Net::Stripe::Plan;
$Net::Stripe::Plan::VERSION = '0.41';
use Moose;
use Moose::Util::TypeConstraints qw(subtype as where message);
use Kavorka;
extends 'Net::Stripe::Resource';

# ABSTRACT: represent a Plan object from Stripe

subtype 'StatementDescriptor',
    as 'Str',
    where { !defined($_) || $_ =~ /^[^<>"']{0,15}$/ },
    message { "The statement descriptor you provided '$_' must be 15 characters or less and not contain <>\"'." };

has 'id'                => (is => 'ro', isa => 'Maybe[Str]', required => 1);
has 'amount'            => (is => 'ro', isa => 'Maybe[Int]', required => 1);
has 'currency'          => (is => 'ro', isa => 'Maybe[Str]', required => 1);
has 'interval'          => (is => 'ro', isa => 'Maybe[Str]', required => 1);
has 'interval_count'    => (is => 'ro', isa => 'Maybe[Int]', required => 0);
has 'name'              => (is => 'ro', isa => 'Maybe[Str]');
has 'trial_period_days' => (is => 'ro', isa => 'Maybe[Int]');
has 'statement_descriptor' => (is => 'ro', isa => 'Maybe[StatementDescriptor]', required => 0);
has 'metadata'          => (is => 'ro', isa => 'Maybe[HashRef]');
has 'product'           => (is => 'ro', isa => 'Maybe[StripeProductId|Str]');

method form_fields {
    return $self->form_fields_for(
        qw/id amount currency interval interval_count name statement_descriptor
            trial_period_days metadata product/
    );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Net::Stripe::Plan - represent a Plan object from Stripe

=head1 VERSION

version 0.41

=head1 ATTRIBUTES

=head2 amount

Reader: amount

Type: Maybe[Int]

This attribute is required.

=head2 boolean_attributes

Reader: boolean_attributes

Type: ArrayRef[Str]

=head2 currency

Reader: currency

Type: Maybe[Str]

This attribute is required.

=head2 id

Reader: id

Type: Maybe[Str]

This attribute is required.

=head2 interval

Reader: interval

Type: Maybe[Str]

This attribute is required.

=head2 interval_count

Reader: interval_count

Type: Maybe[Int]

=head2 metadata

Reader: metadata

Type: Maybe[HashRef]

=head2 name

Reader: name

Type: Maybe[Str]

=head2 product

Reader: product

Type: Maybe[Str|StripeProductId]

=head2 statement_descriptor

Reader: statement_descriptor

Type: Maybe[StatementDescriptor]

=head2 trial_period_days

Reader: trial_period_days

Type: Maybe[Int]

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
