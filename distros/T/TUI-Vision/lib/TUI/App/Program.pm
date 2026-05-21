package TUI::App::Program;
# ABSTRACT: Central program object handling events, menus and desktop

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TProgram
  new_TProgram
);
our @EXPORT_OK = qw(
  $application
  $deskTop
);

use Carp ();
use List::Util qw( min );
use Scalar::Util qw(
  weaken
  isweak
);
use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  :is
  :types
);

use TUI::App::Const qw( 
  :apXXXX
  :cpXXXX
);
use TUI::App::DeskTop;
use TUI::App::ProgInit;
use TUI::Drivers::Const qw( 
  :evXXXX
  :kbXXXX
  :smXXXX
);
use TUI::Drivers::Event;
use TUI::Drivers::EventQueue;
use TUI::Drivers::Screen;
use TUI::Drivers::Util qw( getAltChar );
use TUI::Menus::MenuBar;
use TUI::Menus::StatusDef;
use TUI::Menus::StatusItem;
use TUI::Menus::StatusLine;
use TUI::Memory::Util qw( lowMemory );
use TUI::Objects::Point;
use TUI::Objects::Rect;
use TUI::Views::Const qw( 
  :cmXXXX
  :sfXXXX
  maxViewWidth
);
use TUI::Views::Palette;
use TUI::Views::Group;
use TUI::Views::Util qw( message );
use TUI::Views::View;

sub TProgram() { __PACKAGE__ }
sub new_TProgram { __PACKAGE__->from(@_) }

extends ( TGroup, TProgInit );

# declare global variables
our $exitText = "~Alt-X~ Exit";
our $application;
our $statusLine;
our $menuBar;
our $deskTop;
our $appPalette = 0;
our $pending = TEvent->new();

# import global variables
use vars qw(
  $mouse
  $screenBuffer
  $screenHeight
  $screenMode
  $screenWidth
  $commandSetChanged
  $showMarkers
  $shadowSize
);
{
  no strict 'refs';
  *mouse             = \${ TEventQueue . '::mouse' };
  *screenBuffer      = \${ TScreen . '::screenBuffer' };
  *screenHeight      = \${ TScreen . '::screenHeight' };
  *screenMode        = \${ TScreen . '::screenMode' };
  *screenWidth       = \${ TScreen . '::screenWidth' };
  *commandSetChanged = \${ TView . '::commandSetChanged' };
  *showMarkers       = \${ TView . '::showMarkers' };
  *shadowSize        = \${ TView . '::shadowSize' };
}

sub BUILDARGS {    # \%args ()
  state $sig = signature(
    method => 1,
    named  => [],
    caller_level => +1,
  );
  my ( $class ) = $sig->( @_ );
  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  my $args1 = TGroup->BUILDARGS(
    bounds => TRect->new(
      ax => 0,
      ay => 0,
      bx => min( $screenWidth, maxViewWidth ),
      by => $screenHeight,
    )
  );
  my $args2 = TProgInit->BUILDARGS(
    cStatusLine => $class->can( 'initStatusLine' ),
    cMenuBar    => $class->can( 'initMenuBar' ),
    cDeskTop    => $class->can( 'initDeskTop' ),
  );
  return { %$args1, %$args2 };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $application = $self;
  $self->initScreen();
  $self->{state}   = sfVisible | sfSelected | sfFocused | sfModal | sfExposed;
  $self->{options} = 0;
  $self->{buffer}  = $screenBuffer;

  if ( $self->{createDeskTop}
    && ( $deskTop = $self->createDeskTop( $self->getExtent() ) ) 
  ) {
    $self->insert( $deskTop );
  }
  if ( $self->{createStatusLine}
    && ( $statusLine = $self->createStatusLine( $self->getExtent() ) ) 
  ) {
    $self->insert( $statusLine );
  }
  if ( $self->{createMenuBar}
    && ( $menuBar = $self->createMenuBar( $self->getExtent() ) ) 
  ) {
    $self->insert( $menuBar );
  }
  return;
}

sub from {    # $obj ()
  state $sig = signature(
    method => 1,
    pos    => [],
  );
  my ( $class ) = $sig->( @_ );
  return $class->new();
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $application = undef;
  return;
}

sub canMoveFocus {    # $bool ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  return $deskTop->valid( cmReleasedFocus );
}

