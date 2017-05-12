use Test::More tests => 6;
use Test::Differences;
BEGIN { use_ok('RDF::Trine::Serializer::SparqlUpdate') };

use strict;
use warnings;
use Data::Dumper;

use RDF::Trine;
use RDF::Trine::Parser;

my $default = RDF::Trine::Node::Nil->new;
my $store	= RDF::Trine::Store->temporary_store();
my $model	= RDF::Trine::Model->new( $store );
my $model_quad	= RDF::Trine::Model->temporary_model;
my $model_quad_other	= RDF::Trine::Model->temporary_model;

my $cx1 = RDF::Trine::Node::Resource->new('http://w3c.org/');
my $cx2 = RDF::Trine::Node::Resource->new('http://perlrdf.org/');

my $rdf		= RDF::Trine::Namespace->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#');
my $foaf	= RDF::Trine::Namespace->new('http://xmlns.com/foaf/0.1/');
my $kasei	= RDF::Trine::Namespace->new('http://kasei.us/');

my $page	= $kasei->home; 
my $g		= RDF::Trine::Node::Blank->new('greg');
my $st0		= RDF::Trine::Statement->new( $g, $rdf->type, $foaf->Person );
my $st1		= RDF::Trine::Statement->new( $g, $foaf->name, RDF::Trine::Node::Literal->new('Greg') );
my $st2		= RDF::Trine::Statement->new( $g, $foaf->homepage, $page );
my $st3		= RDF::Trine::Statement->new( $page, $rdf->type, $foaf->Document );
my $quad1   = RDF::Trine::Statement::Quad->new( $kasei->Perl, $rdf->type, $kasei->GoodStuff, $g );
$model->add_statement( $_ ) for ($st0, $st1, $st2, $st3);
$model_quad->add_statement( $_, $cx1 ) for ( $st0, $st2 );
$model_quad->add_statement( $_, $cx2 ) for ( $st3 );
$model_quad->add_statement( $_ ) for ( $st1 );
$model_quad->add_statement( $quad1 );
$model_quad_other->add_statement( $_, $cx1 ) for ( $st1, $st3 );
$model_quad_other->add_statement( $_, $cx2 ) for ( $st0 );
$model_quad_other->add_statement( $_ ) for ( $st2 );

my $ser3 = RDF::Trine::Serializer::SparqlUpdate->new;
my $ser4 = RDF::Trine::Serializer::SparqlUpdate->new( quad_semantics => 1);
my $ser3_atomic = RDF::Trine::Serializer::SparqlUpdate->new( atomic => 1 );
my $ser4_atomic = RDF::Trine::Serializer::SparqlUpdate->new( quad_semantics => 1, atomic => 1);


sub eq_or_diff_without_nl {
    for my $i(0,1) {
        $_[$i] =~ s/\n//g;
    }
    return eq_or_diff( @_ );
}
unified_diff;
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

    my $string = $ser3->serialize_to_string( $model_quad_other );
    # warn Dumper $string;
    my ($type) = $ser4_atomic->media_types;

    my $req = HTTP::Request->new(POST => 'http://localhost/?sparql');
    $req->header(Content_Type => $type);
    $req->content( $string );
    # warn Dumper $sparql_model->size;
    is( $sparql_model->size, 0, 'Model empty before request');
    my $resp = $ua->request( $req );
    is( $sparql_model->size, 4, 'request addded 4 statements.');
    # warn Dumper $ser4->serialize_to_string( $sparql_model );
}
