package TUI::Views::View;
# ABSTRACT: Base class for all visual components

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TView
  new_TView
);

use Devel::StrictMode;
use List::Util qw( min max );
use Scalar::Util qw( weaken );
use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  :is
  :types
);

use TUI::Const qw( INT_MAX );
use TUI::Objects::Object;
use TUI::Objects::Point;
use TUI::Objects::Rect;
use TUI::Drivers::Const qw(
  :evXXXX
  :kbXXXX
);
use TUI::Drivers::Event;
use TUI::Views::Const qw(
  maxViewWidth
  :phaseType
  :selectMode
  :cmXXXX
  :dmXXXX
  :gfXXXX
  :hcXXXX
  :ofXXXX
  :sfXXXX
);
use TUI::Views::CommandSet;
use TUI::Views::DrawBuffer;
use TUI::Views::Palette;
use TUI::Views::Util qw( message );

require TUI::Views::View::Cursor;
require TUI::Views::View::Exposed;
require TUI::Views::View::Write;

sub TView() { __PACKAGE__ }
sub name() { 'TView' }
sub new_TView { __PACKAGE__->from(@_) }

extends TObject;

# declare global variables
our $shadowSize        = TPoint->new( x => 2, y => 1 );
our $shadowAttr        = 0x08;
our $showMarkers       = false;
our $specialChars      = [ "\xAF", "\xAE", "\x1A", "\x1B", ' ', ' ' ];
our $errorAttr         = 0xcf;
our $commandSetChanged = false;
our $curCommandSet     = do {    # initCommands
  my $temp = TCommandSet->new();
  for ( my $i = 0 ; $i < 256 ; $i++ ) {
    $temp->enableCmd( $i );
  }
  $temp->disableCmd( cmZoom );
  $temp->disableCmd( cmClose );
  $temp->disableCmd( cmResize );
  $temp->disableCmd( cmNext );
  $temp->disableCmd( cmPrev );
  $temp;
};

# import global variables
use vars qw(
  $TheTopView
); 
{
  *TheTopView = \$TUI::Views::Group::TheTopView;
}

# public attributes
has next      => ( is => 'bare' );
has size      => ( is => 'rw', default => sub { TPoint->new } );
has options   => ( is => 'rw', default => 0 );
has eventMask => ( is => 'rw', default => evMouseDown | evKeyDown | evCommand );
has state     => ( is => 'rw', default => sfVisible );
has origin    => ( is => 'rw', default => sub { TPoint->new } );
has cursor    => ( is => 'rw', default => sub { TPoint->new } );
has growMode  => ( is => 'rw', default => 0 );
has dragMode  => ( is => 'rw', default => dmLimitLoY );
has helpCtx   => ( is => 'rw', default => hcNoContext );
has owner     => ( is => 'bare' );    # weak_ref => 1

# predeclare private methods
my (
  $moveGrow,
  $change,
  $writeView,
);

my $lock_value = sub {
  Internals::SvREADONLY( $_[0] => 1 )
    if exists &Internals::SvREADONLY;
};

my $unlock_value = sub {
  Internals::SvREADONLY( $_[0] => 0 )
    if exists &Internals::SvREADONLY;
};

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      bounds => Object,
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
  assert ( is_HashRef $args );
  weaken( $self->{owner} ) if $self->{owner};
  weaken( $self->{next} )  if $self->{next};
  &$lock_value( $self->{owner} ) if STRICT;
  &$lock_value( $self->{next} )  if STRICT;
  $self->setBounds( $args->{bounds} );
  return;
} #/ sub BUILD

sub from {    # $obj ($bounds)
  state $sig = signature(
    method => 1,
    pos    => [Object],
  );
  my ( $class, $bounds ) = $sig->( @_ );
  return $class->new( bounds => $bounds );
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  &$unlock_value( $self->{owner} ) if STRICT;
  &$unlock_value( $self->{next} )  if STRICT;
  return;
}

sub sizeLimits {    # void ($min, $max)
  state $sig = signature(
    method => Object,
    pos    => [HashLike, HashLike],
  );
  my ( $self, $min, $max ) = $sig->( @_ );
  $min->{x} = $min->{y} = 0;
  if ( !( $self->{growMode} & gfFixed ) && $self->{owner} ) {
    $max->{x} = $self->{owner}{size}{x};
    $max->{y} = $self->{owner}{size}{y};
  }
  else {
    $max->{x} = $max->{y} = INT_MAX;
  }
  return;
} #/ sub sizeLimits

sub getBounds {    # $rect ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  return TRect->new(
    a => $self->{origin},
    b => $self->{origin} + $self->{size},
  );
}

sub getExtent {    # $rect ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  return TRect->new(
    ax => 0,
    ay => 0,
    bx => $self->{size}{x},
    by => $self->{size}{y},
  );
}

sub getClipRect {    # $rect ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $clip = $self->getBounds();
  if ( $self->{owner} ) {
    $clip->intersect( $self->{owner}{clip} );
  }
  $clip->move( -$self->{origin}{x}, -$self->{origin}{y} );
  return $clip;
}

sub mouseInView {    # $bool ($mouse)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $mouse ) = $sig->( @_ );
  $mouse = $self->makeLocal( $mouse->clone() );
  my $r = $self->getExtent();
  return $r->contains( $mouse );
}

sub containsMouse {    # $bool ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  return ( $self->{state} & sfVisible )
    && $event->{mouse}
    && $self->mouseInView( $event->{mouse}{where} );
}

# Define the range function
my $range = sub {    # $ ($val, $min, $max)
  my ( $val, $min, $max ) = @_;
  assert ( @_ == 3 );
  assert ( is_Int $val );
  assert ( is_Int $min );
  assert ( is_Int $max );
  $min = $max 
    if $min > $max;
  if ( $val < $min ) {
    return $min;
  } elsif ( $val > $max ) {
    return $max;
  } else {
    return $val;
  }
};

