use strict;
use Test::More;
use RDF::TrineX::Merge::Bnodes;
use RDF::Trine::Model;
use RDF::Trine::Parser;
use RDF::Trine::Serializer::NTriples::Canonical;

sub parse {
    my $model  = RDF::Trine::Model->new;
    my $parser = RDF::Trine::Parser->new('turtle');
    $parser->parse_into_model(undef, $_[0], $model);
    return $model;
}

sub serialize {
    my $serializer = RDF::Trine::Serializer::NTriples->new( onfail => 'die' );
    $serializer->serialize_model_to_string($_[0]);
}

sub ttl {
    join '', map { "$_ .\n" } (ref $_[0] ? @{$_[0]} : $_[0]);
}

my @tests = (
    # keep if both blank 
    '_:b1 <p:a> _:b2' => '_:b1 <p:a> _:b2',
    '_:b1 <p:a> _:b1' => '_:b1 <p:a> _:b1',
    # simple keep
    '<x:a> <p:a> <x:b>, _:b1 . _:b1 <p:a> <x:c>'
        => ['_:b1 <p:a> <x:c>','<x:a> <p:a> _:b1','<x:a> <p:a> <x:b>'],
    # simple merge 
    '<x:a> <p:a> _:b2, _:b1' => '<x:a> <p:a> _:b1',
    # merge with multiple statements
    '<x:a> <p:a> _:b2, _:b1 . _:b1 <p:b> "foo" . _:b2 <p:b> "foo"' 
        => ['_:b1 <p:b> "foo"','<x:a> <p:a> _:b1'],
    # don't merge if connted to another bnode
    '<x:a> <p:a> _:b2, _:b1 . _:b1 <p:a> _:b3' 
        => ['_:b1 <p:a> _:b3','<x:a> <p:a> _:b1','<x:a> <p:a> _:b2'],
);

while (@tests) {
    my $turtle = shift @tests;
    my $expect = shift @tests;

    my $in  = parse(ttl($turtle));
    my $out = merge_bnodes($in->as_stream);

    is serialize($out), ttl($expect), $in->size . " => " . $out->size;
}

my $model = parse(<<'RDF');
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@base   <http://example.org/> .

<Alice> foaf:knows [ a foaf:Person ; foaf:name "Bob" ] .
<Alice> foaf:knows [ a foaf:Person ; foaf:name "Bob" ] .
RDF

is $model->size, 6;
is merge_bnodes($model)->size, 3;

done_testing;
