#! perl

use Test::More;

use MooseX::amine;
use lib './t/lib';

my $mex = MooseX::amine->new( 'Test::Inheritance::ObjectWithRoleWithBaseRole' );

isa_ok( $mex , 'MooseX::amine' );

my $expected_data_structure = {
  attributes   => {
    base_attribute   => {
      from   => 'Test::Inheritance::BaseWithRole',
      meta   => { constraint => 'Str' },
      reader => 'base_attribute'
    },
    string_attribute => {
      accessor => 'string_attribute',
      from     => 'Test::Inheritance::ObjectWithRoleWithBaseRole',
      meta     => { constraint => 'Str' }
    },
    role_attribute => {
      accessor => 'role_attribute',
      from     => 'Test::Basic::Role',
      meta     => {
        constraint    => 'Str' ,
        is_required   => 1 ,
        documentation => 'required string' ,
      } ,
    } ,
  },
  methods => {
    base_method => { from => 'Test::Inheritance::BaseWithRole' ,
                     code => qq|sub base_method  { return 'this is a test from the base' }| , } ,
    test_method => { from => 'Test::Inheritance::ObjectWithRoleWithBaseRole' ,
                     code => qq|sub test_method { return 'this is a test' }| , } ,
    role_method => { from => 'Test::Basic::Role' ,
                     code => qq|sub role_method  { return 'role' }| , } ,
  }
};
is_deeply( $mex->examine , $expected_data_structure , 'see expected output from examine()' );

done_testing();
