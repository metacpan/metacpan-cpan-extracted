use strict;
use warnings;
use Test::More;

use App::rdfns;

sub test_run {
    my ($argv, $expect, $msg) = @_;

    my $out;
    local *STDOUT;
    open STDOUT, '>', \$out;
    App::rdfns->new->run(@$argv);
    close STDOUT;

    is $out, (@$expect ? join("\n", @$expect, '') : undef), $msg;
}

test_run ["geo"] => ['http://www.w3.org/2003/01/geo/wgs84_pos#'],
    "look up URI";
test_run ['wgs.prefix'] => ["geo"],
    "normalize prefix";
test_run ['xsd,foaf.json'] => ['"foaf": "http://xmlns.com/foaf/0.1/",
"xsd": "http://www.w3.org/2001/XMLSchema#"'], 
    "JSON (multiple prefixes)";
test_run ['http://www.w3.org/2003/01/geo/wgs84_pos#'] => ["geo"],
    "look up prefix of a namespace";
test_run ['http://notanamespace.foo/'] => [],
    "unknown namespace";
test_run ['http://purl.org/dc/elements/1.1/title'] => ["dc:title"],
    "qname";
test_run ['http://purl.org/dc/elements/1.1/:'] => [],
    "invalid local name";
test_run ['20140901','dblp','20140831','dblp'] => [   
    "http://dblp.l3s.de/d2r/page/authors/\n".
    "http://www4.wiwiss.fu-berlin.de/dblp/terms.rdf#" ],
    "select version";

done_testing;
