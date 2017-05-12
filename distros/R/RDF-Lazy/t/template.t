use strict;
use warnings;

use Test::More;
use RDF::Lazy;
use utf8;

BEGIN {
    eval { require Template; };
    if ($@) {
        diag('Skipping template test, requires Template Toolkit');
        done_testing;
        exit;
    }
}

my ($graph,$rdf,$node,$vars);

$graph = RDF::Lazy->new;

$node = $graph->literal("hallo","en");
test_tt('[% foo %]', { foo => $node }, "hallo", "plain literal");
test_tt('[% foo.is_literal ? 1 : 0 %]', { foo => $node }, "1", "is literal");
test_tt('[% foo.lang %]', { foo => $node }, "en", "language tag");
test_tt('[% foo.datatype %]', { foo => $node }, "", "no datatype");

my $x = $graph->uri("<http://example.org>");
ok( $x->is_resource );

$node = $graph->literal("hallo","<http://example.org/mytype>"); # bug in 0.06 !
test_tt('[% foo %]', { foo => $node }, "hallo", "datatype literal");
test_tt('[% foo.lang %]', { foo => $node }, "", "no language tag");
test_tt('[% foo.datatype %]', { foo => $node }, "http://example.org/mytype", "datatype");

$rdf = <<'TURTLE';
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
<http://example.org/alice> <http://example.org/predicate> <http://example.org/object> .
<http://example.org/alice> foaf:knows <http://example.org/bob> .
<http://example.org/bob> foaf:knows <http://example.org/alice> .
<http://example.org/alice> foaf:name "Alice" .
<http://example.org/bob> foaf:name "Bob" .
TURTLE

$graph = RDF::Lazy->new( $rdf, namespaces => {
    foaf => 'http://xmlns.com/foaf/0.1/',
    'ex' => 'http://example.org/',
});

$a = $graph->resource("http://example.com/'");

test_tt('[% a %]', { a => $a }, "http://example.com/'", 'plain URI with apos');
test_tt('[% a.href %]', { a => $a }, 'http://example.com/&#39;', 'escaped URI with apos');

$vars = {
    'a' => $graph->resource('http://example.org/alice'),
    'b' => $graph->ex_bob,
};

test_tt('[% a.foaf_name %]', $vars, 'Alice', 'single literal property');
test_tt('[% a.foaf_knows %]', $vars, 'http://example.org/bob', 'single uri property');
test_tt('[% a.foaf_knows.foaf_name %]', $vars, 'Bob', 'property chain');

$graph->add(<<'TURTLE');
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
<http://example.org/bob>
    foaf:name "Robert"@en, "Роберт"@ru ;
    foaf:knows [ foaf:name "Алиса"@ru ] ;
    foaf:age "very old", 88, "eightyeight" .
TURTLE

test_tt('[% b.foaf_name("@en") %]', $vars, 'Robert', 'Property value of specific language');
test_tt('[% b.foaf_name("@ru") %]', $vars, 'Роберт', 'Property value of specific language');
test_tt('[% x = b.foaf_knows("-"); x.foaf_name.lang %]', $vars, 'ru', 'Select blank node and language' );
test_tt('[% b.foaf_age("^") %]', $vars, '88', 'Property value with datatype');

done_testing;

sub test_tt {
    my ($template, $vars, $expected, $msg) = @_;
    my $out;
    Template->new->process(\$template, $vars, \$out);
    is $out, $expected, $msg;
}

__END__

