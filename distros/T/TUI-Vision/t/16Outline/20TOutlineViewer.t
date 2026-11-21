use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Drivers::Const', qw( :evXXXX );
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Outline::OutlineViewer';
  use_ok 'TUI::Outline';
  require_ok 'TUI::toolkit';
}

# Concrete subclass backed by TNode trees
{
  package MyOutlineViewer;
  use TUI::toolkit;
  use TUI::Outline;

  extends 'TUI::Outline::OutlineViewer';

  has root => ( is => 'rw' );

  sub adjust {
    my ( $self, $node, $expand ) = @_;
    $node->{expanded} = $expand ? 1 : 0;
    return;
  }

  sub getChild {
    my ( $self, $node, $i ) = @_;
    my $child = $node->{childList};
    $child = $child->{next} for 1 .. $i;
    return $child;
  }

  sub getNumChildren {
    my ( $self, $node ) = @_;
    my $n = 0;
    for ( my $c = $node->{childList}; $c; $c = $c->{next} ) { $n++ }
    return $n;
  }

  sub getRoot    { $_[0]->root }
  sub getText    { $_[1]->{text} }
  sub hasChildren { $_[1]->{childList} ? 1 : 0 }
  sub isExpanded { $_[1]->{expanded} ? 1 : 0 }
}

# Tree:  R -> [A -> [A1], B]
my $a1 = TNode->new( text => 'A1' );
my $b  = TNode->new( text => 'B' );
my $a  = TNode->new( text => 'A', childList => $a1, next => undef );
$a->{next} = $b;
my $r  = TNode->new( text => 'R', childList => $a );

sub new_viewer {
  my $v = MyOutlineViewer->new(
    bounds     => TRect->new( ax => 0, ay => 0, bx => 20, by => 10 ),
    hScrollBar => undef,
    vScrollBar => undef,
  );
  $v->root( $r );
  $v->update();
  return $v;
}

subtest 'getGraph draws level lines and markers' => sub {
  my $v = new_viewer();
  is( $v->getGraph( 0, 0, ovLast | ovExpanded ), "\xC0\xC4\xC4",
    'last expanded node at level 0' );
  is( $v->getGraph( 0, 0, ovChildren ), "\xC3\xC4+",
    'collapsed node with children' );
  is( $v->getGraph( 1, 1, ovExpanded ), "\xB3  \xC3\xC4\xC4",
    'level 1 with continuing parent line' );
  is( $v->getGraph( 1, 0, ovLast | ovExpanded ), "   \xC0\xC4\xC4",
    'level 1 without parent line' );
};

subtest 'forEach visits nodes in display order' => sub {
  my $v = new_viewer();
  my @seen;
  $v->forEach( sub {
    my ( $outLine, $node, $level, $position ) = @_;
    push @seen, [ $outLine->getText( $node ), $position, $level ];
    return 0;
  } );
  is_deeply( \@seen,
    [ [ 'R', 0, 0 ], [ 'A', 1, 1 ], [ 'A1', 2, 2 ], [ 'B', 3, 1 ] ],
    'expanded tree is visited depth first' );
};

subtest 'firstThat stops at matching node' => sub {
  my $v = new_viewer();
  my $found = $v->firstThat( sub {
    my ( $outLine, $node, undef, $position ) = @_;
    return $position == 2;
  } );
  is( $found, $a1, 'returns the node at the requested position' );
};

subtest 'update sets the limit to the visible rows' => sub {
  my $v = new_viewer();
  is( $v->limit->{y}, 4, 'all four nodes are visible' );

  $v->adjust( $a, 0 );
  $v->update();
  is( $v->limit->{y}, 3, 'collapsed children are hidden' );
};

subtest 'minus key collapses the focused node' => sub {
  my $v = new_viewer();
  $v->focused( 1 );
  my $event = TEvent->new(
    what    => evKeyDown,
    keyDown => { charScan => CharScanType->new( charCode => ord '-' ) },
  );
  $v->handleEvent( $event );
  ok( !$v->isExpanded( $a ), 'node A is collapsed' );
  is( $v->limit->{y}, 3, 'limit is updated' );
};

done_testing();
