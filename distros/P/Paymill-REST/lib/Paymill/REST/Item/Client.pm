package Paymill::REST::Item::Client;

use Moose;
use MooseX::Types::DateTime::ButMaintained qw(DateTime);

with 'Paymill::REST::Operations::Delete';

has _factory => (is => 'ro', isa => 'Object');

has id          => (is => 'ro', isa => 'Str');
has description => (is => 'ro', isa => 'Undef|Str');
has email       => (is => 'ro', isa => 'Undef|Str');
has created_at  => (is => 'ro', isa => DateTime, coerce => 1);
has updated_at  => (is => 'ro', isa => DateTime, coerce => 1);
has app_id      => (is => 'ro', isa => 'Undef|Str');

has subscription => (
    is      => 'ro',
    isa     => 'Undef|Object|ArrayRef',
    trigger => sub { Paymill::REST::TypesAndTriggers::items_from_arrayref('subscription', @_) }
);
has payment => (
    is      => 'ro',
    isa     => 'Undef|Object|ArrayRef',
    trigger => sub { Paymill::REST::TypesAndTriggers::items_from_arrayref('payment', @_) }
);

no Moose;
1;
__END__

=encoding utf-8

=head1 NAME

Paymill::REST::Item::Client - Item class for a client

=head1 SYNOPSIS

  my $client_api = Paymill::REST::Clients->new;
  $client = $client_api->find('client_lk2j34h5lk34h5lkjh2');

  say $client->email;  # Prints email address assigned to the client

=head1 DESCRIPTION

Represents a client with all attributes and all sub items.

=head1 ATTRIBUTES

=over 4

=item id

String containing the identifier of the client

=item description

String containing the assigned description

=item email

String containing the assigned email

=item created_at

L<DateTime> object indicating the date of the creation as returned by the API

=item updated_at

L<DateTime> object indicating the date of the last update as returned by the API

=item app_id

String representing the app id that created this client

=back

=head1 SUB ITEMS

=over 4

=item subscription

One or a list of subscriptions, depends on the returned values from the API.

See also L<Paymill::REST::Item::Subscription>.

=item payment

One or a list of payments, depends on the returned values from the API.

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
