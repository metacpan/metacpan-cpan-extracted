package Paymill::REST::Item::Subscription;

use Moose;
use MooseX::Types::DateTime::ButMaintained qw(DateTime);

with 'Paymill::REST::Operations::Delete';

has _factory => (is => 'ro', isa => 'Object');

has id                   => (is => 'ro', isa => 'Str');
has livemode             => (is => 'ro', isa => 'Bool');
has created_at           => (is => 'ro', isa => DateTime, coerce => 1);
has updated_at           => (is => 'ro', isa => DateTime, coerce => 1);
has canceled_at          => (is => 'ro', isa => 'Undef|DateTime', coerce => 1);
has trial_start          => (is => 'ro', isa => 'Undef|DateTime', coerce => 1);
has trial_end            => (is => 'ro', isa => 'Undef|DateTime', coerce => 1);
has next_capture_at      => (is => 'ro', isa => 'DateTime|Bool', coerce => 1);
has cancel_at_period_end => (is => 'ro', isa => 'Bool');
has app_id               => (is => 'ro', isa => 'Undef|Str');

has client => (
    is      => 'ro',
    isa     => 'Undef|Str|Object|HashRef',
    trigger => sub { Paymill::REST::TypesAndTriggers::item_from_hashref('client', @_) }
);
has payment => (
    is      => 'ro',
    isa     => 'Undef|Object|HashRef',
    trigger => sub { Paymill::REST::TypesAndTriggers::item_from_hashref('payment', @_) }
);
has offer => (
    is      => 'ro',
    isa     => 'Undef|Object|HashRef|ArrayRef',
    trigger => sub { Paymill::REST::TypesAndTriggers::item_from_hashref('offer', @_) }
);

no Moose;
1;
__END__

=encoding utf-8

=head1 NAME

Paymill::REST::Item::Subscription - Item class for a subscription

=head1 SYNOPSIS

  my $subscription_api = Paymill::REST::Subscriptions->new;
  $subscription = $subscription_api->find('sub_lk2j34h5lk34h5lkjh2');

  say $subscription->id;  # Prints the id of the subscription

=head1 DESCRIPTION

Represents a subscription with all attributes and all sub items.

=head1 ATTRIBUTES

=over 4

=item id

String containing the identifier of the client

=item livemode

Boolean indicating whether this preauthorization has been made with the live keys or not

=item created_at

L<DateTime> object indicating the date of the creation as returned by the API

=item updated_at

L<DateTime> object indicating the date of the last update as returned by the API

=item canceled_at

L<DateTime> object indicating the cancellation date of the subcription

=item trial_start

L<DateTime> object indicating the date the trial period started

=item trial_end

L<DateTime> object indicating the date the trial period ended

=item next_capture_at

L<DateTime> object indicating the date of the next charging, or boolean if subscription is cancelled

=item cancel_at_period_end

Boolean indicating whether the subscription will be cancelled at the end of this period

=item app_id

String representing the app id that created this subscription

=back

=head1 SUB ITEMS

=over 4

=item client

A client object.

See also L<Paymill::REST::Item::Client>.

=item offer

An offer object.

See also L<Paymill::REST::Item::Offer>.

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