sub executeDialog {    # $int ($pD, \@data|undef)
  state $sig = signature(
    method => Object,
    pos    => [
      Object,
      Maybe[ArrayLike], { optional => 1 },
    ],
  );
  my ( $self, $pD, $data ) = $sig->( @_ );
  alias: for $pD ( $_[1] ) {
  my $c = cmCancel;

  if ( $self->validView( $pD ) ) {
    $pD->setData( $data ) 
      if $data;
    $c = $deskTop->execView( $pD );
    $pD->getData( $data ) 
      if ( $c != cmCancel && $data );
    $self->destroy( $pD );
  }

  return $c;
  } #/ alias
} #/ sub executeDialog

my $hasMouse = sub {    # $bool ($p, $s)
  my ( $p, $s ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $p );
  assert ( is_Object $s );
  return ( $p->{state} & sfVisible ) && $p->mouseInView( $s->{mouse}{where} );
};

sub getEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  if ( $pending->{what} != evNothing ) {
    $event->assign( $pending );
    $pending->{what} = evNothing;
  }
  else {
    $event->getMouseEvent();
    if ( $event->{what} == evNothing ) {
      $event->getKeyEvent();
      $self->idle() 
        if $event->{what} == evNothing;
    }
  }

  if ( $statusLine ) {
    no warnings 'uninitialized';
    if (
      ( $event->{what} & evKeyDown )
      || ( ( $event->{what} & evMouseDown )
        && $self->firstThat( $hasMouse, $event ) == $statusLine )
    ) {
      $statusLine->handleEvent( $event );
    }
  } #/ if ( $self->{statusLine...})
  return;
} #/ sub getEvent

sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  state $color = TPalette->new(
    data => cpAppColor, 
    size => length( cpAppColor ) 
  );
  state $blackwhite = TPalette->new( 
    data => cpAppBlackWhite, 
    size => length( cpAppBlackWhite ) 
  );
  state $monochrome = TPalette->new( 
    data => cpAppMonochrome, 
    size => length( cpAppMonochrome ) 
  );
  state $palettes = [ $color, $blackwhite, $monochrome ];
  return $palettes->[$appPalette]->clone();
} #/ sub getPalette

sub handleEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  if ( $event->{what} == evKeyDown ) {
    my $c = getAltChar( $event->{keyDown}{keyCode} );
    if ( $c ge '1' && $c le '9' ) {
      if ( $self->canMoveFocus() ) {    # <--- Check valid first.
        if ( message( $deskTop, evBroadcast, cmSelectWindowNum, 
              chr( ord( $c ) - ord( '0' ) ) ) 
        ) {
          $self->clearEvent( $event );
        }
      } #/ if ( $self->canMoveFocus...)
      else {
        $self->clearEvent( $event );
      }
    } #/ if ( $c ge '1' && $c le...)
  } #/ if ( $event->{what} eq...)

  $self->SUPER::handleEvent( $event );
  if ( $event->{what} == evCommand && $event->{message}{command} == cmQuit ) {
    $self->endModal( cmQuit );
    $self->clearEvent( $event );
  }
  return;
} #/ sub handleEvent

sub idle {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $statusLine->update() 
    if $statusLine;

  if ( $commandSetChanged ) {
    message( $self, evBroadcast, cmCommandSetChanged, 0 );
    $commandSetChanged = false;
  }
  return;
}

sub initScreen { # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  if ( ( $screenMode & 0x00FF ) != smMono ) {
    if ( $screenMode & smFont8x8 ) {
      $shadowSize->{x} = 1;
    }
    else {
      $shadowSize->{x} = 2;
    }
    $shadowSize->{y} = 1;
    $showMarkers = false;
    if ( ( $screenMode & 0x00FF ) == smBW80 ) {
      $appPalette = apBlackWhite;
    }
    else {
      $appPalette = apColor;
    }
  } #/ if ( ( $screenMode & 0x00FF...))
  else {
    $shadowSize->{x} = 0;
    $shadowSize->{y} = 0;
    $showMarkers     = true;
    $appPalette      = apMonochrome;
  }
  return;
} #/ sub initScreen

sub outOfMemory {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  # Handle out of memory
  return;
}

sub putEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  $pending = $event->clone();
  return;
}

sub run {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->execute();
  return;
}

