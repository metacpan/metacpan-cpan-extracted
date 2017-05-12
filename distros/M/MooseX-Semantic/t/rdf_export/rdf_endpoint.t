use Test::More; 
use Test::Moose;
use Data::Dumper;
use RDF::Endpoint;
use LWP::Protocol::PSGI;
use Config::JFDI;
use MooseX::Semantic::Test::Person;
my $endpoint_config = Config::JFDI->open( name => "RDF::Endpoint", path => 't/config') or die "Couldn't find config";
my $model = RDF::Trine::Model->temporary_model;
my $end     = RDF::Endpoint->new( $model, $endpoint_config );
my $end_app = sub {
    my $env 	= shift;
    my $req 	= Plack::Request->new($env);
    my $resp	= $end->run( $req );
	return $resp->finalize;
};

# XXX this is pure awesomeness for testing
LWP::Protocol::PSGI->register($end_app);

my $p = MooseX::Semantic::Test::Person->new(
    'name' => 'ABC',
);

my $in_sparu = $p->export_to_string( format => 'sparqlu' );
# warn Dumper $in_sparu;

my $model_size_old = $end->{model}->size;
is( $model_size_old, 0, 'Start with empty model');
my $resp = $p->export_to_web( POST => "http://localhost", format => 'sparqlu' );
is( $resp->status_line, "200 OK", 'export was accepted by RDF::Endpoint');
is( $resp->request->method, 'POST', 'Server was requested using POST');
my $model_size_new = $end->{model}->size;
is($model_size_new, 2, 'Model now contains exported rdf data.');

is($resp->request->content, $in_sparu, 'Server received correct serialization');

done_testing;
