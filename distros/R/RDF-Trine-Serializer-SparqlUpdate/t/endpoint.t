use Test::More tests => 5;
use common::sense;
use RDF::Trine;
use Data::Dumper;

my $store	= RDF::Trine::Store->temporary_store();
my $model	= RDF::Trine::Model->new( $store );

my $rdf		= RDF::Trine::Namespace->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#');
my $foaf	= RDF::Trine::Namespace->new('http://xmlns.com/foaf/0.1/');
my $kasei	= RDF::Trine::Namespace->new('http://kasei.us/');

my $page	= RDF::Trine::Node::Resource->new('http://kasei.us/');
my $g		= RDF::Trine::Node::Blank->new('greg');
my $st0		= RDF::Trine::Statement->new( $g, $rdf->type, $foaf->Person );
my $st1		= RDF::Trine::Statement->new( $g, $foaf->name, RDF::Trine::Node::Literal->new('Greg') );
my $st2		= RDF::Trine::Statement->new( $g, $foaf->homepage, $page );
my $st3		= RDF::Trine::Statement->new( $page, $rdf->type, $foaf->Document );
$model->add_statement( $_ ) for ($st0, $st1, $st2, $st3);

{
    require_ok('RDF::Endpoint');
    require_ok('LWP::Protocol::PSGI');
    require_ok('RDF::Trine::Serializer::SparqlUpdate');
    my $end_config  = {
        store => 'Memory',
        endpoint    => {
            endpoint_path   => '/',
            update      => 1,
            load_data   => 1,
            html        => {
                resource_links  => 1,    # turn resources into links in HTML query result pages
                embed_images    => 0,    # display foaf:Images as images in HTML query result pages
                image_width     => 200,  # with 'embed_images', scale images to this width
            },
            service_description => {
                default         => 1,    # generate dataset description of the default graph
                named_graphs    => 1,    # generate dataset description of the available named graphs
            },
        },
    };
    my $sparql_model = RDF::Trine::Model->temporary_model;
    my $end     = RDF::Endpoint->new( $sparql_model, $end_config );
    my $end_app = sub {
        my $env 	= shift;
        my $req 	= Plack::Request->new($env);
        my $resp	= $end->run( $req );
        return $resp->finalize;
    };
    LWP::Protocol::PSGI->register($end_app);
    my $ua = LWP::UserAgent->new;

    my $serializer	= RDF::Trine::Serializer::SparqlUpdate->new;
    my $string = $serializer->serialize_model_to_string( $model );
    # warn Dumper $string;
    my ($type) = $serializer->media_types;

    my $req = HTTP::Request->new(POST => 'http://localhost/?sparql');
    $req->header(Content_Type => $type);
    $req->content( $string );
    # warn Dumper $sparql_model->size;
    is( $sparql_model->size, 0, 'Model empty before request');
    my $resp = $ua->request( $req );
    is( $sparql_model->size, 4, 'request addded 4 statements.');
}