sub insertWindow {    # $window|undef ($pWin)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $pWin ) = $sig->( @_ );
  alias: for $pWin ( $_[1] ) {
  if ( $self->validView( $pWin ) ) {
    if ( $self->canMoveFocus() ) {
      $deskTop->insert( $pWin );
      return $pWin;
    }
    else {
      $self->destroy( $pWin );
    }
  }
  return undef;
  } #/ alias
} #/ sub insertWindow

sub setScreenMode { # void ($mode)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  my ( $self, $mode ) = $sig->( @_ );
  my $r;

  $mouse->hide();
  TScreen->setVideoMode( $mode );
  $self->initScreen();
  $self->{buffer} = $screenBuffer;
  $r = TRect->new( ax => 0, bx => 0, ay => $screenWidth, by => $screenHeight );
  $self->changeBounds( $r );
  $self->setState( sfExposed, 0 );
  $self->setState( sfExposed, 1 );
  $self->redraw();
  $mouse->show();
  return;
} #/ sub setScreenMode

sub shutDown {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  weaken $application 
    if $application 
    && !isweak $application;
  $statusLine = undef;
  $menuBar    = undef;
  $deskTop    = undef;
  $self->SUPER::shutDown();
  # TVMemMgr->clearSafetyPool();
  return;
} #/ sub shutDown

sub suspend {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  return;
}

sub resume {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  return;
}

sub initStatusLine {    # $statusLine ($r)
  state $sig = signature(
    method => 1,
    pos    => [Object],
  );
  my ( $class, $r ) = $sig->( @_ );
  $r->{a}{y} = $r->{b}{y} - 1;
  return TStatusLine->from( $r,
    TStatusDef->from( 0, 0xFFFF ) +
      TStatusItem->from( $exitText, kbAltX,   cmQuit ) +
      TStatusItem->from( '',        kbF10,    cmMenu ) +
      TStatusItem->from( '',        kbAltF3,  cmClose ) +
      TStatusItem->from( '',        kbF5,     cmZoom ) +
      TStatusItem->from( '',        kbCtrlF5, cmResize )
  );
} #/ sub initStatusLine

sub initMenuBar {    # $menuBar ($r)
  state $sig = signature(
    method => 1,
    pos    => [Object],
  );
  my ( $class, $r ) = $sig->( @_ );
  $r->{b}{y} = $r->{a}{y} + 1;
  return TMenuBar->new( bounds => $r, menu => undef );
}

sub initDeskTop {    # $deskTop ($r)
  state $sig = signature(
    method => 1,
    pos    => [Object],
  );
  my ( $class, $r ) = $sig->( @_ );
  $r->{a}{y}++;
  $r->{b}{y}--;
  return TDeskTop->new( bounds => $r );
}

sub validView {    # $view|undef ($view|undef)
  state $sig = signature(
    method => Object,
    pos    => [Maybe[Object]],
  );
  my ( $self, $p ) = $sig->( @_ );
  alias: for $p ( $_[1] ) {
  return undef unless $p;
  if ( lowMemory() ) {
    $self->destroy( $p );
    $self->outOfMemory();
    return undef;
  }
  unless ( $p->valid( cmValid ) ) {
    $self->destroy( $p );
    return undef;
  }
  return $p;
  } #/ alias: for my $p
} #/ sub validView

1

__END__

=pod

=head1 NAME

TUI::App::Program - central program object managing application execution

=head1 HIERARCHY

  TObject
    TView
      TGroup
        TProgram
          TApplication

=head1 SYNOPSIS

  use TUI::App;
  use TUI::Drivers;
  use TUI::Menus;

  package MyProgram;
  extends TProgram;

  sub initMenuBar {
    my ( $class, $r ) = @_;
    $r->{b}{y} = $r->{a}{y} + 1;
    return new_TMenuBar(
      $r,
      new_TSubMenu( '~F~ile', 0, 0 ) +
      new_TMenuItem( 'E~x~it', cmQuit, kbAltX, 0, 'Alt-X' )
    );
  }

  sub initStatusLine {
    my ( $class, $r ) = @_;
    $r->{a}{y} = $r->{b}{y} - 1;
    return new_TStatusLine(
      $r,
      new_TStatusDef( 0, 0xFFFF ) +
      new_TStatusItem( '~Alt-X~ Exit', kbAltX, cmQuit )
    );
  }

  package main;

  my $program = MyProgram->new();
  $program->run();

