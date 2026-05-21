package TUI::Drivers::Display;
# ABSTRACT: low-level display abstraction

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TDisplay
);

use Devel::StrictMode;
use PerlX::Assert::PP;
use Scalar::Util qw( looks_like_number );

use TUI::Drivers::HardwareInfo;

sub TDisplay() { __PACKAGE__ }

my $getCodePage = sub {
  if ( $^O eq 'MSWin32' ) {
    require Win32;
    return Win32::GetConsoleOutputCP();
  }
  return 437;
};

INIT {
  TDisplay->updateIntlChars()
}

sub updateIntlChars {    # void ($class)
  my $class = shift;
  assert ( $class and !ref $class );
  my $cp = &$getCodePage();
  # Some 8-bit code pages are supported directly.
  return 
    if $cp =~ /^(437|720|737|775|850|852|855|857|858|859|860|861|862|863|865)$/
    || $cp =~ /^(866|869)$/;

  require TUI::Views::Frame;
  require TUI::Views::ScrollBar;
  require TUI::Menus::MenuBox;
  require TUI::App::DeskTop;
  if ( $cp == 874 ) {
    $TUI::Views::Frame::frameChars    = "   ' :.+ '\x96+.+++   ' |.+ '\x97+.++ ";
    $TUI::Views::Frame::closeIcon     = "[~x~]";
    $TUI::Views::Frame::zoomIcon      = "[~+~]";
    $TUI::Views::Frame::unZoomIcon    = "[~-~]";
    $TUI::Views::Frame::dragIcon      = "~\x97'~";
    $TUI::Views::ScrollBar::vChars    = "^v # ";
    $TUI::Views::ScrollBar::hChars    = "<> # ";
    $TUI::Menus::MenuBox::frameChars  = " .-.  '-'  | |  +-+ ";
    $TUI::App::DeskTop::defaultBkgrnd = ":";
  }
  elsif ( $cp =~ /^(1250|1251|1252|1253|1254|1256|1257|1258)$/ ) {
    $TUI::Views::Frame::frameChars    = "   ' \xA6.+ '\x96+.+++   ' |.+ '\x97+.+"
                                     . "+ ";
    $TUI::Views::Frame::closeIcon     = "[~\xD7~]";
    $TUI::Views::Frame::zoomIcon      = "[~+~]";
    $TUI::Views::Frame::unZoomIcon    = "[~\xB1~]";
    $TUI::Views::Frame::dragIcon      = "~\x97'~";
    $TUI::Views::ScrollBar::vChars    = "^v \xA4 ";
    $TUI::Views::ScrollBar::hChars    = "<> \xA4 ";
    $TUI::Menus::MenuBox::frameChars  = " .\x97.  '\x97'  | |  +\x97+ ";
    $TUI::App::DeskTop::defaultBkgrnd = ":";
  }
  elsif ( $cp == 1255 ) {
    $TUI::Views::Frame::frameChars    = "   ' :.+ '\x96+.+++   ' |.+ '\x97+.++ ";
    $TUI::Views::Frame::closeIcon     = "[~x~]";
    $TUI::Views::Frame::zoomIcon      = "[~+~]";
    $TUI::Views::Frame::unZoomIcon    = "[~\xB1~]";
    $TUI::Views::Frame::dragIcon      = "~\x97'~";
    $TUI::Views::ScrollBar::vChars    = "^v # ";
    $TUI::Views::ScrollBar::hChars    = "<> # ";
    $TUI::Menus::MenuBox::frameChars  = " .\x97.  '\x97'  | |  +\x97+ ";
    $TUI::App::DeskTop::defaultBkgrnd = ":";
  }
  else {
    $TUI::Views::Frame::frameChars    = "   ' :.+ '-+.+++   ' |.+ '=+.++ ";
    $TUI::Views::Frame::closeIcon     = "[~x~]";
    $TUI::Views::Frame::zoomIcon      = "[~+~]";
    $TUI::Views::Frame::unZoomIcon    = "[~-~]";
    $TUI::Views::Frame::dragIcon      = "~-'~";
    $TUI::Views::ScrollBar::vChars    = "^v # ";
    $TUI::Views::ScrollBar::hChars    = "<> # ";
    $TUI::Menus::MenuBox::frameChars  = " .-.  '-'  | |  +-+ ";
    $TUI::App::DeskTop::defaultBkgrnd = ":";
  }
  return;
} #/ sub updateIntlChars

