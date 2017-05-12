#!perl -Tw

use strict;

use Test::More qw(no_plan);

use SeeAlso::Response;

my $r = SeeAlso::Response->new;
use Data::Dumper;
is( $r->size, 0, 'test empty' );
is( $r->toJSON, '["",[],[],[]]', 'empty response' );
ok( ! $r, 'empty response is false' );
is( $r->toJSON('callme'), 'callme(["",[],[],[]]);', 'callback' );
is( $r->query, "", 'empty query' );

$r = SeeAlso::Response->new("123");
is( $r->toJSON, '["123",[],[],[]]', 'empty response with query' );
is( $r->query, "123", 'query' );
ok( $r, 'empty response with query is true' );

$r->add("foo","urn:baz","uri:bar");
my $json = '["123",["foo"],["urn:baz"],["uri:bar"]]';
my $csv = '"foo","urn:baz","uri:bar"';
is( $r->toJSON, $json, 'simple response (JSON)');
is( $r->toCSV, $csv, 'simple response (CSV)');
is( $r->as_string, $json, 'simple response (as_string)');
is( "$r", $json, 'simple response ("")');

my $list = [ $r->get(0) ];
is_deeply( $list, ["foo","urn:baz","uri:bar"], 'get method' );

my @labels = $r->labels;
is_deeply( \@labels, ["foo"], 'labels' );
my @descriptions = $r->descriptions;
is_deeply( \@descriptions, ["urn:baz"], 'descriptions' );
my @uris = $r->uris;
is_deeply( \@uris, ["uri:bar"], 'uris' );

$r->add("faz");
ok( $r->toJSON() eq '["123",["foo","faz"],["urn:baz",""],["uri:bar",""]]', 'simple response');
is( $r->size, 2, 'test size' );

@labels = $r->labels;
is_deeply( \@labels, ["foo","faz"], 'labels' );
@descriptions = $r->descriptions;
is_deeply( \@descriptions, ["urn:baz",""], 'descriptions' );
@uris = $r->uris;
is_deeply( \@uris, ["uri:bar",""], 'uris' );

$r->add("","","");
is( $r->size, 2, 'empty triple ignored' );

$r->set("urn:xxx");
my $n3 = '<urn:xxx> <urn:baz> <uri:bar> .';
is( $r->toN3(), $n3, 'simple response (N3)');

$r = $r->new("123");
is( $r->toJSON(), '["123",[],[],[]]', '$obj->new');

$list = [ $r->get(0) ];
is_deeply( $list, [ ], 'get method of empty response' );

my ($completion, $description, $url) = $r->get( 0 );
is( $completion, undef, 'get method of empty response' );

$r->add('"'); # empty description and URI
is( $r->toJSON(), '["123",["\""],[""],[""]]', '$obj->add');
$csv = '"""","",""';
$n3 = '';
is( $r->toCSV(), $csv, 'empty description and URI (CSV)');
is( $r->toN3(), $n3, 'empty description and URI (N3)');

$list = [ $r->get(0) ];
is_deeply( $list, ["\"","",""], 'get method of partly empty' );

my @list = $r->get(-1);
is( @list, 0, 'invalid response index' );
@list = $r->get(99);
is( @list, 0, 'invalid response index' );

$r = SeeAlso::Response->fromJSON($json);
is( $r->toJSON(), $json, 'fromJSON');

$r = SeeAlso::Response->new("a",["b"],["c"],["uri:doz"]);
is( $r->size, 1, 'new with size 1' );

$r->fromJSON($json); # call as method
is( $r->toJSON(), $json, 'fromJSON');

$r->set("xyz");
is( $r->size, 1, 'set with only setting the query' );
is( $r->query(), "xyz", 'set with only setting the query' );

$r = SeeAlso::Response->new("a",["b"],["c"],["uri:doz"]);
is( $r->query("xyz"), "xyz", 'set with the query method' );

eval { $r->add("a","b","abc"); };
ok( $@, 'invalid URN detected' );

eval { $r->fromJSON("["); };
ok( $@, 'invalid JSON detected' );

eval { $r = SeeAlso::Response->new("a",["b"],["c","d"],["uri:doz"]); };
ok( $@, 'invalid array sizes detected' );

$r = SeeAlso::Response->new( ["foo"] );
ok( $r->query() =~ /ARRAY/, 'query made string' );

$r = SeeAlso::Response->new("urn:subject");
$r->add("","urn:predicate","urn:object");
is( $r->toN3(), '<urn:subject> <urn:predicate> <urn:object> .', "toN3 (1)");

$r->add("","urn:predicate","urn:object2");
is( $r->toN3(), "<urn:subject> <urn:predicate>\n    <urn:object> ,\n    <urn:object2> .", "toN3 (2)");

$r->add("hello\"world","rdfs:label","");
my $n3_1 = '  <rdfs:label> "hello\"world"';
my $n3_2 = "  <urn:predicate>\n    <urn:object> ,\n    <urn:object2>";
my $n3_a = "<urn:subject>\n$n3_2 ;\n$n3_1 .";
my $n3_b = "<urn:subject>\n$n3_1 ;\n$n3_2 .";
ok( $r->toN3() eq $n3_a || $r->toN3() eq $n3_b, "toN3 (3)");


use SeeAlso::Identifier;
my $id = SeeAlso::Identifier->new("Hallo");
$r = SeeAlso::Response->new( $id );
is( $r->toJSON(), '["Hallo",[],[],[]]', 'SeeAlso::Identifier as parameter');

__END__

my $utf8 = "a\x{cc}\x{88}"; # small a umlaut

$r = SeeAlso::Response->new( "a" );
$r->add($utf8);

# TODO: Unicode::Normalize needed for utf8 testing
# print STDERR $r->toJSON() . "\n";
# is ( $r->toJSON, '["a",["a\x{cc}\x{88}"],[""],[""]]', "utf8" );