sub locate {    # void ($bounds)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $bounds ) = $sig->( @_ );
  my ( $min,  $max ) = ( TPoint->new(), TPoint->new() );
  $self->sizeLimits( $min, $max );
  $bounds->{b}{x} = $bounds->{a}{x} +
    &$range( $bounds->{b}{x} - $bounds->{a}{x}, $min->{x}, $max->{x} );
  $bounds->{b}{y} = $bounds->{a}{y} +
    &$range( $bounds->{b}{y} - $bounds->{a}{y}, $min->{y}, $max->{y} );
  my $r = $self->getBounds();
  if ( $bounds != $r ) {
    $self->changeBounds( $bounds );
    if ( $self->{owner} && ( $self->{state} & sfVisible ) ) {
      if ( $self->{state} & sfShadow ) {
        $r->Union( $bounds );
        $r->{b} += $shadowSize;
      }
      $self->drawUnderRect( $r, undef );
    }
  } #/ if ( $bounds != $r )
  return;
} #/ sub locate

sub dragView {    # void ($event, $mode, $limits, $minSize, $maxSize)
  state $sig = signature(
    method => Object,
    pos    => [Object, PositiveOrZeroInt, Object, Object, Object],
  );
  my ( $self, $event, $mode, $limits, $minSize, $maxSize ) = $sig->( @_ );
  my $saveBounds;

  my ( $p, $s );
  $self->setState( sfDragging, true );

  if ( $event->{what} == evMouseDown ) {
    if ( $mode & dmDragMove ) {
      $p = $self->{origin} - $event->{mouse}{where};
      do {
        $event->{mouse}{where} += $p;
        $self->$moveGrow(
          $event->{mouse}{where}, $self->{size}, $limits, $minSize,
          $maxSize, $mode
        );
      } while ( $self->mouseEvent( $event, evMouseMove ) );
    } #/ if ( $mode & dmDragMove)
    else {
      $p = $self->{size} - $event->{mouse}{where};
      do {
        $event->{mouse}{where} += $p;
        $self->$moveGrow(
          $self->{origin}, $event->{mouse}{where}, $limits, $minSize,
          $maxSize,        $mode
        );
      } while ( $self->mouseEvent( $event, evMouseMove ) );
    } #/ else [ if ( $mode & dmDragMove)]
  } #/ if ( $event->{what} ==...)
  else {
    state $goLeft      = TPoint->new( x => -1, y =>  0 );
    state $goRight     = TPoint->new( x =>  1, y =>  0 );
    state $goUp        = TPoint->new( x =>  0, y => -1 );
    state $goDown      = TPoint->new( x =>  0, y =>  1 );
    state $goCtrlLeft  = TPoint->new( x => -8, y =>  0 );
    state $goCtrlRight = TPoint->new( x =>  8, y =>  0 );

    $saveBounds = $self->getBounds();
    do {
      $p = $self->{origin}->clone();
      $s = $self->{size}->clone();
      $self->keyEvent( $event );
      SWITCH: for ( $event->{keyDown}{keyCode} & 0xff00 ) {
        $_ == kbLeft and do {
          $self->$change( $mode, $goLeft, $p, $s, 
            $event->{keyDown}{controlKeyState} );
          last;
        };
        $_ == kbRight and do {
          $self->$change( $mode, $goRight, $p, $s, 
            $event->{keyDown}{controlKeyState} );
          last;
        };
        $_ == kbUp and do {
          $self->$change( $mode, $goUp, $p, $s, 
            $event->{keyDown}{controlKeyState} );
          last;
        };
        $_ == kbDown and do {
          $self->$change( $mode, $goDown, $p, $s, 
            $event->{keyDown}{controlKeyState} );
          last;
        };
        $_ == kbCtrlLeft and do {
          $self->$change(
            $mode, $goCtrlLeft, $p, $s,
            $event->{keyDown}{controlKeyState}
          );
          last;
        };
        $_ == kbCtrlRight and do {
          $self->$change(
            $mode, $goCtrlRight, $p, $s,
            $event->{keyDown}{controlKeyState}
          );
          last;
        };
        $_ == kbHome and do {
          $p->{x} = $limits->{a}{x};
          last;
        };
        $_ == kbEnd and do {
          $p->{x} = $limits->{b}{x} - $s->{x};
          last;
        };
        $_ == kbPgUp and do {
          $p->{y} = $limits->{a}{y};
          last;
        };
        $_ == kbPgDn and do {
          $p->{y} = $limits->{b}{y} - $s->{y};
          last;
        };
      }
      $self->$moveGrow( $p, $s, $limits, $minSize, $maxSize, $mode );
    } while ( $event->{keyDown}{keyCode} != kbEsc
           && $event->{keyDown}{keyCode} != kbEnter 
          );
    if ( $event->{keyDown}{keyCode} == kbEsc ) {
      $self->locate( $saveBounds );
    }
  } #/ else [ if ( $event->{what} ==...)]
  $self->setState( sfDragging, false );
} #/ sub dragView

