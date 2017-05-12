use strict;
use warnings;

use Test::More;
use RDF::Trine qw(iri literal blank statement);
use RDF::Trine::NamespaceMap;
use RDF::Trine::Parser;

use RDF::Lazy;

my $base = 'http://example.org/';
my $model = RDF::Trine::Model->new;
my $parser = RDF::Trine::Parser->new('turtle');
$parser->parse_into_model( $base, join('',<DATA>), $model );

my $g = RDF::Lazy->new( $model,
    namespaces => { foaf => 'http://xmlns.com/foaf/0.1/' }
);

my $a = $g->resource('http://example.org/alice');
my $b = $g->resource('http://example.org/bob');

is( $a->foaf_knows->str, "$b", 'alice knows bob' );
is( $a->rel('foaf_knows')->str, "$b", 'alice knows bob' );
is( $a->rel('foaf:knows')->str, "$b", 'alice knows bob' );

is( $model->size, 6, 'model used as reference' );
$g = RDF::Lazy->new( $model, namespaces => $g->namespaces );
is( $model->size, 6, 'model used as reference' );

done_testing;

__DATA__
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
<http://example.org/alice> foaf:knows <http://example.org/bob> .
<http://example.org/bob>   foaf:knows <http://example.org/alice> .
<http://example.org/bob>   foaf:knows <http://example.org/dave> .
<http://example.org/alice> foaf:name "Alice" .
<http://example.org/bob>   foaf:name "Bob" .
<http://example.org/dave>  foaf:name "Dave" .
