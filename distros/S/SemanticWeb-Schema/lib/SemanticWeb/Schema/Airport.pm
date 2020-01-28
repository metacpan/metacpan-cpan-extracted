use utf8;

package SemanticWeb::Schema::Airport;

# ABSTRACT: An airport.

use Moo;

extends qw/ SemanticWeb::Schema::CivicStructure /;


use MooX::JSON_LD 'Airport';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v6.0.0';


has iata_code => (
    is        => 'rw',
    predicate => '_has_iata_code',
    json_ld   => 'iataCode',
);



has icao_code => (
    is        => 'rw',
    predicate => '_has_icao_code',
    json_ld   => 'icaoCode',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Airport - An airport.

=head1 VERSION

version v6.0.0

=head1 DESCRIPTION

An airport.

=head1 ATTRIBUTES

=head2 C<iata_code>

C<iataCode>

IATA identifier for an airline or airport.

A iata_code should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_iata_code>

A predicate for the L</iata_code> attribute.

=head2 C<icao_code>

C<icaoCode>

ICAO identifier for an airport.

A icao_code should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_icao_code>

A predicate for the L</icao_code> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::CivicStructure>

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
