use utf8;

package SemanticWeb::Schema::FlightReservation;

# ABSTRACT: A reservation for air travel

use Moo;

extends qw/ SemanticWeb::Schema::Reservation /;


use MooX::JSON_LD 'FlightReservation';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has boarding_group => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'boardingGroup',
);



has passenger_priority_status => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'passengerPriorityStatus',
);



has passenger_sequence_number => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'passengerSequenceNumber',
);



has security_screening => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'securityScreening',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::FlightReservation - A reservation for air travel

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

=for html A reservation for air travel.<br/><br/> Note: This type is for information
about actual reservations, e.g. in confirmation emails or HTML pages with
individual confirmations of reservations. For offers of tickets, use <a
class="localLink" href="http://schema.org/Offer">Offer</a>.

=head1 ATTRIBUTES

=head2 C<boarding_group>

C<boardingGroup>

The airline-specific indicator of boarding order / preference.

A boarding_group should be one of the following types:

=over

=item C<Str>

=back

=head2 C<passenger_priority_status>

C<passengerPriorityStatus>

The priority status assigned to a passenger for security or boarding (e.g.
FastTrack or Priority).

A passenger_priority_status should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QualitativeValue']>

=item C<Str>

=back

=head2 C<passenger_sequence_number>

C<passengerSequenceNumber>

The passenger's sequence number as assigned by the airline.

A passenger_sequence_number should be one of the following types:

=over

=item C<Str>

=back

=head2 C<security_screening>

C<securityScreening>

The type of security screening the passenger is subject to.

A security_screening should be one of the following types:

=over

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Reservation>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/SemanticWeb-Schema>
and may be cloned from L<git://github.com/robrwo/SemanticWeb-Schema.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/SemanticWeb-Schema/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
