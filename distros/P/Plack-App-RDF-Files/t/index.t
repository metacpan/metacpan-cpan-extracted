use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use Plack::App::RDF::Files;

my $app = Plack::App::RDF::Files->new(
    base_dir => 't/data',
    base_uri => 'http://example.org/',
#    index_property => 'http://example.com/',
);

my $RE = qr{^<[^>]+> <http://www\.w3\.org/2000/01/rdf-schema\#seeAlso> <http://example\.org/(.+)>}m;

test_psgi $app, sub {
	my $cb  = shift;
	my $res = $cb->(GET "/", Accept => 'text/turtle'); 
    is $res->code, '404', 'not found';

    $app->index_property(1);

	$res = $cb->(GET "/", Accept => 'text/plain'); 
	is $res->code, '200', '200 OK (index_property 1)';

    my @index = sort ($res->content =~ /$RE/g);
    is_deeply \@index, [qw(alice foo unicode)], 'index';

    $app->index_property('http://purl.org/dc/terms/hasPart');
	$res = $cb->(GET "/", Accept => 'text/plain'); 
    like $res->content, qr{<http://purl\.org/dc/terms/hasPart>}m, 'custom index_property';
};
 
done_testing;
