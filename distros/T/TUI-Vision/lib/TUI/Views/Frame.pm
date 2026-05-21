package TUI::Views::Frame;
# ABSTRACT: Frame class used by windows

use 5.010;
use strict;
use warnings;
use utf8;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TFrame
  new_TFrame
);

use Encode qw( encode );
use List::Util qw( min max );
use TUI::toolkit;
use TUI::toolkit::Types qw(
  :is
  :types
);

use TUI::Drivers::Const qw(
  :evXXXX
  meDoubleClick
);
use TUI::Objects::Point;
use TUI::Views::Const qw(
  :cmXXXX
  cpFrame
  :dmXXXX
  :gfXXXX
  :sfXXXX
  :wfXXXX
  wnNoNumber
);
use TUI::Views::DrawBuffer;
use TUI::Views::Palette;
use TUI::Views::View;

sub TFrame() { __PACKAGE__ }
sub name() { 'TFrame' }
sub new_TFrame { __PACKAGE__->from(@_) }

extends TView;

# declare global variables
our $initFrame =
  "\x06\x0A\x0C\x05\x00\x05\x03\x0A\x09\x16\x1A\x1C\x15\x00\x15\x13\x1A\x19";

# for UnitedStates code page
our $frameChars = encode('cp437' => "   └ │┌├ ┘─┴┐┤┬┼   ╚ ║╔╟ ╝═╧╗╢╤ ");

our $closeIcon  = "[~\xFE~]";    # "[~■~]"
our $zoomIcon   = "[~\x18~]";    # "[~↑~]"
our $unZoomIcon = "[~\x12~]";    # "[~↕~]"
our $dragIcon   = encode('cp437' => "~─┘~");

# import frameLine
require TUI::Views::Frame::Line;

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{growMode} = gfGrowHiX | gfGrowHiY;
  $self->{eventMask} |= evBroadcast | evMouseUp;
  return;
}

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my ( $cFrame, $cTitle );
  my ( $f, $i, $l, $width );
  my $b = TDrawBuffer->new();

  if ( ( $self->{state} & sfDragging ) != 0 ) {
    $cFrame = 0x0505;
    $cTitle = 0x0005;
    $f      = 0;
  }
  elsif ( ( $self->{state} & sfActive ) == 0 ) {
    $cFrame = 0x0101;
    $cTitle = 0x0002;
    $f      = 0;
  }
  else {
    $cFrame = 0x0503;
    $cTitle = 0x0004;
    $f      = 9;
  }

  $cFrame = $self->getColor( $cFrame );
  $cTitle = $self->getColor( $cTitle );

  $width = $self->{size}{x};
  $l     = $width - 10;

  $l -= 6 
    if $self->{owner}{flags} & ( wfClose | wfZoom );
  $self->frameLine( $b, 0, $f, $cFrame );
  if ( $self->{owner}{number} != wnNoNumber
    && $self->{owner}{number} < 10
  ) {
    $l -= 4;
    $i = ( $self->{owner}{flags} & wfZoom ) 
       ? 7 
       : 3;
    $b->putChar( $width - $i, chr( $self->{owner}{number} + ord( '0' ) ) );
  }

  if ( $self->{owner} ) {
    my $title = $self->{owner}->getTitle( $l );
    if ( $title ) {
      $l = min( length( $title ), $width - 10 );
      $l = max( $l, 0 );
      $i = ( $width - $l ) >> 1;
      $b->putChar( $i - 1, ' ' );
      $b->moveBuf( $i, [ unpack 'W*' => $title ], $cTitle, $l );
      $b->putChar( $i + $l, ' ' );
    }
  } #/ if ( $self->{owner} )

  if ( $self->{state} & sfActive ) {
    if ( $self->{owner}{flags} & wfClose ) {
      $b->moveCStr( 2, $closeIcon, $cFrame );
    }
    if ( $self->{owner}{flags} & wfZoom ) {
      my ( $minSize, $maxSize ) = ( TPoint->new(), TPoint->new() );
      $self->{owner}->sizeLimits( $minSize, $maxSize );
      if ( $self->{owner}{size} == $maxSize ) {
        $b->moveCStr( $width - 5, $unZoomIcon, $cFrame );
      }
      else {
        $b->moveCStr( $width - 5, $zoomIcon, $cFrame );
      }
    } #/ if ( ( $self->{owner}...))
  } #/ if ( ( $self->{state} ...))

  $self->writeLine( 0, 0, $self->{size}{x}, 1, $b );
  for ( $i = 1 ; $i <= $self->{size}{y} - 2 ; $i++ ) {
    $self->frameLine( $b, $i, $f + 3, $cFrame );
    $self->writeLine( 0, $i, $self->{size}{x}, 1, $b );
  }
  $self->frameLine( $b, $self->{size}{y} - 1, $f + 6, $cFrame );
  if ( $self->{state} & sfActive ) {
    if ( $self->{owner}{flags} & wfGrow ) {
      $b->moveCStr( $width - 2, $dragIcon, $cFrame );
    }
  }
  $self->writeLine( 0, $self->{size}{y} - 1, $self->{size}{x}, 1, $b );
  return;
} #/ sub draw

sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  state $palette = TPalette->new( data => cpFrame, size => length( cpFrame ) );
  return $palette->clone();
}

