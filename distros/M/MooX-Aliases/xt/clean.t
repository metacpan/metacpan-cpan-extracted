use strictures 1;
use Test::More;
use Test::Fatal;

{
  package Foo;
  use Moo;
  use MooX::Aliases;
  use namespace::clean;
  has attr1 => (
    is => 'ro',
    required => 1,
    alias => 'attr1_alias',
  );
}

is exception { Foo->new( attr1_alias => 1 ); }, undef,
  'aliases work when using namespace::clean';

ok +Foo->can('attr1_alias'),
  'aliases still exist when using namespace::clean';

{
  package Bar;
  use Moo;
  use MooX::Aliases;
  use namespace::clean;
  BEGIN {
    has attr1 => (
      is => 'ro',
      required => 1,
      alias => 'attr1_alias',
    );
  }
}

is exception { Bar->new( attr1_alias => 1 ); }, undef,
  'compile time aliases work in constructor with namespace::clean';

ok +Bar->can('attr1_alias'),
  'compile time alias methods still exist with namespace::clean';

done_testing;
