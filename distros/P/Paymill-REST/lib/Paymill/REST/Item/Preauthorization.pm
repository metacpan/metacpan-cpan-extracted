package Paymill::REST::Item::Preauthorization;

use Moose;
use MooseX::Types::DateTime::ButMaintained qw(DateTime);

with 'Paymill::REST::Operations::Delete';

has _factory => (is => 'ro', isa => 'Object');

has id         => (is => 'ro', isa => 'Str');
has amount     => (is => 'ro', isa => 'Int', required => 1);
has currency   => (is => 'ro', isa => 'Str', required => 1);
has status     => (is => 'ro', isa => 'PreauthStatus');
has livemode   => (is => 'ro', isa => 'Bool');
has created_at => (is => 'ro', isa => DateTime, coerce => 1);
has updated_at => (is => 'ro', isa => DateTime, coerce => 1);
has app_id     => (is => 'ro', isa => 'Undef|Str');

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

no Moose;
1;
__END__

=encoding utf-8

=head1 NAME

Paymill::REST::Item::Preauthorization - Item class for a preauthorization

=head1 SYNOPSIS

  my $preauth_api = Paymill::REST::Preauthorizations->new;
  $preauth = $preauth_api->find('preauth_lk2j34h5lk34h5lkjh2');

  say $preauth->amount;  # Prints amount of the preauthorization

=head1 DESCRIPTION

Represents a preauthorization with all attributes and all sub items.

=head1 ATTRIBUTES

=over 4

=item id

String containing the identifier of the client

=item amount

Integer containing the assigned amount

=item currency

String containing the currency for the amount

=item status

String indicating the current status of the preauthorization.  Can be one of:

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

deleted

=item *

preauth

=back

=item livemode

Boolean indicating whether this preauthorization has been made with the live keys or not

=item created_at

L<DateTime> object indicating the date of the creation as returned by the API

=item updated_at

L<DateTime> object indicating the date of the last update as returned by the API

=item app_id

String representing the app id that created this preauthorization

=back

=head1 SUB ITEMS

=over 4

=item client

A client object.

See also L<Paymill::REST::Item::Client>.

=item payment

A payment object.

See also L<Paymill::REST::Item::Payment>.

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
