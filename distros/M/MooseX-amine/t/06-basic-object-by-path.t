#! perl

use Test::More;

use MooseX::amine;
use lib './t/lib';

my $expected_data_structure = {
  attributes => {
    simple_attribute => {
      accessor => 'simple_attribute',
      from     => 'Test::Basic::Object',
      meta     => {
        constraint => 'Str' ,
      } ,
    } ,
    bare_ro_attribute => {
      reader => 'bare_ro_attribute',
      from     => 'Test::Basic::Object',
    } ,
    hash_trait => {
      accessor => 'hash_trait',
      from     => 'Test::Basic::Object',
      meta     => {
        constraint => 'HashRef' ,
        traits     => [ 'Moose::Meta::Attribute::Native::Trait::Hash' ] ,
      },
    },
  },
  methods => {
    simple_method => {
      from => 'Test::Basic::Object' ,
      code => qq|sub simple_method   { return 'simple' }| ,
    } ,
  } ,
};

{
  my $mex = MooseX::amine->new({ path => './t/lib/Test/Basic/Object.pm' });

  isa_ok( $mex , 'MooseX::amine' , 'Constructor from hashref');
  is_deeply(
    $mex->examine , $expected_data_structure ,
    'see expected output from examine()' );
}
{
  # Same but pass hash to constructor instead of ref
  my $mex = MooseX::amine->new( path => './t/lib/Test/Basic/Object.pm' );

  isa_ok( $mex , 'MooseX::amine', 'Constructor from hash' );
  is_deeply(
    $mex->examine , $expected_data_structure ,
    'see expected output from examine() after build from hash'
  );
}

done_testing();
