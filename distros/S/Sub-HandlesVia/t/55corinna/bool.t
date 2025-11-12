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
  use Types::Standard 'Bool';
  field $attr :param = 0;
  method attr ()         { $attr }
  method _set_attr($new) { $attr = $new }
  use Sub::HandlesVia::Declare [ 'attr', '_set_attr', sub { 0 } ],
    Bool => (
      'my_not' => 'not',
      'my_reset' => 'reset',
      'my_set' => 'set',
      'my_toggle' => 'toggle',
      'my_unset' => 'unset',
    );
}

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
