package TUI::Outline::OutlineViewer;
# ABSTRACT: abstract base class for scrollable outline viewers

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TOutlineViewer
  new_TOutlineViewer
);

use Storable;

use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  :is
  :types
);

use TUI::Drivers::Const qw(
  :evXXXX
  :kbXXXX
  meDoubleClick
);
use TUI::Drivers::Util qw( ctrlToArrow );
use TUI::Outline::Const qw(
  :ovXXXX
  :cpXXXX
);
use TUI::Views::Const qw(
  gfGrowHiX
  gfGrowHiY
  :sfXXXX
);
use TUI::Objects::Rect;
use TUI::Views::DrawBuffer;
use TUI::Views::Palette;
use TUI::Views::Scroller;

sub TOutlineViewer() { __PACKAGE__ }
sub name() { 'TOutlineViewer' }
sub new_TOutlineViewer { __PACKAGE__->from(@_) }

extends TScroller;

# public attributes
has foc => ( is => 'rw', default => 0 );

# private methods
my (
  $adjustFocus,
  $iterate,
  $traverseTree
);

# declare local variables
my $dBuf        = TDrawBuffer->new();
my $auxPos      = 0;
my $focLevel    = 0;
my $focLines    = 0;
my $focFlags    = 0;
my $updateCount = 0;
my $updateMaxX  = 0;

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      bounds     => Object,
      hScrollBar => Maybe[Object], { alias => 'aHScrollBar' },
      vScrollBar => Maybe[Object], { alias => 'aVScrollBar' },
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return { %$args };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{growMode} |= gfGrowHiX | gfGrowHiY;
  return;
}

sub from {    # $viewer ($bounds, $aHScrollBar|undef, $aVScrollBar|undef)
  state $sig = signature(
    method => 1,
    pos    => [Object, Maybe[Object], Maybe[Object]],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], hScrollBar => $args[1],
    vScrollBar => $args[2] );
}

sub adjust {    # void ($node, $expand)
  state $sig = signature(
    method => Object,
    pos    => [Object, Bool],
  );
  $sig->( @_ );
  ...
}

# Called to draw the outline
my $drawTree = sub {    # $bool ($beingDrawn, $cur, $level, $position, $lines, $flags)
  my ( $beingDrawn, $cur, $level, $position, $lines, $flags ) = @_;
  assert ( @_ == 6 );
  assert ( is_Object $beingDrawn );
  assert ( is_Object $cur );
  assert ( is_Int $level );
  assert ( is_Int $position );
  assert ( is_Int $lines );
  assert ( is_PositiveOrZeroInt $flags );

  return false if $position < $beingDrawn->{delta}{y};
  return true
    if $position >= $beingDrawn->{delta}{y} + $beingDrawn->{size}{y};

  my $color;
  if ( ( $position == $beingDrawn->{foc} )
    && ( $beingDrawn->{state} & sfFocused )
  ) {
    $color = $beingDrawn->getColor( 0x0202 );
  }
  elsif ( $beingDrawn->isSelected( $position ) ) {
    $color = $beingDrawn->getColor( 0x0303 );
  }
  else {
    $color = $beingDrawn->getColor( 0x0401 );
  }
  $dBuf->moveChar( 0, ' ', $color, $beingDrawn->{size}{x} );

  my $s = $beingDrawn->getGraph( $level, $lines, $flags );
  if ( ( $flags & ovExpanded ) == 0 ) {
    $s .= '~' . $beingDrawn->getText( $cur ) . '~';
  }
  else {
    $s .= $beingDrawn->getText( $cur );
  }
  my $offset = $beingDrawn->{delta}{x};
  $dBuf->moveCStr(
    0,
    $offset <= length( $s ) ? substr( $s, $offset ) : '',
    $color,
  );
  $beingDrawn->writeLine( 0, $position - $beingDrawn->{delta}{y},
    $beingDrawn->{size}{x}, 1, $dBuf );
  $auxPos = $position;

  return false;
};

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );

  $self->firstThat( $drawTree );
  my $nrmColor = $self->getColor( 0x0401 );
  $dBuf->moveChar( 0, ' ', $nrmColor, $self->{size}{x} );
  $self->writeLine(
    0,
    $auxPos + 1,
    $self->{size}{x},
    $self->{size}{y} - ( $auxPos - $self->{delta}{y} ),
    $dBuf,
  );
  return;
}

