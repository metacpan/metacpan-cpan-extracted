use Test;
BEGIN { plan tests => 11 }
BEGIN { unshift @INC, 'blib/lib', 'examples'; }

use RDF::Notation3::Triples;
use RDF::Notation3::PrefTriples;
use RDF::Notation3::XML;
use MyHandler;
use MyErrorHandler;

# 1
$rdf = new RDF::Notation3::Triples;
$rc = $rdf->parse_file('examples/test01.n3');
ok($rc);

# 2
$rc = $rdf->parse_file('examples/test02.n3');
ok($rc);

# 3
$rc = $rdf->parse_file('examples/test03.n3');
ok($rc);

# 4
$rc = $rdf->parse_file('examples/test04.n3');
ok($rc);


##################################################
$rdf = new RDF::Notation3::PrefTriples;

# 5
$rc = $rdf->parse_file('examples/test04.n3');
ok($rc);


##################################################
#$rdf = new RDF::Notation3::XML;

# 6
$rc = $rdf->parse_file('examples/test03.n3');
ok($rc);

# 7
$rc = $rdf->parse_file('examples/test04.n3');
ok($rc);


##################################################
# SAX
# 8
eval { require XML::SAX };
if ($@) {
    ok(1);
} else { 
    chdir('examples');
    my $ret = `perl sax.pl test04.n3`;
    chdir('..');
    $ret =~ /(\d+)$/ and my $rc = $1;
    ok($rc, 17)
}


##################################################
# add_prefix/triple
# 9
$rdf = new RDF::Notation3::Triples;
$rc = $rdf->parse_file('examples/test01.n3');
$rdf->add_prefix('x','http://www.example.org/x');
$rc = $rdf->add_triple('<uri>','x:prop','"literal"');
ok($rc, 5);


##################################################
# test string parsing
# 10
$rc = $rdf->parse_file('examples/test05.n3');
ok($rc);


##################################################
# keywords
# 11
$rdf->quantification(0);
$rc = $rdf->parse_file('examples/test06.n3');
ok($rc, 79);
