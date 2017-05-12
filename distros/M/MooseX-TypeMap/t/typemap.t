
use strict;
use warnings;
use Scalar::Util 'blessed';
use Test::More tests => 10;
use Test::Exception;

BEGIN { use_ok('MooseX::TypeMap') }

use MooseX::TypeMap::Entry;
use MooseX::Types::Moose (
  qw(Str Int Num Ref Object Value Defined HashRef ArrayRef Undef),
);

my %entries;
lives_ok {
  %entries = (
    Defined => MooseX::TypeMap::Entry->new( type_constraint => Defined, data => 'defined'),
    Str => MooseX::TypeMap::Entry->new( type_constraint => Str, data => 'str'),
    Int => MooseX::TypeMap::Entry->new( type_constraint => Int, data => 'int'),
    Num => MooseX::TypeMap::Entry->new( type_constraint => Num, data => 'num'),
    Ref => MooseX::TypeMap::Entry->new( type_constraint => Ref, data => 'ref'),
    Obj => MooseX::TypeMap::Entry->new( type_constraint => Object, data => 'obj'),
    Value => MooseX::TypeMap::Entry->new( type_constraint => Value, data => 'value'),
    HashRef => MooseX::TypeMap::Entry->new( type_constraint => HashRef, data => 'HashRef'),
  );
} 'Entries build normally';

#fucking MX::Types...
ok(blessed($entries{Defined}->type_constraint) ne 'MooseX::Types::TypeDecorator', 'extract from decorator');

{
  my $type_map = MooseX::TypeMap->new( subtype_entries => [ values %entries ] );
  is( $type_map->resolve(ArrayRef), 'ref' );
  is( $type_map->resolve(HashRef), 'HashRef' );
  ok( !defined $type_map->resolve(Undef) );
}

{
  my $array_ref_entry = MooseX::TypeMap::Entry->new( type_constraint => ArrayRef, data => 'ArrayRef');
  my $type_map = MooseX::TypeMap->new( subtype_entries => [ $entries{Ref} ] );
  my $clone = $type_map->clone_with_additional_entries( {
    type_entries => [ $entries{HashRef} ],
    subtype_entries => [ $array_ref_entry ]
  } );
  is( $type_map->resolve(HashRef), 'ref', 'baseline before clone' );
  is( $clone->resolve(HashRef), 'HashRef', 'clone type_entries' );
  is( $clone->resolve(ArrayRef), 'ArrayRef', 'clone subtype_entries' );

  #now let's test the cache. not pretty, but it works
  delete $clone->{_storted_entries};
  is( $clone->resolve(ArrayRef), 'ArrayRef', 'cache works' );

}


__END__;
