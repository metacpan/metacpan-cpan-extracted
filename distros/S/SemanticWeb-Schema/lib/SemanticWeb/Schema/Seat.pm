use utf8;

package SemanticWeb::Schema::Seat;

# ABSTRACT: Used to describe a seat

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'Seat';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v6.0.0';


has seat_number => (
    is        => 'rw',
    predicate => '_has_seat_number',
    json_ld   => 'seatNumber',
);



has seat_row => (
    is        => 'rw',
    predicate => '_has_seat_row',
    json_ld   => 'seatRow',
);



has seat_section => (
    is        => 'rw',
    predicate => '_has_seat_section',
    json_ld   => 'seatSection',
);



has seating_type => (
    is        => 'rw',
    predicate => '_has_seating_type',
    json_ld   => 'seatingType',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Seat - Used to describe a seat

=head1 VERSION

version v6.0.0

=head1 DESCRIPTION

Used to describe a seat, such as a reserved seat in an event reservation.

=head1 ATTRIBUTES

=head2 C<seat_number>

C<seatNumber>

The location of the reserved seat (e.g., 27).

A seat_number should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_seat_number>

A predicate for the L</seat_number> attribute.

=head2 C<seat_row>

C<seatRow>

The row location of the reserved seat (e.g., B).

A seat_row should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_seat_row>

A predicate for the L</seat_row> attribute.

=head2 C<seat_section>

C<seatSection>

The section location of the reserved seat (e.g. Orchestra).

A seat_section should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_seat_section>

A predicate for the L</seat_section> attribute.

=head2 C<seating_type>

C<seatingType>

The type/class of the seat.

A seating_type should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QualitativeValue']>

=item C<Str>

=back

=head2 C<_has_seating_type>

A predicate for the L</seating_type> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::Intangible>

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
