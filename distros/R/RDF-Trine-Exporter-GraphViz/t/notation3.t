use strict;
use warnings;

use Test::More;
use RDF::Trine::Exporter::GraphViz;

eval { require RDF::TriN3; } or do {
    diag("RDF::TriN3 not found, skipping tests");
    ok(1);
    done_testing;
    exit;
};

my $model = RDF::Trine::Model->temporary_model;
my $rdf = '{ ?x :parent ?y } =>  { ?y :child ?x } .';
$rdf .= ' :x = :y .';
#my $rdf = '?x :parent ?y .';

my $parser = RDF::Trine::Parser::Notation3->new;
$parser->parse_into_model('http://example.com/', $rdf, $model);

#my $log = 'http://www.w3.org/2000/10/swap/log#';

ok(1);

done_testing;
