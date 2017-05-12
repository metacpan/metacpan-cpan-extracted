package Paymill::REST::Item::Offer;

use Moose;
use MooseX::Types::DateTime::ButMaintained qw(DateTime);

with 'Paymill::REST::Operations::Delete';

has _factory => (is => 'ro', isa => 'Object');

has id                 => (is => 'ro', isa => 'Str');
has name               => (is => 'ro', isa => 'Str', required => 1);
has amount             => (is => 'ro', isa => 'Int', required => 1);
has currency           => (is => 'ro', isa => 'Str', required => 1);
has interval           => (is => 'ro', isa => 'Str', required => 1);
has trial_period_days  => (is => 'ro', isa => 'Int|Undef');
has created_at         => (is => 'ro', isa => DateTime, coerce => 1);
has updated_at         => (is => 'ro', isa => DateTime, coerce => 1);
has subscription_count => (is => 'ro', isa => 'HashRef');
has app_id             => (is => 'ro', isa => 'Undef|Str');

no Moose;
1;
__END__

=encoding utf-8

=head1 NAME

Paymill::REST::Item::Offer - Item class for an offer

=head1 SYNOPSIS

  my $offer_api = Paymill::REST::Offers->new;
  $offer = $offer_api->find('offer_lk2j34h5lk34h5lkjh2');

  say $offer->name;  # Prints name assigned to the offer

=head1 DESCRIPTION

Represents an offer with all attributes.

=head1 ATTRIBUTES

=over 4

=item id

String containing the identifier of the client

=item name

String containing the assigned name

=item amount

Integer containing the assigned amount

=item currency

String containing the currency in which the amount will be charged

=item interval

String representing the interval in which the amount will be charged

=item trial_period_days

Integer representing the defined trial days

=item subscription_count

Hashref with keys C<active> and C<inactive>

=item created_at

L<DateTime> object indicating the date of the creation as returned by the API

=item updated_at

L<DateTime> object indicating the date of the last update as returned by the API

=item app_id

String representing the app id that created this offer

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
