package TUI::Drivers::Screen;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TScreen
);

use PerlX::Assert::PP;
use Scalar::Util qw( looks_like_number );
use TUI::toolkit::boolean;

use TUI::Drivers::Const qw( :smXXXX );
use TUI::Drivers::Display;
use TUI::Drivers::HardwareInfo;
use TUI::Drivers::Mouse;

sub TScreen() { __PACKAGE__ }

use parent TDisplay;

our $startupMode    = 0xffff;
our $startupCursor  = 0;
our $screenMode     = 0;
our $screenWidth    = 0;
our $screenHeight   = 0;
our $hiResScreen    = false;
our $checkSnow      = true;
our $screenBuffer   = [];
our $cursorLines    = 0;
our $clearOnSuspend = true;

INIT {
  $startupMode   = TScreen->getCrtMode();
  $startupCursor = TScreen->getCursorType();
  $screenBuffer  = THardwareInfo->allocateScreenBuffer()
    if THardwareInfo->can('allocateScreenBuffer');
  TScreen->setCrtData();
}

sub END {
  TScreen->suspend();
  THardwareInfo->freeScreenBuffer( $screenBuffer ) 
    if THardwareInfo->can('freeScreenBuffer');
}

sub resume {    # void ($class)
  my $class = shift;
  assert ( $class and !ref $class );
  $startupMode   = $class->getCrtMode();
  $startupCursor = $class->getCursorType();
  if ( $screenMode != $startupMode ) {
    $class->setCrtMode( $screenMode );
  }
  $class->setCrtData();
  return;
} #/ sub resume

sub suspend {    # void ($class)
  my $class = shift;
  assert ( $class and !ref $class );
  if ( $startupMode != $class->getCrtMode() ) {
    $class->setCrtMode( $startupMode );
  }
  if ( $clearOnSuspend ) {
    $class->clearScreen();
  }
  $class->setCursorType( $startupCursor );
  return;
} #/ sub suspend

sub fixCrtMode {    # $mode ($class, $mode)
  my ( $class, $mode ) = @_;
  assert ( $class and !ref $class );
  assert ( looks_like_number $mode );
  if ( THardwareInfo->getPlatform() eq 'Windows' ) {
    $mode = ( $mode & smFont8x8 ) ? smCO80 | smFont8x8 : smCO80;
    return $mode;
  }
  if ( ( $mode & 0xff ) == smMono ) {    # Strip smFont8x8 if necessary.
    return smMono;
  }
  return $mode;
} #/ sub fixCrtMode

sub setCrtData {    # void ($class)
  my $class = shift;
  assert ( $class and !ref $class );
  $screenMode   = $class->getCrtMode();
  $screenWidth  = $class->getCols();
  $screenHeight = $class->getRows();
  $hiResScreen  = $screenHeight > 25;

  $cursorLines = $class->getCursorType();
  $class->setCursorType( 0 );
  return;
} #/ sub setCrtData

sub clearScreen {    # void ($class)
  assert ( $_[0] and !ref $_[0] );
  TDisplay->clearScreen( $screenWidth, $screenHeight );
}

sub setVideoMode {    # void ($class, $mode)
  my ( $class, $mode ) = @_;
  assert ( $class and !ref $class );
  assert ( looks_like_number $mode );
  $class->setCrtMode( $class->fixCrtMode( $mode ) );
  $class->setCrtData();
  if ( TMouse->present() ) {
    TMouse->setRange( $class->getCols() - 1, $class->getRows() - 1 );
  }
  return;
}

1

__END__

=pod

=head1 NAME

TUI::Drivers::Screen - global screen and video mode management

=head1 SYNOPSIS

  use TUI::Drivers::Screen;
  use TUI::Drivers::Const qw( smCO80 smFont8x8 );

  # Initialize driver-side screen state.
  TScreen->resume();

  # Select an 80x50 style text mode (platform-adjusted by fixCrtMode).
  TScreen->setVideoMode( smCO80 | smFont8x8 );

  # Optional explicit clear.
  TScreen->clearScreen();

  # Restore startup mode/cursor on shutdown.
  TScreen->suspend();

=head1 DESCRIPTION

C<TScreen> provides global screen and video mode management
facilities used by the TUI::Vision driver layer.

The module maintains global state describing the current screen configuration
and provides class-level routines to suspend, resume, and reinitialize the
video subsystem.

C<TScreen> is not an object-oriented class. It is not instantiated and does
not represent a view. All interaction is performed through class method calls
of the form C<TScreen-E<gt>method>.

=head2 Commonly Used Features

In normal application flow, C<TScreen> is primarily used to coordinate screen
lifecycle transitions (C<resume()> and C<suspend()>) and to switch video mode
via C<setVideoMode()>.

When a mode change occurs, the module refreshes shared screen state such as
C<$screenWidth>, C<$screenHeight>, and C<$hiResScreen>, and updates mouse range
through C<TMouse> when mouse support is available.

=head1 VARIABLES

=head2 $startupMode

Stores the screen mode that was active before TUI::Vision initialized the
video system.

This value is used to restore the original screen mode when TUI::Vision
suspends or terminates.

=head2 $startupCursor

Stores the initial cursor shape before TUI::Vision modifies the cursor.

=head2 $screenMode

Holds the current screen mode requested by the application.

=head2 $screenWidth

Contains the current screen width in character columns.

Typical values are 80 or similar.

=head2 $screenHeight

Contains the current screen height in text rows.

Typical values are 25, 43, or 50 depending on the selected video mode.

=head2 $hiResScreen

Indicates whether a high-resolution text mode is active.

=head2 $checkSnow

Controls CGA snow checking behavior.

If true, TUI::Vision performs additional checks to avoid display artifacts on
older CGA adapters. This variable should not be modified before application
initialization has completed.

=head2 $screenBuffer

Reference to the internal screen buffer.

This variable is initialized during screen setup and tracks the location of
the video memory buffer.

=head2 $cursorLines

Encodes the current cursor shape.

The high nibble represents the top scan line, and the low nibble represents
the bottom scan line of the cursor.

=head2 $clearOnSuspend

Controls whether the screen is cleared when the video subsystem is suspended.

=head1 METHODS

=head2 clearScreen

  TScreen->clearScreen();

Clears the screen after the video subsystem has been resumed.

Most applications do not need to call this method explicitly.

=head2 fixCrtMode

  my $mode = TScreen->fixCrtMode($mode);

Adjusts the supplied screen mode value to match hardware constraints.

=head2 setVideoMode

  TScreen->setVideoMode($mode);

Selects a new screen mode.

This method changes the screen color mode and optionally the screen height.
Typically, applications should call C<TProgram-E<gt>setScreenMode> instead,
which performs additional updates such as palette and mouse repositioning.

=head2 suspend

  TScreen->suspend();

Suspends TUI::Vision video support and restores the original screen state.

This method is called automatically during application shutdown.

=head2 resume

  TScreen->resume();

Initializes the TUI::Vision video subsystem and switches the display to the
mode specified by C<$screenMode>.

This method initializes C<$screenWidth>, C<$screenHeight>, C<$hiResScreen>,
C<$checkSnow>, C<$screenBuffer>, and C<$cursorLines>.

=head1 SEE ALSO

L<TUI::App::Program>,
L<TUI::Drivers::Display>,
L<TUI::Drivers::HardwareInfo>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 CONTRIBUTORS

Contributors are documented in the POD of the respective framework modules.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2021-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
