#=======================================================================
# graph.t
#=======================================================================
use common::sense;
use Test::Most tests => 6;
use RDF::Trine qw(iri statement);
use Data::Dumper;
use Scalar::Util qw(refaddr);

{
    package GraphPackage;
    use Moose;
    with qw( MooseX::Semantic::Role::Graph MooseX::Semantic::Role::RdfExport MooseX::Semantic::Role::RdfImport );
    has 'timestamp' => (
        traits => ['Semantic'],
        is => 'rw',
        default => '1234',
        uri => 'dc:date',
    );
}

my $g = GraphPackage->new(rdf_about => 'graph_1');
# warn Dumper $g->rdf_graph;
$g->add_statement(statement iri('A'), iri('B'), iri('C') );
$g->add_statement_smartly('D', 'E', 'F');
# warn Dumper $g->rdf_graph;
# warn Dumper ref $g->rdf_graph;
# warn Dumper $g->export_to_hash;
# warn Dumper $g->export_to_string(format=>'nquads');
is($g->rdf_about->as_string, '<graph_1>');
ok($g->get_statements(iri 'A', iri 'B', iri 'C')->next);

diag "round trip";
# warn Dumper $g->rdf_graph->get_statements->next;
# warn Dumper $g->export_to_model;
my $g_model = $g->export_to_model;
my $g2 = GraphPackage->new_from_model($g_model, $g->rdf_about);
# warn Dumper $g2->rdf_graph->get_statements->next;
ok($g2->get_statements->next);

# warn Dumper $g->export_to_string(format=>'nquads');
# warn Dumper $g2->export_to_string(format=>'nquads');
is($g->export_to_string(format=>'nquads'), $g2->export_to_string(format=>'nquads') );
isnt(refaddr $g, refaddr $g2);
isnt(refaddr $g->rdf_graph, refaddr $g2->rdf_graph);
