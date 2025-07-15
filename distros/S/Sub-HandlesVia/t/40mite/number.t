use strict;
use warnings;
## skip Test::Tabs
use Test::More;
use Test::Requires '5.008001';
use Test::Fatal;
use FindBin qw($Bin);
use lib "$Bin/lib";

use MyTest::TestClass::Number;
my $CLASS = q[MyTest::TestClass::Number];

## abs

can_ok( $CLASS, 'my_abs' );

subtest 'Testing my_abs' => sub {
  my $e = exception {
    my $object = $CLASS->new( attr => -5 );
    $object->my_abs;
    is( $object->attr, 5, q{$object->attr is 5} );
  };
  is( $e, undef, 'no exception thrown running abs example' );
};

## add

can_ok( $CLASS, 'my_add' );

subtest 'Testing my_add' => sub {
  my $e = exception {
    my $object = $CLASS->new( attr => 4 );
    $object->my_add( 5 );
    is( $object->attr, 9, q{$object->attr is 9} );
  };
  is( $e, undef, 'no exception thrown running add example' );
};

## ceil

can_ok( $CLASS, 'my_ceil' );

## cmp

can_ok( $CLASS, 'my_cmp' );

## div

can_ok( $CLASS, 'my_div' );

subtest 'Testing my_div' => sub {
  my $e = exception {
    my $object = $CLASS->new( attr => 6 );
    $object->my_div( 2 );
    is( $object->attr, 3, q{$object->attr is 3} );
  };
  is( $e, undef, 'no exception thrown running div example' );
};

## eq

can_ok( $CLASS, 'my_eq' );

## floor

can_ok( $CLASS, 'my_floor' );

## ge

can_ok( $CLASS, 'my_ge' );

## get

can_ok( $CLASS, 'my_get' );

subtest 'Testing my_get' => sub {
  my $e = exception {
    my $object = $CLASS->new( attr => 4 );
    is( $object->my_get, 4, q{$object->my_get is 4} );
  };
  is( $e, undef, 'no exception thrown running get example' );
};

## gt

can_ok( $CLASS, 'my_gt' );

## le

can_ok( $CLASS, 'my_le' );

## lt

can_ok( $CLASS, 'my_lt' );

## mod

can_ok( $CLASS, 'my_mod' );

subtest 'Testing my_mod' => sub {
  my $e = exception {
    my $object = $CLASS->new( attr => 5 );
    $object->my_mod( 2 );
    is( $object->attr, 1, q{$object->attr is 1} );
  };
  is( $e, undef, 'no exception thrown running mod example' );
};

## mul

can_ok( $CLASS, 'my_mul' );

subtest 'Testing my_mul' => sub {
  my $e = exception {
    my $object = $CLASS->new( attr => 2 );
    $object->my_mul( 5 );
    is( $object->attr, 10, q{$object->attr is 10} );
  };
  is( $e, undef, 'no exception thrown running mul example' );
};

## ne

can_ok( $CLASS, 'my_ne' );

## set

can_ok( $CLASS, 'my_set' );

subtest 'Testing my_set' => sub {
  my $e = exception {
    my $object = $CLASS->new( attr => 4 );
    $object->my_set( 5 );
    is( $object->attr, 5, q{$object->attr is 5} );
  };
  is( $e, undef, 'no exception thrown running set example' );
};

## sub

can_ok( $CLASS, 'my_sub' );

subtest 'Testing my_sub' => sub {
  my $e = exception {
    my $object = $CLASS->new( attr => 9 );
    $object->my_sub( 6 );
    is( $object->attr, 3, q{$object->attr is 3} );
  };
  is( $e, undef, 'no exception thrown running sub example' );
};

done_testing;