=head1 DESCRIPTION

C<TProgram> implements the core functionality of a TUI::Vision application.
It manages the event loop, screen initialization, desktop, menu bar, and status
line.

Most applications derive from C<TApplication>, which extends C<TProgram> with
additional behavior. However, it is also possible to derive an application
directly from C<TProgram>.

C<TProgram> owns all top-level views of the application and coordinates event
dispatch, idle processing, and shutdown.

=head2 Commonly Used Features

In normal applications you instantiate a C<TProgram>-derived class and call
C<run>; most day-to-day customization happens by overriding C<initMenuBar>,
C<initStatusLine>, C<handleEvent>, and sometimes C<idle>. C<TProgram> wires
the desktop, menu bar, and status line during construction, then drives the
main event loop for you. While many projects derive from C<TApplication>, the
same workflow applies because C<TApplication> builds directly on this class.

=head1 VARIABLES

The following global variables are used by C<TProgram> and its subclasses
to access application state and top-level views.

=head2 $exitText

Label text for the standard application exit command, including optional
accelerator markers.

=head2 $application

Reference to the running application object (usually C<TApplication>).

=head2 $statusLine

Reference to the application's C<TStatusLine> instance.

=head2 $menuBar

Reference to the application's C<TMenuBar> instance.

=head2 $deskTop

Reference to the application's C<TDeskTop> container.

=head2 $appPalette

Index of the active application color palette.

=head2 $pending

Pending C<TEvent> object queued for later processing.

=head1 CONSTRUCTOR

=head2 new

  my $program = TProgram->new();

Creates a new program object and initializes TUI::Vision support.

This constructor corresponds to the Turbo Vision 2.0 constructor and calls
C<initScreen>, C<initDeskTop>, C<initMenuBar>, and C<initStatusLine>.

=head2 new_TProgram

  my $program = new_TProgram();

Factory-style constructor using positional arguments.

This constructor is provided for compatibility with traditional Turbo Vision
construction patterns.

=head1 DESTRUCTOR

=head2 DEMOLISH

  $self->DEMOLISH($in_global_destruction);

Releases application-level resources during object destruction.

This method is part of the Perl object lifecycle and ensures that internal
references to the desktop, menu bar, and status line are released when the
program object is destroyed.

=head1 METHODS

=head2 canMoveFocus

  my $bool = $program->canMoveFocus();

Returns true if the focus can be moved between views.

=head2 executeDialog

  my $command = $program->executeDialog($dialog, \@data | undef);

Executes a dialog modally and returns the resulting command.

=head2 getEvent

  $program->getEvent($event);

Retrieves the next input event and dispatches it to the appropriate view.

=head2 getPalette

  my $palette = $program->getPalette();

Returns the current application-level color palette.

=head2 handleEvent

  $program->handleEvent($event);

Handles application-level events.

Applications typically override this method and call the inherited
implementation first.

=head2 idle

  $program->idle();

Performs background processing during idle periods.

=head2 initDeskTop

  my $desktop = $program->initDeskTop($rect);

Initializes the desktop view.

=head2 initMenuBar

  my $menuBar = $program->initMenuBar($rect);

Initializes the menu bar.

=head2 initScreen

  $program->initScreen();

Initializes screen mode dependent settings.

=head2 initStatusLine

  my $statusLine = $program->initStatusLine($rect);

Initializes the status line.

=head2 insertWindow

  my $window = $program->insertWindow($window);

Inserts a window into the desktop.

=head2 outOfMemory

  $program->outOfMemory();

Handles low-memory conditions.

=head2 putEvent

  $program->putEvent($event);

Places an event back into the event queue.

=head2 resume

  $program->resume();

Resumes execution after suspension.

=head2 run

  $program->run();

Starts the main application event loop.

=head2 setScreenMode

  $program->setScreenMode($mode);

Changes the application screen mode.

=head2 shutDown

  $program->shutDown();

Shuts down the application and releases resources.

=head2 suspend

  $program->suspend();

Suspends application execution.

=head2 validView

  my $view = $program->validView($view | undef);

Validates a newly created view and handles low-memory conditions.

=head1 SEE ALSO

L<TUI::App::Application>,
L<TUI::Views::View>,
L<TUI::Views::Group>

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

