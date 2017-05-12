package MooseX::Semantic::Role::RdfImportAll;

use Moose::Role;
use namespace::autoclean;

use RDF::Trine::Namespace qw/rdf/;
use MooseX::Semantic::Types qw(ArrayOfTrineResources);
use Try::Tiny;

use Data::Dumper;

with( 'MooseX::Semantic::Role::RdfImport' );

=head1 NAME

MooseX::Semantic::Role::RdfImportAll - Import all resources from a RDF source

=head1 SYNOPSIS

    # multiple_persons.ttl
    @prefix foaf:   <http://xmlns.com/foaf/0.1/> .
    @prefix schema: <http://schema.org/> .
    <alice>
        a foaf:Person ;
        foaf:name "Alice" .
    <bob>
        a schema:Person ;
        foaf:name "Bob" .

    # My/Model/Person.pm
    package My::Model::Person;
    use Moose;
    with qw( MooseX::Semantic::Role::RdfImportAll MooseX::Semantic::Role::WithRdfType );
    __PACKAGE__->rdf_type([qw{http://xmlns.com/foaf/0.1/Person http://schema.org/Person}]);
    has name => (
        is         => 'rw',
        traits     => ['Semantic'],
        uri        => 'http://xmlns.com/foaf/0.1/name',
        uri_reader => [qw(http://schema.org/name)]
    );
    ...

    # your script
    my $model = RDF::Trine::Model->new;
    RDF::Trine::Parser::Turtle->new->parse_file_into_model(
        'http://example.com/',
        'multiple_persons.ttl',
        $model
    );
    my @people = My::Model::Person->import_all_from_model($model);
    print $people[0]->name;     # prints 'Alice'
    print $people[1]->name;     # prints 'Bob'
    

=head1 DESCRIPTION

=head1 METHODS

=cut

=head2 import_all

C<import_all( %opts )>

For C<%opts> see L<IMPORT OPTIONS> below.

=cut

sub import_all {
    my $class = shift;
    my %opts = @_;
    my $model = delete $opts{model};
    if ($model) {
        return $class->import_all_from_model( $model, %opts );
    }
    my $uris = delete $opts{uri};
    $uris = delete( $opts{uris} ) unless $uris;
    if ( $uris ) {
        return $class->import_all_from_web( $uris, %opts );
    }
    confess "Must specify either 'uri' or 'model' to 'import_all'";
}

=head2 import_all_from_model

C<import_all_from_model( $model, %opts )>

Imports all resources from C<$model>.

For C<%opts> see L<IMPORT OPTIONS> below.

=cut

sub import_all_from_model {
    my ($class, $model, %opts ) = @_;
    my @rdf_types = $class->_get_rdf_types_from_opts_or_class(%opts);
    
    my %resources; # use hash to uniquify results.
    foreach my $type (@rdf_types) {
        # warn Dumper $type;
        $model->subjects($rdf->type, $type)->each(sub {
            my $r = shift;
            $resources{ $r } = $r;
        });
    }

    my @return;
    foreach my $r (values %resources) {
        my $R;
        # Skip over resources which throw exceptions.
        # Usually they are missing a required property.
        try {
            $R = $class->new_from_model($model, $r);
        } catch {
            # warn $r;
            # warn substr( $_, 0, 20);
        };
        # skip undefined resources
        next unless defined $R;
        # skip blank nodes if $opts{skip_blank} is set
        next if ($opts{skip_blank} && $R->rdf_about->is_blank);
        push @return, $R;
    }
    @return;
}

=head2 import_all_from_web

C<import_all_from_web( $uris, %opts )>

TODO

For C<%opts> see L<IMPORT OPTIONS> below.

=cut

sub import_all_from_web {
    my ($class, $opt_uris, %opts) = @_;
    my @uris = @{ $opt_uris };

    confess "Must specify at least one 'uri' for import_all_from_web." unless scalar @uris;

    my @rdf_types = $class->_get_rdf_types_from_opts_or_class(%opts);
    
    my $model = RDF::Trine::Model->temporary_model;
    RDF::Trine::Parser->parse_url_into_model($_, $model)
        foreach @uris;
    return $class->import_all_from_model($model, %opts);
}

sub _get_rdf_types_from_opts_or_class {
    my ($class, %opts) = @_;
    my $rdf_types;
    if ($opts{rdf_type}) {
        $rdf_types = ArrayOfTrineResources->coerce( $opts{rdf_type} );
    }
    else {
        confess("Class $class has no associated RDF types and no 'rdf_type' argument was specified.")
            unless $class->can('rdf_type') && scalar $class->list_rdf_types;
        $rdf_types = [$class->list_rdf_types];
    }
    # warn Dumper $rdf_types;
    return @{$rdf_types};
}

no Moose;
1;

=head1 IMPORT OPTIONS

=over 4

=item C<rdf_type>

Additional rdf:types

=item C<model>

The model to import from

=item C<uris>

=item C<uri>

An array reference of URIs to import

=item C<skip_blank>

If set to true, blank nodes (i.e. resources without a URI) are skipped.

=back

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

