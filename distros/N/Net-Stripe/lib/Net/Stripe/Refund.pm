package Net::Stripe::Refund;
$Net::Stripe::Refund::VERSION = '0.43';
use Moose;
use Kavorka;
extends 'Net::Stripe::Resource';

# ABSTRACT: represent a Refund object from Stripe

has 'id'                  => (is => 'ro', isa => 'Maybe[Str]');
has 'amount'              => (is => 'ro', isa => 'Maybe[Int]');
has 'created'             => (is => 'ro', isa => 'Maybe[Int]');
has 'currency'            => (is => 'ro', isa => 'Maybe[Str]');
has 'balance_transaction' => (is => 'ro', isa => 'Maybe[Str]');
has 'charge'              => (is => 'ro', isa => 'Maybe[Str]');
has 'metadata'            => (is => 'ro', isa => 'Maybe[HashRef]');
has 'reason'              => (is => 'ro', isa => 'Maybe[Str]');
has 'receipt_number'      => (is => 'ro', isa => 'Maybe[Str]');
has 'status'              => (is => 'ro', isa => 'Maybe[Str]');
has 'description'         => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    default => sub {
        warn
            "Use of Net::Stripe::Refund->description is deprecated and will be removed in the next Net::Stripe release";
        return;
    }
);

# Create only
has 'refund_application_fee' => (is => 'ro', isa => 'Maybe[Bool|Object]');

method form_fields {
    return $self->form_fields_for(
        qw/amount refund_application_fee reason metadata/
    );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Net::Stripe::Refund - represent a Refund object from Stripe

=head1 VERSION

version 0.43

=head1 ATTRIBUTES

=head2 amount

Reader: amount

Type: Maybe[Int]

=head2 balance_transaction

Reader: balance_transaction

Type: Maybe[Str]

=head2 boolean_attributes

Reader: boolean_attributes

Type: ArrayRef[Str]

=head2 charge

Reader: charge

Type: Maybe[Str]

=head2 created

Reader: created

Type: Maybe[Int]

=head2 currency

Reader: currency

Type: Maybe[Str]

=head2 description

Reader: description

Type: Maybe[Str]

=head2 id

Reader: id

Type: Maybe[Str]

=head2 metadata

Reader: metadata

Type: Maybe[HashRef]

=head2 reason

Reader: reason

Type: Maybe[Str]

=head2 receipt_number

Reader: receipt_number

Type: Maybe[Str]

=head2 refund_application_fee

Reader: refund_application_fee

Type: Maybe[Bool|Object]

=head2 status

Reader: status

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
