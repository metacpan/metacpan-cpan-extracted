use Test::More 'no_plan';
use Test::Exception;

use Data::Dumper;

use constant DONE => 1;

my $AG_SERVER = $ENV{AG4_SERVER};
unless ($AG_SERVER) {
    ok (1, 'Tests skipped. Use "export AG4_SERVER=http://my.server:port" before running the test suite. See README for details.');
    exit;
}

if (DONE) {
    use RDF::AllegroGraph::Server;
    my $server = new RDF::AllegroGraph::Server (ADDRESS => $AG_SERVER);
    # TODO: generate scratch here
    use RDF::AllegroGraph::Catalog4;
    my $scratch = new RDF::AllegroGraph::Catalog4 (NAME => '/scratch', SERVER => $server);

    use Fcntl;
    my $model  = $scratch->repository ('/scratch/catlitter', O_CREAT);

    my $cwd = `pwd`; chomp $cwd;
    $model->add ("file://$cwd/t/kennedy.n3");
    $model->namespace ('kdy' => 'http://www.franz.com/simple#');
    
#    my @stms = $model->match ([ '<http://www.franz.com/simple#person12>', undef, undef ]);
#    warn Dumper \@stms;

    my @ss1 = $model->sparql ('SELECT ?p ?o WHERE { kdy:person1 ?p ?o .}' );
#    warn Dumper \@ss;

    my $se = $model->session;
    isa_ok ($se, 'RDF::AllegroGraph::Session4');
    isa_ok ($se, 'RDF::AllegroGraph::Repository');

    is ($se->ping, 'pong', 'session alive');

    my @ss2 = $model->sparql ('SELECT ?p ?o WHERE { kdy:person1 ?p ?o .}' );
    is ((scalar @ss1), (scalar @ss2), 'session has the same data');

    throws_ok {
	$se->rules (q{ xxx });
    } qr/MALFORMED PROGRAM/, 'sending borken LISP Prolog';

    lives_ok {
	$se->rules (q{
	    (<-- (woman ?person) ;; IF
	     (q ?person !kdy:sex !kdy:female)
	     (q ?person !rdf:type !kdy:person))
	    (<-- (man ?person) ;; IF
	     (q ?person !kdy:sex !kdy:male)
	     (q ?person !rdf:type !kdy:person))
	    });
    } 'LISP correct';

    throws_ok {
	$model->prolog (q{
	(select (?person)
	        (man ?person)
	        ( q ?person !rdf:type !kdy:person )
        )
	});
    } qr/undefined function/, 'unknown rules';

    my @ss3 = $se->prolog (q{
	(select (?person)
	        (man ?person)
	        ( q ?person !rdf:type      !kdy:person )
	        ( q ?person !kdy:last-name !"Shriver" )
        )
	});

#    warn Dumper \@ss3;
    ok (eq_array ([
		   sort
		   map { $_->[0] } @ss3 
		   ],
		  [
		   sort
		   map { "<http://www.franz.com/simple#person$_>"}
		   (10, 25, 28, 31, 33)
		   ]
		  ), 'all male Shrivers');


    $model->disband;
}

__END__

