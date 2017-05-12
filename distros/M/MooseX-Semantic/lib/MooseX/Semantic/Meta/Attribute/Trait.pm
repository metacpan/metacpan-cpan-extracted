package MooseX::Semantic::Meta::Attribute::Trait;
use Moose::Role;
use MooseX::Semantic::Types qw(TrineResource ArrayOfTrineResources);
use Data::Dumper;
with ( 'MooseX::HasDefaults::Meta::IsRW' );
=head1 NAME

MooseX::Semantic::Meta::Attribute::Trait - Attribute trait for semantic attributes

=head1 SYNOPSIS

    package My::Model::Person;
    use RDF::Trine::Namespace qw(foaf xsd);

    has name => (
        traits => ['Semantic'],
        is => 'rw',
        isa => 'Str',
        uri => $foaf->name,
        rdf_datatype => $xsd->string,
    );

    has knows => (
        traits => ['Semantic'],
        is => 'rw',
        isa => 'My::Model::Person',
        uri => $foaf->knows,
    );

=cut

=head1 DESCRIPTION

Attributes that apply the C<Semantic> trait can be extended using the attributes listed below.

By default, all Semantic attributes are read-write, i.e. C<is => 'rw'>.

=head1 ATTRIBUTES

=cut

=head2 uri

The URI of the property this attribute represents.

=cut

has uri => (
    is => 'rw',
    isa => TrineResource,
    coerce => 1,
    predicate => 'has_uri',
);

=head2 uri_reader

Additional URIs for this attribute that are checked when objects of this class
are imported from RDF using the MooseX::Semantic::Role::RdfImport role.

=cut

has uri_reader => (
    traits => ['Array'],
    is => 'rw',
    isa => ArrayOfTrineResources,
    coerce => 1,
    predicate => 'has_uri_reader',
    default => sub { [] },
    handles => {
        'get_uri_reader' => 'elements',
    }
);

=head2 uri_writer

Additional URIs for this attribute that generate additional statements when
this object is converted to RDF.

=cut

has uri_writer => (
    traits => ['Array'],
    is => 'rw',
    isa => ArrayOfTrineResources,
    coerce => 1,
    predicate => 'has_uri_writer',
    default => sub { [] },
    handles => {
        'get_uri_writer' => 'elements',
    }
);

=head2 rdf_datatype

RDF datatype for this resource. 

Makes sense only when the attribute in question is of a literal type, i.e.
C<Str>, C<Num> or descendants thereof.

=cut

has rdf_datatype => (
    is => 'rw',
    # XXX Maybe leave this Uri
    isa => TrineResource,
    coerce => 1,
    predicate => 'has_rdf_datatype',
);

=head2 rdf_lang

RDF language for this resource. 

Makes sense only when the attribute in question is of a literal type, i.e.
C<Str>, C<Bool>, C<Num> or descendants thereof.

=cut

has rdf_lang => (
    is => 'rw',
    isa => 'Str',
    predicate => 'has_rdf_lang',
);

# has rdfs_comment => (
#     # XXX this might blow up terribly, depending on how attributes are built (inf. recursion)
#     # XXX indeed it does. should be moved to a 'Semantic::Extended' trait or something
#     traits => ['Semantic'],
#     is => 'rw',
#     isa => 'Str',
#     predicate => 'has_rdfs_comment',
# );

=head2 rdf_formatter

CodeRef of a function for coercing the value to a RDF literal. Defaults to the identity function.

=cut

has rdf_formatter => (
    is => 'rw',
    isa => 'CodeRef',
    predicate => 'has_rdf_formatter',
    # default => sub { sub{ return $_[0] }},
);

=head2 rdf_parser

CodeRef of a function for parsing the literal value before importing this statement. Defaults to the identity function.

=cut

has rdf_parser => (
    is => 'rw',
    isa => 'CodeRef',
    default => sub {sub{ return $_[0] }},
);

has 'is' => (
    is => 'rw',
    default => 'rw',
);

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

