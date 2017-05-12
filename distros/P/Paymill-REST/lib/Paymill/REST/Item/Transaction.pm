package Paymill::REST::Item::Transaction;

use Moose;
use MooseX::Types::DateTime::ButMaintained qw(DateTime);

has _factory => (is => 'ro', isa => 'Object');

has id            => (is => 'ro', isa => 'Str');
has description   => (is => 'ro', isa => 'Str');
has amount        => (is => 'ro', isa => 'Int', required => 1);
has origin_amount => (is => 'ro', isa => 'Int');
has currency      => (is => 'ro', isa => 'Str', required => 1);
has livemode      => (is => 'ro', isa => 'Bool');
has created_at    => (is => 'ro', isa => DateTime, coerce => 1);
has updated_at    => (is => 'ro', isa => DateTime, coerce => 1);
has status        => (is => 'ro', isa => 'TxStatus');
has response_code => (is => 'ro', isa => 'Int');
has short_id      => (is => 'ro', isa => 'Str');
has invoices      => (is => 'ro', isa => 'Undef|ArrayRef');
has fees          => (is => 'ro', isa => 'Undef|ArrayRef');
has app_id        => (is => 'ro', isa => 'Undef|Str');

has client => (
    is      => 'ro',
    isa     => 'Undef|Object|HashRef',
    trigger => sub { Paymill::REST::TypesAndTriggers::item_from_hashref('client', @_) }
);
has payment => (
    is      => 'ro',
    isa     => 'Undef|Object|HashRef',
    trigger => sub { Paymill::REST::TypesAndTriggers::item_from_hashref('payment', @_) }
);
has preauthorization => (
    is      => 'ro',
    isa     => 'Undef|Object|HashRef',
    trigger => sub { Paymill::REST::TypesAndTriggers::item_from_hashref('preauthorization', @_) }
);
has refunds => (
    is      => 'ro',
    isa     => 'Undef|Object|ArrayRef',
    trigger => sub { Paymill::REST::TypesAndTriggers::items_from_arrayref('refunds', @_) }
);


no Moose;
1;
__END__

=encoding utf-8

=head1 NAME

Paymill::REST::Item::Transaction - Item class for a transaction

=head1 SYNOPSIS

  my $transaction_api = Paymill::REST::Transactions->new;
  $transaction = $transaction_api->find('tran_lk2j34h5lk34h5lkjh2');

  say $transaction->amount;  # Prints amount of the transaction

=head1 DESCRIPTION

Represents a transaction with all attributes and all sub items.

=head1 ATTRIBUTES

=over 4

=item id

String containing the identifier of the client

=item amount

Integer containing the charged amount minus amount refunded

=item origin_amount

String containing the initially charged amount

=item currency

String containing the currency in which the amount has been charged

=item description

String containing the assigned description

=item status

String indicating the current status of the transaction.  Can be one of:

=over

=item * 

open

=item * 

pending

=item * 

closed

=item * 

failed

=item * 

partial_refunded

=item * 

refunded

=item * 

preauth

=item * 

chargeback

=back

=item livemode

Boolean indicating whether this transaction has been made with the live keys or not

=item created_at

L<DateTime> object indicating the date of the creation as returned by the API

=item updated_at

L<DateTime> object indicating the date of the last update as returned by the API

=item response_code

Integer containing the response code from the API

=item short_id

String containing the short id from the API

=item invoices

Arrayref of invoices, if transaction has been billed yet

=item fees

Arrayref of fees

=item app_id

String representing the app id that issued this transaction

=back

=head1 SUB ITEMS

=over 4

=item client

A client object.

See also L<Paymill::REST::Item::Client>.

=item payment

A payment object.

See also L<Paymill::REST::Item::Payment>.

=item preauthorization

A preauthorization object.

See also L<Paymill::REST::Item::Preauthorization>.

=item refunds

A list of refund objects.

See also L<Paymill::REST::Item::Refund>.

=back

=head1 AVAILABLE OPERATIONS

=over 4

=item -

=back

=head1 SEE ALSO

L<Paymill::REST> for more documentation.

=head1 AUTHOR

Matthias Dietrich E<lt>perl@rainboxx.deE<gt>

=head1 COPYRIGHT

Copyright 2013 - Matthias Dietrich

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
