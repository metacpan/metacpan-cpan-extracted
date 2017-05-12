use Test::More skip_all => 'nothing to see here - yet :D';
use RDF::Trine;
use Data::Dumper;
use RDF::Trine::Serializer::SparqlUpdate;

my $store	= RDF::Trine::Store->temporary_store();
my $model	= RDF::Trine::Model->new( $store );

my $rdf		= RDF::Trine::Namespace->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#');
my $foaf	= RDF::Trine::Namespace->new('http://xmlns.com/foaf/0.1/');
my $kasei	= RDF::Trine::Namespace->new('http://kasei.us/');

my $context1 = RDF::Trine::Node::Resource->new('http://kons.ti/#me');
my $page	= RDF::Trine::Node::Resource->new('http://kasei.us/');
my $g		= RDF::Trine::Node::Blank->new('greg');
my $st0		= RDF::Trine::Statement->new( $g, $rdf->type, $foaf->Person );
my $st1		= RDF::Trine::Statement->new( $g, $foaf->name, RDF::Trine::Node::Literal->new('Greg') );
my $st2		= RDF::Trine::Statement::Quad->new( $g, $foaf->homepage, $page, $page );
my $st3		= RDF::Trine::Statement->new( $page, $rdf->type, $foaf->Document );
$model->add_statement( $_, $context1 ) for ($st0, $st1, $st3);
my $model2 = RDF::Trine::Model->temporary_model;
$model2->add_statement( $st2 );

my $ser = RDF::Trine::Serializer::SparqlUpdate->new( quad_semantics => 1 );

# warn Dumper $ser->_create_clause( 'INSERT', $st0 );
# warn Dumper $ser->serialize_iterator_to_string( $st0, delete => $st2 );
# warn Dumper $ser->_serialize_data( $model );
# my $iter = $model->get_contexts;
# while ($_ = $iter->next) {
#     warn Dumper $_;
# }
