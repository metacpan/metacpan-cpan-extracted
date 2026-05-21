use strict;
use warnings;

use Test::More;
use Test::Exception;

use Devel::Refcount qw( refcount );
use Scalar::Util qw( isweak );

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Views::View';
  use_ok 'TUI::Views::Group';
}

my (
  $bounds,
  @view,
  $group,
);

subtest 'Test object creations' => sub {
  $bounds = TRect->new();
  isa_ok( $bounds, TRect, 'Object is of class TRect' );
  @view = map { TView->new( bounds => $bounds ) } 0..2;
  isa_ok( $_, TView, sprintf 'Object %x is of class TView', $_ ) for @view;
  $group = TGroup->new( bounds => $bounds );
  isa_ok( $group, TGroup, sprintf 'Object %x is of class TGroup', $group );
};

subtest sprintf( 'Test insert %x', $view[0] ) => sub {
  is( refcount( $view[0] ), 1, sprintf 'Object %x refcount is 1', $view[0] );
  lives_ok { $group->insert( $view[0] ) } sprintf 'insert Object %x', $view[0];
  is( $group->{last}, $view[0], sprintf 'last is Object %x',  $view[0] );
  is( $view[0]->owner(), $group, sprintf 'owner is Object %x', $group );
  ok( isweak( $view[0]->{owner} ), sprintf 'owner %x is weak', $group );
  is( $view[0]->{next}, $view[0], sprintf '%x->next is Object %x', @view[0,0] );
  ok( isweak( $view[0]->{next} ), sprintf '%x->next = %x is weak', @view[0,0] );
  is( refcount( $view[0] ), 2, sprintf 'Object %x refcount is 2', $view[0] );
}; #/ sub

subtest sprintf( 'Test insert %x', $view[1] ) => sub {
  is( refcount( $view[1] ), 1, sprintf 'Object %x refcount is 1', $view[1] );
  lives_ok { $group->insert( $view[1] ) } sprintf 'insert Object %x', $view[1];
  is( $group->{last}, $view[0], sprintf 'last is Object %x', $view[0] );
  is( $view[0]->{next}, $view[1], sprintf '%x->next is Object %x', @view[0,1] );
  ok( !isweak( $view[0]->{next} ), sprintf '%x is strong', $view[1] );
  is( $view[1]->{next}, $view[0], sprintf '%x->next is Object %x', @view[1,0] );
  ok( isweak( $view[1]->{next} ), sprintf '%x is weak', $view[0] );
  is( refcount( $view[0] ), 2, sprintf 'Object %x refcount is 2', $view[0] );
  is( refcount( $view[1] ), 2, sprintf 'Object %x refcount is 2', $view[1] );
};

subtest sprintf( 'Test insert %x', $view[2] ) => sub {
  is( refcount( $view[2] ), 1, sprintf 'Object %x refcount is 1', $view[2] );
  lives_ok { $group->insert( $view[2] ) } sprintf 'insert Object %x', $view[2];
  is( $group->{last}, $view[0], sprintf 'last is Object %x', $view[0] );
  is( $view[0]->{next}, $view[2], sprintf '%x->next is Object %x', @view[0,2] );
  ok( !isweak( $view[0]->{next} ), sprintf '%x is strong', $view[2] );
  is( $view[2]->{next}, $view[1], sprintf '%x->next is Object %x', @view[2,1] );
  ok( !isweak( $view[2]->{next} ), sprintf '%x is strong', $view[1] );
  is( $view[1]->{next}, $view[0], sprintf '%x->next is Object %x', @view[1,0] );
  ok( isweak( $view[1]->{next} ), sprintf '%x is weak', $view[0] );
  is( refcount( $view[1] ), 2, sprintf 'Object %x refcount is 2', $view[1] );
  is( refcount( $view[2] ), 2, sprintf 'Object %x refcount is 2', $view[2] );
};

subtest 'Test current field' => sub {
  lives_ok { $group->current( $view[2] ) }
    sprintf 'current Object %x', $view[2];
  ok( 
    isweak( $group->{current} ),
    sprintf 'current %x is weak', $group->{current}
  );
};

subtest sprintf( 'Test remove %x', $view[1] ) => sub {
  is( refcount( $view[1] ), 2, sprintf 'Object %x refcount is 2', $view[1] );
  lives_ok { $group->remove( $view[1] ) } sprintf 'remove Object %x', $view[1];
  is( $group->{last}, $view[0], sprintf 'last is Object %x', $view[0] );
  is( $view[0]->{next}, $view[2], sprintf '%x->next is Object %x', @view[0,2] );
  ok( !isweak( $view[0]->{next} ), sprintf '%x is strong', $view[2] );
  is( $view[2]->{next}, $view[0], sprintf '%x->next is Object %x', @view[2,0] );
  ok( isweak( $view[2]->{next} ), sprintf '%x is weak', $view[0] );
  ok( !$view[1]->{owner}, sprintf '%x->owner is undef', $view[1] );
  ok( !$view[1]->{next}, sprintf '%x->next is undef', $view[1] );
  is( refcount( $view[1] ), 1, sprintf 'Object %x refcount is 1', $view[1] );
};

subtest sprintf( 'Test insert new' ) => sub {
  lives_ok { $group->insert( TView->new( bounds => $bounds ) ) }
    'insert new view';
  ok(
    $group->{last},
    sprintf '%x->last is Object %x', $group, $group->{last},
  );
  cmp_ok(
    scalar( grep { $_ == $group->{last}{next} } @view), '==', 0,
    sprintf 'Object %x != @view', $group->{last}{next}
  );
  cmp_ok(
    refcount( $group->{last}{next} ), '==', 1,
    sprintf 'Object %x refcount is 1', $group->{last}{next} 
  );
};

subtest sprintf( 'Test remove (%x, %x)', @view[2,0] ) => sub {
  lives_ok { $group->remove( $view[2] ) } sprintf 'remove Object %x', $view[2];
  lives_ok { $group->remove( $view[0] ) } sprintf 'remove Object %x', $view[0];
  cmp_ok( 
    $group->{last}, '==', $group->{last}{next}, 
    sprintf '%x is %x->next', $group->{last}, $group->{last}{next}
  );
  ok(
    isweak( $group->{last}{next} ), 
    sprintf '%x is weak', $group->{last}{next}
  );
};

subtest 'Test cleanup' => sub {
  lives_ok { undef $group } 'Object of class TGroup deleted';
  is( refcount( $view[0] ), 1, sprintf 'Object %x refcount is 1', $view[0] );
  is( refcount( $view[1] ), 1, sprintf 'Object %x refcount is 1', $view[1] );
  is( refcount( $view[2] ), 1, sprintf 'Object %x refcount is 1', $view[2] );
};

done_testing();