# Called whenever Node is receives focus
sub focused {    # void ($i)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $i ) = $sig->( @_ );
  $self->{foc} = $i;
  return;
}

sub getChild {    # $node ($node, $i)
  state $sig = signature(
    method => Object,
    pos    => [Object, Int],
  );
  $sig->( @_ );
  ...
}

#
# Called to retrieve the characters to display prior to the
# text returned by GetText. Can be overridden to return
# change the appearance of the outline. My default calls
# createGraph with the default.
#
sub getGraph {    # $graph ($level, $lines, $flags)
  state $sig = signature(
    method => Object,
    pos    => [Int, Int, PositiveOrZeroInt],
  );
  my ( $self, $level, $lines, $flags ) = $sig->( @_ );
  my $levelWidth = 3;
  my $endWidth   = $levelWidth;
  my $graphChars = "\x20\xB3\xC3\xC0\xC4\xC4+\xC4";
  return $self->createGraph(
    $level, $lines, $flags, $levelWidth, $endWidth, $graphChars );
}

sub getNumChildren {    # $count ($node)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  $sig->( @_ );
  ...
}

my $isNode = sub {    # $bool ($outLine, $node, $level, $position, $lines, $flags)
  my ( $outLine, $node, $level, $position, $lines, $flags ) = @_;
  assert ( @_ == 6 );
  assert ( is_Object $outLine );
  assert ( is_Object $node );
  assert ( is_Int $level );
  assert ( is_Int $position );
  assert ( is_Int $lines );
  assert ( is_PositiveOrZeroInt $flags );
  return $auxPos == $position;
};

# Returns a pointer to the node that is to be shown on line i
sub getNode {    # $node|undef ($i)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $i ) = $sig->( @_ );
  $auxPos = $i;
  return $self->firstThat( $isNode );
}

#
# Returns the outline palette
#
# Palette layout
#   1 = Normal color
#   2 = Focus color
#   3 = Select color
#   4 = Not expanded color
#
sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  state $palette = TPalette->new(
    data => cpOutlineViewer,
    size => length( cpOutlineViewer ),
  );
  return $palette->clone();
}

sub getRoot {    # $node ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  $sig->( @_ );
  ...
}

sub getText {    # $text ($node)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  $sig->( @_ );
  ...
}

my $isFocused = sub {    # $bool ($focusCheck, $cur, $level, $position, $lines, $flags)
  my ( $focusCheck, $cur, $level, $position, $lines, $flags ) = @_;
  assert ( @_ == 6 );
  assert ( is_Object $focusCheck );
  assert ( is_Object $cur );
  assert ( is_Int $level );
  assert ( is_Int $position );
  assert ( is_Int $lines );
  assert ( is_PositiveOrZeroInt $flags );
  return false
    if $position != $focusCheck->{foc};
  $focLevel = $level;
  $focLines = $lines;
  $focFlags = $flags;
  return true;
};

