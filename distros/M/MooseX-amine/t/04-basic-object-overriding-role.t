#! perl

use Test::More;

use MooseX::amine;
use lib './t/lib';

my $mex = MooseX::amine->new( 'Test::Basic::ObjectOverridingRole' );

isa_ok( $mex , 'MooseX::amine' );

my $expected_data_structure = {
  attributes => {
    role_attribute => {
      accessor => 'role_attribute',
      from     => 'Test::Basic::ObjectOverridingRole',
      meta     => {
        constraint    => 'Int' ,
        documentation => 'overridden attribute' ,
      } ,
    } ,
  },
  methods => {
    role_method => {
      from => 'Test::Basic::ObjectOverridingRole' ,
      code => qq|sub role_method  { return 'override' }| ,
    } ,
  } ,
};
is_deeply( $mex->examine , $expected_data_structure , 'see expected output from examine()' );

done_testing();
