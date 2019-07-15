package Net::Stripe::Refund;
$Net::Stripe::Refund::VERSION = '0.37';
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
    return (
        $self->form_fields_for_metadata(),
        map { $_ => $self->$_ }
            grep { defined $self->$_ }
                qw/amount refund_application_fee reason/
    );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Net::Stripe::Refund - represent a Refund object from Stripe

=head1 VERSION

version 0.37

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
