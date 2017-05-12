package Paymill::REST::Item::Refund;

use Moose;
use MooseX::Types::DateTime::ButMaintained qw(DateTime);

has _factory => (is => 'ro', isa => 'Object');

has id          => (is => 'ro', isa => 'Str');
has amount      => (is => 'ro', isa => 'Int', required => 1);
has status      => (is => 'ro', isa => 'RefundStatus');
has description => (is => 'ro', isa => 'Undef|Str');
has livemode    => (is => 'ro', isa => 'Bool');
has created_at  => (is => 'ro', isa => DateTime, coerce => 1);
has updated_at  => (is => 'ro', isa => DateTime, coerce => 1);
has app_id      => (is => 'ro', isa => 'Undef|Str');

has transaction => (
    is      => 'ro',
    isa     => 'Undef|Object|HashRef',
    trigger => sub { Paymill::REST::TypesAndTriggers::item_from_hashref('transaction', @_) }
);

no Moose;
1;
__END__

=encoding utf-8

=head1 NAME

Paymill::REST::Item::Refund - Item class for a refund

=head1 SYNOPSIS

  my $refund_api = Paymill::REST::Refunds->new;
  $refund = $refund_api->find('refund_lk2j34h5lk34h5lkjh2');

  say $refund->amount;  # Prints amount of the refund

=head1 DESCRIPTION

Represents a refund with all attributes and all sub items.

=head1 ATTRIBUTES

=over 4

=item id

String containing the identifier of the client

=item amount

Integer containing the assigned amount

=item description

String containing the assigned description

=item status

String indicating the current status of the refund.  Can be one of:

=over

=item *

open

=item *

refunded

=item *

failed

=back

=item livemode

Boolean indicating whether this refund has been made with the live keys or not

=item created_at

L<DateTime> object indicating the date of the creation as returned by the API

=item updated_at

L<DateTime> object indicating the date of the last update as returned by the API

=item app_id

String representing the app id that issued this transaction

=back

=head1 SUB ITEMS

=over 4

=item transaction

A transaction object.

See also L<Paymill::REST::Item::Transaction>.

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