sub calcBounds {    # void ($bounds, $delta);
  state $sig = signature(
    method => Object,
    pos    => [Object, Object],
  );
  my ( $self, $bounds, $delta ) = $sig->( @_ );

  my ( $s, $d );

  my $grow = sub {    # ($i)
    if ( $self->{growMode} & gfGrowRel ) {
      $_[0] = ( $_[0] * $s + ( ( $s - $d ) >> 1 ) ) / ( $s - $d );
    }
    else {
      $_[0] += $d;
    }
  };

  %$bounds = %{ $self->getBounds() };

  assert ( $self->{owner} );
  $s = $self->{owner}{size}{x};
  $d = $delta->{x};

  if ( $self->{growMode} & gfGrowLoX ) {
    &$grow( $bounds->{a}{x} );
  }

  if ( $self->{growMode} & gfGrowHiX ) {
    &$grow( $bounds->{b}{x} );
  }

  $s = $self->{owner}{size}{y};
  $d = $delta->{y};

  if ( $self->{growMode} & gfGrowLoY ) {
    &$grow( $bounds->{a}{y} );
  }

  if ( $self->{growMode} & gfGrowHiY ) {
    &$grow( $bounds->{b}{y} );
  }

  my ( $minLim, $maxLim ) = ( TPoint->new(), TPoint->new() );
  $self->sizeLimits( $minLim, $maxLim );
  $bounds->{b}{x} = $bounds->{a}{x} +
    &$range( $bounds->{b}{x} - $bounds->{a}{x}, $minLim->{x}, $maxLim->{x} );
  $bounds->{b}{y} = $bounds->{a}{y} +
    &$range( $bounds->{b}{y} - $bounds->{a}{y}, $minLim->{y}, $maxLim->{y} );
  return;
} #/ sub calcBounds

sub changeBounds {    # void ($bounds)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $bounds ) = $sig->( @_ );
  $self->setBounds( $bounds );
  $self->drawView();
  return;
}

sub growTo {    # void ($x, $y)
  state $sig = signature(
    method => Object,
    pos    => [Int, Int],
  );
  my ( $self, $x, $y ) = $sig->( @_ );
  my $r = TRect->new(
    ax => $self->{origin}{x},
    ay => $self->{origin}{y},
    bx => $self->{origin}{x} + $x,
    by => $self->{origin}{y} + $y,
  );
  $self->locate( $r );
  return;
} #/ sub growTo

sub moveTo {    # void ($x, $y)
  state $sig = signature(
    method => Object,
    pos    => [Int, Int],
  );
  my ( $self, $x, $y ) = $sig->( @_ );
  my $r = TRect->new(
    ax => $x,
    ay => $y,
    bx => $x + $self->{size}{x},
    by => $y + $self->{size}{y},
  );
  $self->locate( $r );
  return;
} #/ sub moveTo

sub setBounds {    # void ($bounds)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $bounds ) = $sig->( @_ );
  $self->{origin} = $bounds->{a}->clone;
  $self->{size}   = $bounds->{b} - $bounds->{a};
  return;
}

sub getHelpCtx {    # $int ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  if ( $self->{state} & sfDragging ) {
    return hcDragging;
  }
  return $self->{helpCtx};
}

sub valid {    # $bool ($command)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  $sig->( @_ );
  return true;
}

sub hide {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  if ( $self->{state} & sfVisible ) {
    $self->setState( sfVisible, false );
  }
  return;
}

sub show {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  if ( ( $self->{state} & sfVisible ) == 0 ) {
    $self->setState( sfVisible, true );
  }
  return;
}

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $b = TDrawBuffer->new();

  $b->moveChar( 0, ' ', $self->getColor( 1 ), $self->{size}{x} );
  $self->writeLine( 0, 0, $self->{size}{x}, $self->{size}{y}, $b );
  return;
}

sub drawView {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  if ( $self->exposed() ) {
    $self->draw();
    $self->drawCursor();
  }
  return;
}

sub exposed {    # $bool ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  return TUI::Views::View::Exposed::L0( $self );
}

sub focus {    # $bool ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $result = true;

  if ( !( $self->{state} & ( sfSelected | sfModal ) ) ) {
    if ( $self->{owner} ) {
      $result = $self->{owner}->focus();
      if ( $result ) {
        if ( !$self->{owner}{current} ||
            ( !( $self->{owner}{current}{options} & ofValidate ) || 
              $self->{owner}{current}->valid( cmReleasedFocus ) )
        ) {
          $self->select();
        }
        else {
          return false;
        }
      } #/ if ( $result )
    } #/ if ( $self->{owner} )
  } #/ if ( !( $self->{state}...))
  return $result;
} #/ sub focus

sub hideCursor {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->setState( sfCursorVis, false );
  return;
}

sub drawHide {    # void ($lastView|undef)
  state $sig = signature(
    method => Object,
    pos    => [Maybe[Object]],
  );
  my ( $self, $lastView ) = $sig->( @_ );
  $self->drawCursor();
  $self->drawUnderView( ($self->{state} & sfShadow) != 0, $lastView );
  return;
}

sub drawShow {    # void ($lastView|undef)
  state $sig = signature(
    method => Object,
    pos    => [Maybe[Object]],
  );
  my ( $self, $lastView ) = $sig->( @_ );
  $self->drawView();
  if ( $self->{state} & sfShadow ) {
    $self->drawUnderView( true, $lastView );
  }
  return;
}

sub drawUnderRect {    # void ($r, $lastView|undef)
  state $sig = signature(
    method => Object,
    pos    => [Object, Maybe[Object]],
  );
  my ( $self, $r, $lastView ) = $sig->( @_ );
  assert ( is_Object $self->{owner} );
  $self->{owner}{clip}->intersect( $r );
  $self->{owner}->drawSubViews( $self->nextView(), $lastView );
  $self->{owner}{clip} = $self->{owner}->getExtent();
  return;
}

sub drawUnderView {    # void ($doShadow, $lastView|undef)
  state $sig = signature(
    method => Object,
    pos    => [Bool, Maybe[Object]],
  );
  my ( $self, $doShadow, $lastView ) = $sig->( @_ );
  my $r = $self->getBounds();
  if ( $doShadow ) {
    $r->{b} += $shadowSize;
  }
  $self->drawUnderRect( $r, $lastView );
  return;
}

sub dataSize {    # $size ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  $sig->( @_ );
  return 0;
}

