package Net::Stripe::Invoiceitem;
$Net::Stripe::Invoiceitem::VERSION = '0.33';
use Moose;
use Kavorka;
extends 'Net::Stripe::Resource';
with 'MooseX::Clone';

# ABSTRACT: represent an Invoice Item object from Stripe

has 'id'                => (is => 'ro', isa => 'Maybe[Str]');
has 'customer'          => (is => 'ro', isa => 'Maybe[Str]', required => 1);
has 'amount'            => (is => 'rw', isa => 'Maybe[Int]', required => 1);
has 'currency'          => (is => 'rw', isa => 'Maybe[Str]', required => 1, clearer => 'clear_currency');
has 'description'       => (is => 'rw', isa => 'Maybe[Str]');
has 'date'              => (is => 'ro', isa => 'Maybe[Int]');
has 'invoice'           => (is => 'ro', isa => 'Maybe[Str]');
has 'metadata'          => (is => 'rw', isa => 'Maybe[HashRef]');

method form_fields {
    return (
        $self->form_fields_for_metadata(),
        map { $_ => $self->$_ }
            grep { defined $self->$_ }
                qw/amount currency description invoice/,
                ($self->id ? () : qw/customer/)
    );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Net::Stripe::Invoiceitem - represent an Invoice Item object from Stripe

=head1 VERSION

version 0.33

=head1 ATTRIBUTES

=head2 amount

Reader: amount

Writer: amount

Type: Maybe[Int]

This attribute is required.

=head2 currency

Reader: currency

Writer: currency

Type: Maybe[Str]

This attribute is required.

=head2 customer

Reader: customer

Type: Maybe[Str]

This attribute is required.

=head2 date

Reader: date

Type: Maybe[Int]

=head2 description

Reader: description

Writer: description

Type: Maybe[Str]

=head2 id

Reader: id

Type: Maybe[Str]

=head2 invoice

Reader: invoice

Type: Maybe[Str]

=head2 metadata

Reader: metadata

Writer: metadata

Type: Maybe[HashRef]

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
