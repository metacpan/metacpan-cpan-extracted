use Test::More;

use RDF::Helper;
use RDF::Helper::TiedPropertyHash;
use Data::Dumper;

#----------------------------------------------------------------------
# RDF::Redland
#----------------------------------------------------------------------
SKIP: {
  eval { require RDF::Redland };
  skip "RDF::Redland not installed", 22 if $@;

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
     },
  );
  
  test( $rdf );

  my $in_memory = RDF::Helper->new(
      BaseInterface => 'RDF::Redland',
      BaseURI => 'http://totalcinema.com/NS/test#',
      Namespaces => { 
        rdf => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
        dc => 'http://purl.org/dc/elements/1.1/',
     },
  );
  
  test_inmemory( $in_memory );
}

#----------------------------------------------------------------------
# RDF::Trine
#----------------------------------------------------------------------
SKIP: {
  eval { require RDF::Trine };
  skip "RDF::Trine not installed", 22 if $@;

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
     },
  );
  
  test( $rdf );

  my $in_memory = RDF::Helper->new(
      BaseInterface => 'RDF::Trine',
      BaseURI => 'http://totalcinema.com/NS/test#',
      Namespaces => { 
        rdf => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
        dc => 'http://purl.org/dc/elements/1.1/',
     },
  );
  
  test_inmemory( $in_memory );
}

done_testing();

#
# Test Functions
#

sub test {
  my $rdf = shift;
  $rdf->include_rdfxml(filename => 't/data/use.perl.rss');
  
  my %hash = ();
  
  tie %hash, RDF::Helper::TiedPropertyHash, $rdf, 'urn:x-test:1'; 
  is( tied(%hash), 'urn:x-test:1', 'Tied property "" overloading' );
  ok( tied(%hash) eq 'urn:x-test:1', 'Tied property eq overloading' );
  ok( tied(%hash) == 'urn:x-test:1', 'Tied property == overloading' );
  
  $hash{foo} = 'wibble';
  $hash{bar} = 'norkle';
  
  is( $hash{foo}, 'wibble', 'Set hash property "foo"' );
  is( $hash{bar}, 'norkle', 'Set hash property "bar"' );
  
  my $tester = delete $hash{foo};
  is( $tester, 'wibble', 'Delete hash property "foo"');
  
  my $hashref = $rdf->tied_property_hash('urn:x-test:1');
  ok( $hashref, 'tied_property_hash' );
  
  $hashref->{'dc:creator'} = 'ubu';
  is( $hashref->{'dc:creator'}, 'ubu', 'Set hash property "dc:creator"' );

  $hashref->{'dc:language'} = [qw( en-US jp fr es )];
  is( join(',', sort(@{$hashref->{'dc:language'}})), join(',', sort(qw( en-US jp fr es ))), 'set / return multiple property "dc:language" values' );

  $hashref->{'dc:language'} = [qw( en-US jp es )];
  is( join(',', sort(@{$hashref->{'dc:language'}})), join(',', sort(qw( en-US jp es ))), 'set / return different property "dc:language" values' );

  $hashref->{'dc:language'} = "en-US";
  is( ref($hashref->{'dc:language'}), '', 'Set single value into "dc:language" property' );
  is( $hashref->{'dc:language'}, 'en-US', 'Fetch value from "dc:language" property' );

  $hashref->{'link'} = 'http://www.google.com/';
  my ($link_res_1) = $rdf->get_statements('urn:x-test:1', 'http://purl.org/rss/1.0/link', undef);
  ok($link_res_1->object->is_resource, 'Set a string that looks like a URI encodes it as a resource');

  $hashref->{'link'} = ['http://www.google.com/'];
  my ($link_res_2) = $rdf->get_statements('urn:x-test:1', 'http://purl.org/rss/1.0/link', undef);
  ok($link_res_2->object->is_resource, 'Set an arrayref that looks like a URI encodes it as a resource');

  my %useperl1;
  tie %useperl1, RDF::Helper::TiedPropertyHash, $rdf, 'http://use.perl.org/'; 
  is( $useperl1{title}, 'use Perl', 'Get existing RSS property "title"' );
  is( $useperl1{'dc:language'}, 'en-us', 'Get existing RSS property "dc:language"' );

  ok( !ref($useperl1{'image'}), 'Resource node does not return a reference' );
  is( $useperl1{'image'}, 'http://use.perl.org/images/topics/useperl.gif', 'Resource node returns a plain value' );

  my %useperl2;
  tie %useperl2, RDF::Helper::TiedPropertyHash, $rdf, 'http://use.perl.org/', { Deep => 1 }; 
  is( $useperl2{title}, 'use Perl', 'Got title for deep-tied hash' );

  is( ref($useperl2{'image'}), 'HASH', 'Deep-tied resource node returns a hash reference' );
  is( $useperl2{'image'}->{url}, 'http://use.perl.org/images/topics/useperl.gif', 'Traverse deep-tied resource node to image -> url property' );

}

sub test_inmemory {
  my $rdf = shift;
  my %dummy = ();
  tie %dummy, RDF::Helper::TiedPropertyHash, $rdf, 'http://totalcinema.com/'; 
  
  $dummy{'dc:creator'} = [ 'mike', 'kip', 'kjetil' ];
  
  my $creators = $dummy{'dc:creator'};
  ok( ref( $creators ) eq 'ARRAY' and scalar @{$creators} == 3 );
}
