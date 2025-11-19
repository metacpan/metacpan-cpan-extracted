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
  use Types::Standard 'ArrayRef';
  field $attr :param = [];
  method attr ()         { $attr }
  method _set_attr($new) { $attr = $new }
  use Sub::HandlesVia::Declare [ 'attr', '_set_attr', sub { [] } ],
    Array => (
      'my_accessor' => 'accessor',
      'my_all' => 'all',
      'my_all_true' => 'all_true',
      'my_any' => 'any',
      'my_apply' => 'apply',
      'my_clear' => 'clear',
      'my_count' => 'count',
      'my_delete' => 'delete',
      'my_elements' => 'elements',
      'my_first' => 'first',
      'my_first_index' => 'first_index',
      'my_flatten' => 'flatten',
      'my_flatten_deep' => 'flatten_deep',
      'my_for_each' => 'for_each',
      'my_for_each_pair' => 'for_each_pair',
      'my_get' => 'get',
      'my_grep' => 'grep',
      'my_head' => 'head',
      'my_indexed' => 'indexed',
      'my_insert' => 'insert',
      'my_is_empty' => 'is_empty',
      'my_join' => 'join',
      'my_map' => 'map',
      'my_max' => 'max',
      'my_maxstr' => 'maxstr',
      'my_min' => 'min',
      'my_minstr' => 'minstr',
      'my_natatime' => 'natatime',
      'my_not_all_true' => 'not_all_true',
      'my_pairfirst' => 'pairfirst',
      'my_pairgrep' => 'pairgrep',
      'my_pairkeys' => 'pairkeys',
      'my_pairmap' => 'pairmap',
      'my_pairs' => 'pairs',
      'my_pairvalues' => 'pairvalues',
      'my_pick_random' => 'pick_random',
      'my_pop' => 'pop',
      'my_print' => 'print',
      'my_product' => 'product',
      'my_push' => 'push',
      'my_reduce' => 'reduce',
      'my_reductions' => 'reductions',
      'my_reset' => 'reset',
      'my_reverse' => 'reverse',
      'my_sample' => 'sample',
      'my_set' => 'set',
      'my_shallow_clone' => 'shallow_clone',
      'my_shift' => 'shift',
      'my_shuffle' => 'shuffle',
      'my_shuffle_in_place' => 'shuffle_in_place',
      'my_sort' => 'sort',
      'my_sort_in_place' => 'sort_in_place',
      'my_splice' => 'splice',
      'my_sum' => 'sum',
      'my_tail' => 'tail',
      'my_uniq' => 'uniq',
      'my_uniq_in_place' => 'uniq_in_place',
      'my_uniqnum' => 'uniqnum',
      'my_uniqnum_in_place' => 'uniqnum_in_place',
      'my_uniqstr' => 'uniqstr',
      'my_uniqstr_in_place' => 'uniqstr_in_place',
      'my_unshift' => 'unshift',
    );
}

## accessor

can_ok( 'My::Class', 'my_accessor' );

subtest 'Testing my_accessor' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => [ 'foo', 'bar', 'baz' ] );
    $object->my_accessor( 1, 'quux' );
    is_deeply( $object->attr, [ 'foo', 'quux', 'baz' ], q{$object->attr deep match} );
    is( $object->my_accessor( 2 ), 'baz', q{$object->my_accessor( 2 ) is 'baz'} );
  };
  is( $e, undef, 'no exception thrown running accessor example' );
};

## all

can_ok( 'My::Class', 'my_all' );

subtest 'Testing my_all' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => [ 'foo', 'bar' ] );
    my @list = $object->my_all;
    is_deeply( \@list, [ 'foo', 'bar' ], q{\@list deep match} );
  };
  is( $e, undef, 'no exception thrown running all example' );
};

## all_true

can_ok( 'My::Class', 'my_all_true' );

## any

can_ok( 'My::Class', 'my_any' );

subtest 'Testing my_any' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => [ 'foo', 'bar', 'baz' ] );
    my $truth  = $object->my_any( sub { /a/ } );
    ok( $truth, q{$truth is true} );
  };
  is( $e, undef, 'no exception thrown running any example' );
};

## apply

can_ok( 'My::Class', 'my_apply' );

## clear

can_ok( 'My::Class', 'my_clear' );

subtest 'Testing my_clear' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => [ 'foo' ] );
    $object->my_clear;
    is_deeply( $object->attr, [], q{$object->attr deep match} );
  };
  is( $e, undef, 'no exception thrown running clear example' );
};

## count

can_ok( 'My::Class', 'my_count' );

subtest 'Testing my_count' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => [ 'foo', 'bar' ] );
    is( $object->my_count, 2, q{$object->my_count is 2} );
  };
  is( $e, undef, 'no exception thrown running count example' );
};

## delete

can_ok( 'My::Class', 'my_delete' );

## elements

can_ok( 'My::Class', 'my_elements' );

