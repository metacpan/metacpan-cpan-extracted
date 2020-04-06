use utf8;

package SemanticWeb::Schema::Suite;

# ABSTRACT: A suite in a hotel or other public accommodation

use Moo;

extends qw/ SemanticWeb::Schema::Accommodation /;


use MooX::JSON_LD 'Suite';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.3';


has bed => (
    is        => 'rw',
    predicate => '_has_bed',
    json_ld   => 'bed',
);



has number_of_rooms => (
    is        => 'rw',
    predicate => '_has_number_of_rooms',
    json_ld   => 'numberOfRooms',
);



has occupancy => (
    is        => 'rw',
    predicate => '_has_occupancy',
    json_ld   => 'occupancy',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Suite - A suite in a hotel or other public accommodation

=head1 VERSION

version v7.0.3

=head1 DESCRIPTION

=for html <p>A suite in a hotel or other public accommodation, denotes a class of
luxury accommodations, the key feature of which is multiple rooms (Source:
Wikipedia, the free encyclopedia, see <a
href="http://en.wikipedia.org/wiki/Suite_(hotel)">http://en.wikipedia.org/w
iki/Suite_(hotel)</a>). <br /><br /> See also the <a
href="/docs/hotels.html">dedicated document on the use of schema.org for
marking up hotels and other forms of accommodations</a>.<p>

=head1 ATTRIBUTES

=head2 C<bed>

The type of bed or beds included in the accommodation. For the single case
of just one bed of a certain type, you use bed directly with a text. If you
want to indicate the quantity of a certain kind of bed, use an instance of
BedDetails. For more detailed information, use the amenityFeature property.

A bed should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::BedDetails']>

=item C<InstanceOf['SemanticWeb::Schema::BedType']>

=item C<Str>

=back

=head2 C<_has_bed>

A predicate for the L</bed> attribute.

=head2 C<number_of_rooms>

C<numberOfRooms>

The number of rooms (excluding bathrooms and closets) of the accommodation
or lodging business. Typical unit code(s): ROM for room or C62 for no unit.
The type of room can be put in the unitText property of the
QuantitativeValue.

A number_of_rooms should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=item C<Num>

=back

=head2 C<_has_number_of_rooms>

A predicate for the L</number_of_rooms> attribute.

=head2 C<occupancy>

The allowed total occupancy for the accommodation in persons (including
infants etc). For individual accommodations, this is not necessarily the
legal maximum but defines the permitted usage as per the contractual
agreement (e.g. a double room used by a single person). Typical unit
code(s): C62 for person

A occupancy should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<_has_occupancy>

A predicate for the L</occupancy> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::Accommodation>

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
