package MooseX::Semantic::Role::RdfBackend;
use  Moose::Role;
use MooseX::ClassAttribute;
use MooseX::Semantic::Types qw(ArrayOfTrineResources TrineStore);
use Data::Dumper;
# use MooseX::Role::Parameterized;

with (
    # Class role
    'MooseX::Semantic::Role::WithRdfType',
    'MooseX::Semantic::Role::Resource',
);


=head1 NAME

MooseX::Semantic::Role::RdfBackend - Associate a class with a RDF::Trine::Store

=head1 SYNOPSIS

    # My/Model/Person.pm
    package My::Model::Person;
    use Moose;
    with qw(MooseX::Semantic::Role::RdfBackend);
    __PACKAGE__->rdf_store({
        storetype => 'DBI',
        name => 'semantic_moose',
        dsn => 'dbi:SQLite:dbname=t/data/semantic_moose.sqlite',
        username => 'FAKE',
        password => 'FAKE',
    });
    ...

    # your script
    my $p = My::Model::Person->new( rdf_about => 'http://mydomain.org/data/John' );
    $p->store();
    my $x = My::Model::Person->new_from_store( 'http://mydomain.org/data/John' );
    print $x->rdf_about     # prints "<http://mydomain.org/data/John>"


=head1 DESCRIPTION

=cut

=head1 CLASS ATTRIBUTES

=head2 rdf_store

Reference to a lazily built RDF::Trine::Store object. Can be instantiated with everything
that L<RDF::Trine::Store's|RDF::Trine::Store> C<new> method accepts, i.e. a DSN-like string,
a hash reference of options or a blessed object.

=cut

class_has rdf_store => (
    is => 'rw',
    lazy => 1,
    coerce => 1,
    isa => TrineStore,
    default => sub { TrineStore->coerce; }, # XXX is this really what we want by default - a volatile store?
);

=head1 METHODS

=head2 new_from_store

C<new_from_store( $uri )>

Searches the RDF store for a resource C<$uri> and tries to instantiate an object
using the C<new_from_model> method of L<MooseX::Semantic::Role::RdfImport>.

=cut

sub new_from_store {
    my ($cls, $uri) = @_;
    my $model = RDF::Trine::Model->new( $cls->rdf_store );
    return $cls->new_from_model( $model, $uri );
}

=head2 store

Exports an instance to RDF into the model underlying the RDF store.

=cut

sub store {
    my ($inst) = @_;
    my $model = RDF::Trine::Model->new( $inst->rdf_store );
    $inst->export_to_model( $model );
}

=head1 CONSUMED ROLES

=over 4

=item L<MooseX::Semantic::Role::WithRdfType>

=item L<MooseX::Semantic::Role::Resource>

=back

=cut

1;

=head1 AUTHOR

Konstantin Baierer (<kba@cpan.org>)

=head1 SEE ALSO

=over 4

=item L<MooseX::Semantic|MooseX::Semantic>

=item L<RDF::Trine::Store|RDF::Trine::Store>

=back

=cut

=head1 LICENCE AND COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