subtest 'Testing my_elements' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => [ 'foo', 'bar' ] );
    my @list = $object->my_elements;
    is_deeply( \@list, [ 'foo', 'bar' ], q{\@list deep match} );
  };
  is( $e, undef, 'no exception thrown running elements example' );
};

## first

can_ok( 'My::Class', 'my_first' );

subtest 'Testing my_first' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => [ 'foo', 'bar', 'baz' ] );
    my $found  = $object->my_first( sub { /a/ } );
    is( $found, 'bar', q{$found is 'bar'} );
  };
  is( $e, undef, 'no exception thrown running first example' );
};

## first_index

can_ok( 'My::Class', 'my_first_index' );

subtest 'Testing my_first_index' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => [ 'foo', 'bar', 'baz' ] );
    my $found  = $object->my_first_index( sub { /z$/ } );
    is( $found, 2, q{$found is 2} );
  };
  is( $e, undef, 'no exception thrown running first_index example' );
};

## flatten

can_ok( 'My::Class', 'my_flatten' );

subtest 'Testing my_flatten' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => [ 'foo', 'bar' ] );
    my @list = $object->my_flatten;
    is_deeply( \@list, [ 'foo', 'bar' ], q{\@list deep match} );
  };
  is( $e, undef, 'no exception thrown running flatten example' );
};

## flatten_deep

can_ok( 'My::Class', 'my_flatten_deep' );

subtest 'Testing my_flatten_deep' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => [ 'foo', [ 'bar', [ 'baz' ] ] ] );
    is_deeply( [ $object->my_flatten_deep ], [ 'foo', 'bar', 'baz' ], q{[ $object->my_flatten_deep ] deep match} );
  
    my $object2 = My::Class->new( attr => [ 'foo', [ 'bar', [ 'baz' ] ] ] );
    is_deeply( [ $object->my_flatten_deep(1) ], [ 'foo', 'bar', [ 'baz' ] ], q{[ $object->my_flatten_deep(1) ] deep match} );
  };
  is( $e, undef, 'no exception thrown running flatten_deep example' );
};

## for_each

can_ok( 'My::Class', 'my_for_each' );

subtest 'Testing my_for_each' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => [ 'foo', 'bar', 'baz' ] );
    $object->my_for_each( sub { note "Item $_[1] is $_[0]." } );
  };
  is( $e, undef, 'no exception thrown running for_each example' );
};

## for_each_pair

can_ok( 'My::Class', 'my_for_each_pair' );

## get

can_ok( 'My::Class', 'my_get' );

subtest 'Testing my_get' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => [ 'foo', 'bar', 'baz' ] );
    is( $object->my_get(  0 ), 'foo', q{$object->my_get(  0 ) is 'foo'} );
    is( $object->my_get(  1 ), 'bar', q{$object->my_get(  1 ) is 'bar'} );
    is( $object->my_get( -1 ), 'baz', q{$object->my_get( -1 ) is 'baz'} );
  };
  is( $e, undef, 'no exception thrown running get example' );
};

## grep

can_ok( 'My::Class', 'my_grep' );

## head

can_ok( 'My::Class', 'my_head' );

## indexed

can_ok( 'My::Class', 'my_indexed' );

## insert

can_ok( 'My::Class', 'my_insert' );

subtest 'Testing my_insert' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => [ 'foo', 'bar', 'baz' ] );
    $object->my_insert( 1, 'quux' );
    is_deeply( $object->attr, [ 'foo', 'quux', 'bar', 'baz' ], q{$object->attr deep match} );
  };
  is( $e, undef, 'no exception thrown running insert example' );
};

## is_empty

can_ok( 'My::Class', 'my_is_empty' );

subtest 'Testing my_is_empty' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => [ 'foo', 'bar' ] );
    ok( !($object->my_is_empty), q{$object->my_is_empty is false} );
    $object->_set_attr( [] );
    ok( $object->my_is_empty, q{$object->my_is_empty is true} );
  };
  is( $e, undef, 'no exception thrown running is_empty example' );
};

## join

can_ok( 'My::Class', 'my_join' );

subtest 'Testing my_join' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => [ 'foo', 'bar', 'baz' ] );
    is( $object->my_join, 'foo,bar,baz', q{$object->my_join is 'foo,bar,baz'} );
    is( $object->my_join( '|' ), 'foo|bar|baz', q{$object->my_join( '|' ) is 'foo|bar|baz'} );
  };
  is( $e, undef, 'no exception thrown running join example' );
};

## map

can_ok( 'My::Class', 'my_map' );

## max

can_ok( 'My::Class', 'my_max' );

## maxstr

can_ok( 'My::Class', 'my_maxstr' );

## min

can_ok( 'My::Class', 'my_min' );

## minstr

can_ok( 'My::Class', 'my_minstr' );

## natatime

can_ok( 'My::Class', 'my_natatime' );