# Called to handle an event
sub handleEvent {    # void ($event)
  no warnings 'uninitialized';
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );

  my $mouseAutoToSkip = 3;
  my ( $mouse, $newFocus, $count, $dragged, $cur, $graph );

  $self->SUPER::handleEvent( $event );

  SWITCH: for ( $event->{what} ) {
    evMouseDown == $_ and do {
      $count    = 0;
      $dragged  = 0;
      # C++ leaves newFocus unset for a click outside the view; keep the
      # current focus instead of letting undef jump to line 0.
      $newFocus = $self->{foc};
      do {
        $dragged++ if $dragged < 2;
        $mouse = $self->makeLocal( $event->{mouse}{where} );
        if ( $self->mouseInView( $event->{mouse}{where} ) ) {
          $newFocus = $self->{delta}{y} + $mouse->{y};
        }
        else {
          $count++ if $event->{what} == evMouseAuto;
          if ( $count == $mouseAutoToSkip ) {
            $count = 0;
            $newFocus-- if $mouse->{y} < 0;
            $newFocus++ if $mouse->{y} >= $self->{size}{y};
          }
        }
        if ( $self->{foc} != $newFocus ) {
          $self->$adjustFocus( $newFocus );
          $self->drawView();
        }
      } while ( !( $event->{mouse}{eventFlags} & meDoubleClick )
        && $self->mouseEvent( $event, evMouseMove | evMouseAuto ) );

      if ( $event->{mouse}{eventFlags} & meDoubleClick ) {
        $self->selected( $self->{foc} );
      }
      elsif ( $dragged < 2 ) {
        $cur = $self->firstThat( $isFocused );
        if ( defined $cur ) {
          # C++ calls adjust() even when no node is focused (empty outline),
          # which dereferences NULL; skip expand/collapse in that case.
          $graph = $self->getGraph( $focLevel, $focLines, $focFlags );
          if ( $mouse->{x} < length( $graph ) ) {
            $self->adjust( $cur, !$self->isExpanded( $cur ) );
            $self->update();
            $self->drawView();
          }
        }
      }
      last;
    };

    evKeyboard == $_ and do {
      $newFocus = $self->{foc};
      SWITCH: for ( ctrlToArrow( $event->{keyDown}{keyCode} ) ) {
        kbUp == $_ ||
        kbLeft == $_ and do {
          $newFocus--;
          last;
        };
        kbDown == $_ ||
        kbRight == $_ and do {
          $newFocus++;
          last;
        };
        kbPgDn == $_ and do {
          $newFocus += $self->{size}{y} - 1;
          last;
        };
        kbPgUp == $_ and do {
          $newFocus -= $self->{size}{y} - 1;
          last;
        };
        kbHome == $_ and do {
          $newFocus = $self->{delta}{y};
          last;
        };
        kbEnd == $_ and do {
          $newFocus = $self->{delta}{y} + $self->{size}{y} - 1;
          last;
        };
        kbCtrlPgUp == $_ and do {
          $newFocus = 0;
          last;
        };
        kbCtrlPgDn == $_ and do {
          $newFocus = $self->{limit}{y} - 1;
          last;
        };
        ( kbCtrlEnter == $_ || kbEnter == $_ ) and do {
          $self->selected( $newFocus );
          last;
        };
        DEFAULT: {
          my $code = chr $event->{keyDown}{charScan}{charCode};
          SWITCH: for ( $code ) {
            '-' eq $_ ||
            '+' eq $_ and do {
              my $node = $self->getNode( $newFocus );
              $self->adjust( $node, '+' eq $_ ) if $node;
              last;
            };
            '*' eq $_ and do {
              my $node = $self->getNode( $newFocus );
              $self->expandAll( $node ) if $node;
              last;
            };
            DEFAULT: {
              return;
            }
          } #/ SWITCH: for ( $code )
          $self->update();
        }
      } #/ SWITCH: for ( ctrlToArrow( $event...))
      $self->clearEvent( $event );
      $self->$adjustFocus( $newFocus );
      $self->drawView();
      last;
    };
  } #/ SWITCH: for ( $event->{what} )
  return;
}

sub hasChildren {    # $bool ($node)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  $sig->( @_ );
  ...
}

sub isExpanded {    # $bool ($node)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  $sig->( @_ );
  ...
}

#
# Returns if Node is selected. By default, returns true if Node is
# Focused (i.e. single selection). Can be overridden to handle
# multiple selections.
#
sub isSelected {    # $bool ($i)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $i ) = $sig->( @_ );
  return $self->{foc} == $i;
}

# Called whenever Node is selected by the user either via keyboard
# control or by the mouse.
sub selected {    # void ($i)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $i ) = $sig->( @_ );
  return;
}

