package Net::Stripe::Charge;
$Net::Stripe::Charge::VERSION = '0.39';
use Moose;
use Kavorka;
extends 'Net::Stripe::Resource';

# ABSTRACT: represent an Charge object from Stripe

has 'id'                  => (is => 'ro', isa => 'Maybe[Str]');
has 'created'             => (is => 'ro', isa => 'Maybe[Int]');
has 'amount'              => (is => 'ro', isa => 'Maybe[Int]', required => 1);
has 'currency'            => (is => 'ro', isa => 'Maybe[Str]', required => 1);
has 'customer'            => (is => 'ro', isa => 'Maybe[Str]');
has 'card'                => (is => 'ro', isa => 'Maybe[Net::Stripe::Token|Net::Stripe::Card|Str]');
has 'description'         => (is => 'ro', isa => 'Maybe[Str]');
has 'livemode'            => (is => 'ro', isa => 'Maybe[Bool|Object]');
has 'paid'                => (is => 'ro', isa => 'Maybe[Bool|Object]');
has 'refunded'            => (is => 'ro', isa => 'Maybe[Bool|Object]');
has 'amount_refunded'     => (is => 'ro', isa => 'Maybe[Int]');
has 'captured'            => (is => 'ro', isa => 'Maybe[Bool|Object]');
has 'balance_transaction' => (is => 'ro', isa => 'Maybe[Str]');
has 'failure_message'     => (is => 'ro', isa => 'Maybe[Str]');
has 'failure_code'        => (is => 'ro', isa => 'Maybe[Str]');
has 'application_fee'     => (is => 'ro', isa => 'Maybe[Int]');
has 'metadata'            => (is => 'rw', isa => 'Maybe[HashRef]');
has 'invoice'             => (is => 'ro', isa => 'Maybe[Str]');
has 'receipt_email'       => (is => 'ro', isa => 'Maybe[Str]');
has 'status'              => (is => 'ro', isa => 'Maybe[Str]');
has 'capture'             => (is => 'ro', isa => 'Maybe[Bool]');

method form_fields {
    my $capture = ( !defined( $self->capture ) || $self->capture ) ? 'true' : 'false';
    return (
        $self->fields_for('card'),
        $self->form_fields_for_metadata(),
        capture => $capture,
        map { $_ => $self->$_ }
            grep { defined $self->$_ }
                qw/amount currency customer description application_fee receipt_email/
    );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Net::Stripe::Charge - represent an Charge object from Stripe

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
