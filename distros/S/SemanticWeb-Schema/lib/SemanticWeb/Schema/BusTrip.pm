package SemanticWeb::Schema::BusTrip;

# ABSTRACT: A trip on a commercial bus line.

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'BusTrip';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';


has arrival_bus_stop => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'arrivalBusStop',
);



has arrival_time => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'arrivalTime',
);



has bus_name => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'busName',
);



has bus_number => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'busNumber',
);



has departure_bus_stop => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'departureBusStop',
);



has departure_time => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'departureTime',
);



has provider => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'provider',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::BusTrip - A trip on a commercial bus line.

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

A trip on a commercial bus line.

=head1 ATTRIBUTES

=head2 C<arrival_bus_stop>

C<arrivalBusStop>

The stop or station from which the bus arrives.

A arrival_bus_stop should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::BusStop']>

=item C<InstanceOf['SemanticWeb::Schema::BusStation']>

=back

=head2 C<arrival_time>

C<arrivalTime>

The expected arrival time.

A arrival_time should be one of the following types:

=over

=item C<Str>

=back

=head2 C<bus_name>

C<busName>

The name of the bus (e.g. Bolt Express).

A bus_name should be one of the following types:

=over

=item C<Str>

=back

=head2 C<bus_number>

C<busNumber>

The unique identifier for the bus.

A bus_number should be one of the following types:

=over

=item C<Str>

=back

=head2 C<departure_bus_stop>

C<departureBusStop>

The stop or station from which the bus departs.

A departure_bus_stop should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::BusStation']>

=item C<InstanceOf['SemanticWeb::Schema::BusStop']>

=back

=head2 C<departure_time>

C<departureTime>

The expected departure time.

A departure_time should be one of the following types:

=over

=item C<Str>

=back

=head2 C<provider>

The service provider, service operator, or service performer; the goods
producer. Another party (a seller) may offer those services or goods on
behalf of the provider. A provider may also serve as the seller.

A provider should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Intangible>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
