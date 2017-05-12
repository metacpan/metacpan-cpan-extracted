use strictures 1;
use Test::More;
use Test::Fatal;

{
  package Foo;
  use Moo;
  use MooX::Aliases;
  use namespace::autoclean;
  has attr1 => (
    is => 'ro',
    required => 1,
    alias => 'attr1_alias',
  );
}

is exception { Foo->new( attr1_alias => 1 ); }, undef,
  'aliases work when using namespace::autoclean';

ok +Foo->can('attr1_alias'),
  'aliases still exist when using namespace::autoclean';

{
  package Bar;
  use Moo;
  use MooX::Aliases;
  use namespace::autoclean;
  BEGIN {
    has attr1 => (
      is => 'ro',
      required => 1,
      alias => 'attr1_alias',
    );
  }
}

is exception { Bar->new( attr1_alias => 1 ); }, undef,
  'compile time aliases work in constructor with namespace::autoclean';

ok +Bar->can('attr1_alias'),
  'compile time alias methods still exist with namespace::autoclean';

done_testing;
