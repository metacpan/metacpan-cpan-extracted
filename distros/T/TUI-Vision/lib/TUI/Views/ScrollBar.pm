package TUI::Views::ScrollBar;
# ABSTRACT: Class defining a scroll bar

use 5.010;
use strict;
use warnings;
use utf8;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TScrollBar
  new_TScrollBar
);

use List::Util qw( min max );
use TUI::toolkit;
use TUI::toolkit::Types qw(
  is_Object
  :types
);

use TUI::Drivers::Const qw( 
  :evXXXX
  :kbXXXX
);
use TUI::Drivers::Util qw( ctrlToArrow );
use TUI::Views::DrawBuffer;
use TUI::Objects::Point;
use TUI::Objects::Rect;
use TUI::Views::Const qw(
  :cmXXXX
  cpScrollBar
  :gfXXXX
  :sbXXXX
  sfVisible
);
use TUI::Views::Palette;
use TUI::Views::View;
use TUI::Views::Util qw( message );

sub TScrollBar() { __PACKAGE__ }
sub name() { 'TScrollBar' }
sub new_TScrollBar { __PACKAGE__->from(@_) }

extends TView;

# declare global variables
our $vChars = "\x1E\x1F\xB1\xFE\xB2";    # cp437: "▲▼░■▒"
our $hChars = "\x11\x10\xB1\xFE\xB2";    # cp437: "◄►░■▒"

# public attributes
has value  => ( is => 'rw', default => 0 );
has chars  => ( is => 'rw', default => "\0" x 5 );
has minVal => ( is => 'rw', default => 0 );
has maxVal => ( is => 'rw', default => 0 );
has pgStep => ( is => 'rw', default => 1 );
has arStep => ( is => 'rw', default => 1 );

# predeclare private methods
my (
  $getPartCode,
);

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  if ( $self->{size}{x} == 1 ) {
    $self->{growMode} = gfGrowLoX | gfGrowHiX | gfGrowHiY;
    $self->{chars}    = $vChars;
  }
  else {
    $self->{growMode} = gfGrowLoY | gfGrowHiX | gfGrowHiY;
    $self->{chars}    = $hChars;
  }
  return;
}

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->drawPos( $self->getPos() );
  return;
}

sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  state $palette = TPalette->new(
    data => cpScrollBar, 
    size => length( cpScrollBar ),
  );
  return $palette->clone();
}

my $mouse = TPoint->new();
my ( $p, $s );
my $extent = TRect->new();

