use strict;
use warnings;
## skip Test::Tabs
use Test::More;
use Test::Requires '5.010001';
use Test::Fatal;
use FindBin qw($Bin);
use lib "$Bin/lib";

use MyTest::TestClass::Counter;
my $CLASS = q[MyTest::TestClass::Counter];

## dec

can_ok( $CLASS, 'my_dec' );

subtest 'Testing my_dec' => sub {
  my $e = exception {
    my $object = $CLASS->new( attr => 10 );
    $object->my_dec;
    $object->my_dec;
    is( $object->attr, 8, q{$object->attr is 8} );
    $object->my_dec( 5 );
    is( $object->attr, 3, q{$object->attr is 3} );
  };
  is( $e, undef, 'no exception thrown running dec example' );
};

## inc

can_ok( $CLASS, 'my_inc' );

subtest 'Testing my_inc' => sub {
  my $e = exception {
    my $object = $CLASS->new( attr => 0 );
    $object->my_inc;
    $object->my_inc;
    is( $object->attr, 2, q{$object->attr is 2} );
    $object->my_inc( 3 );
    is( $object->attr, 5, q{$object->attr is 5} );
  };
  is( $e, undef, 'no exception thrown running inc example' );
};

## reset

can_ok( $CLASS, 'my_reset' );

subtest 'Testing my_reset' => sub {
  my $e = exception {
    my $object = $CLASS->new( attr => 10 );
    $object->my_reset;
    is( $object->attr, 0, q{$object->attr is 0} );
  };
  is( $e, undef, 'no exception thrown running reset example' );
};

## set

can_ok( $CLASS, 'my_set' );

subtest 'Testing my_set' => sub {
  my $e = exception {
    my $object = $CLASS->new( attr => 0 );
    $object->my_set( 5 );
    is( $object->attr, 5, q{$object->attr is 5} );
  };
  is( $e, undef, 'no exception thrown running set example' );
};

done_testing;