sub getData {    # void (\@rec)
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike],
  );
  $sig->( @_ );
  return;
}

sub setData {    # void ($rec)
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike],
  );
  $sig->( @_ );
  return;
}

sub awaken {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  $sig->( @_ );
  return;
}

sub blockCursor {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->setState( sfCursorIns, true );
  return;
}

sub normalCursor {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->setState( sfCursorIns, false );
  return;
}

sub resetCursor {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  TUI::Views::View::Cursor::resetCursor( $self );
  return;
}

sub setCursor {    # void ($x, $y)
  state $sig = signature(
    method => Object,
    pos    => [Int, Int],
  );
  my ( $self, $x, $y ) = $sig->( @_ );
  $self->{cursor}{x} = $x;
  $self->{cursor}{y} = $y;
  $self->drawCursor();
  return;
}

sub showCursor {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->setState( sfCursorVis, true );
  return;
}

sub drawCursor {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  if ( $self->{state} & sfFocused ) {
    $self->resetCursor();
  }
  return;
}

sub clearEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  $event->{what}    = evNothing;
  $event->{message} = MessageEvent->new( infoPtr => $self );
  return;
}

sub eventAvail {    # $bool ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $event = TEvent->new();
  $self->getEvent( $event );
  if ( $event->{what} != evNothing ) {
    $self->putEvent( $event );
  }
  return $event->{what} != evNothing;
}

sub getEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  $self->{owner}->getEvent( $event )
    if $self->{owner};
  return;
}

sub handleEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  if ( $event->{what} == evMouseDown ) {
    if ( !( $self->{state} & ( sfSelected | sfDisabled ) )
      && ( $self->{options} & ofSelectable )
    ) {
      if ( !$self->focus() || !( $self->{options} & ofFirstClick ) ) {
        $self->clearEvent( $event );
      }
    }
  }
  return;
} #/ sub handleEvent

sub putEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  $self->{owner}->putEvent( $event )
    if $self->{owner};
  return;
}

sub commandEnabled {    # $bool ($command)
  state $sig = signature(
    method => 1,
    pos    => [PositiveOrZeroInt],
  );
  my ( $class, $command ) = $sig->( @_ );
  return ( $command > 255 ) || $curCommandSet->has( $command );
}

sub disableCommands {    # void ($commands)
  state $sig = signature(
    method => 1,
    pos    => [Object],
  );
  my ( $class, $commands ) = $sig->( @_ );
  $commandSetChanged ||= !( $curCommandSet & $commands )->isEmpty();
  $curCommandSet->disableCmd( $commands );
  return;
}

sub enableCommands {    # void ($commands)
  state $sig = signature(
    method => 1,
    pos    => [Object],
  );
  my ( $class, $commands ) = $sig->( @_ );
  $commandSetChanged ||= ( $curCommandSet & $commands ) != $commands;
  $curCommandSet += $commands;
  assert ( is_Object $curCommandSet );
  return;
}

sub disableCommand {    # void ($command)
  state $sig = signature(
    method => 1,
    pos    => [PositiveOrZeroInt],
  );
  my ( $class, $command ) = $sig->( @_ );
  $commandSetChanged ||= $curCommandSet->has( $command );
  $curCommandSet->disableCmd( $command );
  return;
}

sub enableCommand {    # void ($command)
  state $sig = signature(
    method => 1,
    pos    => [PositiveOrZeroInt],
  );
  my ( $class, $command ) = $sig->( @_ );
  $commandSetChanged ||= !$curCommandSet->has( $command );
  $curCommandSet += $command;
  return;
}

sub getCommands {    # void ($commands)
  state $sig = signature(
    method => 1,
    pos    => [Object],
  );
  my ( $class, $commands ) = $sig->( @_ );
  @$commands = @$curCommandSet;
  return;
}

sub setCommands {    # void ($commands)
  state $sig = signature(
    method => 1,
    pos    => [Object],
  );
  my ( $class, $commands ) = $sig->( @_ );
  $commandSetChanged ||= $curCommandSet != $commands;
  @$curCommandSet = @$commands;
  return;
}

sub setCmdState {    # void ($commands, $enable)
  state $sig = signature(
    method => 1,
    pos    => [Object, Bool],
  );
  my ( $class, $commands, $enable ) = $sig->( @_ );
  $enable
    ? $class->enableCommands( $commands )
    : $class->disableCommands( $commands );
  return;
}

sub endModal {    # void ($command)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  my ( $self, $command ) = $sig->( @_ );
  if ( $self->TopView() ) {
    $self->TopView()->endModal( $command );
  }
  return;
}

sub execute {    # $cmd ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  $sig->( @_ );
  return cmCancel;
}

sub getColor {    # $int ($color)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  my ( $self, $color ) = $sig->( @_ );
  my $colorPair = $color >> 8;

  if ( $colorPair != 0 ) {
    $colorPair = $self->mapColor( $colorPair ) << 8;
  }

  $colorPair |= $self->mapColor( $color & 0xff );

  return $colorPair;
}

sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  state $palette = TPalette->new( data => "\0", size => 0 );
  return $palette->clone();
}

sub mapColor {    # $int ($color)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  my ( $self, $color ) = $sig->( @_ );

  return $errorAttr
    unless $color;

  my $cur = $self;
  do {
    my $p = $cur->getPalette();
    if ( $p->at( 0 ) ) {
      if ( $color > $p->at( 0 ) ) {
        return $errorAttr;
      }
      $color = $p->at( $color );
      return $errorAttr
        unless $color;
    }
    $cur = $cur->{owner};
  } while ( $cur );

  return $color;
} #/ sub mapColor

sub getState {    # $bool ($aState)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  my ( $self, $aState ) = $sig->( @_ );
  return ( $self->{state} & $aState ) == $aState;
}

