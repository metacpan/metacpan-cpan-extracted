use strict;
use warnings;

use Test::More;
use RDF::Trine::Parser;
use RDF::Lazy;

my $model = RDF::Trine::Model->new;
my $parser = RDF::Trine::Parser->new('turtle');
$parser->parse_into_model( 'http://example.org/', join('',<DATA>), $model );

my $g = RDF::Lazy->new(
    rdf => $model,
    namespaces => {
        foaf    => 'http://xmlns.com/foaf/0.1/',
        rdf     => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
        dcterms => 'http://purl.org/dc/terms/',
        ex      => 'http://example.org/',
    },
);

my $a = $g->uri('<http://example.org/alice>');
my $b = $g->resource('http://example.org/bob');
my $c = $g->resource('http://example.org/claire');
my $d = $g->resource('http://example.org/dave');
my $t = $g->uri('rdf:type');
my $p = $g->uri('foaf:Person');
my $o = $g->uri('foaf:Organization');
my $x = $g->blank;

# short form
is $a->qname, 'ex:alice', 'qname';
is $t->qname, 'rdf:type', 'qname';
is $g->resource('http://example.com')->qname, '', 'qname (not found)';

# blank nodes
ok( $x->id, 'blank node' );
$x = $g->blank('foo');
is( $x->id, 'foo', 'blank node' );

my $y = $g->uri('_:foo');
is( $x->id, $y->id, 'another blank' );

# type
is( $a->type->uri, $g->foaf_Person->uri, 'type eq' );
is( $a->type->str, $g->foaf_Person->str, 'type eq' );
ok( $a->type('foaf:Person'), 'a faof:Person' );
ok( $a->type('foaf:Organization','foaf:Person'), 'a faof:Person' );
ok( $a->type('foaf:Person','foaf:Organization'), 'a faof:Person' );
ok( $a->a('foaf:Organization','foaf:Person'), 'a faof:Person' );

my $types = $a->types;
is( $types->[0]->uri, $g->foaf_Person->uri, 'types' );

is( $a->foaf_knows->uri, $b->uri, 'a knows b' );
is( $b->rev('foaf:knows')->uri, $a->uri, 'b is known by a' );

is( $d->rel->uri, $t->uri, 'd rdf:type _' );
is( $d->rev->uri, $g->foaf_knows->uri, '_ foaf:knows d' );

list_is( $b->rels('rdf:type'), [qw(foaf:Organization foaf:Person)], 'rels (rdf:type): 2' );
list_is( $b->types, [qw(foaf:Organization foaf:Person)], 'types' );
list_is( $c->rels('rdf:type'), [], 'rels (rdf:type): 0' );

list_is( $p->revs('rdf:type'), [qw(ex:alice ex:bob ex:dave)], 'revs (rdf:type): 2' );
list_is( $o->revs('rdf:type'), [qw(ex:bob)], 'revs (rdf:type): 1' );

list_is( $p->rels, [ ], 'rels (empty)' );
list_is( $a->rels, [qw(rdf:type foaf:knows)], 'rels (2)' );

list_is( $a->revs, [], 'rels (empty)' );
list_is( $p->revs, [qw(rdf:type)], 'revs (1)' );
list_is( $d->revs, [qw(foaf:knows)], 'revs (1)' );

is ( $g->ex_foo->dcterms_title->str, "FOO" );

# TODO: test rev(foaf_knows_)

#$g = RDF::Lazy->new( namespaces => {
#    foaf => 'http://xmlns.com/foaf/0.1/'
#} );
#$g->add("<http://uri.gbv.de/database/gvk>", "dcterms:title", $g->literal('Foo') );

$g = RDF::Lazy->new( namespaces => { foaf => 'http://xmlns.com/foaf/0.1/' } );
$g->add( "<http://example.org/foo>", "foaf:knows", "<http://example.org/baz>" );
like( $g->ttl, qr{<http://example.org/foo> foaf:knows <http://example.org/baz> .}, 'added triple' );

done_testing;

sub list_is {
    my ($x,$y,$msg)  = @_;
    $x = [ sort map { "$_" } @$x ];
    $y = [ sort map { $g->uri($_)->str } @$y ];
    is_deeply( $x, $y, $msg );
}

__DATA__
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@prefix dcterms: <http://purl.org/dc/terms/> .
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
<http://example.org/alice> rdf:type foaf:Person .
<http://example.org/bob>   a foaf:Person, foaf:Organization .
<http://example.org/claire> foaf:knows <http://example.org/dave> .
<http://example.org/dave>  a foaf:Person .
<http://example.org/alice> foaf:knows <http://example.org/bob> .

<http://example.org/foo> dcterms:title "FOO" .

