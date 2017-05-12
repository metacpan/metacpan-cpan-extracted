use strict;
use warnings;

use Test::More;
use RDF::Flow;
use RDF::Flow::Dummy;
use RDF::Trine::Serializer::Turtle;

my $ser = RDF::Trine::Serializer::Turtle->new;

my $ttl1 = "<http://example.org/x> a <http://www.w3.org/2000/01/rdf-schema#Resource> .\n";
my $ttl2 = "<http://example.com/foo> a <http://www.w3.org/2000/01/rdf-schema#Resource> .\n";
# specific form of timestamp depends on OS
#my $time = qr/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(Z|[+-]\d\d:\d\d)$/;
my $time = qr{\d{4}};

my $dummy = RDF::Flow::Dummy->new( name => 'foo' );

my $rdf = $dummy->retrieve( "http://example.org/x" );
is( $ser->serialize_model_to_string($rdf), $ttl1, 'retriev from plain URI' );

my $env = { };
$rdf = $dummy->retrieve( $env );
isa_ok( $rdf, 'RDF::Trine::Model', 'valid response' );
is( $rdf->size, 0, 'empty response' );

$env = { 'rdflow.uri' => "http://example.org/x" };
$rdf = $dummy->retrieve( $env );
is( $ser->serialize_model_to_string($rdf), $ttl1, 'retriev from env (URI given)' );
like( $env->{'rdflow.timestamp'}, $time, 'timestamp has been set' );

$env = { HTTP_HOST => "example.org", SCRIPT_NAME => '/x', };
$rdf = $dummy->retrieve( $env );
is( $ser->serialize_model_to_string($rdf), $ttl1, 'retriev from env (URI build)' );


$dummy = RDF::Flow::Dummy->new( name => 'foo' , match => qr/^[a-z]:/ );
$rdf = $dummy->retrieve( $env );
is( $rdf->size, 0, 'URI did not match' );
$env = { 'rdflow.uri' => 'a:foo' };
$rdf = $dummy->retrieve( $env );
is( $rdf->size, 1, 'URI matched' );

$dummy = RDF::Flow::Dummy->new( name => 'foo' , match => sub { $_[0] =~ s/example\.org/example.com/ } );
$env = { 'rdflow.uri' => 'http://example.org/foo' };
$rdf = $dummy->retrieve( $env );
is( $rdf->size, 1, 'URI matched' );
is( $ser->serialize_model_to_string($rdf), $ttl2, 'URI was changed' );
is( $env->{'rdflow.uri'}, 'http://example.org/foo', 'mapped URI not changed' );

$rdf = $dummy->retrieve( 'http://example.com/' );
is( $rdf->size, 0, 'URI did not map' );

done_testing;
