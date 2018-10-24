use utf8;

package SemanticWeb::Schema::Suite;

# ABSTRACT: A suite in a hotel or other public accommodation

use Moo;

extends qw/ SemanticWeb::Schema::Accommodation /;


use MooX::JSON_LD 'Suite';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';


has bed => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'bed',
);



has number_of_rooms => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'numberOfRooms',
);



has occupancy => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'occupancy',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Suite - A suite in a hotel or other public accommodation

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

=for html A suite in a hotel or other public accommodation, denotes a class of luxury
accommodations, the key feature of which is multiple rooms (Source:
Wikipedia, the free encyclopedia, see <a
href="http://en.wikipedia.org/wiki/Suite_(hotel)">http://en.wikipedia.org/w
iki/Suite_(hotel)</a>). <br /><br /> See also the <a
href="/docs/hotels.html">dedicated document on the use of schema.org for
marking up hotels and other forms of accommodations</a>.

=head1 ATTRIBUTES

=head2 C<bed>

The type of bed or beds included in the accommodation. For the single case
of just one bed of a certain type, you use bed directly with a text. If you
want to indicate the quantity of a certain kind of bed, use an instance of
BedDetails. For more detailed information, use the amenityFeature property.

A bed should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::BedDetails']>

=item C<Str>

=back

=head2 C<number_of_rooms>

C<numberOfRooms>

The number of rooms (excluding bathrooms and closets) of the accommodation
or lodging business. Typical unit code(s): ROM for room or C62 for no unit.
The type of room can be put in the unitText property of the
QuantitativeValue.

A number_of_rooms should be one of the following types:

=over

=item C<Num>

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

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

=head1 SEE ALSO

L<SemanticWeb::Schema::Accommodation>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
