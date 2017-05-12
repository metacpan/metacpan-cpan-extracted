BEGIN {print "1..6\n";}
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

use RDFStore::Serializer::RDFXML;
use RDFStore::Serializer::NTriples;

#use RDFStore::Parser::NTriples;
use RDFStore::Parser::SiRPAC;
use RDFStore::NodeFactory;

$loaded = 1;
print "ok 1\n";

my $tt=2;
my $factory = new RDFStore::NodeFactory();
#ok $tt++, my $parser1 = new RDFStore::Parser::NTriples(Style => 'RDFStore::Parser::Styles::RDFStore::Model',NodeFactory => $factory );
ok $tt++, my $parser2 = new RDFStore::Parser::SiRPAC(Style => 'RDFStore::Parser::Styles::RDFStore::Model', NodeFactory => $factory );

my $rdfstring = qq|<rdf:RDF
	xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'
	xmlns:a='http://description.org/schema/'>
<rdf:Description rdf:about='http://www.w3.org'>
	<a:Date>1998-10-03T02:27</a:Date>
	<a:Publisher>World Wide Web Consortium</a:Publisher>
	<a:Title>W3C Home Page</a:Title>
	<a:memyI> </a:memyI>
	<a:albe rdf:parseType='Literal'><this xmlns:is="http://iscool.org" xmlns="http://anduot.edu" is:me="a test">
Hei!!<me you="US"><you><a><b/></a></you>aaaa</me>

ciao!!!
<test2/>

---lsls;s</this></a:albe>
	<a:ee>EEEEE</a:ee>
        <a:bb rdf:parseType="Literal"><a:raffa xmlns:a="http://description.org/schema/">Ella</a:raffa></a:bb>
	<a:test2>aabbccdd</a:test2>
	<a:test3>aabbccdd</a:test3>
</rdf:Description>
<rdf:Description rdf:about='http://www.w3.org/aaaa'>
	<a:test1>CCCCCCC</a:test1>
</rdf:Description>
</rdf:RDF>|;

#my $model1;
#eval {
#    $model1 = $parser1->parsestring($rdfstrawmanstring);
#};
#ok $tt++, !$@;

#ok $tt++, ( $model1->serialize(undef, "Strawman") eq $model1->toStrawmanRDF );
#ok $tt++, ( $model1->serialize(undef, "Strawman") eq $rdfstrawmanstring ); # pure conversion?

my $model2;
eval {
    $model2 = $parser2->parsestring($rdfstring);
};
ok $tt++, !$@;

ok $tt++,  $model2->serialize(undef,"N-Triples" );
ok $tt++,  $model2->serialize(undef,undef,{ 'http://description.org/schema/' => 'a' } );

#not yet...
#print $model2->serialize(undef,undef,{ 'http://description.org/schema/' => 'a' } );
#open(A,">a.txt");
#print A $model2->serialize(undef,undef,{ 'http://description.org/schema/' => 'a' } );
#close(A);
#open(B,">b.txt");
#print B $rdfstring;
#close(B);
#ok $tt++, ( $model2->serialize(undef,undef,{ 'http://description.org/schema/' => 'a' } ) eq $rdfstring ); # pure conversion?

my $statement = $factory->createStatement(	$factory->createResource('http://www.w3.org/Home/Lassila'),
						$factory->createResource('http://description.org/schema/','Author'),
						$factory->createLiteral('Ora Lissala') );
#my $meta_statement = $factory->createStatement(	$statement,
#						$factory->createResource('http://description.org/schema/','MetaAuthor'),
#						$factory->createLiteral('meMyselI') );
#my $meta_meta_statement = $factory->createStatement(	$meta_statement,
#						$factory->createResource('http://description.org/schema/','MetaMetaAuthor'),
#						$factory->createLiteral('You') );
#$model2->add( $meta_statement );
#$model2->add( $meta_meta_statement );
ok $tt++,  $model2->serialize(undef,undef,{ 'http://description.org/schema/' => 'a' } );
#print $model2->serialize(undef,undef,{ 'http://description.org/schema/' => 'a' } );
