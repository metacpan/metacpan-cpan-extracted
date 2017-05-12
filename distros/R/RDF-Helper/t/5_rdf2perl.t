use Test::More;

use RDF::Helper;
use Data::Dumper;

#----------------------------------------------------------------------
# RDF::Redland
#----------------------------------------------------------------------
SKIP: {
  eval { require RDF::Redland };
  skip "RDF::Redland not installed", 2 if $@;

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

  $rdf->include_rdfxml(filename => 't/data/use.perl.rss');
  
  my $ref = $rdf->deep_prophash('http://use.perl.org/');
  
  ok( scalar keys %{$ref} > 0 );
  
  my $hash_count = scalar keys %{$ref->{items}};
  #warn Dumper( $ref );

  ok ( $hash_count > 0 );
  
  #
  
  my %data = (
      'dc:name' => 'kingubu',
      'name' => 'Fooo',
      'array' => [ 'one', 'two', 'three' ],
  );
  
  my $rdf2 = RDF::Helper->new(
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
  
  $rdf2->hashref2rdf( \%data );
  #warn $rdf2->serialize( filename => 'dump.rdf' );

  #warn $rdf2->serialize( format => 'rdfxml-abbrev' );
}

#----------------------------------------------------------------------
# RDF::Trine
#----------------------------------------------------------------------
SKIP: {
  eval { require RDF::Trine };
  skip "RDF::Trine not installed", 2 if $@;

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

  $rdf->include_rdfxml(filename => 't/data/use.perl.rss');
  
  my $ref = $rdf->deep_prophash('http://use.perl.org/');
  
  ok( scalar keys %{$ref} > 0 );
  
  my $hash_count = scalar keys %{$ref->{items}};
  #warn Dumper( $ref );

  ok ( $hash_count > 0 );
  
  #
  
  my %data = (
      'dc:name' => 'kingubu',
      'name' => 'Fooo',
      'array' => [ 'one', 'two', 'three' ],
  );
  
  my $rdf2 = RDF::Helper->new(
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
  
  $rdf2->hashref2rdf( \%data );
  #warn $rdf2->serialize( filename => 'dump.rdf' );

  #warn $rdf2->serialize( format => 'rdfxml-abbrev' );
}

done_testing();
