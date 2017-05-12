use Test::More 'no_plan';
use Test::Exception;

use Data::Dumper;

use constant DONE => 1;

my $AG_SERVER = $ENV{AG3_SERVER};

unless ($AG_SERVER) {
    ok (1, 'Tests skipped. Use "export AG3_SERVER=http://my.server:port" before running the test suite. See README for details.');
    exit;
}

use RDF::AllegroGraph::Server3;
use_ok ('RDF::AllegroGraph::Catalog3');

if (DONE) {
    my $server = new RDF::AllegroGraph::Server (ADDRESS => $AG_SERVER);
    my $vienna = new RDF::AllegroGraph::Catalog3 (NAME => '/scratch', SERVER => $server);
    like ($vienna->version,  qr/^3\./, 'store version');
    like ($vienna->protocol, qr/\d/,   'protocol version');
    my %cats = $server->catalogs;
    is ((scalar keys %cats), 1, 'only scratch found');
    isa_ok ($cats{'/scratch'}, 'RDF::AllegroGraph::Catalog3');

    my $scratch = new RDF::AllegroGraph::Catalog3 (NAME => '/scratch', SERVER => $server);
    my $proto = $scratch->protocol;
    like ($proto, qr/4/,   'protocol version');
}

if (DONE) {
    my $server = new RDF::AllegroGraph::Server (ADDRESS => $AG_SERVER);
    my $scratch = new RDF::AllegroGraph::Catalog3 (NAME => '/scratch', SERVER => $server);
    {
	my @repos = $scratch->repositories;
	is ((scalar @repos), 0, 'not a single repository');
    }
    throws_ok {
	use Fcntl;
	$scratch->repository ('/scratchxxx/catlitter', O_CREAT);
    } qr/cannot open/, 'wrong naming for catalogs';

    my $model = $scratch->repository ('/scratch/catlitter');
    isa_ok ($model, 'RDF::AllegroGraph::Repository');
    @repos = $scratch->repositories;
    is ((scalar @repos), 1, 'a single repository');

#    warn Dumper \@repos;

    $model->disband;
    @repos = $scratch->repositories;
    is ((scalar @repos), 0, 'no more repository');
}


__END__

