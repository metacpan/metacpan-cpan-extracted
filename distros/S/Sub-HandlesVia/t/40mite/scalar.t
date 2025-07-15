use strict;
use warnings;
## skip Test::Tabs
use Test::More;
use Test::Requires '5.008001';
use Test::Fatal;
use FindBin qw($Bin);
use lib "$Bin/lib";

use MyTest::TestClass::Scalar;
my $CLASS = q[MyTest::TestClass::Scalar];

## get

can_ok( $CLASS, 'my_get' );

## make_getter

can_ok( $CLASS, 'my_make_getter' );

subtest 'Testing my_make_getter' => sub {
  my $e = exception {
    my $object = $CLASS->new( attr => 10 );
    my $getter = $object->my_make_getter;
    $object->_set_attr( 11 );
    is( $getter->(), 11, q{$getter->() is 11} );
  };
  is( $e, undef, 'no exception thrown running make_getter example' );
};

## make_setter

can_ok( $CLASS, 'my_make_setter' );

subtest 'Testing my_make_setter' => sub {
  my $e = exception {
    my $object = $CLASS->new( attr => 10 );
    my $setter = $object->my_make_setter;
    $setter->( 11 );
    is( $object->attr, 11, q{$object->attr is 11} );
  };
  is( $e, undef, 'no exception thrown running make_setter example' );
};

## scalar_reference

can_ok( $CLASS, 'my_scalar_reference' );

subtest 'Testing my_scalar_reference' => sub {
  my $e = exception {
    my $object = $CLASS->new( attr => 10 );
    my $ref = $object->my_scalar_reference;
    $$ref++;
    is( $object->attr, 11, q{$object->attr is 11} );
  };
  is( $e, undef, 'no exception thrown running scalar_reference example' );
};

## set

can_ok( $CLASS, 'my_set' );

## stringify

can_ok( $CLASS, 'my_stringify' );

done_testing;
