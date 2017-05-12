package Paymill::REST::Item::Payment;

use Moose;
use MooseX::Types::DateTime::ButMaintained qw(DateTime);

with 'Paymill::REST::Operations::Delete';

has _factory => (is => 'ro', isa => 'Object');

has id           => (is => 'ro', isa => 'Str');
has type         => (is => 'ro', isa => 'CCorDebit');
has client       => (is => 'ro', isa => 'Str');
has expire_month => (is => 'ro', isa => 'Int');
has expire_year  => (is => 'ro', isa => 'Int');
has last4        => (is => 'ro', isa => 'Int');
has card_type    => (is => 'ro', isa => 'Str');
has card_holder  => (is => 'ro', isa => 'Undef|Str');
has country      => (is => 'ro', isa => 'Undef|Str');
has code         => (is => 'ro', isa => 'Str');
has account      => (is => 'ro', isa => 'Str');
has holder       => (is => 'ro', isa => 'Str');
has app_id       => (is => 'ro', isa => 'Undef|Str');

has created_at => (is => 'ro', isa => DateTime, coerce => 1);
has updated_at => (is => 'ro', isa => DateTime, coerce => 1);

no Moose;
1;
__END__

=encoding utf-8

=head1 NAME

Paymill::REST::Item::Payment - Item class for a payment

=head1 SYNOPSIS

  my $payment_api = Paymill::REST::Payments->new;
  $payment = $payment_api->find('pay_lk2j34h5lk34h5lkjh2');

  say $payment->last4;  # Prints last4 of the payment

=head1 DESCRIPTION

Represents a payment with all attributes.

=head1 ATTRIBUTES

=over 4

=item id

String containing the identifier of the payment

=item type

String identifying the type of the payment, can be either C<creditcard> or C<debit>

=item client

String containing the identifier of the client

=item expire_month

Integer representing the expiry month of the credit card

=item expire_year

Integer representing the expiry year of the credit card

=item last4

Integer representing the last four digits of the credit card

=item card_type

String containing the card type eg. visa, mastercard

=item card_holder

String containing the name of the card holder

=item country

String representing the country of the credit card

=item code

String containing the bank code

=item account

String containing the account number

=item holder

String containing the name of the account holder

=item created_at

L<DateTime> object indicating the date of the creation as returned by the API

=item updated_at

L<DateTime> object indicating the date of the last update as returned by the API

=item app_id

String representing the app id that created this payment

=back

=head1 AVAILABLE OPERATIONS

=over 4

=item delete

L<Paymill::REST::Operations::Delete>

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
