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
  use Types::Standard 'HashRef';
  field $attr :param = {};
  method attr ()         { $attr }
  method _set_attr($new) { $attr = $new }
  use Sub::HandlesVia::Declare [ 'attr', '_set_attr', sub { {} } ],
    Hash => (
      'my_accessor' => 'accessor',
      'my_all' => 'all',
      'my_clear' => 'clear',
      'my_count' => 'count',
      'my_defined' => 'defined',
      'my_delete' => 'delete',
      'my_delete_where' => 'delete_where',
      'my_elements' => 'elements',
      'my_exists' => 'exists',
      'my_for_each_key' => 'for_each_key',
      'my_for_each_pair' => 'for_each_pair',
      'my_for_each_value' => 'for_each_value',
      'my_get' => 'get',
      'my_is_empty' => 'is_empty',
      'my_keys' => 'keys',
      'my_kv' => 'kv',
      'my_reset' => 'reset',
      'my_set' => 'set',
      'my_shallow_clone' => 'shallow_clone',
      'my_sorted_keys' => 'sorted_keys',
      'my_values' => 'values',
    );
}

## accessor

can_ok( 'My::Class', 'my_accessor' );

## all

can_ok( 'My::Class', 'my_all' );

subtest 'Testing my_all' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => { foo => 0, bar => 1 } );
    my %hash = $object->my_all;
  };
  is( $e, undef, 'no exception thrown running all example' );
};

## clear

can_ok( 'My::Class', 'my_clear' );

subtest 'Testing my_clear' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => { foo => 0, bar => 1 } );
    $object->my_clear;
    ok( !(exists $object->attr->{foo}), q{exists $object->attr->{foo} is false} );
    ok( !(exists $object->attr->{bar}), q{exists $object->attr->{bar} is false} );
  };
  is( $e, undef, 'no exception thrown running clear example' );
};

## count

can_ok( 'My::Class', 'my_count' );

subtest 'Testing my_count' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => { foo => 0, bar => 1 } );
    is( $object->my_count, 2, q{$object->my_count is 2} );
  };
  is( $e, undef, 'no exception thrown running count example' );
};

## defined

can_ok( 'My::Class', 'my_defined' );

subtest 'Testing my_defined' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => { foo => 0, bar => 1 } );
    is( $object->my_defined( 'foo' ), 1, q{$object->my_defined( 'foo' ) is 1} );
  };
  is( $e, undef, 'no exception thrown running defined example' );
};

## delete

can_ok( 'My::Class', 'my_delete' );

subtest 'Testing my_delete' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => { foo => 0, bar => 1 } );
    $object->my_delete( 'foo' );
    ok( !(exists $object->attr->{foo}), q{exists $object->attr->{foo} is false} );
  };
  is( $e, undef, 'no exception thrown running delete example' );
};

## delete_where

can_ok( 'My::Class', 'my_delete_where' );

subtest 'Testing my_delete_where' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => { foo => 0, bar => 1, baz => 2 } );
    $object->my_delete_where( sub { $_ eq 'foo' or $_ eq 'bar' } );
    is_deeply( $object->attr, { baz => 2 }, q{$object->attr deep match} );
    
    my $object2 = My::Class->new( attr => { foo => 0, bar => 1, baz => 2 } );
    $object2->my_delete_where( qr/^b/ );
    is_deeply( $object2->attr, { foo => 0 }, q{$object2->attr deep match} );
  };
  is( $e, undef, 'no exception thrown running delete_where example' );
};

## elements

can_ok( 'My::Class', 'my_elements' );

subtest 'Testing my_elements' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => { foo => 0, bar => 1 } );
    my %hash = $object->my_elements;
  };
  is( $e, undef, 'no exception thrown running elements example' );
};

## exists

can_ok( 'My::Class', 'my_exists' );

subtest 'Testing my_exists' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => { foo => 0, bar => 1 } );
    ok( $object->my_exists( 'foo' ), q{$object->my_exists( 'foo' ) is true} );
    ok( !($object->my_exists( 'baz' )), q{$object->my_exists( 'baz' ) is false} );
  };
  is( $e, undef, 'no exception thrown running exists example' );
};

## for_each_key

can_ok( 'My::Class', 'my_for_each_key' );

## for_each_pair

can_ok( 'My::Class', 'my_for_each_pair' );

## for_each_value

can_ok( 'My::Class', 'my_for_each_value' );

## get

can_ok( 'My::Class', 'my_get' );

subtest 'Testing my_get' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => { foo => 0, bar => 1 } );
    is( $object->my_get( 'bar' ), 1, q{$object->my_get( 'bar' ) is 1} );
  };
  is( $e, undef, 'no exception thrown running get example' );
};

## is_empty

can_ok( 'My::Class', 'my_is_empty' );

subtest 'Testing my_is_empty' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => { foo => 0, bar => 1 } );
    ok( !($object->my_is_empty), q{$object->my_is_empty is false} );
    $object->_set_attr( {} );
    ok( $object->my_is_empty, q{$object->my_is_empty is true} );
  };
  is( $e, undef, 'no exception thrown running is_empty example' );
};

## keys

can_ok( 'My::Class', 'my_keys' );

subtest 'Testing my_keys' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => { foo => 0, bar => 1 } );
    # says 'foo' and 'bar' in an unpredictable order
    note for $object->my_keys;
  };
  is( $e, undef, 'no exception thrown running keys example' );
};

## kv

can_ok( 'My::Class', 'my_kv' );

## reset

can_ok( 'My::Class', 'my_reset' );

## set

can_ok( 'My::Class', 'my_set' );

subtest 'Testing my_set' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => { foo => 0, bar => 1 } );
    $object->my_set( bar => 2, baz => 1 );
    is( $object->attr->{foo}, 0, q{$object->attr->{foo} is 0} );
    is( $object->attr->{baz}, 1, q{$object->attr->{baz} is 1} );
    is( $object->attr->{bar}, 2, q{$object->attr->{bar} is 2} );
  };
  is( $e, undef, 'no exception thrown running set example' );
};

## shallow_clone

can_ok( 'My::Class', 'my_shallow_clone' );

## sorted_keys

can_ok( 'My::Class', 'my_sorted_keys' );

subtest 'Testing my_sorted_keys' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => { foo => 0, bar => 1 } );
    # says 'bar' then 'foo'
    note for $object->my_sorted_keys;
  };
  is( $e, undef, 'no exception thrown running sorted_keys example' );
};

## values

can_ok( 'My::Class', 'my_values' );

subtest 'Testing my_values' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => { foo => 0, bar => 1 } );
    # says '0' and '1' in an unpredictable order
    note for $object->my_values;
  };
  is( $e, undef, 'no exception thrown running values example' );
};

done_testing;
