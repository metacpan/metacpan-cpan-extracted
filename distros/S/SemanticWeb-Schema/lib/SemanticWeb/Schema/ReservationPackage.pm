use utf8;

package SemanticWeb::Schema::ReservationPackage;

# ABSTRACT: A group of multiple reservations with common values for all sub-reservations.

use Moo;

extends qw/ SemanticWeb::Schema::Reservation /;


use MooX::JSON_LD 'ReservationPackage';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';


has sub_reservation => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'subReservation',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ReservationPackage - A group of multiple reservations with common values for all sub-reservations.

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

A group of multiple reservations with common values for all
sub-reservations.

=head1 ATTRIBUTES

=head2 C<sub_reservation>

C<subReservation>

The individual reservations included in the package. Typically a repeated
property.

A sub_reservation should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Reservation']>

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
