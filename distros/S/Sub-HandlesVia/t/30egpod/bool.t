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
  use Types::Standard 'Bool';
  has attr => (
    is => 'rwp',
    isa => Bool,
    handles_via => 'Bool',
    handles => {
      'my_not' => 'not',
      'my_reset' => 'reset',
      'my_set' => 'set',
      'my_toggle' => 'toggle',
      'my_unset' => 'unset',
    },
    default => sub { 0 },
  );
};

## not

can_ok( 'My::Class', 'my_not' );

subtest 'Testing my_not' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => 1 );
    ok( !($object->my_not()), q{$object->my_not() is false} );
  };
  is( $e, undef, 'no exception thrown running not example' );
};

## reset

can_ok( 'My::Class', 'my_reset' );

## set

can_ok( 'My::Class', 'my_set' );

subtest 'Testing my_set' => sub {
  my $e = exception {
    my $object = My::Class->new();
    $object->my_set();
    ok( $object->attr, q{$object->attr is true} );
  };
  is( $e, undef, 'no exception thrown running set example' );
};

## toggle

can_ok( 'My::Class', 'my_toggle' );

subtest 'Testing my_toggle' => sub {
  my $e = exception {
    my $object = My::Class->new();
    $object->my_toggle();
    ok( $object->attr, q{$object->attr is true} );
    $object->my_toggle();
    ok( !($object->attr), q{$object->attr is false} );
  };
  is( $e, undef, 'no exception thrown running toggle example' );
};

## unset

can_ok( 'My::Class', 'my_unset' );

subtest 'Testing my_unset' => sub {
  my $e = exception {
    my $object = My::Class->new();
    $object->my_unset();
    ok( !($object->attr), q{$object->attr is false} );
  };
  is( $e, undef, 'no exception thrown running unset example' );
};

done_testing;
