#! perl

use Test::More;

use MooseX::amine;
use lib './t/lib';

my $mex = MooseX::amine->new( 'Test::Override::Object' );

isa_ok( $mex , 'MooseX::amine' );

my $expected_data_structure = {
  attributes   => {
    base_attribute   => {
      from     => 'Test::Override::Object',
      meta     => { constraint => 'Str' },
      accessor => 'base_attribute'
    },
    string_attribute => {
      accessor => 'string_attribute',
      from     => 'Test::Override::Object',
      meta     => { constraint => 'Str' }
    }
  },
  methods => {
    base_method => { from => 'Test::Override::Object' ,
                     code => qq|sub base_method { return 'this is a test' }| , },
    test_method => { from => 'Test::Override::Object' ,
                     code => qq|sub test_method { return 'this is a test' }| , }
  }
};
is_deeply( $mex->examine , $expected_data_structure , 'see expected output from examine()' );

done_testing();