# Redraws the outline if the outliner sfFocus state changes
sub setState {    # void ($aState, $enable)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, Bool],
  );
  my ( $self, $aState, $enable ) = $sig->( @_ );
  $self->SUPER::setState( $aState, $enable );
  $self->drawView()
    if $aState & sfFocused;
  return;
}

my $countNode = sub {    # $bool ($beingCounted, $p, $level, $position, $lines, $flags)
  my ( $beingCounted, $p, $level, $position, $lines, $flags ) = @_;
  assert ( @_ == 6 );
  assert ( is_Object $beingCounted );
  assert ( is_Object $p );
  assert ( is_Int $level );
  assert ( is_Int $position );
  assert ( is_Int $lines );
  assert ( is_PositiveOrZeroInt $flags );
  $updateCount++;
  my $graph = $beingCounted->getGraph( $level, $lines, $flags );
  my $len   = length( $beingCounted->getText( $p ) ) + length( $graph );
  $updateMaxX = $len
    if $updateMaxX < $len;
  return false;
};

#
# Updates the limits of the outline viewer.  Should be called whenever
# the data of the outline viewer changes.  This includes during
# the initialization of base classes.  TOutlineViewer assumes that the
# outline is empty.  If the outline becomes non-empty during the
# initialization, Update must be called. Also, if during the operation
# of the TOutlineViewer the data being displayed changes, Update and
# DrawView must be called.
#
sub update {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $updateCount = 0;
  $updateMaxX  = 0;
  $self->firstThat( $countNode );
  $self->setLimit( $updateMaxX, $updateCount );
  $self->$adjustFocus( $self->{foc} );
  return;
}

# ExpandAll expands the current node and all child nodes
sub expandAll {    # void ($node)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $node ) = $sig->( @_ );
  if ( $self->hasChildren( $node ) ) {
    $self->adjust( $node, true );
    my $n = $self->getNumChildren( $node ) - 1;
    for my $i ( 0 .. $n ) {
      $self->expandAll( $self->getChild( $node, $i ) );
    }
  }
  return;
}

#
# FirstThat iterates over the nodes of the outline until the given
# local function returns true. The declaration for the local function
# must look like (save for the names, of course):
#
#   sub myIter ($cur, $level, $position, $lines, $flags) { ... }
#
# The parameters are as follows:
#
#   $cur:      A object to the node being checked.
#   $level:    The level of the node (how many node above it it has)
#              $level is 0 based. This can be used to a call to
#              either getGraph() or createGraph().
#   $position: The display order position of the node in the list.
#              This can be used in a call to focused() or selected().
#              If in range, $position - $delta->{y} is the location the node
#              is displayed on the view.
#   $lines:    Bits indicating the active levels. This can be used in a
#              call to getGraph() or createGraph(). It dictates which
#              horizontal lines need to be drawn.
#   $flags:    Various flags for drawing (see :ovXXXX flags). Can be used
#              in a call to getGraph() or createGraph().
#
sub firstThat {    # $node|undef (\&test)
  state $sig = signature(
    method => Object,
    pos    => [CodeRef],
  );
  my ( $self, $test ) = $sig->( @_ );
  return $self->$iterate( $test, true );
}

sub forEach {    # $node|undef (\&action)
  state $sig = signature(
    method => Object,
    pos    => [CodeRef],
  );
  my ( $self, $action ) = $sig->( @_ );
  return $self->$iterate( $action, false );
}

