use Test::More 'no_plan';
use Test::Exception;

use Data::Dumper;

use_ok( 'RDF::AllegroGraph::Catalog4' );

use constant DONE => 1;

my $AG_SERVER = $ENV{AG4_SERVER};
unless ($AG_SERVER) {
    diag ('Tests skipped. Use "export AG4_SERVER=http://my.server:port" before running the test suite. See README for details.');
    exit;
}

if (DONE) {
    use RDF::AllegroGraph::Server;
    my $server = new RDF::AllegroGraph::Server (ADDRESS => $AG_SERVER);
    my %cats = $server->catalogs;
    isa_ok ($cats{'/'}, 'RDF::AllegroGraph::Catalog4');
    isa_ok ($cats{'/'}, 'RDF::AllegroGraph::Catalog');
    ok ($cats{'/'}->{SERVER} == $server, 'server captured');
}

diag ("the following only works if a named catalog 'scratch' is configured");

if (DONE) { # protocol versions
    my $server = new RDF::AllegroGraph::Server (ADDRESS => $AG_SERVER);
    { 
	my $root = new RDF::AllegroGraph::Catalog4 (NAME => '/', SERVER => $server);
	like ($root->protocol, qr/4/,   'protocol version for the root');
    }
  TODO: {
      local $TODO = 'protocols for named catalogs';
      my $scratch = new RDF::AllegroGraph::Catalog4 (NAME => '/scratch', SERVER => $server);
      my $proto;
      eval {
	  $proto = $scratch->protocol;
      };
      like ($proto, qr/4/,   'protocol version');
  }
}

if (DONE) { # this only works if "Dynamic Catalogs" are configured
    my $server = new RDF::AllegroGraph::Server (ADDRESS => $AG_SERVER);

    my $c = $server->catalog ('/scratch');
    isa_ok ($c, 'RDF::AllegroGraph::Catalog4');
    isa_ok ($c, 'RDF::AllegroGraph::Catalog');
    is ($c->{NAME}, '/scratch', 'existing: NAME');
    is ($c->{SERVER}, $server, 'existing: server hook');

    throws_ok {
	$c = $server->catalog ('/scratchy');
    } qr /cannot/, 'non-existing catalog not found';

    diag ("the following only works if 'Dynamic Catalogs' are configured");

    use Fcntl;
    $c = $server->catalog ('/scratchy', O_CREAT);
    isa_ok ($c, 'RDF::AllegroGraph::Catalog4');
    isa_ok ($c, 'RDF::AllegroGraph::Catalog');
    is ($c->{NAME}, '/scratchy', 'newly created: NAME');
    is ($c->{SERVER}, $server, 'newly created: server hook');

    my $c2 = $server->catalog ('/scratchy');
    isa_ok ($c2, 'RDF::AllegroGraph::Catalog4');
    isa_ok ($c2, 'RDF::AllegroGraph::Catalog');
    is ($c2->{NAME}, '/scratchy', 'newly created: NAME');
    is ($c2->{SERVER}, $server, 'newly created: server hook');


    $c2->disband;
    throws_ok {
	$c = $server->catalog ('/scratchy');
    } qr /cannot/, 'deleted catalog not found';
}


if (DONE) { # test root catalog repo creation
    my $server = new RDF::AllegroGraph::Server (ADDRESS => $AG_SERVER);
    my $root = new RDF::AllegroGraph::Catalog4 (NAME => '/', SERVER => $server);
    my @repos = $root->repositories;
    ok (scalar @repos == 0, 'no repositories at start');

    throws_ok {
	use Fcntl;
	$root->repository ('/scratchxxx/catlitter1', O_CREAT);
    } qr/root/, 'wrong naming for catalogs';

    use Fcntl;
    my $model1  = $root->repository ('/catlitter1', O_CREAT);
    @repos = $root->repositories;
    ok (scalar @repos == 1, 'one repository created');
    is ($repos[0]->id, '/catlitter1', 'with correct name');

    my $model2  = $root->repository ('/catlitter2', O_CREAT);
    @repos = $root->repositories;
    ok (scalar @repos == 2, 'two repositories created');
    ok (eq_array ([  map { $_->id }  @repos ],
		  [ '/catlitter1', '/catlitter2' ]), 'with correct names');

    $model1->disband;
    $model2->disband;
    @repos = $root->repositories;
    ok (scalar @repos == 0, 'none anymore');
    
}

if (DONE) { # test non-existing catalog
    my $server = new RDF::AllegroGraph::Server (ADDRESS => $AG_SERVER);
    throws_ok {
	new RDF::AllegroGraph::Catalog4 (NAME => '/rumstibumsti', SERVER => $server);
    } qr/does not ex/, 'non-existing catalog detected at constructor time';
}

if (DONE) { # test scratch catalog, if it exists
    my $server = new RDF::AllegroGraph::Server (ADDRESS => $AG_SERVER);
    eval {
	my $scratch = new RDF::AllegroGraph::Catalog4 (NAME => '/scratch', SERVER => $server);
	my @repos = $scratch->repositories;
	ok (scalar @repos == 0, 'no repositories at start');
	
	throws_ok {
	    use Fcntl;
	    $scratch->repository ('/scratchxxx/catlitter1', O_CREAT);
	} qr/named/, 'wrong naming for catalogs';
	
	my $model1  = $scratch->repository ('/scratch/catlitter1', O_CREAT);
	@repos = $scratch->repositories;
	ok (scalar @repos == 1, 'one repository created');
	is ($repos[0]->id, '/scratch/catlitter1', 'with correct name');
	
	my $model2  = $scratch->repository ('/scratch/catlitter2', O_CREAT);
	@repos = $scratch->repositories;
	ok (scalar @repos == 2, 'two repositories created');
	ok (eq_array ([  map { $_->id }  @repos ],
		      [ '/scratch/catlitter1', '/scratch/catlitter2' ]), 'with correct names');
	
	$model1->disband;
	$model2->disband;
	@repos = $scratch->repositories;
	ok (scalar @repos == 0, 'none anymore');
	
    }; if ($@) {
	diag ('Test on catalog scratch ... uhm scratch, because it does not exist on the server');
    }
}


__END__
