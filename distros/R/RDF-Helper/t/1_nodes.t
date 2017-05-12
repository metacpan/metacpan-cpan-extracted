use Test::More;

use strict;
use warnings;
use Data::Dumper;

use RDF::Helper;

use constant URI1 => 'http://example.org/one';
use constant XSD_INT => 'http://www.w3.org/2001/XMLSchema#int';

#----------------------------------------------------------------------
# RDF::Redland
#----------------------------------------------------------------------
SKIP: {
  eval { require RDF::Redland };
  skip "RDF::Redland not installed", 6 if $@;

  my $rdf = RDF::Helper->new(
      BaseInterface => 'RDF::Redland',
      namespaces => {
		     xsd => 'http://www.w3.org/2001/XMLSchema#',
		    },
      ExpandQNames => 1,
      BaseURI => 'http://totalcinema.com/NS/test#'
  );
  
  test( $rdf );

}

#----------------------------------------------------------------------
# RDF::Trine
#----------------------------------------------------------------------
SKIP: {
  eval { require RDF::Trine };
  skip "RDF::Redland not installed", 6 if $@;

  my $rdf = RDF::Helper->new(
      BaseInterface => 'RDF::Trine',
      namespaces => {
		     xsd => 'http://www.w3.org/2001/XMLSchema#',
		    },
      ExpandQNames => 1,
      BaseURI => 'http://totalcinema.com/NS/test#'
  );

  test( $rdf );

}

sub test {
  my $rdf = shift;
  ok( $rdf->new_resource(URI1) );
  ok( $rdf->new_literal('A Value') );
  ok( $rdf->new_bnode );

  my $typed = $rdf->new_literal('15', undef, XSD_INT);
  my $typed2 = $rdf->new_literal('42.17', undef, 'xsd:decimal');
  my $langed = $rdf->new_literal('Speek Amurrican', 'en-US');

  is($typed->literal_datatype->as_string, XSD_INT);
  is($typed2->literal_datatype->as_string, 'http://www.w3.org/2001/XMLSchema#decimal');
  is($langed->literal_value_language, 'en-US');
}

done_testing();
