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
  use Types::Standard 'Any';
  field $attr :param = q[];
  method attr ()         { $attr }
  method _set_attr($new) { $attr = $new }
  use Sub::HandlesVia::Declare [ 'attr', '_set_attr', sub { q[] } ],
    Scalar => (
      'my_get' => 'get',
      'my_make_getter' => 'make_getter',
      'my_make_setter' => 'make_setter',
      'my_set' => 'set',
      'my_stringify' => 'stringify',
    );
}

## get

can_ok( 'My::Class', 'my_get' );

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

## set

can_ok( 'My::Class', 'my_set' );

## stringify

can_ok( 'My::Class', 'my_stringify' );

done_testing;
