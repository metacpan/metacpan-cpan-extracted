use lib '../allegro/lib';

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;

use Data::Dumper;

use RDF::Trine::Store::AllegroGraph;

use constant DONE => 0;

my $AG4_SERVER = $ENV{AG4_SERVER};

unless ($AG4_SERVER) {
    ok (1, 'Tests skipped. Use "export AG4_SERVER=http://my.server:port" before running the test suite. See README for details.');
    exit;
}

if (1||DONE) {
    use RDF::Trine::Store;
    my $store = RDF::Trine::Store->new_with_string( "AllegroGraph;$AG4_SERVER/scratch/catlitter" );
    use RDF::Trine::Model;
    my $model = RDF::Trine::Model->new ($store);

    my $p1          = RDF::Trine::Node::Resource->new('http://example.org/alice');
    my $type        = RDF::Trine::Node::Resource->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#type');
    my $person      = RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/person');

    my $st          = RDF::Trine::Statement->new( $p1, $type, $person );

    is ($model->count_statements( $st->nodes ), 0, 'no such statement');

    $model->begin_bulk_ops;
    $model->add_statement ($st);
    is ($model->{store}->{model}->size, 0,         'added, but not in the store');
    is ($model->count_statements( $st->nodes ), 1, 'now added one statement in bulk');


    $model->begin_bulk_ops;
    $model->add_statement ($_) foreach ( map { RDF::Trine::Statement->new(
									  RDF::Trine::Node::Resource->new('http://example.org/'.$_),
									  $type, $person)
					 } qw(alice eve bob rumsti));
    is ($model->{store}->{model}->size, 1,         'added more, but not in the store');
    $model->end_bulk_ops;
    is ($model->{store}->{model}->size, 4,         'added more, but now in the store');

    is ($model->count_statements( undef, $type, $person ), 4, 'now added all statements in bulk');

    $model->_store->_nuke; # dirtyish
    exit;




}


