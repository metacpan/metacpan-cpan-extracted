#!/usr/bin/env perl

use FindBin qw($Bin);
use Plack::Request;

use strict;
use Test::More;# tests => 23;
use Test::RDF;
use Test::Exception;

my $file = $Bin . '/data/basic.ttl';

use Log::Any::Adapter;

Log::Any::Adapter->set($ENV{LOG_ADAPTER} || 'Stderr') if $ENV{TEST_VERBOSE};

BEGIN {
    use_ok('RDF::LinkedData');
    use_ok('URI::NamespaceMap');
    use_ok('RDF::Helper::Properties');
    use_ok('RDF::Trine::Parser');
    use_ok('RDF::Trine::Model');
}



my $parser     = RDF::Trine::Parser->new( 'turtle' );
my $model = RDF::Trine::Model->temporary_model;
my $base_uri = 'http://localhost';
$parser->parse_file_into_model( $base_uri, $file, $model );

ok($model, "We have a model");

my $ld = RDF::LinkedData->new(model => $model, base_uri=>$base_uri, hypermedia => 0);

isa_ok($ld, 'RDF::LinkedData');
is($ld->count, 3, "There are 3 triples in model");
is_deeply($ld->model, $model, "The model is still the model");

is($ld->base_uri, $base_uri, "The base is still the base");

my $node = $ld->my_node(URI->new($base_uri . '/foo'));

isa_ok($node, 'RDF::Trine::Node::Resource');

is($node->uri_value, 'http://localhost/foo', "URI is still there");

my $preds = RDF::Helper::Properties->new(model => $model);

is($preds->title($node), 'This is a test', "Correct title");

{
    my $req = Plack::Request->new({ HTTP_ACCEPT  => 'application/rdf+xml' });
    my $ldh = $ld;
	 $ldh->namespaces(URI::NamespaceMap->new({ skos => 'http://www.w3.org/2004/02/skos/core#', dc => 'http://purl.org/dc/terms/' } ));
    $ldh->request($req);
    my $content = $ldh->_content($node, 'data');
	 like($content->{body}, qr|xmlns:skos="http://www.w3.org/2004/02/skos/core#"|, 'SKOS NS URI');
    is($content->{content_type}, 'application/rdf+xml', "RDF/XML content type");
}

{
    my $req = Plack::Request->new({ HTTP_ACCEPT	=> 'application/turtle'});
    my $ldh = $ld;
    $ldh->request($req);
    my $content = $ldh->_content($node, 'data');
    is($content->{content_type}, 'application/turtle', "Turtle content type");
    is_valid_rdf($content->{body}, 'turtle', '/foo return RDF validates');
    is_rdf($content->{body}, 'turtle',
	   "\@base <http://localhost/> .\n\@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema\#> .\n\n </foo> rdfs:label \"This is a test\"\@en ; \n<http://xmlns.com/foaf/0.1/page> <http://en.wikipedia.org/wiki/Foo> .",
			  'turtle',
			  '/foo return RDF is OK');
	 like($content->{body}, qr/\@base <$base_uri> ./, 'Base URI is present in serialization');
}

my $barnode = $ld->my_node(URI->new($base_uri . '/bar/baz/bing'));
isa_ok($node, 'RDF::Trine::Node::Resource');

is($barnode->uri_value, 'http://localhost/bar/baz/bing', "'Bar' URI is still there");

{
    my $req = Plack::Request->new({ HTTP_ACCEPT	=> 'text/html'});
    my $ldh = $ld;
    $ldh->request($req);
	 my $content = $ldh->_content($barnode, 'data');
	 is($content->{content_type}, 'text/html', "HTML is proper data type");
	 {
		 my $mcontent = $ldh->_content($barnode, 'page');
		 is($mcontent->{content_type}, 'text/html', "Page gives HTML");
	 }
}

is($preds->page($node), 'http://en.wikipedia.org/wiki/Foo', "/foo has a foaf:page at Wikipedia");

is($preds->page($barnode), 'http://localhost/bar/baz/bing/page', "/bar/baz/bing has default page");

done_testing;
