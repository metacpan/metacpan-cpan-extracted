use strict;
use warnings;
## skip Test::Tabs
use Test::More;
use Test::Requires '5.008001';
use Test::Fatal;
use FindBin qw($Bin);
use lib "$Bin/lib";

use MyTest::TestClass::Bool;
my $CLASS = q[MyTest::TestClass::Bool];

## not

can_ok( $CLASS, 'my_not' );

subtest 'Testing my_not' => sub {
  my $e = exception {
    my $object = $CLASS->new( attr => 1 );
    ok( !($object->my_not()), q{$object->my_not() is false} );
  };
  is( $e, undef, 'no exception thrown running not example' );
};

## reset

can_ok( $CLASS, 'my_reset' );

## set

can_ok( $CLASS, 'my_set' );

subtest 'Testing my_set' => sub {
  my $e = exception {
    my $object = $CLASS->new();
    $object->my_set();
    ok( $object->attr, q{$object->attr is true} );
  };
  is( $e, undef, 'no exception thrown running set example' );
};

## toggle

can_ok( $CLASS, 'my_toggle' );

subtest 'Testing my_toggle' => sub {
  my $e = exception {
    my $object = $CLASS->new();
    $object->my_toggle();
    ok( $object->attr, q{$object->attr is true} );
    $object->my_toggle();
    ok( !($object->attr), q{$object->attr is false} );
  };
  is( $e, undef, 'no exception thrown running toggle example' );
};

## unset

can_ok( $CLASS, 'my_unset' );

subtest 'Testing my_unset' => sub {
  my $e = exception {
    my $object = $CLASS->new();
    $object->my_unset();
    ok( !($object->attr), q{$object->attr is false} );
  };
  is( $e, undef, 'no exception thrown running unset example' );
};

done_testing;
