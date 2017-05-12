use Test::More;

use RDF::Helper;

my $xml_string = undef;
{
    local $/= undef;
    $xml_string = <DATA>;
}

#----------------------------------------------------------------------
# RDF::Redland
#----------------------------------------------------------------------
SKIP: {
  eval { require RDF::Redland };
  skip "RDF::Redland not installed", 11 if $@;

  my $rdf = RDF::Helper->new(
      BaseInterface => 'RDF::Redland',
      BaseURI => 'http://totalcinema.com/NS/test#'
  );

ok($rdf->include_rdfxml(xml => $xml_string), 'include_rdfxml');
ok($rdf->exists('urn:test:1', 'http://totalcinema.com/NS/test#testa', 'Test A1'), 'test t:testa (1)');
ok($rdf->exists('urn:test:1', 'http://totalcinema.com/NS/test#testb', 'Test B1'), 'test t:testb (1)');
ok($rdf->exists('urn:test:1', 'http://totalcinema.com/NS/test#testc', 'Test C1'), 'test t:testc (1)');
ok(!$rdf->exists('urn:test:1', 'http://totalcinema.com/NS/test#testd', undef), 'test nonexistant t:testd');
ok($rdf->exists('urn:test:2', 'http://totalcinema.com/NS/test#testa', 'Test A2'), 'test t:testa (2)');
ok($rdf->exists('urn:test:2', 'http://totalcinema.com/NS/test#testb', 'Test B2'), 'test t:testb (2)');
ok($rdf->exists('urn:test:2', 'http://totalcinema.com/NS/test#testc', 'Test C2'), 'test t:testc (2)');
is($rdf->count(undef, 'http://totalcinema.com/NS/test#testa', undef), 2, 'count of t:testa');
is($rdf->count(undef, 'http://totalcinema.com/NS/test#testb', undef), 2, 'count of t:testb');
is($rdf->count(undef, 'http://totalcinema.com/NS/test#testc', undef), 2, 'count of t:testc');
}


#----------------------------------------------------------------------
# RDF::Trine
#----------------------------------------------------------------------
SKIP: {
  eval { require RDF::Trine };
  skip "RDF::Trine not installed", 11 if $@;

  my $rdf = RDF::Helper->new(
      BaseInterface => 'RDF::Trine',
      BaseURI => 'http://totalcinema.com/NS/test#'
  );

ok($rdf->include_rdfxml(xml => $xml_string), 'include_rdfxml');
ok($rdf->exists('urn:test:1', 'http://totalcinema.com/NS/test#testa', 'Test A1'), 'test t:testa (1)');
ok($rdf->exists('urn:test:1', 'http://totalcinema.com/NS/test#testb', 'Test B1'), 'test t:testb (1)');
ok($rdf->exists('urn:test:1', 'http://totalcinema.com/NS/test#testc', 'Test C1'), 'test t:testc (1)');
ok(!$rdf->exists('urn:test:1', 'http://totalcinema.com/NS/test#testd', undef), 'test nonexistant t:testd');
ok($rdf->exists('urn:test:2', 'http://totalcinema.com/NS/test#testa', 'Test A2'), 'test t:testa (2)');
ok($rdf->exists('urn:test:2', 'http://totalcinema.com/NS/test#testb', 'Test B2'), 'test t:testb (2)');
ok($rdf->exists('urn:test:2', 'http://totalcinema.com/NS/test#testc', 'Test C2'), 'test t:testc (2)');
is($rdf->count(undef, 'http://totalcinema.com/NS/test#testa', undef), 2, 'count of t:testa');
is($rdf->count(undef, 'http://totalcinema.com/NS/test#testb', undef), 2, 'count of t:testb');
is($rdf->count(undef, 'http://totalcinema.com/NS/test#testc', undef), 2, 'count of t:testc');
}

done_testing();

__DATA__
<?xml version="1.0"?>
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
         xmlns:t="http://totalcinema.com/NS/test#">

  <t:test rdf:about="urn:test:1">
    <t:testa>Test A1</t:testa>
    <t:testb>Test B1</t:testb>
    <t:testc>Test C1</t:testc>
  </t:test>

  <t:test rdf:about="urn:test:2">
    <t:testa>Test A2</t:testa>
    <t:testb>Test B2</t:testb>
    <t:testc>Test C2</t:testc>
    <t:testd>
        <rdf:Seq>
            <rdf:li rdf:resource="urn:test:1"/>
        </rdf:Seq>
    </t:testd>
  </t:test>

</rdf:RDF>
