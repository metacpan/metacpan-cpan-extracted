#=======================================================================
#  DESCRIPTION:  
#       AUTHOR:  Konstantin Baierer (kba), konstantin.baierer@gmail.com
#      CREATED:  11/22/2011 11:40:13 PM
#    COPYRIGHT:  Artistic License 2.0
#=======================================================================
package MooseX::Semantic::Test::StrictPerson;
use Moose;
use MooseX::ClassAttribute;
use URI;

extends 'MooseX::Semantic::Test::Person';

with (
    'MooseX::Semantic::Role::RdfImportAll',
);
 
__PACKAGE__->rdf_type([qw{http://xmlns.com/foaf/0.1/Person http://schema.org/Person}]);

has '+name' => (
    uri_reader => ['http://schema.org/name', 'http://www.w3.org/2000/01/rdf-schema#label'],
    uri_writer => ['http://www.w3.org/2000/01/rdf-schema#label'],
    required => 1,
);
1;