sub select {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  return
    unless $self->{options} & ofSelectable;
  if ( $self->{options} & ofTopSelect ) {
    $self->makeFirst();
  }
  elsif ( $self->{owner} ) {
    $self->{owner}->setCurrent( $self, normalSelect );
  }
  return;
} #/ sub select

sub setState {    # void ($aState, $enable)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, Bool],
  );
  my ( $self, $aState, $enable ) = $sig->( @_ );

  if ( $enable ) {
    $self->{state} |= $aState;
  }
  else {
    $self->{state} &= ~$aState;
  }

  return
    unless $self->{owner};

  SWITCH: for ( $aState ) {
    sfVisible == $_ and do {
      if ( $self->{owner}{state} & sfExposed ) {
        $self->setState( sfExposed, $enable );
      }
      if ( $enable ) {
        $self->drawShow( undef );
      }
      else {
        $self->drawHide( undef );
      }
      if ( $self->{options} & ofSelectable ) {
        $self->{owner}->resetCurrent();
      }
      last;
    };
    sfCursorVis == $_ || 
    sfCursorIns == $_ and do {
      $self->drawCursor();
      last;
    };
    sfShadow == $_ and do {
      $self->drawUnderView( true, undef );
      last;
    };
    sfFocused == $_ and do {
      $self->resetCursor();
      message(
        $self->{owner},
        evBroadcast,
        $enable ? cmReceivedFocus : cmReleasedFocus,
        $self
      );
      last;
    };
  } #/ SWITCH: for ( $aState )
  return;
} #/ sub setState

sub keyEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  do {
    $self->getEvent( $event );
  } while ( $event->{what} != evKeyDown );
  return;
}

sub mouseEvent { # bool ($event, $mask)
  state $sig = signature(
    method => Object,
    pos    => [Object, PositiveOrZeroInt],
  );
  my ( $self, $event, $mask ) = $sig->( @_ );
  do {
    $self->getEvent( $event );
  } while ( !( $event->{what} & ( $mask | evMouseUp ) ) );

  return $event->{what} != evMouseUp;
}

sub makeGlobal {    # $point ($source)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $source ) = $sig->( @_ );
  my $temp = $source + $self->{origin};
  my $cur  = $self;
  while ( $cur->{owner} ) {
    $cur = $cur->{owner};
    $temp += $cur->{origin};
  }
  return $temp;
} #/ sub makeGlobal

sub makeLocal {    # $point ($source)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $source ) = $sig->( @_ );
  my $temp = $source - $self->{origin};
  my $cur  = $self;
  while ( $cur->{owner} ) {
    $cur = $cur->{owner};
    $temp -= $cur->{origin};
  }
  return $temp;
} #/ sub makeLocal

sub nextView {    # $view|undef ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  no warnings qw( uninitialized numeric );
  return !$self->{owner} || $self == $self->{owner}{last}
    ? undef
    : $self->{next};
}

sub prevView {    # $view|undef ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  no warnings qw( uninitialized numeric );
  return !$self->{owner} || $self == $self->{owner}->first()
    ? undef 
    : $self->prev();
}

sub prev {    # $view|undef ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  no warnings qw( uninitialized numeric );
  my $res = $self;
  while ( $res->{next} != $self ) {
    return undef unless $res->{next};
    $res = $res->{next};
  }
  return $res;
}

sub next {    # $view|undef (|$view|undef)
  state $sig = signature(
    method => Object,
    pos    => [
      Maybe[Object], { optional => 1 },
    ],
  );
  my ( $self, $view ) = $sig->( @_ );
  goto SET if @_ > 1;
  GET: {
    return $self->{next};
  }
  SET: {
    &$unlock_value( $self->{next} ) if STRICT;
    $self->{next} = $view;
    &$lock_value( $self->{next} ) if STRICT;
    return;
  }
} #/ sub next

sub makeFirst {    # $void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->putInFrontOf( $self->{owner}->first() )
    if $self->{owner};
  return;
}

sub putInFrontOf {    # void ($target|undef)
  state $sig = signature(
    method => Object,
    pos    => [Maybe[Object]],
  );
  my ( $self, $target ) = $sig->( @_ );
  no warnings qw( uninitialized numeric );

  if ( $self->{owner}
    && $target != $self
    && $target != $self->nextView()
    && ( !$target || $target->{owner} == $self->{owner} ) )
  {
    if ( !( $self->{state} & sfVisible ) ) {
      $self->{owner}->removeView( $self );
      $self->{owner}->insertView( $self, $target );
    }
    else {
      my $lastView = $self->nextView();
      my $p        = $target;
      while ( $p && $p != $self ) {
        $p = $p->nextView();
      }
      $lastView = $target
        if !$p;
      $self->{state} &= ~sfVisible;
      $self->drawHide( $lastView )
        if $lastView == $target;
      $self->{owner}->removeView( $self );
      $self->{owner}->insertView( $self, $target );
      $self->{state} |= sfVisible;
      $self->drawShow( $lastView )
        if $lastView != $target;
      $self->{owner}->resetCurrent()
        if $self->{options} & ofSelectable;
    } #/ else [ if ( !( $self->{state}...))]
  } #/ if ( $self->{owner} &&...)
  return;
} #/ sub putInFrontOf

sub TopView {    # $view ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  return $TheTopView
    if $TheTopView;

  my $p = $self;
  while ( $p && !( $p->{state} & sfModal ) ) {
    $p = $p->{owner};
  }
  return $p;
} #/ sub TopView