sub handleEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  
  my $Tracking;
  my ( $i, $clickPart );

  $self->SUPER::handleEvent( $event );
  SWITCH: for ( $event->{what} ) {
    $_ == evMouseDown and do {
      # Clicked()
      message( $self->owner, evBroadcast, cmScrollBarClicked, $self );
      $mouse  = $self->makeLocal( $event->{mouse}{where} );
      $extent = $self->getExtent();
      $extent->grow( 1, 1 );
      $p = $self->getPos();
      $s = $self->getSize() - 1;
      $clickPart = $self->$getPartCode();
      if ( $clickPart != sbIndicator ) {
        do {
          $mouse = $self->makeLocal( $event->{mouse}{where} );
          if ( $self->$getPartCode() == $clickPart ) {
            $self->setValue( $self->{value} + $self->scrollStep( $clickPart ) );
          }
        } while ( $self->mouseEvent( $event, evMouseAuto ) );
      }
      else {
        do {
          $mouse = $self->makeLocal( $event->{mouse}{where} );
          $Tracking = $extent->contains( $mouse );
          if ( $Tracking ) {
            $i = $self->{size}{x} == 1 
              ? $mouse->{y} 
              : $mouse->{x};
            $i = max( $i, 1);
            $i = min( $i, $s - 1);
          }
          else {
            $i = $self->getPos();
          }
          if ( $i != $p ) {
            $self->drawPos( $i );
            $p = $i;
          }
        } while ( $self->mouseEvent( $event, evMouseMove ) );
        if ( $Tracking && $s > 2 ) {
          $s -= 2;
          $self->setValue(
            int(
              (
                  ( $p - 1 ) 
                * ( $self->{maxVal} - $self->{minVal} ) 
                + ( $s >> 1 )
              ) / $s + $self->{minVal}
            )
          );
        }
      } #/ else [ if ( $clickPart != sbIndicator)]
      $self->clearEvent( $event );
      last;
    };
    $_ == evKeyDown and do {
      if ( $self->{state} & sfVisible ) {
        $clickPart = sbIndicator;
        if ( $self->{size}{y} == 1 ) {
          SWITCH: for ( ctrlToArrow( $event->{keyDown}{keyCode} ) ) {
            $_ == kbLeft and do {
              $clickPart = sbLeftArrow;
              last;
            };
            $_ == kbRight and do {
              $clickPart = sbRightArrow;
              last;
            };
            $_ == kbCtrlLeft and do {
              $clickPart = sbPageLeft;
              last;
            };
            $_ == kbCtrlRight and do {
              $clickPart = sbPageRight;
              last;
            };
            $_ == kbHome and do {
              $i = $self->{minVal};
              last;
            };
            $_ == kbEnd and do {
              $i = $self->{maxVal};
              last;
            };
            DEFAULT: {
              return;
            }
          }
        }
        else {
          SWITCH: for ( ctrlToArrow( $event->{keyDown}{keyCode} ) ) {
            $_ == kbUp and do {
              $clickPart = sbUpArrow;
              last;
            };
            $_ == kbDown and do {
              $clickPart = sbDownArrow;
              last;
            };
            $_ == kbPgUp and do {
              $clickPart = sbPageUp;
              last;
            };
            $_ == kbPgDn and do {
              $clickPart = sbPageDown;
              last;
            };
            $_ == kbCtrlPgUp and do {
              $i = $self->{minVal};
              last;
            };
            $_ == kbCtrlPgDn and do {
              $i = $self->{maxVal};
              last;
            };
            DEFAULT: {
              return;
            }
          }
        }
        # Clicked
        message( $self->owner, evBroadcast, cmScrollBarClicked, $self );
        $i = $self->{value} + $self->scrollStep( $clickPart )
          if $clickPart != sbIndicator;
        $self->setValue( $i );
        $self->clearEvent( $event );
      } #/ if ( ( $self->{state} ...))
      last;
    }; #/ do
  } #/ SWITCH: for ( $event->{what} ...)
  return;
} #/ sub handleEvent

sub scrollDraw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  message( $self->owner, evBroadcast, cmScrollBarChanged, $self );
  return;
}

sub scrollStep {    # $steps ($part)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $part ) = $sig->( @_ );
  my $step = ( $part & 2 )
           ? $self->{pgStep} 
           : $self->{arStep};
  return ( $part & 1 )
    ? $step
    : -$step;
}

sub setParams {    # void ($aValue, $aMin, $aMax, $aPgStep, $aArStep)
  state $sig = signature(
    method => Object,
    pos    => [Int, Int, Int, Int, Int],
  );
  my ( $self, $aValue, $aMin, $aMax, $aPgStep, $aArStep ) = $sig->( @_ );

  $aMax   = max( $aMax, $aMin );
  $aValue = max( $aValue, $aMin );
  $aValue = min( $aValue, $aMax );
  my $sValue = $self->{value};
  if ( $sValue != $aValue
    || $self->{minVal} != $aMin
    || $self->{maxVal} != $aMax
  ) {
    $self->{value}  = $aValue;
    $self->{minVal} = $aMin;
    $self->{maxVal} = $aMax;
    $self->drawView();
    $self->scrollDraw()
      if $sValue != $aValue;
  } #/ if ( $sValue != $aValue...)
  $self->{pgStep} = $aPgStep;
  $self->{arStep} = $aArStep;
  return;
} #/ sub setParams

sub setRange {    # void ($aMin, $aMax)
  state $sig = signature(
    method => Object,
    pos    => [Int, Int],
  );
  my ( $self, $aMin, $aMax ) = $sig->( @_ );
  $self->setParams( $self->{value}, $aMin, $aMax, $self->{pgStep},
    $self->{arStep} );
  return;
}

