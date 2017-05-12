use Test::More;
use List::Objects::WithUtils;
use MoopsX::ListObjects;

class My::Foo :rw {

  has array => (
    default => sub { array },
    isa     => ArrayObj,
    coerce  => 1,
  );

  has hash => (
    default => sub { hash },
    isa     => HashObj,
    coerce  => 1,
  );

  has immarray => (
    default => sub { immarray },
    isa     => ImmutableArray,
    coerce  => 1,
  );

  has string => (
    default => sub { 'str' },
    isa     => Str,
  );
  
  method fooify ( (ArrayObj) $foo ) {
    $foo->count
  }
}

my $foo = My::Foo->new;
isa_ok $foo->array, 'List::Objects::WithUtils::Array';
isa_ok $foo->hash,  'List::Objects::WithUtils::Hash';
isa_ok $foo->immarray, 'List::Objects::WithUtils::Array::Immutable';


# Types.
ok $foo->string eq 'str', 'imported Types::Standard ok';

ok $foo->fooify( array 1 .. 10 ) == 10, 'type-checking ok';

done_testing;
