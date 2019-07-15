use utf8;

package SemanticWeb::Schema::Flight;

# ABSTRACT: An airline flight.

use Moo;

extends qw/ SemanticWeb::Schema::Trip /;


use MooX::JSON_LD 'Flight';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has aircraft => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'aircraft',
);



has arrival_airport => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'arrivalAirport',
);



has arrival_gate => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'arrivalGate',
);



has arrival_terminal => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'arrivalTerminal',
);



has boarding_policy => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'boardingPolicy',
);



has carrier => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'carrier',
);



has departure_airport => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'departureAirport',
);



has departure_gate => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'departureGate',
);



has departure_terminal => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'departureTerminal',
);



has estimated_flight_duration => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'estimatedFlightDuration',
);



has flight_distance => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'flightDistance',
);



has flight_number => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'flightNumber',
);



has meal_service => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'mealService',
);



has seller => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'seller',
);



has web_checkin_time => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'webCheckinTime',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Flight - An airline flight.

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

An airline flight.

=head1 ATTRIBUTES

=head2 C<aircraft>

The kind of aircraft (e.g., "Boeing 747").

A aircraft should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Vehicle']>

=item C<Str>

=back

=head2 C<arrival_airport>

C<arrivalAirport>

The airport where the flight terminates.

A arrival_airport should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Airport']>

=back

=head2 C<arrival_gate>

C<arrivalGate>

Identifier of the flight's arrival gate.

A arrival_gate should be one of the following types:

=over

=item C<Str>

=back

=head2 C<arrival_terminal>

C<arrivalTerminal>

Identifier of the flight's arrival terminal.

A arrival_terminal should be one of the following types:

=over

=item C<Str>

=back

=head2 C<boarding_policy>

C<boardingPolicy>

The type of boarding policy used by the airline (e.g. zone-based or
group-based).

A boarding_policy should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::BoardingPolicyType']>

=back

=head2 C<carrier>

'carrier' is an out-dated term indicating the 'provider' for parcel
delivery and flights.

A carrier should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=back

=head2 C<departure_airport>

C<departureAirport>

The airport where the flight originates.

A departure_airport should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Airport']>

=back

=head2 C<departure_gate>

C<departureGate>

Identifier of the flight's departure gate.

A departure_gate should be one of the following types:

=over

=item C<Str>

=back

=head2 C<departure_terminal>

C<departureTerminal>

Identifier of the flight's departure terminal.

A departure_terminal should be one of the following types:

=over

=item C<Str>

=back

=head2 C<estimated_flight_duration>

C<estimatedFlightDuration>

The estimated time the flight will take.

A estimated_flight_duration should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Duration']>

=item C<Str>

=back

=head2 C<flight_distance>

C<flightDistance>

The distance of the flight.

A flight_distance should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Distance']>

=item C<Str>

=back

=head2 C<flight_number>

C<flightNumber>

The unique identifier for a flight including the airline IATA code. For
example, if describing United flight 110, where the IATA code for United is
'UA', the flightNumber is 'UA110'.

A flight_number should be one of the following types:

=over

=item C<Str>

=back

=head2 C<meal_service>

C<mealService>

Description of the meals that will be provided or available for purchase.

A meal_service should be one of the following types:

=over

=item C<Str>

=back

=head2 C<seller>

An entity which offers (sells / leases / lends / loans) the services /
goods. A seller may also be a provider.

A seller should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<web_checkin_time>

C<webCheckinTime>

The time when a passenger can check into the flight online.

A web_checkin_time should be one of the following types:

=over

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Trip>

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