sub setStep {    # void ($aPgStep, $aArStep)
  state $sig = signature(
    method => Object,
    pos    => [Int, Int],
  );
  my ( $self, $aPgStep, $aArStep ) = $sig->( @_ );
  $self->setParams( $self->{value}, $self->{minVal}, $self->{maxVal}, $aPgStep,
    $aArStep );
  return;
}

sub setValue {    # void ($aValue)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $aValue ) = $sig->( @_ );
  $self->setParams( $aValue, $self->{minVal}, $self->{maxVal}, $self->{pgStep},
    $self->{arStep} );
  return;
}

sub drawPos {    # void ($pos)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $pos ) = $sig->( @_ );
  my $b = TDrawBuffer->new();
  my $s = $self->getSize() - 1;
  $b->moveChar( 0, substr($self->{chars}, 0, 1), $self->getColor( 2 ), 1 );
  if ( $self->{maxVal} == $self->{minVal} ) {
    $b->moveChar( 1, substr($self->{chars}, 4, 1), $self->getColor( 1 ), $s-1 );
  }
  else {
    $b->moveChar( 1, substr($self->{chars}, 2, 1), $self->getColor( 1 ), $s-1 );
    $b->moveChar( $pos, substr($self->{chars}, 3, 1), $self->getColor( 3 ), 1 );
  }
  $b->moveChar( $s, substr( $self->{chars}, 1, 1), $self->getColor( 2 ), 1 );
  $self->writeBuf( 0, 0, $self->{size}{x}, $self->{size}{y}, $b );
  return;
} #/ sub drawPos

sub getPos {    # $pos ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $r = $self->{maxVal} - $self->{minVal};
  return 1 
    if $r == 0;
  return int(
    (
        ( $self->{value} - $self->{minVal} ) 
      * ( $self->getSize() - 3 )
      + ( $r >> 1 )
    ) / $r + 1
  );
} #/ sub getPos

sub getSize {   # $size ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  return $self->{size}{x} == 1 
    ? $self->{size}{y}
    : $self->{size}{x};
}

$getPartCode = sub {    # $int ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( is_Object $self );
  my $part = -1;
  if ( $extent->contains( $mouse ) ) {
    my $mark = $self->{size}{x} == 1 ? $mouse->{y} : $mouse->{x};

    # Check for vertical or horizontal size of 2
    if ( ( $self->{size}{x} == 1 && $self->{size}{y} == 2 )
      || ( $self->{size}{x} == 2 && $self->{size}{y} == 1 )
    ) {
      # Set 'part' to left or right arrow only
      if ( $mark < 1 ) {
        $part = sbLeftArrow;
      } 
      elsif ( $mark == $p ) {
        $part = sbRightArrow;
      }
    }
    else {
      if ( $mark == $p ) {
        $part = sbIndicator;
      }
      else {
        if ( $mark < 1 ) {
          $part = sbLeftArrow;
        }
        elsif ( $mark < $p ) {
          $part = sbPageLeft;
        }
        elsif ( $mark < $s ) {
          $part = sbPageRight;
        }
        else {
          $part = sbRightArrow;
        }
        $part += 4 
          if $self->{size}{x} == 1;
      } #/ else [ if ( $mark == $self->{...})]
    } #/ else [ if ( ( $self->{size}->...))]
  } #/ if ( $extent->...)
  return $part;
};

1

__END__

=pod

=head1 NAME

TUI::Views::ScrollBar - scroll bar view components

=head1 HIERARCHY

  TObject
    TView
      TScrollBar

=head1 SYNOPSIS

  use TUI::Objects;
  use TUI::Views;

  my $bounds = TRect->new( ax => 0, ay => 0, bx => 30, by => 10 );
  my $vbar   = TScrollBar->new(
    bounds => TRect->new( ax => 29, ay => 0, bx => 30, by => 10 )
  );

  my $viewer = TListViewer->new(
    bounds     => $bounds,
    numCols    => 1,
    hScrollBar => undef,
    vScrollBar => $vbar,
  );

  # Typical setup for list-style scrolling.
  $vbar->setRange(0, 99);
  $vbar->setStep(10, 1);
  $vbar->setValue(0);

=head1 DESCRIPTION

C<TScrollBar> implements a visual scroll bar used to control and display a
numeric position within a bounded range. Scroll bars are typically attached
to other views such as list viewers, text editors, or scrollers and remain
synchronized with the associated view.

