use utf8;

package SemanticWeb::Schema::Airport;

# ABSTRACT: An airport.

use Moo;

extends qw/ SemanticWeb::Schema::CivicStructure /;


use MooX::JSON_LD 'Airport';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';


has iata_code => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'iataCode',
);



has icao_code => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'icaoCode',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Airport - An airport.

=head1 VERSION

version v0.0.2

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

=head2 C<icao_code>

C<icaoCode>

ICAO identifier for an airport.

A icao_code should be one of the following types:

=over

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::CivicStructure>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