sub getCursorType {    # $size ($class)
  assert ( $_[0] and !ref $_[0] );
  return THardwareInfo->getCaretSize();
}

sub setCursorType {    # void ($class, $ct)
  my ( $class, $ct ) = @_;
  assert ( $class and !ref $class );
  assert ( looks_like_number $ct );
  THardwareInfo->setCaretSize( $ct & 0xff );
  return;
}

sub clearScreen {    # void ($class, $w, $h)
  my ( $class, $w, $h ) = @_;
  assert ( $class and !ref $class );
  assert ( looks_like_number $w );
  assert ( looks_like_number $h );
  THardwareInfo->clearScreen( $w, $h );
  return;
}

sub getRows {    # $rows ($class)
  assert ( $_[0] and !ref $_[0] );
  return THardwareInfo->getScreenRows();
}

sub getCols {    # $cols ($class)
  assert ( $_[0] and !ref $_[0] );
  return THardwareInfo->getScreenCols();
}

sub getCrtMode {    # void ($class)
  assert ( $_[0] and !ref $_[0] );
  return THardwareInfo->getScreenMode();
}

sub setCrtMode {    # void ($class, $mode)
  my ( $class, $mode ) = @_;
  assert ( $class and !ref $class );
  assert ( looks_like_number $mode );
  THardwareInfo->setScreenMode( $mode );
  return;
}

1

__END__

=pod

=head1 NAME

TUI::Drivers::Display - low-level display abstraction

=head1 SYNOPSIS

  use TUI::Drivers::Display;

  # TDisplay is used as a static driver facade.
  my $cols = TDisplay->getCols();
  my $rows = TDisplay->getRows();

  my $mode = TDisplay->getCrtMode();
  TDisplay->setCrtMode($mode);

  my $cursor = TDisplay->getCursorType();
  TDisplay->setCursorType($cursor);

  TDisplay->clearScreen($cols, $rows);

=head1 DESCRIPTION

C<TDisplay> provides a low-level abstraction layer for screen and
cursor operations used by the TUI::Vision driver subsystem.

The module defines a set of class-level routines for querying and modifying
display parameters such as screen size, cursor shape, and video mode. It does
not maintain any internal state of its own.

C<TDisplay> is not an object-oriented class. It must not be instantiated.
All interaction is performed via class method calls of the form
C<< TDisplay->method >>.

This module is primarily used internally by C<TScreen> and related driver
components.

=head2 Commonly Used Features

Most code interacts with C<TDisplay> through class-style calls to query and
control the terminal state: C<getCols()>, C<getRows()>, C<getCrtMode()>,
C<setCrtMode()>, C<getCursorType()>, C<setCursorType()>, and C<clearScreen()>.

C<TDisplay> is a thin abstraction over C<THardwareInfo> and is generally used
inside the driver stack (for example C<TScreen>) rather than directly in
application dialogs or views. The C<updateIntlChars()> routine adjusts frame,
scrollbar, and desktop drawing characters based on the active code page.

=head1 METHODS

=head2 clearScreen

  TDisplay->clearScreen($width, $height);

Clears the display using the specified screen dimensions.

=head2 getCols

  my $cols = TDisplay->getCols();

Returns the current number of screen columns.

=head2 getRows

  my $rows = TDisplay->getRows();

Returns the current number of screen rows.

=head2 getCrtMode

  my $mode = TDisplay->getCrtMode();

Returns the current CRT video mode.

=head2 setCrtMode

  TDisplay->setCrtMode($mode);

Sets the CRT video mode.

=head2 getCursorType

  my $type = TDisplay->getCursorType();

Returns the current cursor shape encoding.

=head2 setCursorType

  TDisplay->setCursorType($type);

Sets the cursor shape using a hardware-specific encoding.

=head2 updateIntlChars

  TDisplay->updateIntlChars();

Updates the display's international character mappings.

=head1 SEE ALSO

L<TUI::Drivers::Screen>,
L<TUI::Drivers::HardwareInfo>

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
