use strict;
use warnings;

use utf8;
use Test::More;

use RDF::Trine qw(iri statement literal blank variable);
use RDF::Trine::Model;

my $model = RDF::Trine::Model->new;
$model->add_statement(
    statement( blank('x1'), iri('u:ri'), literal('データ') )
);

use RDF::Trine::Exporter::GraphViz;

my $g = RDF::Trine::Exporter::GraphViz->new( as => 'dot' );

my $dot = $g->serialize_model_to_string( $model );
like $dot, qr/digraph/, "dot format";

is $g->to_string($model), $dot, "to_string(model)";
is $g->to_string($model->as_stream), $dot, "to_string(iterator)";

my $skos = 'http://www.w3.org/2004/02/skos/core#';

$model->add_statement(
    statement( blank('x1'), iri("${skos}broader"), iri('z:1') ));

$model->add_statement(
    statement( iri('z:1'), iri("${skos}narrower"), blank('x1') ));

$dot = $g->to_string($model, edge => sub {
    return unless /^$skos/;
    return { style => 'bold' };
}, alias => sub {
    return $_ eq 'z:1' ? "Z" : undef;
});

my @edges = map { s/^\s+//; $_ } sort ($dot =~ /^.+->.+/mg);
is_deeply \@edges, [
  'Z -> node1 [label="skos:narrower", style=bold];',
  'node1 -> Z [label="skos:broader", style=bold];',
], 'edges';

done_testing;
