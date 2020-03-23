use utf8;

package SemanticWeb::Schema::BusTrip;

# ABSTRACT: A trip on a commercial bus line.

use Moo;

extends qw/ SemanticWeb::Schema::Trip /;


use MooX::JSON_LD 'BusTrip';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.0';


has arrival_bus_stop => (
    is        => 'rw',
    predicate => '_has_arrival_bus_stop',
    json_ld   => 'arrivalBusStop',
);



has bus_name => (
    is        => 'rw',
    predicate => '_has_bus_name',
    json_ld   => 'busName',
);



has bus_number => (
    is        => 'rw',
    predicate => '_has_bus_number',
    json_ld   => 'busNumber',
);



has departure_bus_stop => (
    is        => 'rw',
    predicate => '_has_departure_bus_stop',
    json_ld   => 'departureBusStop',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::BusTrip - A trip on a commercial bus line.

=head1 VERSION

version v7.0.0

=head1 DESCRIPTION

A trip on a commercial bus line.

=head1 ATTRIBUTES

=head2 C<arrival_bus_stop>

C<arrivalBusStop>

The stop or station from which the bus arrives.

A arrival_bus_stop should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::BusStation']>

=item C<InstanceOf['SemanticWeb::Schema::BusStop']>

=back

=head2 C<_has_arrival_bus_stop>

A predicate for the L</arrival_bus_stop> attribute.

=head2 C<bus_name>

C<busName>

The name of the bus (e.g. Bolt Express).

A bus_name should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_bus_name>

A predicate for the L</bus_name> attribute.

=head2 C<bus_number>

C<busNumber>

The unique identifier for the bus.

A bus_number should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_bus_number>

A predicate for the L</bus_number> attribute.

=head2 C<departure_bus_stop>

C<departureBusStop>

The stop or station from which the bus departs.

A departure_bus_stop should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::BusStation']>

=item C<InstanceOf['SemanticWeb::Schema::BusStop']>

=back

=head2 C<_has_departure_bus_stop>

A predicate for the L</departure_bus_stop> attribute.

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

This software is Copyright (c) 2018-2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
