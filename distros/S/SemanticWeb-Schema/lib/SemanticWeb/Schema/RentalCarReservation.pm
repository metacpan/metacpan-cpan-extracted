use utf8;

package SemanticWeb::Schema::RentalCarReservation;

# ABSTRACT: A reservation for a rental car

use Moo;

extends qw/ SemanticWeb::Schema::Reservation /;


use MooX::JSON_LD 'RentalCarReservation';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';


has dropoff_location => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'dropoffLocation',
);



has dropoff_time => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'dropoffTime',
);



has pickup_location => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'pickupLocation',
);



has pickup_time => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'pickupTime',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::RentalCarReservation - A reservation for a rental car

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

=for html A reservation for a rental car.<br/><br/> Note: This type is for
information about actual reservations, e.g. in confirmation emails or HTML
pages with individual confirmations of reservations.

=head1 ATTRIBUTES

=head2 C<dropoff_location>

C<dropoffLocation>

Where a rental car can be dropped off.

A dropoff_location should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<dropoff_time>

C<dropoffTime>

When a rental car can be dropped off.

A dropoff_time should be one of the following types:

=over

=item C<Str>

=back

=head2 C<pickup_location>

C<pickupLocation>

Where a taxi will pick up a passenger or a rental car can be picked up.

A pickup_location should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<pickup_time>

C<pickupTime>

When a taxi will pickup a passenger or a rental car can be picked up.

A pickup_time should be one of the following types:

=over

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Reservation>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