sub handleEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  $self->SUPER::handleEvent( $event );
  if ( $event->{what} == evMouseDown ) {
    my $mouse = $self->makeLocal( $event->{mouse}{where} );
    if ( $mouse->{y} == 0 ) {
      if ( ( $self->{owner}{flags} & wfClose ) != 0
        && ( $self->{state} & sfActive )
        && $mouse->{x} >= 2
        && $mouse->{x} <= 4 
      ) {
        while ( $self->mouseEvent( $event, evMouse ) ) {
        }
        $mouse = $self->makeLocal( $event->{mouse}{where} );
        if ( $mouse->{y} == 0 && $mouse->{x} >= 2 && $mouse->{x} <= 4 ) {
          $event->{what} = evCommand;
          $event->{message}{command} = cmClose;
          $event->{message}{infoPtr} = $self->{owner};
          $self->putEvent( $event );
          $self->clearEvent( $event );
        }
      } #/ if ( ( $self->{owner}...))
      elsif (
        ( $self->{owner}{flags} & wfZoom ) != 0
        && ( $self->{state} & sfActive )
        && (
          (
               $mouse->{x} >= $self->{size}{x} - 5 
            && $mouse->{x} <= $self->{size}{x} - 3
          )
          || ( $event->{mouse}{eventFlags} & meDoubleClick )
        )
      ) {
        $event->{what} = evCommand;
        $event->{message}{command} = cmZoom;
        $event->{message}{infoPtr} = $self->{owner};
        $self->putEvent( $event );
        $self->clearEvent( $event );
      } #/ elsif ( ( $self->{owner}...))
      elsif ( $self->{owner}{flags} & wfMove ) {
        $self->dragWindow( $event, dmDragMove );
      }
    } #/ if ( $mouse->{y} == 0 )
    elsif ( ( $mouse->{x} >= $self->{size}{x} - 2 &&
              $mouse->{y} >= $self->{size}{y} - 1 )
         && ( $self->{state} & sfActive )
    ) {
      if ( $self->{owner}{flags} & wfGrow ) {
        $self->dragWindow( $event, dmDragGrow );
      }
    }
  } #/ if ( $event->{what} ==...)
  return;
} #/ sub handleEvent

sub setState {    # void ($aState, $enable)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, Bool],
  );
  my ( $self, $aState, $enable ) = $sig->( @_ );
  $self->SUPER::setState( $aState, $enable );
  if ( $aState & ( sfActive | sfDragging ) ) {
    $self->drawView();
  }
  return;
}

sub dragWindow {    # void ($event, $mode)
  state $sig = signature(
    method => Object,
    pos    => [Object, PositiveOrZeroInt],
  );
  my ( $self, $event, $mode ) = $sig->( @_ );
  my $limits = $self->{owner}{owner}->getExtent();
  my ( $min, $max ) = ( TPoint->new(), TPoint->new() );
  $self->{owner}->sizeLimits( $min, $max );
  $self->{owner}->dragView( 
    $event, $self->{owner}{dragMode} | $mode, $limits, $min, $max
  );
  $self->clearEvent( $event );
  return;
}

1

__END__

=pod

=head1 NAME

TUI::Views::Frame - frame class for window components

=head1 HIERARCHY

  TObject
    TView
      TFrame

=head1 SYNOPSIS

  use TUI::Views;

  my $frame = TFrame->new(bounds => $bounds);
  $frame->draw();

=head1 DESCRIPTION

C<TFrame> implements the visual border that surrounds a window. It is
responsible for drawing the window frame, including the title, border lines,
and standard window icons such as close, zoom, and resize indicators.

Frame objects are normally created and managed automatically by
C<TWindow>. Applications rarely instantiate C<TFrame> directly and typically
do not interact with it except through subclassing or customization hooks
provided by the window.

To customize the appearance of a window frame, applications override
C<TWindow::initFrame> to instantiate a C<TFrame>-derived object with modified
behavior, such as a different color palette.

=head1 VARIABLES

The following global variables define the visual appearance and behavior
of C<TFrame>.

=head2 $initFrame

Initial frame definition table used to map frame styles and states.

=head2 $frameChars

Character set used to draw frame borders.
The default value uses CP437 line-drawing characters.

=head2 $closeIcon

Icon text used for the close window command.

=head2 $zoomIcon

Icon text used for the zoom window command.

=head2 $unZoomIcon

Icon text used for the unzoom window command.

=head2 $dragIcon

Icon text used to indicate window dragging (CP437).

=head1 CONSTRUCTOR

=head2 new

  my $frame = TFrame->new(bounds => $bounds);

Creates a new frame object with the specified bounds. This constructor is
normally called internally by C<TWindow::initFrame>.

=over

=item bounds

Bounding rectangle of the frame (I<TRect>).

=back

=head2 new_TFrame

  my $frame = new_TFrame($bounds);

Factory-style constructor using positional arguments.

This constructor is equivalent to calling C<new> with the C<bounds> parameter
and is provided for compatibility with traditional Turbo Vision construction
patterns.

=head1 METHODS

=head2 draw

  $self->draw();

Draws the frame, including the window title and any enabled window icons. The
exact appearance depends on the current view state flags.

=head2 getPalette

  my $palette = $self->getPalette();

Returns the color palette used to draw the frame. The default implementation
returns the standard frame palette.

To customize frame colors, override C<TWindow::initFrame> to create a
C<TFrame>-derived object that overrides this method.

=head2 handleEvent

  $self->handleEvent($event);

Handles events directed at the frame. This method delegates general event
processing to C<TView::handleEvent> and processes events related to frame
icons such as close or zoom.

=head2 setState

  $self->setState($state, $enable);

Updates the frame state. After delegating to C<TView::setState>, the frame is
redrawn if the active or dragging state changes.

=head2 dragWindow

  $self->dragWindow($event, $mode);

Handles interactive dragging of the owning window using the mouse.

=head1 SEE ALSO

L<TUI::Views::Window>, L<TUI::Views::View>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2021-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution). This documentation is provided under the same terms
as the Turbo Vision library itself.

=cut
