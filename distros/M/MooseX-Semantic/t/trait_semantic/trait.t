#=======================================================================
#         FILE:  trait.t
#  DESCRIPTION:  
#       AUTHOR:  Konstantin Baierer (kba), konstantin.baierer@gmail.com
#      CREATED:  11/22/2011 11:38:36 PM
#=======================================================================
use strict;
use warnings;
use Test::More; 
use Test::Moose;
use Data::Dumper;
use Scalar::Util qw(blessed);
use MooseX::Semantic::Test::Person;
use URI;

sub person_with_rdfabout {
    my $person = MooseX::Semantic::Test::Person->new(
        rdf_about => 'http://some/person'
    );
    my $person_attr_name =  $person->meta->get_attribute('name');
    does_ok( $person_attr_name, 'MooseX::Semantic::Meta::Attribute::Trait' );
    can_ok( $person_attr_name, 'has_uri' );
    ok( $person_attr_name->uri->uri eq 'http://xmlns.com/foaf/0.1/name', 'uri attribute matches');
}
sub person_blank {
    my $person = MooseX::Semantic::Test::Person->new;
    my $person_attr_name =  $person->meta->get_attribute('name');
    does_ok( $person_attr_name, 'MooseX::Semantic::Meta::Attribute::Trait' );
    can_ok( $person_attr_name, 'has_uri' );
    is( $person_attr_name->uri->uri, 'http://xmlns.com/foaf/0.1/name', 'uri attribute matches');
    # warn Dumper $person;
    # warn Dumper $person->rdf_about;
    # warn Dumper $person;
}
# warn Dumper  $person->meta->get_attribute('friends')->type_constraint;
# warn Dumper  $person->meta->get_attribute('name')->type_constraint;
# warn Dumper blessed( 1);
# warn Dumper( URI->new('bla')
# );

&person_with_rdfabout;
&person_blank;



done_testing;
