use utf8;

package SemanticWeb::Schema::BoatTrip;

# ABSTRACT: A trip on a commercial ferry line.

use Moo;

extends qw/ SemanticWeb::Schema::Trip /;


use MooX::JSON_LD 'BoatTrip';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v9.0.0';


has arrival_boat_terminal => (
    is        => 'rw',
    predicate => '_has_arrival_boat_terminal',
    json_ld   => 'arrivalBoatTerminal',
);



has departure_boat_terminal => (
    is        => 'rw',
    predicate => '_has_departure_boat_terminal',
    json_ld   => 'departureBoatTerminal',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::BoatTrip - A trip on a commercial ferry line.

=head1 VERSION

version v9.0.0

=head1 DESCRIPTION

A trip on a commercial ferry line.

=head1 ATTRIBUTES

=head2 C<arrival_boat_terminal>

C<arrivalBoatTerminal>

The terminal or port from which the boat arrives.

A arrival_boat_terminal should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::BoatTerminal']>

=back

=head2 C<_has_arrival_boat_terminal>

A predicate for the L</arrival_boat_terminal> attribute.

=head2 C<departure_boat_terminal>

C<departureBoatTerminal>

The terminal or port from which the boat departs.

A departure_boat_terminal should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::BoatTerminal']>

=back

=head2 C<_has_departure_boat_terminal>

A predicate for the L</departure_boat_terminal> attribute.

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
