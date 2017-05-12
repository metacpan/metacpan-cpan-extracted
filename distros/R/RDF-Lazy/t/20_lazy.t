use strict;
use warnings;

use Test::More;
use RDF::Trine qw(iri literal blank statement);
use RDF::Trine::NamespaceMap;
use RDF::Trine::Parser;

use_ok 'RDF::Lazy';

my $graph = RDF::Lazy->new;
isa_ok $graph, 'RDF::Lazy';

$graph = RDF::Lazy->new( undef );
isa_ok $graph, 'RDF::Lazy';
is $graph->size, 0, 'empty graph';

my $lit = $graph->uri( literal("Geek & Poke") );
isa_ok $lit, 'RDF::Lazy::Literal';
isa_ok $lit->graph, 'RDF::Lazy', '->graph';

ok ($lit->is_literal && !$lit->is_resource && !$lit->is_blank, '->is_literal');
is $lit->str, 'Geek & Poke', 'stringify literal';
is $lit->esc, 'Geek &amp; Poke', 'HTML escape literal';
is $lit->type, undef, 'untyped literal';

is $graph->literal("Geek & Poke")->str, $lit->str, 'construct via ->literal';

my ($l1, $l2);
$l1 = $graph->literal("love","en");
ok $l1->is_en && $l1->is_en_, 'is_en_ and is_en';

$l1 = $graph->literal("hello","<http://example.org/mytype>");
is $l1->datatype->str, "http://example.org/mytype", "datatype";

#diag('blank nodes');
my $blank = $graph->uri( blank('x1') );
isa_ok $blank, 'RDF::Lazy::Blank';
ok (!$blank->is_literal && !$blank->is_resource && $blank->is_blank, 'is_blank');
is $blank->id, 'x1', 'blank id';

is $graph->blank("x1")->id, $blank->id, 'construct via ->blank';
is RDF::Lazy::Blank->new( $graph, 'x1' )->id, $blank->id, 'blank constructor';

# TODO: test accessing properties of blank nodes

#diag('resource nodes');
my $uri = $graph->uri( iri("http://example.com/'") );
isa_ok $uri, 'RDF::Lazy::Resource';
ok (!$uri->is_literal && $uri->is_resource && !$uri->is_blank, 'is_resource');
is "$uri", "http://example.com/'", 'stringify URI';
is $uri->href, 'http://example.com/&#39;', 'HTML escape URI';
is $uri->esc,  'http://example.com/&#39;', 'HTML escape URI';

is $graph->resource("http://example.com/'")->uri, $uri->uri, 'construct via ->resource';

my $map  = RDF::Trine::NamespaceMap->new({
  foaf => iri('http://xmlns.com/foaf/0.1/'),
  'x'   => iri('http://example.org/'),
});
my $base = 'http://example.org/';
my $model = RDF::Trine::Model->new;
my $parser = RDF::Trine::Parser->new('turtle');
$parser->parse_into_model( $base, join('',<DATA>), $model );

$graph = RDF::Lazy->new( namespaces => $map, rdf => $model );
isa_ok( $graph->namespaces, 'RDF::NS' );

my $obj = [ map { "$_" }
        $graph->rel( iri('http://example.org/alice'), 'foaf_knows' )
    ];

is_deeply( $obj, ['http://example.org/bob'], 'resource object');

my $a = $graph->resource('http://example.org/alice');
$obj = $a->foaf_name;
is_deeply( "$obj", 'Alice', 'literal object');

# this was a bug
$obj = $a->blablabla;
ok !$a->blablabla, 'no result without prefix';

isa_ok( $graph->namespaces, 'RDF::NS' );

$graph->{namespaces}->{'ex'} = 'http://example.org/'; # one-letter prefix not allowed in RDF::NS <= 20111031
is $graph->uri('ex:alice')->uri, 'http://example.org/alice';
is $graph->ex_bob->foaf_name->str, 'Bob', 'chaining accesors';

is $graph->foaf_name->uri, 'http://xmlns.com/foaf/0.1/name', 'namespace URI';
is $graph->foaf_foo_bar->uri, 'http://xmlns.com/foaf/0.1/foo_bar', 'namespace URI with _';

$graph->add( statement(
  iri('http://example.org/alice'), iri('http://example.org/zonk'), literal('bar','fr'),
));
$graph->add( statement(
  iri('http://example.org/alice'), iri('http://example.org/zonk'), literal('doz'),
));

$obj = $a->x_zonk('@fr');
is_deeply( "$obj", 'bar', 'property with filter');
#$obj

# FIXME: outcome depends on hash ordering
# $obj = $a->x_zonk('@en','');
# is_deeply( "$obj", 'doz', 'property with filter');

my $ttl = $a->ttl;
ok $ttl, '->ttl';

#use RDF::NS;
$a->graph->namespaces( RDF::NS->new );
#note explain $a->graph->namespaces;
#is $a->ttl, $ttl, 'namespaces';

done_testing;

__DATA__
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@prefix x: <http://example.org/> .
<http://example.org/alice> foaf:knows <http://example.org/bob> .
<http://example.org/bob>   foaf:knows <http://example.org/alice> .
<http://example.org/alice> foaf:name "Alice" .
<http://example.org/bob>   foaf:name "Bob" .
<http://example.org/alice> x:zonk "foo"@en .