When linked to a compatible view, the scroll bar automatically reflects
changes in position and range. Conversely, user interaction with the scroll
bar generates events that notify the owning view of position changes.

C<TScrollBar> supports both vertical and horizontal orientations. A vertical
scroll bar is created when its width is one column; otherwise, a horizontal
scroll bar is created.

=head2 Commonly Used Features

In everyday code, scroll bars are usually created once and then configured with
either C<setParams> (single-call setup) or the C<setRange>/C<setStep>/
C<setValue> trio (incremental setup). After that, application logic mainly
reacts to scroll events rather than manipulating internal fields directly.

=head1 VARIABLES

The following global variables define the characters used to render
C<TScrollBar> elements.

=head2 $vChars

Defines the character set used for vertical scroll bars.
The default value uses CP437 characters (up, down, track, thumb).

=head2 $hChars

Defines the character set used for horizontal scroll bars.
The default value uses CP437 characters (left, right, track, thumb).

=head1 ATTRIBUTES

The following attributes describe the state and behavior of the scroll bar.

=over

=item value

Current position of the scroll bar (I<Int>).

=item minVal

Lower bound of the scroll bar range (I<Int>).

=item maxVal

Upper bound of the scroll bar range (I<Int>).

=item pgStep

Page step size used for page-up and page-down operations (I<Int>).

=item arStep

Arrow step size used for single-step movements (I<Int>).

=back

=head1 CONSTRUCTOR

=head2 new

  my $scrollBar = TScrollBar->new(bounds => $bounds);

Creates a new scroll bar with the specified bounds.

=over

=item bounds

Bounding rectangle of the scroll bar (I<TRect>).

=back

=head2 new_TScrollBar

  my $scrollBar = new_TScrollBar($bounds);

Factory-style constructor using positional arguments.

This constructor is equivalent to calling C<new> with the C<bounds> parameter
and is provided for compatibility with traditional Turbo Vision construction
patterns.

=head1 METHODS

=head2 draw

  $scrollBar->draw();

Draws the scroll bar.

=head2 drawPos

  $scrollBar->drawPos($pos);

Draws the scroll bar thumb at the specified position.

=head2 getPalette

  my $palette = $scrollBar->getPalette();

Returns the color palette used to draw the scroll bar.

=head2 getPos

  my $pos = $scrollBar->getPos();

Returns the current scroll bar position.

=head2 getSize

  my $size = $scrollBar->getSize();

Returns the usable size of the scroll bar track.

=head2 handleEvent

  $scrollBar->handleEvent($event);

Handles mouse and keyboard events directed at the scroll bar.

=head2 scrollDraw

  $scrollBar->scrollDraw();

Redraws the scroll bar after a value change and notifies the owner.

=head2 scrollStep

  my $delta = $scrollBar->scrollStep($part);

Determines the step size associated with a specific scroll bar part, such as
an arrow or page region.

=head2 setParams

  $scrollBar->setParams($value, $min, $max, $pgStep, $arStep);

Initializes all scroll bar parameters in a single call.

=head2 setRange

  $scrollBar->setRange($min, $max);

Sets the minimum and maximum range of the scroll bar.

=head2 setStep

  $scrollBar->setStep($pgStep, $arStep);

Sets the page and arrow step sizes.

=head2 setValue

  $scrollBar->setValue($value);

Sets the current scroll bar value and updates the display.

=head1 EXAMPLE

The following example demonstrates how to create a scroll bar and link it to
a list viewer:

  # Define scroll bar bounds relative to the list viewer
  my $barBounds = $bounds->clone;
  $barBounds->{b}->{x} += 1;
  $barBounds->{a}->{x}  = $bounds->{b}->{x};

  # Create the scroll bar
  my $listScroller = TScrollBar->new(bounds => $barBounds);

  # Create a list viewer and link it to the scroll bar
  my $listObject = TListViewer->new(
      bounds     => $bounds,
      numCols    => 1,
      scrollBar  => $listScroller,
  );

  # Insert both views into the owning group
  $group->insert($listScroller);
  $group->insert($listObject);

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2025-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
