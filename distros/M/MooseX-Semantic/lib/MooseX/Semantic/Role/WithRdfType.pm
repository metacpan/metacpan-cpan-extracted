package MooseX::Semantic::Role::WithRdfType;
use Moose::Role;
# use MooseX::Role::Parameterized;
use MooseX::ClassAttribute;
use MooseX::Semantic::Types qw(ArrayOfTrineResources);

=head1 NAME

MooseX::Semantic::Role::WithRdfType - Role that for assigning a RDF type to a class

=head1 SYNOPSIS

    package My::Model::Person;
    use RDF::Trine::Namespace qw(foaf);
    with qw(MooseX::Semantic::Role::WithRdfType');
    __PACKAGE__->rdf_type($foaf->Person);

    package main;
    print My::Model::Person->rdf_type;


=head1 DESCRIPTION

A class that consumes this role has a class attribute C<rdf_type> that can be
used in exporting objects of this class to or creating objects from RDF data.

=head1 METHODS

=cut

=head2 rdf_type

Class Attribute that stores one or more rdf:type URIs. The URIs are stored as
an array of L<RDF::Trine::Resources|RDF::Trine::Resource> and can be coerced
from strings, L<URI> objects and arrays thereof.

=cut

class_has rdf_type => (
    traits => ['Array'],
    is => 'rw',
    isa => ArrayOfTrineResources,
    coerce => 1,
    default => sub { [] },
    handles => {
        list_rdf_types => 'elements',
        get_rdf_type => 'get',
    },
);

no MooseX::ClassAttribute;
no Moose;

1;

=head1 AUTHOR

Konstantin Baierer (<kba@cpan.org>)

=head1 SEE ALSO

=over 4

=item L<MooseX::Semantic|MooseX::Semantic>

=back

=cut

=head1 LICENCE AND COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

