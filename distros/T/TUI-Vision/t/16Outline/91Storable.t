use strict;
use warnings;

use Test::More;
use Storable qw( freeze thaw );

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Outline::Node';
  use_ok 'TUI::Outline::OutlineViewer';
  use_ok 'TUI::Outline::Outline';
}

subtest 'TOutlineViewer Storable roundtrip' => sub {
  my $viewer = TOutlineViewer->new(
    bounds     => TRect->new( ax => 3, ay => 4, bx => 23, by => 14 ),
    hScrollBar => undef,
    vScrollBar => undef,
  );
  $viewer->{foc} = 5;

  my $restored = thaw( freeze( $viewer ) );
  isa_ok( $restored, TOutlineViewer );
  is( $restored->{foc}, 5, 'preserves focused position' );
  is( $viewer->{foc}, 5, 'does not change the original' );
}; #/ 'TOutlineViewer Storable roundtrip' => sub

subtest 'TOutline Storable roundtrip' => sub {
  my $child   = new_TNode( 'Child', undef, undef, !!0 );
  my $root    = new_TNode( 'Root', $child, new_TNode( 'Sibling' ), !!1 );
  my $outline = TOutline->new(
    bounds     => TRect->new( ax => 0, ay => 0, bx => 20, by => 10 ),
    hScrollBar => undef,
    vScrollBar => undef,
    root       => $root,
  );
  $outline->{foc} = 2;

  my $restored = thaw( freeze( $outline ) );
  isa_ok( $restored, TOutline );
  is( $restored->{foc}, 2, 'preserves focused position' );

  my $r = $restored->root;
  is( $r->text, 'Root', 'restores root text' );
  ok( $r->expanded, 'restores expanded root' );
  is( $r->childList->text, 'Child', 'restores child text' );
  ok( !$r->childList->expanded, 'restores retracted child' );
  is( $r->next->text, 'Sibling', 'restores sibling' );
  is( $restored->getNumChildren( $r ), 1, 'restores child count' );
}; #/ 'TOutline Storable roundtrip' => sub

subtest 'TOutline Storable roundtrip without root' => sub {
  my $outline = TOutline->new(
    bounds     => TRect->new(),
    hScrollBar => undef,
    vScrollBar => undef,
    root       => undef,
  );

  my $restored = thaw( freeze( $outline ) );
  isa_ok( $restored, TOutline );
  ok( !defined $restored->root, 'keeps empty outline' );
}; #/ 'TOutline Storable roundtrip without root' => sub

done_testing();
