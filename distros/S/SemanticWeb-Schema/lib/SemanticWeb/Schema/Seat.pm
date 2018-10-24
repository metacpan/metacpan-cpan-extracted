use utf8;

package SemanticWeb::Schema::Seat;

# ABSTRACT: Used to describe a seat

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'Seat';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';


has seat_number => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'seatNumber',
);



has seat_row => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'seatRow',
);



has seat_section => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'seatSection',
);



has seating_type => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'seatingType',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Seat - Used to describe a seat

=head1 VERSION

version v0.0.2

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

=head2 C<seat_row>

C<seatRow>

The row location of the reserved seat (e.g., B).

A seat_row should be one of the following types:

=over

=item C<Str>

=back

=head2 C<seat_section>

C<seatSection>

The section location of the reserved seat (e.g. Orchestra).

A seat_section should be one of the following types:

=over

=item C<Str>

=back

=head2 C<seating_type>

C<seatingType>

The type/class of the seat.

A seating_type should be one of the following types:

=over

=item C<Str>

=item C<InstanceOf['SemanticWeb::Schema::QualitativeValue']>

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
