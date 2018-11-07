use utf8;

package SemanticWeb::Schema::BedDetails;

# ABSTRACT: An entity holding detailed information about the available bed types

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'BedDetails';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';


has number_of_beds => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'numberOfBeds',
);



has type_of_bed => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'typeOfBed',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::BedDetails - An entity holding detailed information about the available bed types

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

=for html An entity holding detailed information about the available bed types, e.g.
the quantity of twin beds for a hotel room. For the single case of just one
bed of a certain type, you can use bed directly with a text. See also <a
class="localLink" href="http://schema.org/BedType">BedType</a> (under
development).

=head1 ATTRIBUTES

=head2 C<number_of_beds>

C<numberOfBeds>

The quantity of the given bed type available in the HotelRoom, Suite,
House, or Apartment.

A number_of_beds should be one of the following types:

=over

=item C<Num>

=back

=head2 C<type_of_bed>

C<typeOfBed>

The type of bed to which the BedDetail refers, i.e. the type of bed
available in the quantity indicated by quantity.

A type_of_bed should be one of the following types:

=over

=item C<Str>

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
