use Test::More 'no_plan';
use Test::Exception;

use Data::Dumper;

use_ok( 'RDF::AllegroGraph::Easy' );

use constant DONE => 1;


my $AG_SERVER = $ENV{AG4_SERVER};

unless ($AG_SERVER) {
    ok (1, 'Tests skipped. Use "export AG4_SERVER=http://my.server:port" before running the test suite. See README for details.');
    exit;
}


if (DONE) {
    my $storage;

    throws_ok {
	$storage = new RDF::AllegroGraph::Easy ('xyz');
    } qr/ADDRESS/, 'invalid server address';

    throws_ok {
	$storage = new RDF::AllegroGraph::Easy ('http://localhost:1111');
    } qr/./, 'implicit testing of connectivity'; 

    throws_ok {
	$storage = new RDF::AllegroGraph::Easy (undef, TEST => 1 );
    } qr/connect/, 'testing of connectivity (default)';
}

if (DONE) {
    my $storage = new RDF::AllegroGraph::Easy ($AG_SERVER);
    my %models = $storage->models;
    is (scalar keys %models, 0, 'no model to begin with');

    use Fcntl;
    my $model1 = $storage->model ('/scratch/catlitter1', mode => O_CREAT);
    isa_ok ($model1, 'RDF::AllegroGraph::Repository', 'catlitter created');

       %models = $storage->models;
    is (scalar keys %models, 1, 'one model in the list');
    isa_ok ($models{'/scratch/catlitter1'}, 'RDF::AllegroGraph::Repository');


    my $model2 = $storage->model ('/catlitter2', mode => O_CREAT);
       %models = $storage->models;
    is (scalar keys %models, 2, 'models in the list');
    isa_ok ($models{'/catlitter2'}, 'RDF::AllegroGraph::Repository');

    $model1->disband;
    throws_ok {
	my $model = $storage->model ('/scratch/catlitter1');
    } qr/cannot/, 'no more catlitter1';

    my $model = $storage->model ('/catlitter2');
    ok ($model, '2nd model still here');

    $model2->disband;
    throws_ok {
        my $model = $storage->model ('/catlitter2');
    } qr/cannot/, 'no more catlitter2';

# TODO wrong path /xxx
}

__END__

