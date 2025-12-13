package Net::Stripe::Invoice;
$Net::Stripe::Invoice::VERSION = '0.43';
use Moose;
use Kavorka;
extends 'Net::Stripe::Resource';

# ABSTRACT: represent an Invoice object from Stripe

has 'id'            => ( is => 'ro', isa => 'Maybe[Str]' );
has 'created'       => ( is => 'ro', isa => 'Maybe[Int]' );
has 'subtotal'      => ( is => 'ro', isa => 'Maybe[Int]', required => 1 );
has 'amount_due'    => ( is => 'ro', isa => 'Maybe[Int]', required => 1 );
has 'attempt_count' => ( is => 'ro', isa => 'Maybe[Int]', required => 1 );
has 'attempted'     => ( is => 'ro', isa => 'Maybe[Bool|Object]', required => 1 );
has 'closed'        => ( is => 'ro', isa => 'Maybe[Bool|Object]', trigger => \&_closed_change_detector);
has 'auto_advance'  => ( is => 'ro', isa => 'Maybe[Bool]');
has 'created'       => ( is => 'ro', isa => 'Maybe[Int]' );
has 'customer'      => ( is => 'ro', isa => 'Maybe[Str]', required => 1 );
has 'date'          => ( is => 'ro', isa => 'Maybe[Str]' );
has 'lines'         => ( is => 'ro', isa => 'Net::Stripe::List', required => 1 );
has 'paid'          => ( is => 'ro', isa => 'Maybe[Bool|Object]', required => 1 );
has 'period_end'    => ( is => 'ro', isa => 'Maybe[Int]' );
has 'period_start'  => ( is => 'ro', isa => 'Maybe[Int]' );
has 'starting_balance' => ( is => 'ro', isa => 'Maybe[Int]' );
has 'subtotal'         => ( is => 'ro', isa => 'Maybe[Int]' );
has 'total'            => ( is => 'ro', isa => 'Maybe[Int]', required => 1 );
has 'charge'           => ( is => 'ro', isa => 'Maybe[Str]' );
has 'ending_balance'   => ( is => 'ro', isa => 'Maybe[Int]' );
has 'next_payment_attempt' => ( is => 'ro', isa => 'Maybe[Int]' );
has 'metadata'         => ( is => 'rw', isa => 'HashRef');
has 'description' => (is => 'rw', isa => 'Maybe[Str]');

sub _closed_change_detector {
    my ($instance, $new_value, $orig_value) = @_;
    # Strip can update invoices but only wants to see the closed flag if it has been changed.
    # Meaning if you retrieve an invoice then try to update it, and it is already closed
    # it will reject the update.
    if (!defined($orig_value) || $new_value ne $orig_value) {
        $instance->{closed_value_changed} = 1;
    }
    return;
}

method form_fields {
    return $self->form_fields_for(
        qw/description metadata auto_advance/,
        ($self->{closed_value_changed} ? qw/closed/ : ())
    );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Net::Stripe::Invoice - represent an Invoice object from Stripe

=head1 VERSION

version 0.43

=head1 ATTRIBUTES

=head2 amount_due

Reader: amount_due

Type: Maybe[Int]

This attribute is required.

=head2 attempt_count

Reader: attempt_count

Type: Maybe[Int]

This attribute is required.

=head2 attempted

Reader: attempted

Type: Maybe[Bool|Object]

This attribute is required.

=head2 auto_advance

Reader: auto_advance

Type: Maybe[Bool]

=head2 boolean_attributes

Reader: boolean_attributes

Type: ArrayRef[Str]

=head2 charge

Reader: charge

Type: Maybe[Str]

=head2 closed

Reader: closed

Type: Maybe[Bool|Object]

=head2 created

Reader: created

Type: Maybe[Int]

=head2 customer

Reader: customer

Type: Maybe[Str]

This attribute is required.

=head2 date

Reader: date

Type: Maybe[Str]

=head2 description

Reader: description

Writer: description

Type: Maybe[Str]

=head2 ending_balance

Reader: ending_balance

Type: Maybe[Int]

=head2 id

Reader: id

Type: Maybe[Str]

=head2 lines

Reader: lines

Type: Net::Stripe::List

This attribute is required.

=head2 metadata

Reader: metadata

Writer: metadata

Type: HashRef

=head2 next_payment_attempt

Reader: next_payment_attempt

Type: Maybe[Int]

=head2 paid

Reader: paid

Type: Maybe[Bool|Object]

This attribute is required.

=head2 period_end

Reader: period_end

Type: Maybe[Int]

=head2 period_start

Reader: period_start

Type: Maybe[Int]

=head2 starting_balance

Reader: starting_balance

Type: Maybe[Int]

=head2 subtotal

Reader: subtotal

Type: Maybe[Int]

=head2 total

Reader: total

Type: Maybe[Int]

This attribute is required.

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
