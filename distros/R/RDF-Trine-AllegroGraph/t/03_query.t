use lib '../allegro/lib';

use Test::More 'no_plan';
use Test::Exception;

use Data::Dumper;

use_ok( 'RDF::Trine::Store::AllegroGraph' );

use constant DONE => 1;

my $AG4_SERVER = $ENV{AG4_SERVER};

unless ($AG4_SERVER) {
    ok (1, 'Tests skipped. Use "export AG4_SERVER=http://my.server:port" before running the test suite. See README for details.');
    exit;
}

my $p1          = RDF::Trine::Node::Resource->new('http://example.org/alice');
my $p2          = RDF::Trine::Node::Resource->new('http://example.org/eve');
my $p3          = RDF::Trine::Node::Resource->new('http://example.org/bob');
my $type        = RDF::Trine::Node::Resource->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#type');
my $person      = RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/person');

if (DONE) {
    use RDF::Trine::Store::AllegroGraph;
    my $trine = RDF::Trine::Store->new_with_string( "AllegroGraph;$AG4_SERVER/scratch/catlitter" );

    my $st         = RDF::Trine::Statement->new( $p3, $type, $person );
    $trine->add_statement ($st);

    use RDF::Trine::Model;
    my $model = RDF::Trine::Model->new ($trine);

    use RDF::Query;
    my $query = RDF::Query->new( 'SELECT $a $b WHERE { $a a $b . }', { lang => 'sparql' }  );
#    warn Dumper $query;
    my $iterator = $query->execute( $model );
#    warn Dumper $iterator;
    while (my $row = $iterator->next) {
       is ($row->{a}->uri_value, 'http://example.org/bob',           'binding for a, AG native SPARQL');
       is ($row->{b}->uri_value, 'http://xmlns.com/foaf/0.1/person', 'binding for b, AG native SPARQL');
    }

    $query = RDF::Query->new( 'SELECT $a $b WHERE { $a a $b . }', { lang => 'sparql11' }  );   # not going to AG
#    warn Dumper $query;
    $iterator = $query->execute( $model );
#    warn Dumper $iterator;
    while (my $row = $iterator->next) {
       is ($row->{a}->uri_value, 'http://example.org/bob',           'binding for a, SPARQL 1.1');
       is ($row->{b}->uri_value, 'http://xmlns.com/foaf/0.1/person', 'binding for b, SPARQL 1.1');
    }

    $trine->_nuke;
}

