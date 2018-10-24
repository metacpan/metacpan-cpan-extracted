use utf8;

package SemanticWeb::Schema::EngineSpecification;

# ABSTRACT: Information about the engine of the vehicle

use Moo;

extends qw/ SemanticWeb::Schema::StructuredValue /;


use MooX::JSON_LD 'EngineSpecification';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';


has fuel_type => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'fuelType',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::EngineSpecification - Information about the engine of the vehicle

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

Information about the engine of the vehicle. A vehicle can have multiple
engines represented by multiple engine specification entities.

=head1 ATTRIBUTES

=head2 C<fuel_type>

C<fuelType>

The type of fuel suitable for the engine or engines of the vehicle. If the
vehicle has only one engine, this property can be attached directly to the
vehicle.

A fuel_type should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QualitativeValue']>

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::StructuredValue>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
