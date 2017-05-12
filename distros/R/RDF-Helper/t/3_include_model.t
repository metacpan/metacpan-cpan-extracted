use Test::More;

use strict;
use warnings;

use RDF::Helper;
use RDF::Helper::Constants qw(:rdf :rss1);

use constant URI1 => 'http://example.org/one';
use constant URI2 => 'http://example.org/two';

#----------------------------------------------------------------------
# RDF::Redland
#----------------------------------------------------------------------
SKIP: {
  eval { require RDF::Redland };
  skip "RDF::Redland not installed", 5 if $@;

  my $rdf1 = RDF::Helper->new(
      BaseInterface => 'RDF::Redland',
      BaseURI => 'http://totalcinema.com/NS/test#'
  );

  my $rdf2 = RDF::Helper->new(
      BaseInterface => 'RDF::Redland',
      BaseURI => 'http://totalcinema.com/NS/test#'
  );
  
  $rdf1->assert_resource(URI1, RSS1_LINK, URI2); 
  $rdf1->assert_literal(URI1, RSS1_DESCRIPTION, 'Some Description');

  $rdf2->assert_resource(URI2, RSS1_LINK, URI1); 
  $rdf2->assert_literal(URI2, RSS1_DESCRIPTION, 'Some Other Description');

  $rdf1->include_model( $rdf2->model() );
  
  ok ( $rdf1->count() == 4, '4 nodes');
  ok( $rdf1->exists(URI1, RSS1_LINK, $rdf1->new_resource(URI2)) == 1 );
  ok( $rdf1->exists(URI1, RSS1_DESCRIPTION, 'Some Description') == 1 );
  ok( $rdf1->exists(URI2, RSS1_LINK, $rdf1->new_resource(URI1)) == 1 );
  ok( $rdf1->exists(URI2, RSS1_DESCRIPTION, 'Some Other Description') == 1 );

#my $serializer=new RDF::Redland::Serializer();

#  my $out = $serializer->serialize_model_to_file("deleteme.rdf", RDF::Redland::URI->new('http://totalcinema.com/NS/test#'), $rdf1->model);
}

#----------------------------------------------------------------------
# RDF::Trine
#----------------------------------------------------------------------
SKIP: {
  eval { require RDF::Trine };
  skip "RDF::Trine not installed", 5 if $@;

  my $rdf1 = RDF::Helper->new(
      BaseInterface => 'RDF::Trine',
      BaseURI => 'http://totalcinema.com/NS/test#'
  );

  my $rdf2 = RDF::Helper->new(
      BaseInterface => 'RDF::Trine',
      BaseURI => 'http://totalcinema.com/NS/test#'
  );
  
  $rdf1->assert_resource(URI1, RSS1_LINK, URI2); 
  $rdf1->assert_literal(URI1, RSS1_DESCRIPTION, 'Some Description');

  $rdf2->assert_resource(URI2, RSS1_LINK, URI1); 
  $rdf2->assert_literal(URI2, RSS1_DESCRIPTION, 'Some Other Description');

  $rdf1->include_model( $rdf2->model() );
  
  ok ( $rdf1->count() == 4, '4 nodes');
  ok( $rdf1->exists(URI1, RSS1_LINK, $rdf1->new_resource(URI2)) == 1 );
  ok( $rdf1->exists(URI1, RSS1_DESCRIPTION, 'Some Description') == 1 );
  ok( $rdf1->exists(URI2, RSS1_LINK, $rdf1->new_resource(URI1)) == 1 );
  ok( $rdf1->exists(URI2, RSS1_DESCRIPTION, 'Some Other Description') == 1 );
}

done_testing();
