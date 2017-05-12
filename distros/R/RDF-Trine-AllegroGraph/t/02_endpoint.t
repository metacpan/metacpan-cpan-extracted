use lib '../allegro/lib';

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;

use Data::Dumper;

use RDF::Trine::Store::AllegroGraph;

use constant DONE => 1;

my $AG4_SERVER = $ENV{AG4_SERVER};

unless ($AG4_SERVER) {
    ok (1, 'Tests skipped. Use "export AG4_SERVER=http://my.server:port" before running the test suite. See README for details.');
    exit;
}

if (DONE) {
    use RDF::Trine::Store::AllegroGraph;
    my $trine = RDF::Trine::Store->new_with_string( "AllegroGraph;$AG4_SERVER/scratch/catlitter" );
    _populate ();

    no warnings qw(taint);
    my $tester = do "t/endpoint.psgi";
    BAIL_OUT("The application is not running") unless ($tester);

#    use Log::Log4perl qw(:easy);
#    Log::Log4perl->easy_init( { level   => $FATAL } ) unless $ENV{TEST_VERBOSE};

    use Test::WWW::Mechanize::PSGI;
    my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester, requests_redirectable => []);
    my $res = $mech->get("/");
    is($mech->status, 200, "Returns 200");

    _test_results ( $mech );
    $trine->_nuke;

sub _populate {
    my $type        = RDF::Trine::Node::Resource->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#type');
    my $person      = RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/person');

    $trine->add_statement ($_) foreach ( map { RDF::Trine::Statement->new(
									  RDF::Trine::Node::Resource->new('http://example.org/'.$_),
									  $type, $person)
					 } qw(alice eve bob));
}

sub _test_results {
    my $mech = shift;

    my $sparql = q{
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
SELECT $a
WHERE { $a a foaf:person . }
};

    use HTTP::Request::Common;
    $mech->post_ok ( '/', { query        => $sparql,
			    'media-type' => 'application/json'} , "POSTing a SPARQL query" );
    
    use RDF::Trine::Iterator;
    my $i = RDF::Trine::Iterator->from_json ( $mech->content );

    my %expects = map { "http://example.org/".$_ => 1 } qw(alice bob eve);
    while (my $row = $i->next) {
	delete $expects{ $row->{'a'}->uri_value };
    }
    ok (keys %expects == 0, 'no more expected, all received');
}

}


__END__
    use LWP::UserAgent;
    my $ua = LWP::UserAgent->new;
    my $res = $ua->request($req);

    ok ($res->is_success, 'endpoint responded');

    {
	use threads;
	my $rh = threads->create (sub {
	    use Carp qw(confess);
	    my $end = RDF::Endpoint->new( $config );

	    warn Dumper $config; exit;
	    sub {
		my $env     = shift;
		my $req     = Plack::Request->new($env);
		my $resp    = $end->run( $req );
		return $resp->finalize;
	    }

	});
	sleep 5; # wait it to be up

	_test_results ();

	$rh->kill('KILL')->detach();
    }
