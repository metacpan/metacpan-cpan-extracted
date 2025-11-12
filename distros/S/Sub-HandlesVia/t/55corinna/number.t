use Test::Requires '5.038';
use 5.038;
use strict;
use warnings;
use feature 'class';
no warnings 'experimental::class';
use Test::More;
use Test::Fatal;
## skip Test::Tabs

class My::Class {
  use Types::Standard 'Num';
  field $attr :param = 0;
  method attr ()         { $attr }
  method _set_attr($new) { $attr = $new }
  use Sub::HandlesVia::Declare [ 'attr', '_set_attr', sub { 0 } ],
    Number => (
      'my_abs' => 'abs',
      'my_add' => 'add',
      'my_ceil' => 'ceil',
      'my_cmp' => 'cmp',
      'my_div' => 'div',
      'my_eq' => 'eq',
      'my_floor' => 'floor',
      'my_ge' => 'ge',
      'my_get' => 'get',
      'my_gt' => 'gt',
      'my_le' => 'le',
      'my_lt' => 'lt',
      'my_mod' => 'mod',
      'my_mul' => 'mul',
      'my_ne' => 'ne',
      'my_set' => 'set',
      'my_sub' => 'sub',
    );
}

## abs

can_ok( 'My::Class', 'my_abs' );

subtest 'Testing my_abs' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => -5 );
    $object->my_abs;
    is( $object->attr, 5, q{$object->attr is 5} );
  };
  is( $e, undef, 'no exception thrown running abs example' );
};

## add

can_ok( 'My::Class', 'my_add' );

subtest 'Testing my_add' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => 4 );
    $object->my_add( 5 );
    is( $object->attr, 9, q{$object->attr is 9} );
  };
  is( $e, undef, 'no exception thrown running add example' );
};

## ceil

can_ok( 'My::Class', 'my_ceil' );

## cmp

can_ok( 'My::Class', 'my_cmp' );

## div

can_ok( 'My::Class', 'my_div' );

subtest 'Testing my_div' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => 6 );
    $object->my_div( 2 );
    is( $object->attr, 3, q{$object->attr is 3} );
  };
  is( $e, undef, 'no exception thrown running div example' );
};

## eq

can_ok( 'My::Class', 'my_eq' );

## floor

can_ok( 'My::Class', 'my_floor' );

## ge

can_ok( 'My::Class', 'my_ge' );

## get

can_ok( 'My::Class', 'my_get' );

subtest 'Testing my_get' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => 4 );
    is( $object->my_get, 4, q{$object->my_get is 4} );
  };
  is( $e, undef, 'no exception thrown running get example' );
};

## gt

can_ok( 'My::Class', 'my_gt' );

## le

can_ok( 'My::Class', 'my_le' );

## lt

can_ok( 'My::Class', 'my_lt' );

## mod

can_ok( 'My::Class', 'my_mod' );

subtest 'Testing my_mod' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => 5 );
    $object->my_mod( 2 );
    is( $object->attr, 1, q{$object->attr is 1} );
  };
  is( $e, undef, 'no exception thrown running mod example' );
};

## mul

can_ok( 'My::Class', 'my_mul' );

subtest 'Testing my_mul' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => 2 );
    $object->my_mul( 5 );
    is( $object->attr, 10, q{$object->attr is 10} );
  };
  is( $e, undef, 'no exception thrown running mul example' );
};

## ne

can_ok( 'My::Class', 'my_ne' );

## set

can_ok( 'My::Class', 'my_set' );

subtest 'Testing my_set' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => 4 );
    $object->my_set( 5 );
    is( $object->attr, 5, q{$object->attr is 5} );
  };
  is( $e, undef, 'no exception thrown running set example' );
};

## sub

can_ok( 'My::Class', 'my_sub' );

subtest 'Testing my_sub' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => 9 );
    $object->my_sub( 6 );
    is( $object->attr, 3, q{$object->attr is 3} );
  };
  is( $e, undef, 'no exception thrown running sub example' );
};

done_testing;
