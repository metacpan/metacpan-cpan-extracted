package MooseX::Semantic::Role::Graph;
use Moose::Role;
use MooseX::Semantic::Types qw(TrineModel TrineLiteral TrineNode TrineResource );
use RDF::Trine qw(iri literal statement);
use Data::Dumper;

with qw(
    MooseX::Semantic::Role::Resource
);

=head1 NAME

MooseX::Semantic::Role::Graph - Role for Moose objects that represent named graphs

=cut

=head2 

=head2 SYNOPSIS

    package GraphPackage;
    use Moose;
    with qw( MooseX::Semantic::Role::Graph MooseX::Semantic::Role::RdfExport );
    has 'timestamp' => (
        traits => ['Semantic'],
        is => 'rw',
        default => '1234',
        uri => 'dc:date',
    );
    package main;
    my $g = GraphPackage->new;
    $g->rdf_graph->add_statement(statement iri('A'), iri('B'), iri('C') );

=cut

=head2 ATTRIBUTES

=head3 rdf_graph

The model this graph represents

=cut

has rdf_graph => (
    traits => ['Semantic'],
    is => 'rw',
    isa => TrineModel,
    coerce => 1,
    default => sub { TrineModel->coerce },
    uri => 'http://moosex-semantic.org/onto#rdf_graph',
    # lazy => 1,
    handles => [qw(
        add_statement
        get_statements
    )],
);

=head2 METHODS

=head3 From RDF::Trine::Model

=over 4

=item add_statement

=item get_statements

=back

=head3 add_statement_smartly

More DWIMmy version of RDF::Trine::Model->add_statmeent

WARNING: Don't use this

=cut

sub add_statement_smartly {
    my $self = shift;
    my @args = @_;

    $args[0] = TrineResource->coerce($args[0]);
    $args[1] = TrineResource->coerce($args[1]);
    $args[2] = TrineLiteral->coerce($args[2]);
    return $self->rdf_graph->add_statement(statement(@args));
}


1;
