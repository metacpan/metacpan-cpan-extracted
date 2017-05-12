use strict;
use warnings;
use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use JSON;

use Plack::App::RDF::Files;

my $app = Plack::App::RDF::Files->new(
    base_dir => 't/data',
    base_uri => 'http://example.org/'
);

test_psgi $app, sub {
    my ($cb, $res) = @_;

    $res = $cb->(GET "/xxx");
    is $res->code, 404, "not found";

    $res = $cb->(HEAD "/alice");
    is $res->code, 200, 'HEAD ok';

    $res = $cb->(GET "/alice", 'If-None-Match' => $res->header('ETag'));
    is $res->code, 304, 'ETag 304 Not Modified';

    foreach my $type (qw(text/turtle application/rdf+xml application/x-rdf+json)) {
        $res = $cb->(HEAD "/alice", Accept => $type);
        is $res->code, 200, 'HEAD ok';
        is $res->header('content-type'), $type, "HEAD $type";
    }

    $res = $cb->(GET "/alice");
    is $res->code, 200;
    is $res->content,
        "<http://example.org/alice> <http://xmlns.com/foaf/0.1/knows> \"B\\u00F6b\" .\n",
        "simple graph";

    $res = $cb->(GET "/foo");
    is $res->code, 200;
    is $res->content,
        "<http://example.org/foo> a <http://www.w3.org/2000/01/rdf-schema#Resource> .\n",
        "empty graph";

    $res = $cb->(GET "/foo/bar");
    is $res->code, 200;
    is $res->content,
        "<http://example.org/foo/bar> <http://www.w3.org/2000/01/rdf-schema#type> <http://example.org/Thing> .\n";
};

$app = Plack::App::RDF::Files->new( base_dir => 't/data' );

my $rdf_json = { 
    "http://example.org/alice" => {
            "http://xmlns.com/foaf/0.1/knows" =>
                [ { "type" => "literal", "value" => "Böb"}]
        } 
    };

test_psgi $app, sub {
	my $cb  = shift;

    foreach my $format (qw(text/turtle application/json text/plain)) {
    	my $res = $cb->(GET "/alice", Accept => $format);
        is $res->header('Content-Type'), $format, "Accept: $format";
    }

    foreach (qw(/ /rdf0 ../data/alice)) {
    	is $cb->(GET $_)->code, '404', "404 not ok: $_";
    }

	my $res = $cb->(GET "/alice", Accept => 'application/json'); 
	is $res->code, '200', '200 OK';
    is $res->header('Content-Type'), 'application/json';
    is_deeply (JSON->new->decode($res->decoded_content), $rdf_json, 'RDF/JSON');
};

# test non-streaming
my $env = GET("/alice")->to_psgi; 
$env->{'psgi.streaming'} = 0;
$env->{'negotiate.format'} = 'json';
#$env->{'rdf.uri'} = 'http://example.com/bob';
my $res = $app->call($env);
my $body = ref $res->[2] eq 'ARRAY' ? $res->[2]->[0] : $res->[2]->getline;
is_deeply( JSON->new->decode($body), $rdf_json, 'non-streaming, negotiate.format' );

done_testing;