subtest 'Testing my_natatime' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => [ 'foo', 'bar', 'baz' ] );
    my $iter   = $object->my_natatime( 2 );
    is_deeply( [ $iter->() ], [ 'foo', 'bar' ], q{[ $iter->() ] deep match} );
    is_deeply( [ $iter->() ], [ 'baz' ], q{[ $iter->() ] deep match} );
  };
  is( $e, undef, 'no exception thrown running natatime example' );
};

## not_all_true

can_ok( 'My::Class', 'my_not_all_true' );

## pairfirst

can_ok( 'My::Class', 'my_pairfirst' );

## pairgrep

can_ok( 'My::Class', 'my_pairgrep' );

## pairkeys

can_ok( 'My::Class', 'my_pairkeys' );

## pairmap

can_ok( 'My::Class', 'my_pairmap' );

## pairs

can_ok( 'My::Class', 'my_pairs' );

## pairvalues

can_ok( 'My::Class', 'my_pairvalues' );

## pick_random

can_ok( 'My::Class', 'my_pick_random' );

## pop

can_ok( 'My::Class', 'my_pop' );

subtest 'Testing my_pop' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => [ 'foo', 'bar', 'baz' ] );
    is( $object->my_pop, 'baz', q{$object->my_pop is 'baz'} );
    is( $object->my_pop, 'bar', q{$object->my_pop is 'bar'} );
    is_deeply( $object->attr, [ 'foo' ], q{$object->attr deep match} );
  };
  is( $e, undef, 'no exception thrown running pop example' );
};

## print

can_ok( 'My::Class', 'my_print' );

## product

can_ok( 'My::Class', 'my_product' );

## push

can_ok( 'My::Class', 'my_push' );

subtest 'Testing my_push' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => [ 'foo' ] );
    $object->my_push( 'bar', 'baz' );
    is_deeply( $object->attr, [ 'foo', 'bar', 'baz' ], q{$object->attr deep match} );
  };
  is( $e, undef, 'no exception thrown running push example' );
};

## reduce

can_ok( 'My::Class', 'my_reduce' );

## reductions

can_ok( 'My::Class', 'my_reductions' );

## reset

can_ok( 'My::Class', 'my_reset' );

subtest 'Testing my_reset' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => [ 'foo', 'bar', 'baz' ] );
    $object->my_reset;
    is_deeply( $object->attr, [], q{$object->attr deep match} );
  };
  is( $e, undef, 'no exception thrown running reset example' );
};

## reverse

can_ok( 'My::Class', 'my_reverse' );

## sample

can_ok( 'My::Class', 'my_sample' );

## set

can_ok( 'My::Class', 'my_set' );

subtest 'Testing my_set' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => [ 'foo', 'bar', 'baz' ] );
    $object->my_set( 1, 'quux' );
    is_deeply( $object->attr, [ 'foo', 'quux', 'baz' ], q{$object->attr deep match} );
  };
  is( $e, undef, 'no exception thrown running set example' );
};

## shallow_clone

can_ok( 'My::Class', 'my_shallow_clone' );

## shift

can_ok( 'My::Class', 'my_shift' );

subtest 'Testing my_shift' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => [ 'foo', 'bar', 'baz' ] );
    is( $object->my_shift, 'foo', q{$object->my_shift is 'foo'} );
    is( $object->my_shift, 'bar', q{$object->my_shift is 'bar'} );
    is_deeply( $object->attr, [ 'baz' ], q{$object->attr deep match} );
  };
  is( $e, undef, 'no exception thrown running shift example' );
};

## shuffle

can_ok( 'My::Class', 'my_shuffle' );

## shuffle_in_place

can_ok( 'My::Class', 'my_shuffle_in_place' );

## sort

can_ok( 'My::Class', 'my_sort' );

## sort_in_place

can_ok( 'My::Class', 'my_sort_in_place' );

## splice

can_ok( 'My::Class', 'my_splice' );

## sum

can_ok( 'My::Class', 'my_sum' );

## tail

can_ok( 'My::Class', 'my_tail' );

## uniq

can_ok( 'My::Class', 'my_uniq' );

## uniq_in_place

can_ok( 'My::Class', 'my_uniq_in_place' );

## uniqnum

can_ok( 'My::Class', 'my_uniqnum' );

## uniqnum_in_place

can_ok( 'My::Class', 'my_uniqnum_in_place' );

## uniqstr

can_ok( 'My::Class', 'my_uniqstr' );

## uniqstr_in_place

can_ok( 'My::Class', 'my_uniqstr_in_place' );

## unshift

can_ok( 'My::Class', 'my_unshift' );

subtest 'Testing my_unshift' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => [ 'foo' ] );
    $object->my_unshift( 'bar', 'baz' );
    is_deeply( $object->attr, [ 'bar', 'baz', 'foo' ], q{$object->attr deep match} );
  };
  is( $e, undef, 'no exception thrown running unshift example' );
};

done_testing;
