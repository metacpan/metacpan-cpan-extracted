use utf8;

package SemanticWeb::Schema::House;

# ABSTRACT: A house is a building or structure that has the ability to be occupied for habitation by humans or other creatures (Source: Wikipedia

use Moo;

extends qw/ SemanticWeb::Schema::Accommodation /;


use MooX::JSON_LD 'House';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';


has number_of_rooms => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'numberOfRooms',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::House - A house is a building or structure that has the ability to be occupied for habitation by humans or other creatures (Source: Wikipedia

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

=for html A house is a building or structure that has the ability to be occupied for
habitation by humans or other creatures (Source: Wikipedia, the free
encyclopedia, see <a
href="http://en.wikipedia.org/wiki/House">http://en.wikipedia.org/wiki/Hous
e</a>).

=head1 ATTRIBUTES

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

=head1 SEE ALSO

L<SemanticWeb::Schema::Accommodation>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
