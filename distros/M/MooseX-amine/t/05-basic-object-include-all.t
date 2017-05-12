#! perl

use Test::More;

use MooseX::amine;
use lib './t/lib';

my $mex = MooseX::amine->new({
  module                           => 'Test::Basic::Object',
  include_accessors_in_method_list => 1 ,
  include_moose_in_isa             => 1 ,
  include_private_attributes       => 1 ,
  include_private_methods          => 1 ,
  include_standard_methods         => 1 ,
});

isa_ok( $mex , 'MooseX::amine' );

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
      from   => 'Test::Basic::Object',
    } ,
    hash_trait => {
      accessor => 'hash_trait',
      from     => 'Test::Basic::Object',
      meta     => {
        constraint => 'HashRef' ,
        traits     => [ 'Moose::Meta::Attribute::Native::Trait::Hash' ] ,
      },
    },
    _private_attribute => {
      reader => '_private_attribute' ,
      from   => 'Test::Basic::Object' ,
      meta   => {
        constraint => 'Int' ,
      } ,
    } ,
  },
  methods => {
    _private_attribute => { from => 'Test::Basic::Object' } ,
    _private_method    => { from => 'Test::Basic::Object' } ,
    simple_attribute   => { from => 'Test::Basic::Object' } ,
    bare_ro_attribute  => { from => 'Test::Basic::Object' } ,
    hash_trait         => { from => 'Test::Basic::Object' } ,
    simple_method      => { from => 'Test::Basic::Object' } ,
    BUILDALL           => { from => 'Moose::Object' },
    BUILDARGS          => { from => 'Moose::Object' },
    DEMOLISHALL        => { from => 'Moose::Object' },
    DESTROY            => { from => 'Test::Basic::Object' },
    DOES               => { from => 'Moose::Object' },
    does               => { from => 'Moose::Object' },
    dump               => { from => 'Moose::Object' },
    meta               => { from => 'Test::Basic::Object' },
    new                => { from => 'Test::Basic::Object' },
  } ,
};

my $examine = $mex->examine;
delete $examine->{methods}{$_}{code} foreach ( keys %{ $examine->{methods} } );
is_deeply( $examine , $expected_data_structure , 'see expected output from examine()' );

done_testing();