#
# Draws a graph string suitable for returning from getGraph. Level
# indicates the outline level.  Lines is the set of bits describing
# the which levels have a "continuation" mark (usually a vertical
# lines). If bit 3 is set, level 3 is continued beyond this level.
# Flags gives extra information about how to draw the end of the
# graph (see the ovXXX constants).  LevWidth is how many characters
# to indent for each level.  endWidth is the length the end characters.
#
# The graphics is divided into two parts: the level marks, and the end
# or node graphic.  The level marks consist of the Level Mark character
# separated by Level Filler. What marks are present is determined by
# Lines. The end graphic is constructed by placing on of the End First
# characters followed by endWidth-4 End Filler characters, followed by the
# End Child character, followed by the Retract/Expand character.  If
# endWidth equals 2, End First and Retract/Expand are used.  If endWidth
# equals 1, only the Retract/Expand character is used.  Which characters
# are selected is determined by Flags.
#
# The layout for the characters in the Chars is:
#
#  1: Level Filler
#    Typically a space. Used between level markers.
#  2: Level Mark
#    Typically a vertical bar. Used to mark the levels currently active.
#  3: End First (not last child)
#    Typically a sideways T. Used as the first character of the end part
#    of a node graphic if the node is not the last child of the parent.
#  4: End First (last child)
#    Typically a L shape. Used as the first character of the end part
#    of a node graphic if the node is the last child of the parent.
#  5: End Filler
#    Typically a horizontal line. Used as filler for the end part of a
#    node graphic.
#  6: End Child position
#    Typically not used. If endWidth > LevWidth this character will
#    be placed on top of the markers for next level. If used it is
#    typically a T.
#  7: Retracted character
#    Typically a '+'. Displayed as the last character of the end
#    node if the level has children and they are not expanded.
#  8: Expanded character
#    Typically as straight line. Displayed as the last character of
#    the end node if the level has children and they are expanded.
#
sub createGraph {    # $graph ($level, $lines, $flags, $levW, $endW, $chars)
  state $sig = signature(
    method => Object,
    pos    => [Int, Int, PositiveOrZeroInt, Int, Int, Str],
  );
  my ( $self, $level, $lines, $flags, $levWidth, $endWidth, $chars )
    = $sig->( @_ );

  my $fillerOrBar   = 0;
  my $yOrL          = 2;
  my $straightOrTee = 4;
  my $retracted     = 6;

  my $expanded = ( $flags & ovExpanded ) != 0;
  my $children = ( $flags & ovChildren ) != 0;
  my $last     = ( $flags & ovLast ) != 0;

  my $graph = '';
  for ( ; $level > 0 ; $level--, $lines >>= 1 ) {
    $graph .= substr(
      $chars,
      ( $lines & 1 ) ? $fillerOrBar + 1 : $fillerOrBar, 1
    );
    $graph .= substr( $chars, $fillerOrBar, 1 ) x ( $levWidth - 1 );
  }

  if ( --$endWidth > 0 ) {
    $graph .= substr( $chars, $last ? $yOrL + 1 : $yOrL, 1 );
    if ( --$endWidth > 0 ) {
      if ( --$endWidth > 0 ) {
        $graph .= substr( $chars, $straightOrTee, 1 ) x $endWidth;
      }
      $graph .= substr( $chars,
        $children ? $straightOrTee + 1 : $straightOrTee, 1 );
    }
    $graph .= substr( $chars,
      $expanded ? $retracted + 1 : $retracted, 1 );
  }
  return $graph;
}

# Called internally to ensure the focus is within range and displayed
$adjustFocus = sub {    # void ($self, $newFocus)
  my ( $self, $newFocus ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Int $newFocus );
  if ( $newFocus < 0 ) {
    $newFocus = 0;
  }
  elsif ( $newFocus >= $self->{limit}{y} ) {
    $newFocus = $self->{limit}{y} - 1;
  }
  if ( $self->{foc} != $newFocus ) {
    $self->focused( $newFocus );
  }
  if ( $newFocus < $self->{delta}{y} ) {
    $self->scrollTo( $self->{delta}{x}, $newFocus );
  }
  elsif ( ( $newFocus - $self->{size}{y} ) >= $self->{delta}{y} ) {
    $self->scrollTo( $self->{delta}{x}, $newFocus - $self->{size}{y} + 1 );
  }
  return;
};

