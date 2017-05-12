use Test::More tests => 5;
BEGIN { use_ok('RDF::RDFa::Parser') };

my $atom = <<ATOM;
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom"
	xmlns:y="http://search.yahoo.com/datarss/"
	xmlns:rel="http://example.com/rel#"
	xmlns:product="http://example.com/product#"
	xmlns:units="http://example.com/units#"
	xmlns:currency="http://example.com/currency#">
  <title type="text">dive into mark</title>
  <subtitle type="html">
    A &lt;em&gt;lot&lt;/em&gt; of effort
    went into making this effortless
  </subtitle>

  <updated>2005-07-31T12:29:29Z</updated>
  <id>tag:example.org,2003:3</id>
  <link rel="alternate" type="text/html" 
   hreflang="en" href="http://example.org/"/>
  <link rel="self" type="application/atom+xml" 
   href="http://example.org/feed.atom"/>
  <rights>Copyright (c) 2003, Mark Pilgrim</rights>

  <generator uri="http://www.example.com/" version="1.0">
    Example Toolkit
  </generator>
  <entry>
    <title>Atom draft-07 snapshot</title>
    <link rel="alternate" type="text/html" 
     href="http://example.org/2005/04/02/atom"/>

    <link rel="enclosure" type="audio/mpeg" length="1337"
     href="http://example.org/audio/ph34r_my_podcast.mp3"/>
    <id>tag:example.org,2003:3.2397</id>
    <updated>2005-07-31T12:29:29Z</updated>
    <published>2003-12-13T08:29:29-04:00</published>

    <author>
      <name>Mark Pilgrim</name>
      <uri>http://example.org/</uri>
      <email>f8dy\@example.com</email>

    </author>
    <contributor>
      <name>Sam Ruby</name>
    </contributor>
    <contributor>

      <name>Joe Gregorio</name>
    </contributor>
    <content type="xhtml" xml:lang="en" 
     xml:base="http://diveintomark.org/">
      <div xmlns="http://www.w3.org/1999/xhtml">
        <p><i>[Update: The Atom draft is finished.]</i></p>

      </div>
    </content>
  <y:adjunct name="com.website.products" version="1.0">
    <y:item rel="rel:Product">
      <y:meta property="product:listPrice" datatype="currency:USD">12.99</y:meta>
      <y:meta property="product:shippingCost" datatype="currency:USD">0</y:meta>
      <y:meta property="product:shippingWeight" datatype="units:g">500</y:meta>
      <y:item rel="rel:Review" 
            resource="http://www.onlinestore.com/reviews/12345/browse"/>
      </y:item>
    </y:adjunct>
  </entry>
</feed>
ATOM

my $opts = RDF::RDFa::Parser::Config->new('atom','1.0',atom_parser=>1);
my $p = RDF::RDFa::Parser->new($atom, "http://example.com/", $opts);
$p->consume;

my $graph = $p->graph;

SKIP: {
	skip "XML::Atom::OWL not installed", 2
		unless $RDF::RDFa::Parser::HAS_AWOL;
	
	ok(
		$graph->count_statements(
			undef,
			RDF::Trine::Node::Resource->new('http://bblfish.net/work/atom-owl/2006-06-06/#id'),
			RDF::Trine::Node::Literal->new('tag:example.org,2003:3', undef, 'http://www.w3.org/2001/XMLSchema#anyURI')
			),
		"Parsed feed OK."
		);
		
	ok(
		$graph->count_statements(
			undef,
			RDF::Trine::Node::Resource->new('http://bblfish.net/work/atom-owl/2006-06-06/#id'),
			RDF::Trine::Node::Literal->new('tag:example.org,2003:3.2397', undef, 'http://www.w3.org/2001/XMLSchema#anyURI')
			),
		"Parsed entry OK."
		);
	
};

ok(
	$graph->count_statements(
		undef,
		RDF::Trine::Node::Resource->new('http://www.iana.org/assignments/relation/enclosure'),
		RDF::Trine::Node::Resource->new('http://example.org/audio/ph34r_my_podcast.mp3')
		),
	"IANA-registered link type recognised."
	);

eval "use RDF::Query;";
SKIP: {
	skip "RDF::Query and XML::Atom::OWL not installed", 1 if $@ or !$RDF::RDFa::Parser::HAS_AWOL;
	skip "Need newer version of Trine", 1 unless $RDF::Trine::VERSION gt '0.128';
	
	$result = RDF::Query->new("PREFIX awol: <http://bblfish.net/work/atom-owl/2006-06-06/#>
	ASK WHERE {
		?entry a awol:Entry ;
			awol:author [ awol:uri <http://example.org/> ] ;
			<http://example.com/rel#Product> [ <http://example.com/product#listPrice> \"12.99\"^^<http://example.com/currency#USD> ] .
	}")->execute($graph);
	
	ok($result->get_boolean, "Atom native semantics and RDFa mix properly.");
};

