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
  use Types::Standard 'Any';
  has attr => (
    is => 'rwp',
    isa => Any,
    handles_via => 'Scalar',
    handles => {
      'my_make_getter' => 'make_getter',
      'my_make_setter' => 'make_setter',
      'my_scalar_reference' => 'scalar_reference',
    },
    default => sub { q[] },
  );
};

## make_getter

can_ok( 'My::Class', 'my_make_getter' );

subtest 'Testing my_make_getter' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => 10 );
    my $getter = $object->my_make_getter;
    $object->_set_attr( 11 );
    is( $getter->(), 11, q{$getter->() is 11} );
  };
  is( $e, undef, 'no exception thrown running make_getter example' );
};

## make_setter

can_ok( 'My::Class', 'my_make_setter' );

subtest 'Testing my_make_setter' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => 10 );
    my $setter = $object->my_make_setter;
    $setter->( 11 );
    is( $object->attr, 11, q{$object->attr is 11} );
  };
  is( $e, undef, 'no exception thrown running make_setter example' );
};

## scalar_reference

can_ok( 'My::Class', 'my_scalar_reference' );

subtest 'Testing my_scalar_reference' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => 10 );
    my $ref = $object->my_scalar_reference;
    $$ref++;
    is( $object->attr, 11, q{$object->attr is 11} );
  };
  is( $e, undef, 'no exception thrown running scalar_reference example' );
};

done_testing;
