package Net::Stripe::Invoice;
$Net::Stripe::Invoice::VERSION = '0.39';
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
has 'closed'        => ( is => 'ro', isa => 'Maybe[Bool|Object]', required => 1, trigger => \&_closed_change_detector);
has 'customer'      => ( is => 'ro', isa => 'Maybe[Str]', required => 1 );
has 'date'          => ( is => 'ro', isa => 'Maybe[Str]', required => 1 );
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
    return (
        $self->form_fields_for_metadata(),
        (($self->{closed_value_changed}) ? (closed => (($self->closed) ? 'true' : 'false')) : ()),
        map { ($_ => $self->$_) }
            grep { defined $self->$_ } qw/description/
    );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Net::Stripe::Invoice - represent an Invoice object from Stripe

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
