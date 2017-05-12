use strict;
use warnings;

use Test::More;
use Test::RDF;
use RDF::Trine qw(statement iri);
use RDF::Flow;
use RDF::Flow::Source qw(rdflow_uri);

sub simple_source {
    my $env = shift;
    my $uri = rdflow_uri($env);

    my $model = RDF::Trine::Model->new;
    $model->add_statement(statement(
        iri($uri), iri('x:foo'), iri('x:bar')
    ));

    return $model;
};

my $source = RDF::Flow::Source->new( \&simple_source );

my $env = make_query('/hello');
my $rdf = $source->retrieve($env);

isa_ok( $rdf, 'RDF::Trine::Model', 'simple source returns RDF::Trine::Model' );

done_testing;

sub make_query {
    return { HTTP_HOST => 'example.org', PATH_INFO => shift };
}
