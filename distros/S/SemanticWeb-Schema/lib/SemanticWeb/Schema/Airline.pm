use utf8;

package SemanticWeb::Schema::Airline;

# ABSTRACT: An organization that provides flights for passengers.

use Moo;

extends qw/ SemanticWeb::Schema::Organization /;


use MooX::JSON_LD 'Airline';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';


has boarding_policy => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'boardingPolicy',
);



has iata_code => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'iataCode',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Airline - An organization that provides flights for passengers.

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

An organization that provides flights for passengers.

=head1 ATTRIBUTES

=head2 C<boarding_policy>

C<boardingPolicy>

The type of boarding policy used by the airline (e.g. zone-based or
group-based).

A boarding_policy should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::BoardingPolicyType']>

=back

=head2 C<iata_code>

C<iataCode>

IATA identifier for an airline or airport.

A iata_code should be one of the following types:

=over

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Organization>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