# Internal function used by both FirstThat and ForEach to do the
# actual iteration over the data. See FirstThat for more details
$traverseTree = sub {    # $node|undef ($outLine, \&action, \$position, $checkResult, $cur, $level, $lines, $lastChild)
  my ( $outLine, $action, $position, $checkResult, $cur, $level, $lines,
    $lastChild ) = @_;
  assert ( @_ == 8 );
  assert ( is_Object $outLine );
  assert ( is_CodeRef $action );
  assert ( is_ScalarRef $position );
  assert ( is_Bool $checkResult );
  assert ( is_Undef( $cur ) || is_Object( $cur ) );
  assert ( is_Int $level );
  assert ( is_Int $lines );
  assert ( is_Bool $lastChild );
  return unless $cur;

  my $children = $outLine->hasChildren( $cur );

  my $flags = 0;
  $flags |= ovLast if $lastChild;
  $flags |= ovChildren if $children && $outLine->isExpanded( $cur );
  $flags |= ovExpanded if !$children || $outLine->isExpanded( $cur );

  $$position++;

  my $result = $action->(
    $outLine, $cur, $level, $$position, $lines, $flags );
  return $cur if $checkResult && $result;

  if ( $children && $outLine->isExpanded( $cur ) ) {
    my $childCount = $outLine->getNumChildren( $cur );

    $lines |= 1 << $level unless $lastChild;

    for my $j ( 0 .. $childCount - 1 ) {
      my $ret = $traverseTree->(
        $outLine,
        $action,
        $position,
        $checkResult,
        $outLine->getChild( $cur, $j ),
        $level + 1,
        $lines,
        $j == $childCount - 1,
      );
      return $ret if $ret;
    }
  }
  return;
};

$iterate = sub {    # $node|undef ($outLine, \&action, $checkResult)
  my ( $outLine, $action, $checkResult ) = @_;
  assert ( @_ == 3 );
  assert ( is_Object $outLine );
  assert ( is_CodeRef $action );
  assert ( is_Bool $checkResult );
  my $position = -1;
  return $traverseTree->(
    $outLine,
    $action,
    \$position,
    $checkResult,
    $outLine->getRoot(),
    0,
    0,
    true,
  );
};

sub read :method {    # $self ($is)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $is ) = $sig->( @_ );
  $self->SUPER::read( $is );
  $self->{foc} = $is->get();
  return $self;
}

sub write :method {    # void ($os)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $os ) = $sig->( @_ );
  $self->SUPER::write( $os );
  $os->put( $self->{foc} );
  return;
}

sub build {    # $obj ()
  my ( $class ) = @_;
  assert ( @_ == 1 );
  assert ( is_Str $class );
  assert ( Storable::is_retrieving );
  return $class->new(
    bounds     => TRect->new(),
    hScrollBar => undef,
    vScrollBar => undef,
  );
}

1;

__END__

=pod

=head1 NAME

TUI::Outline::OutlineViewer - abstract base for scrollable outline viewers

=head1 HIERARCHY

  TObject
    TView
      TScroller
        TOutlineViewer

=head1 SYNOPSIS

  package MyOutlineViewer {
    use TUI::toolkit;
    use TUI::Outline;
    use TUI::Views;

    extends TOutlineViewer;
    # implement adjust, getChild, getNumChildren, getRoot, getText,
    # hasChildren and isExpanded
  }

=head1 DESCRIPTION

C<TOutlineViewer> is the abstract base class for views that display a
hierarchy of L<TNode|TUI::Outline::Node> objects. It derives from
L<TScroller|TUI::Views::Scroller>, so the outline scrolls horizontally and
vertically through its scroll bars.

The class does not know how the tree is stored. A subclass must implement the
abstract methods C<adjust>, C<getChild>, C<getNumChildren>, C<getRoot>,
C<getText>, C<hasChildren> and C<isExpanded>. The viewer then draws the
graph (level lines and expand/retract markers) for each visible node, handles
keyboard and mouse navigation, and expands or retracts nodes.

The explicit disposal of nodes is not needed. Memory of the node tree is
managed by Perl reference counting. Streaming is supported through Storable
serialization.

=head1 ATTRIBUTES

=head2 foc

The display position of the focused node, starting at 0 (I<Int>).

=head1 CONSTRUCTOR

=head2 new

  my $viewer = MyOutlineViewer->new(
    bounds     => $bounds,
    hScrollBar => $hScrollBar,
    vScrollBar => $vScrollBar
  );

