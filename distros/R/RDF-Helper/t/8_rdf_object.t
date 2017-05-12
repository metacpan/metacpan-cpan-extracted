use Test::More;

use RDF::Helper;
use RDF::Helper::Object;
use Data::Dumper;

#----------------------------------------------------------------------
# RDF::Redland
#----------------------------------------------------------------------
SKIP: {
  eval { require RDF::Redland };
  skip "RDF::Redland not installed", 28 if $@;

  my $rdf = RDF::Helper->new(
      BaseInterface => 'RDF::Redland',
      BaseURI => 'http://totalcinema.com/NS/test#',
      Namespaces => { 
        dc => 'http://purl.org/dc/elements/1.1/',
        rdf => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
        '#default' => "http://purl.org/rss/1.0/",
        slash => "http://purl.org/rss/1.0/modules/slash/",
        taxo => "http://purl.org/rss/1.0/modules/taxonomy/",
        syn => "http://purl.org/rss/1.0/modules/syndication/",
        admin => "http://webns.net/mvcb/",
        contact => "http://www.w3.org/2000/10/swap/pim/contact#",
        air => "http://www.daml.org/2001/10/html/airport-ont#",
     },
  );
  

  test( $rdf );
}

#----------------------------------------------------------------------
# RDF::Trine
#----------------------------------------------------------------------
SKIP: {
  eval { require RDF::Trine };
  skip "RDF::Trine not installed", 28 if $@;

  my $rdf = RDF::Helper->new(
      BaseInterface => 'RDF::Trine',
      BaseURI => 'http://totalcinema.com/NS/test#',
      Namespaces => { 
        dc => 'http://purl.org/dc/elements/1.1/',
        rdf => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
        '#default' => "http://purl.org/rss/1.0/",
        slash => "http://purl.org/rss/1.0/modules/slash/",
        taxo => "http://purl.org/rss/1.0/modules/taxonomy/",
        syn => "http://purl.org/rss/1.0/modules/syndication/",
        admin => "http://webns.net/mvcb/",
        contact => "http://www.w3.org/2000/10/swap/pim/contact#",
        air => "http://www.daml.org/2001/10/html/airport-ont#",
     },
  );
  

  test( $rdf );
}

done_testing();


#
# Test Functions
#

sub test {
  my $rdf = shift;

  $rdf->include_rdfxml(filename => 't/data/use.perl.rss');
  
  my $obj1 = new RDF::Helper::Object( RDFHelper => $rdf, ResourceURI => 'http://use.perl.org/' );
  ok(UNIVERSAL::isa($obj1, 'RDF::Helper::Object'), 'object isa RDF::Helper::Object');

  ok(sprintf($obj1) eq 'http://use.perl.org/', 'object scalar overloading');
  ok($obj1 eq 'http://use.perl.org/', 'object "eq" overloading');
  ok($obj1 == 'http://use.perl.org/', 'object "==" overloading');
  
  is( $obj1->title, 'use Perl', 'get resource value via default namespace' );
  is( $obj1->dc_language, 'en-us', 'get resource value via specified namespace prefix, using underscore' );
  ok( $obj1->title('New Title for use Perl'), 'set a new title' );
  is( $obj1->title, 'New Title for use Perl', 'new title properly set' );
  ok( $obj1->dc_language('en-gb'), 'set a new language via underscore prefix' );
  is( $obj1->dc_language, 'en-gb', 'new language value properly set' );
  ok( $obj1->title(undef), 'removing a value' );
  is( $obj1->title, undef, 'value removed successfully' );
  ok( $obj1->dc_language([qw( en-gb jp fr )]), 'set multiple language values' );
  is( ref(scalar($obj1->dc_language)), 'ARRAY', 'multiple values - scalar arrayref' );
  my @languages = $obj1->dc_language;
  is( join(',', sort(@languages)), join(',', sort(qw( en-gb jp fr ))), 'proper languages returned - list context' );

  is( join(',', sort(@{$obj1->dc_language})), join(',', sort(qw( en-gb jp fr ))), 'proper languages returned - scalar arrayref' );
  is( join(',', sort($obj1->dc_language)), join(',', sort(qw( en-gb jp fr ))), 'proper languages returned - array' );
  ok( $obj1->dc_language([qw( en-gb fr )]), 'remove value from multiple language set' );
  is( join(',', sort($obj1->dc_language)), join(',', sort(qw( en-gb fr ))), 'proper languages returned - array' );
  is( $obj1->dc_author->dc_fullname, 'Mike Nachbaur', 'Traverse 2 object levels');
  is( $obj1->dc_author->contact_nearestAirport->air_iata, 'YHW', 'Traverse 3 object levels');

  $obj1->link('http://www.google.com/');
  my ($link_res) = $rdf->get_statements('http://use.perl.org/', 'http://purl.org/rss/1.0/link', undef);
  ok($link_res->object->is_resource, 'set a string that looks like a URI encodes it as a resource');

  is( $obj1->image, "http://use.perl.org/images/topics/useperl.gif", 'image property' );
  is( ref($obj1->image), "RDF::Helper::Object", 'image property blessed resource' );
  is( $obj1->image->object_uri, "http://use.perl.org/images/topics/useperl.gif", 'image property blessed object URI' );
  is( $obj1->image->link, "http://use.perl.org/", 'image property traversed blessed object property' );
  is( ref($obj1->items), "RDF::Helper::Object", 'items property blessed blank node' );
  
  my $seq =  $obj1->items;
  
  my @items = $seq->rdf_li;
  #warn "ITEMS " . Dumper( \@items );

  my $obj2 = $rdf->get_object('http://use.perl.org/');
  ok(UNIVERSAL::isa($obj2, 'RDF::Helper::Object'), 'object via get_object() isa RDF::Helper::Object');
}