sub writeBuf {    # void ($x, $y, $w, $h, $b)
  state $sig = signature(
    method => Object,
    pos    => [Int, Int, Int, Int, ArrayLike],
  );
  my ( $self, $x, $y, $w, $h, $b ) = $sig->( @_ );
  while ( $h-- > 0 ) {
    $self->$writeView( $x, $y++, $w, $b );
    alias: $b = sub { \@_ }->( @$b[ $w .. $#$b ] );
  }
  return;
}

my $setCell = sub {    # void ($cell, $ch, $attr)
  assert ( @_ == 3 );
  assert ( is_ScalarRef \$_[0] );
  assert ( is_Int $_[1] );
  assert ( is_Int $_[2] );
  $_[0] = ( ( $_[2] & 0xff ) << 8 ) | $_[1] & 0xff;
  return;
};

sub writeChar {    # void ($x, $y, $c, $color, $count)
  state $sig = signature(
    method => Object,
    pos    => [Int, Int, Str, PositiveOrZeroInt, Int],
  );
  my ( $self, $x, $y, $c, $color, $count ) = $sig->( @_ );
  my $attr = $self->mapColor( $color );
  if ( $count > 0 ) {
    &$setCell( my $cell, ord( $c ), $attr );
    my $buf = [ ( $cell ) x $count ];
    $self->$writeView( $x, $y, $count, $buf );
  }
  return;
}

sub writeLine {    # void ($x, $y, $w, $h, $b)
  state $sig = signature(
    method => Object,
    pos    => [Int, Int, Int, Int, ArrayLike],
  );
  my ( $self, $x, $y, $w, $h, $b ) = $sig->( @_ );
  while ( $h-- > 0 ) {
    $self->$writeView( $x, $y++, $w, $b );
  }
  return;
}

sub writeStr {    # void ($x, $y, $str, $color)
  state $sig = signature(
    method => Object,
    pos    => [Int, Int, Str, PositiveOrZeroInt],
  );
  my ( $self, $x, $y, $str, $color ) = $sig->( @_ );
  if ( $str ) {
    my $length = length( $str );
    if ( $length > 0 ) {
      my $attr = $self->mapColor( $color );
      my $buf  = [ ( 0 ) x maxViewWidth ];
      my $i    = 0;
      foreach my $c ( split //, $str ) {
        &$setCell( $buf->[$i], ord( $c ), $attr );
        $i++;
      }
      $self->$writeView( $x, $y, $length, $buf );
    } #/ if ( $length > 0 )
  } #/ if ( $str )
  return;
} #/ sub writeStr

sub owner {    # $group|undef (|$group|undef)
  state $sig = signature(
    method => Object,
    pos    => [
      Maybe[Object], { optional => 1 },
    ],
  );
  my ( $self, $group ) = $sig->( @_ );
  goto SET if @_ > 1;
  GET: {
    return $self->{owner};
  }
  SET: {
    &$unlock_value( $self->{owner} ) if STRICT;
    weaken $self->{owner}
      if $self->{owner} = $group;
    &$lock_value( $self->{owner} ) if STRICT;
  }
  return;
}

sub shutDown {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->hide();
  if ( $self->{owner} ) {
    $self->{owner}->remove( $self );
  }
  $self->SUPER::shutDown();
  return;
}

$moveGrow = sub {
  my ( $self, $p, $s, $limits, $minSize, $maxSize, $mode ) = @_;
  assert ( @_ == 7 );
  assert ( is_Object $self );
  assert ( is_Object $p );
  assert ( is_Object $s );
  assert ( is_HashLike $limits );
  assert ( is_HashLike $minSize );
  assert ( is_HashLike $maxSize );
  assert ( is_PositiveOrZeroInt $mode );

  $p = $p->clone();
  $s = $s->clone();

  $s->{x} = min( max( $s->{x}, $minSize->{x} ), $maxSize->{x} );
  $s->{y} = min( max( $s->{y}, $minSize->{y} ), $maxSize->{y} );
  $p->{x} = min(
    max( $p->{x}, $limits->{a}{x} - $s->{x} + 1 ),
    $limits->{b}{x} - 1
  );
  $p->{y} = min(
    max( $p->{y}, $limits->{a}{y} - $s->{y} + 1 ),
    $limits->{b}{y} - 1
  );

  if ( $mode & dmLimitLoX ) {
    $p->{x} = max( $p->{x}, $limits->{a}{x} );
  }
  if ( $mode & dmLimitLoY ) {
    $p->{y} = max( $p->{y}, $limits->{a}{y} );
  }
  if ( $mode & dmLimitHiX ) {
    $p->{x} = min( $p->{x}, $limits->{b}{x} - $s->{x} );
  }
  if ( $mode & dmLimitHiY ) {
    $p->{y} = min( $p->{y}, $limits->{b}{y} - $s->{y} );
  }

  my $r = TRect->new(
    ax => $p->{x},
    ay => $p->{y},
    bx => $p->{x} + $s->{x},
    by => $p->{y} + $s->{y},
  );
  $self->locate( $r );
  return;
}; #/ $moveGrow = sub

$change = sub {    # void ($mode, $delta, $p, $s, $ctrlState)
  my ( $self, $mode, $delta, $p, $s, $ctrlState ) = @_;
  assert ( @_ == 6 );
  assert ( is_Object $self );
  assert ( is_PositiveOrZeroInt $mode );
  assert ( is_Object $delta );
  assert ( is_Object $p );
  assert ( is_Object $s );
  assert ( is_PositiveOrZeroInt $ctrlState );
  if ( ( $mode & dmDragMove ) && !( $ctrlState & !kbShift ) ) {
    $p += $delta;
  }
  elsif ( ( $mode & dmDragGrow ) && ( $ctrlState & kbShift ) ) {
    $s += $delta;
  }
  return;
};

$writeView = sub {    # void ($x, $y, $count, $b)
  my ( $self, $x, $y, $count, $b ) = @_;
  assert ( @_ == 5 );
  assert ( is_Object $self );
  assert ( is_Int $x );
  assert ( is_Int $y );
  assert ( is_Int $count );
  assert ( is_ArrayLike $b );
  TUI::Views::View::Write::L0( $self, $x, $y, $count, $b );
  return;
};

1

__END__

=pod

=head1 NAME

TUI::Views::View - base class for all visual components in TUI::Vision

=head1 HIERARCHY

  TObject
    TView

=head1 SYNOPSIS

  use TUI::Views;

  my $view = TView->new(bounds => $bounds);
  $view->draw();
  $view->handleEvent($event);

=head1 DESCRIPTION

C<TView> is the fundamental base class for all visible objects in TUI::Vision.
Every visual component shown on the screen ultimately derives from C<TView>.

The class provides the core infrastructure required for drawing, event
handling, coordinate transformation, focus management, command processing,
and interaction with the owning view hierarchy. Most applications do not use
C<TView> directly but instead instantiate one of its many descendants such as
dialogs, windows, list viewers, or menu views.

C<TView> defines a large number of methods, many of which are intended for
internal use or for implementation by subclasses. Application code typically
interacts with C<TView> through state flags, command handling, drawing helpers,
and event dispatch.

The behavior and appearance of a view are controlled primarily through its
state, options, event mask, and geometry attributes.

=head2 Commonly Used Features

In day-to-day application code, the most relevant configuration fields are
C<growMode>, C<dragMode>, C<helpCtx>, C<state>, C<options>, and C<eventMask>.
They define resize behavior, input handling, help context, and event routing.

The methods most commonly touched outside framework internals are
C<clearEvent>, C<commandEnabled>, C<dataSize>, C<disableCommands>, C<draw>,
C<drawView>, C<enableCommands>, C<getColor>, C<getCommands>, C<getHelpCtx>,
C<getPalette>, C<getState>, C<hideCursor>, C<normalCursor>, C<select>,
C<setCommands>, C<setState>, C<show>, C<showCursor>, C<valid>, C<writeLine>,
and C<writeStr>.

=head1 VARIABLES

The following global variables define default behavior and visual
properties shared by all C<TView> objects.

=head2 $shadowSize

Default size of the view shadow, specified as a C<TPoint>.

=head2 $shadowAttr

Attribute value used when drawing view shadows.

=head2 $showMarkers

Controls whether focus and selection markers are displayed.

=head2 $specialChars

Array reference defining special navigation and marker characters.

=head2 $errorAttr

Attribute value used to render views in an error state.

=head2 $commandSetChanged

Indicates whether the active command set has been modified.

=head2 $curCommandSet

Holds the current default command set used for command enabling
and dispatch.

=head1 ATTRIBUTES

The following attributes define the geometry, state, and ownership of a view.
Unless otherwise noted, attributes are part of the public view state and may
be read or modified by application code.

=over

=item next

Internal link to the next view in the owner's Z-ordered view list.
This attribute is managed internally.

=item size

Size of the view as a C<TPoint>.

=item origin

Upper-left corner of the view relative to its owner.

=item cursor

Current cursor position within the view.

=item owner

Owning group of this view (I<TGroup>). This reference is managed internally.

=item options

View option flags (I<Int>), typically a combination of C<ofXXXX> constants.

=item eventMask

Event mask controlling which event classes are accepted by the view.

=item state

Current state flags of the view, such as visibility, selection, and cursor
mode (C<sfXXXX> constants).

=item growMode

Grow mode flags controlling how the view resizes when its owner changes size
(C<gfXXXX> constants).

=item dragMode

Drag behavior flags controlling how the view responds to mouse dragging
(C<dmXXXX> constants).

=item helpCtx

Help context identifier associated with the view.

=back

=head1 CONSTRUCTOR

=head2 new

  my $view = TView->new(bounds => $bounds);

Creates and initializes a new view with the specified bounding rectangle.
The view is created with default state, option, and event mask values.

=over

=item bounds

Bounding rectangle of the view (I<TRect>).

=back

=head2 new_TView

  my $view = new_TView($bounds);

Factory-style constructor using positional arguments.

This constructor is equivalent to calling C<new> with the C<bounds> parameter
and is provided for compatibility with traditional Turbo Vision construction
patterns.

=head1 DESTRUCTOR

=head2 DEMOLISH

  $self->DEMOLISH($in_global_destruction);

Destroys the view and removes it from the screen and the view hierarchy.
This method corresponds to the Turbo Vision destructor and is normally called
automatically by the owning group.

=head1 METHODS

C<TView> defines a comprehensive set of methods for drawing, event handling,
state management, and interaction with the view hierarchy. Many of these
methods are intended to be used by subclasses or internally by the framework.

=head2 new

  my $view = TView->new(bounds => $bounds);

Initializes an instance of C<TView> with the specified bounds.

=over

=item bounds

The bounds of the view (TRect).

=back

=head2 DEMOLISH

  $self->DEMOLISH();

=head2 TopView

  my $view = $self->TopView();

Returns the top view in the view hierarchy.

=head2 awaken

  $self->awaken();

Prepares the view for activation.

=head2 blockCursor

  $self->blockCursor();

Sets the cursor to block mode.

=head2 calcBounds

  $self->calcBounds($bounds, $delta);

Calculates the bounds of the view based on the given delta.

=head2 changeBounds

  $self->changeBounds($bounds);

Changes the bounds of the view.

=head2 clearEvent

  $self->clearEvent($event);

Clears the specified event.

=head2 commandEnabled

  my $bool = TView->commandEnabled($command);

Checks if the specified command is enabled.

=head2 containsMouse

  my $bool = $self->containsMouse($event);

Checks if the mouse is within the view's bounds.

=head2 dataSize

  my $size = $self->dataSize();

Returns the size of the view's data.

=head2 disableCommand

  $self->disableCommand($command);

Disables the specified command.

=head2 disableCommands

  $self->disableCommands($commands);

Disables the specified commands.

=head2 dragView

  $self->dragView($event, $mode, $limits, $minSize, $maxSize);

Handles the dragging of the view.

=head2 draw

  $self->draw();

Draws the view on the screen.

=head2 drawCursor

  $self->drawCursor();

Draws the cursor in the view.

=head2 drawHide

  $self->drawHide($lastView | undef);

Hides the view by drawing over it.

=head2 drawShow

  $self->drawShow($lastView | undef);

Shows the view by drawing it.

=head2 drawUnderRect

  $self->drawUnderRect($r, $lastView | undef);

Draws the view under the specified rectangle.

=head2 drawUnderView

  $self->drawUnderView($doShadow, $lastView | undef);

Draws the view under another view.

=head2 drawView

  $self->drawView();

Draws the view.

=head2 enableCommand

  $self->enableCommand($command);

Enables the specified command.

=head2 enableCommands

  $self->enableCommands($commands);

Enables the specified commands.

=head2 endModal

  $self->endModal($command);

Ends the modal state of the view.

=head2 eventAvail

  my $bool = $self->eventAvail();

Checks if an event is available.

=head2 execute

  my $cmd = $self->execute();

Executes the view.

=head2 exposed

  my $bool = $self->exposed();

Checks if the view is exposed.

=head2 focus

  my $bool = $self->focus();

Sets the focus to the view.

=head2 getBounds

  my $rect = $self->getBounds();

Returns the bounds of the view.

=head2 getClipRect

  my $rect = $self->getClipRect();

Returns the clipping rectangle of the view.

=head2 getColor

  my $int = $self->getColor($color);

Returns the color of the view.

=head2 getCommands

  $self->getCommands($commands);

Gets the commands of the view.

=head2 getData

  $self->getData(\@rec);

Returns the data of the view.

=head2 getEvent

  $self->getEvent($event);

Gets the specified event.

=head2 getExtent

  my $rect = $self->getExtent();

Returns the extent of the view.

=head2 getHelpCtx

  my $int = $self->getHelpCtx();

Returns the help context of the view.

=head2 getPalette

  my $palette = $self->getPalette();

Returns the view's color palette.

=head2 getState

  my $bool = $self->getState($aState);

Returns the state of the view.

=head2 growTo

  $self->growTo($x, $y);

Grows the view to the specified size.

=head2 handleEvent

  $self->handleEvent($event);

Handles an event sent to the view.

=head2 hide

  $self->hide();

Hides the view.

=head2 hideCursor

  $self->hideCursor();

Hides the cursor in the view.

=head2 keyEvent

  $self->keyEvent($event);

Handles a key event.

=head2 locate

  $self->locate($bounds);

Positions the view within the specified bounds.

=head2 makeFirst

  my $void = $self->makeFirst();

Moves the view to the front of the view hierarchy.

=head2 makeGlobal

  my $point = $self->makeGlobal($source);

Converts a local point to a global point.

=head2 makeLocal

  my $point = $self->makeLocal($source);

Converts a global point to a local point.

=head2 mapColor

  my $int = $self->mapColor($color);

Maps a color to the view's palette.

=head2 mouseEvent

  my $bool = $self->mouseEvent($event, $mask);

Handles a mouse event.

=head2 mouseInView

  my $bool = $self->mouseInView($mouse);

Checks if the mouse is within the view.

=head2 moveTo

  $self->moveTo($x, $y);

Moves the view to the specified position.

=head2 nextView

  my $view | undef = $self->nextView();

Returns the next view in the view hierarchy.

=head2 normalCursor

  $self->normalCursor();

Sets the cursor to normal mode.

=head2 prev

  my $view | undef = $self->prev();

Returns the previous view in the view hierarchy.

=head2 prevView

  my $view | undef = $self->prevView();

Returns the previous view in the view hierarchy.

=head2 putEvent

  $self->putEvent($event);

Puts an event in the event queue.

=head2 putInFrontOf

  $self->putInFrontOf($target | undef);

Puts the view in front of the specified target view.

=head2 resetCursor

  $self->resetCursor();

Resets the cursor in the view.

=head2 select

  $self->select();

Selects the view.

=head2 setBounds

  $self->setBounds($bounds);

Sets the bounds of the view to the specified values.

=head2 setCmdState

  $self->setCmdState($commands, $enable);

Sets the command state of the view.

=head2 setCommands

  $self->setCommands($commands);

Sets the commands of the view.

=head2 setCursor

  $self->setCursor($x, $y);

Sets the position of the cursor in the view to the specified values.

=head2 setData

  $self->setData($rec);

Sets the data of the view to the specified values.

=head2 setState

  $self->setState($aState, $enable);

Sets the state of the view to the specified value.

=head2 show

  $self->show();

Shows the view.

=head2 showCursor

  $self->showCursor();

Displays the cursor in the view.

=head2 shutDown

  $self->shutDown();

Shuts down the view.

=head2 sizeLimits

  $self->sizeLimits($min, $max);

Determines the minimum and maximum sizes of the view.

=head2 valid

  my $bool = $self->valid($command);

Checks if the view is valid for the specified command.

=head2 writeBuf

  $self->writeBuf($x, $y, $w, $h, $b);

Writes a buffer to the view.

=head2 writeChar

  $self->writeChar($x, $y, $c, $color, $count);

Writes a character to the view.

=head2 writeLine

  $self->writeLine($x, $y, $w, $h, $b);

Writes a line to the view.

=head2 writeStr

  $self->writeStr($x, $y, $str, $color);

Writes a string to the view.

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2021-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is 
part of the distribution). 

=cut
