BEGIN {print "1..13\n";}
END { print "not ok 1\n" unless $::loaded; RDFStore::debug_malloc_dump(); };

my $a = "";
local $SIG{__WARN__} = sub {$a = $_[0]} ;

sub ok
{
    my $no = shift ;
    my $result = shift ;
 
    print "not " unless $result ;
    print "ok $no\n" ;
}

use RDFStore::Parser::SiRPAC;
use RDFStore::Parser::NTriples;
use RDFStore::NodeFactory;

$loaded = 1;
print "ok 1\n";

my $tt=2;
ok $tt++, my $parser = new RDFStore::Parser::SiRPAC(ProtocolEncoding => 'ISO-8859-1',NodeFactory => new RDFStore::NodeFactory());
ok $tt++, my $parser1 = new RDFStore::Parser::NTriples(NodeFactory => new RDFStore::NodeFactory());
ok $tt++, my $parser2 = new RDFStore::Parser::SiRPAC(Style => 'RDFStore::Parser::Styles::RDFStore::Model', NodeFactory => new RDFStore::NodeFactory());
ok $tt++, my $parser3 = new RDFStore::Parser::NTriples(Style => 'RDFStore::Parser::Styles::RDFStore::Model', NodeFactory => new RDFStore::NodeFactory());

my $rdfstring =<<"End_of_RDF;";
<?xml version='1.0' encoding='ISO-8859-1'?>
<!DOCTYPE rdf:RDF [
         <!ENTITY rdf 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'>
         <!ENTITY a 'http://description.org/schema/'>
]>
<rdf:RDF
	xmlns:rdf="&rdf;" xmlns:a="&a;">
<rdf:Description rdf:about="http://www.w3.org">
        <a:Date>1998-10-03T02:27</a:Date>
        <a:Publisher>World Wide Web Consortium</a:Publisher>
        <a:Title>W3C Home Page</a:Title>
        <a:memyI xml:space="preserve"> </a:memyI>
        <a:albe rdf:parseType="Literal"><this xmlns:is="http://iscool.org" xmlns="http://anduot.edu" is:me="a test">
Hei!!<me you="US"><you><a><b/></a></you>aaaa</me>

ciao!!!
<test2/>

---lsls;s</this></a:albe>
        <a:ee>EEEEE</a:ee>
        <a:bb rdf:parseType="Literal"><a:raffa xmlns:a="&a;">Ella</a:raffa></a:bb>
	<a:test rdf:nodeID="test222er"/>
</rdf:Description>

<a:TEST rdf:nodeID="test222er"/>

</rdf:RDF>
End_of_RDF;

my $rdfntriplesstring =<<"End_of_RDF;";
<http://example.org/foo> <http://example.org/bar> "10"^^<http://www.w3.org/2001/XMLSchema#integer> .
<http://example.org/foo> <http://example.org/baz> "10"\@fr^^<http://www.w3.org/2001/XMLSchema#integer> .
<http://www.w3.org/2000/10/rdf-tests/rdfcore/rdfms-xml-literal-namespaces/test001.rdf#John_Smith> <http://my.example.org/Name>  "\n      <html:h1 xmlns:html=\"http://NoHTML.example.org\">\n        <b xmlns=\"http://www.w3.org/1999/xhtml\">John</b>\n      </html:h1>\n   "^^<http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral> .
End_of_RDF;

eval {
    $parser->setHandlers(
				Init    => sub { "INIT"; },
                        	Final   => sub { "FINAL"; },
                        	Assert  => sub { "STATEMENT"; },
                        	Start_XML_Literal  => sub { $_[0]->recognized_string if($_[0]->can('recognized_string')); },
                        	Stop_XML_Literal  => sub { $_[0]->recognized_string if($_[0]->can('recognized_string')); },
                        	Char_Literal  => sub { $_[0]->recognized_string if($_[0]->can('recognized_string')); }
			);
};
ok $tt++, !$@;

eval {
    $parser->parsestring($rdfstring);
};
ok $tt++, !$@;

eval {
    $parser1->setHandlers(
				Init    => sub { "INIT"; },
                        	Final   => sub { "FINAL"; },
                        	Assert  => sub { "STATEMENT"; },
                        	Start_XML_Literal  => sub { $_[0]->recognized_string if($_[0]->can('recognized_string')); },
                        	Stop_XML_Literal  => sub { $_[0]->recognized_string if($_[0]->can('recognized_string')); },
                        	Char_Literal  => sub { $_[0]->recognized_string if($_[0]->can('recognized_string')); }
			);
};
ok $tt++, !$@;

eval {
    $parser1->parsestring($rdfntriplesstring);
};
ok $tt++, !$@;

eval {
    $parser2->parsestring($rdfstring);
    #print $parser2->parsestring($rdfstring)->serialize(undef,'RDF/XML');
    #print $parser2->parsestring($rdfstring)->serialize(undef,'N-Triples');
};
ok $tt++, !$@;

eval {
    $parser3->parsestring($rdfntriplesstring);
    #print $parser3->parsestring($rdfntriplesstring)->serialize(undef,'RDF/XML');
    #print $parser3->parsestring($rdfntriplesstring)->serialize(undef,'N-Triples');
};
ok $tt++, !$@;

# bNode re-write test
eval {
    my %uri_map = ( 'test222er' => 'http://foo.org/test.html' );
    $parser2->setHandlers(
				manage_bNodes   => sub { $_[1]->createResource($uri_map{$_[2]}); }
			);
};
ok $tt++, !$@;

eval {
    $parser2->parsestring($rdfstring);
    #print $parser2->parsestring($rdfstring)->serialize(undef,'RDF/XML');
};
ok $tt++, !$@;