Creates a new outline viewer. The viewer grows with its owner in both
directions.

=over

=item bounds

Bounding rectangle of the outline viewer (L<TRect|TUI::Objects::Rect>).

=item hScrollBar

Optional horizontal scroll bar (L<TScrollBar|TUI::Views::ScrollBar> or
C<undef>).

=item vScrollBar

Optional vertical scroll bar (L<TScrollBar|TUI::Views::ScrollBar> or C<undef>).

=back

=head2 new_TOutlineViewer

  my $viewer = new_TOutlineViewer($bounds, $hScrollBar | undef,
    $vScrollBar | undef);

Factory constructor that mirrors the positional I<Turbo Vision> constructor.

=head1 METHODS

=head2 adjust

  $viewer->adjust($node, $expand);

Expands ($expand true) or retracts ($expand false) the node. Abstract: a
subclass must implement this method.

=head2 createGraph

  my $graph = $viewer->createGraph($level, $lines, $flags, $levWidth,
    $endWidth, $chars);

Builds the graph string for one node. C<$chars> holds the eight graph
characters in CP437 order (level filler, level mark, end first, end first last
child, end filler, end child, retracted, expanded).

=head2 draw

  $viewer->draw();

Draws the visible part of the outline.

=head2 expandAll

  $viewer->expandAll($node);

Expands the node and all its descendants.

=head2 firstThat

  my $node = $viewer->firstThat(\&test);

Walks the visible tree in display order and returns the first node for which
C<test> returns true. C<test> is called as

  test($viewer, $node, $level, $position, $lines, $flags)

=head2 focused

  $viewer->focused($i);

Called when the node at position $i receives focus. Sets L</foc>.

=head2 forEach

  $viewer->forEach(\&action);

Calls C<action> for every visible node in display order. The arguments are the
same as for C<firstThat>.

=head2 getChild

  my $child = $viewer->getChild($node, $i);

Returns the child with index $i of the node. Abstract: a subclass must
implement this method.

=head2 getGraph

  my $graph = $viewer->getGraph($level, $lines, $flags);

Returns the graph characters drawn before the text of a node. Uses
C<createGraph> with the default widths.

=head2 getNode

  my $node = $viewer->getNode($i);

Returns the node displayed at position $i, or C<undef>.

=head2 getNumChildren

  my $count = $viewer->getNumChildren($node);

Returns the number of children of the node. Abstract: a subclass must
implement this method.

=head2 getPalette

  my $palette = $viewer->getPalette();

Returns the outline palette.

=head2 getRoot

  my $root = $viewer->getRoot();

Returns the root node of the outline, or C<undef> if the outline is empty.
Abstract: a subclass must implement this method.

=head2 getText

  my $text = $viewer->getText($node);

Returns the text displayed for the node. Abstract: a subclass must implement
this method.

=head2 handleEvent

  $viewer->handleEvent($event);

Handles keyboard and mouse events. Keyboard keys C<-> and C<+> retract or
expand the focused node, and C<*> expands it with all its children.

=head2 hasChildren

  my $bool = $viewer->hasChildren($node);

Returns true if the node has children. Abstract: a subclass must implement
this method.

=head2 isExpanded

  my $bool = $viewer->isExpanded($node);

Returns true if the node is expanded. Abstract: a subclass must implement this
method.

=head2 isSelected

  my $bool = $viewer->isSelected($i);

Returns true if the node at position $i is selected. By default only the
focused node is selected.

=head2 selected

  $viewer->selected($i);

Called when the node at position $i is selected by the user. Does nothing by
default.

=head2 setState

  $viewer->setState($aState, $enable);

Redraws the outline when the focus state changes.

=head2 update

  $viewer->update();

Recalculates the limits of the viewer. Call it after the data of the outline
has changed.

=head1 SEE ALSO

L<TNode|TUI::Outline::Node>,
L<TOutline|TUI::Outline::Outline>,
L<TScroller|TUI::Views::Scroller>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
