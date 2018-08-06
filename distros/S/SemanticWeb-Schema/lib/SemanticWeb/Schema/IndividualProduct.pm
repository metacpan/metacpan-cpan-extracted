package SemanticWeb::Schema::IndividualProduct;

# ABSTRACT: A single, identifiable product instance (e

use Moo;

extends qw/ SemanticWeb::Schema::Product /;


use MooX::JSON_LD 'IndividualProduct';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';


has serial_number => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'serialNumber',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::IndividualProduct - A single, identifiable product instance (e

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

A single, identifiable product instance (e.g. a laptop with a particular
serial number).

=head1 ATTRIBUTES

=head2 C<serial_number>

C<serialNumber>

The serial number or any alphanumeric identifier of a particular product.
When attached to an offer, it is a shortcut for the serial number of the
product included in the offer.

A serial_number should be one of the following types:

=over

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Product>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
