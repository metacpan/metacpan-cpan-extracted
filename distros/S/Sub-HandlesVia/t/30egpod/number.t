use 5.008;
use strict;
use warnings;
use Test::More;
use Test::Fatal;
## skip Test::Tabs

{ package Local::Dummy1; use Test::Requires { 'Moo' => '1.006' } };

use constant { true => !!1, false => !!0 };

BEGIN {
  package My::Class;
  use Moo;
  use Sub::HandlesVia;
  use Types::Standard 'Num';
  has attr => (
    is => 'rwp',
    isa => Num,
    handles_via => 'Number',
    handles => {
      'my_abs' => 'abs',
      'my_add' => 'add',
      'my_cmp' => 'cmp',
      'my_div' => 'div',
      'my_eq' => 'eq',
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
    },
    default => sub { 0 },
  );
};

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
