package TUI::Drivers::HardwareInfo;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw( THardwareInfo );

# Code snippet taken from File::Spec
my %module = (
  MSWin32 => 'Win32',
);

my $module = $module{$^O} || 'Unix';

sub THardwareInfo() { "TUI::Drivers::HardwareInfo::$module" }

require "TUI/Drivers/HardwareInfo/$module.pm";
our @ISA = ( THardwareInfo );

1

__END__

=pod

=head1 NAME

TUI::Drivers::HardwareInfo - platform-independent hardware interface dispatcher

=head1 SYNOPSIS

  use TUI::Drivers::HardwareInfo;

  my $hw = THardwareInfo;

  my $ticks = $hw->getTickCount();
  my $cols  = $hw->getScreenCols();
  my $rows  = $hw->getScreenRows();

=head1 DESCRIPTION

C<THardwareInfo> provides the platform-independent entry point for
hardware-related operations used by the TUI::Vision driver layer.

This module does not implement any hardware access itself. Instead, it selects
and loads a platform-specific backend at runtime and exposes it under the
symbolic name C<THardwareInfo>.

All calls made through C<THardwareInfo> are delegated directly to the active
backend implementation.

This module contains the public interface documentation for the
C<THardwareInfo> symbol. Backend modules provide platform-specific
implementation details.

C<THardwareInfo> must not be instantiated.

=head2 Commonly Used Features

Typical code uses C<THardwareInfo> as a static interface for low-level driver
queries and operations, for example: reading screen dimensions
(C<getScreenCols()>/C<getScreenRows()>), checking timing
(C<getTickCount()>), reading platform information (C<getPlatform()>), and
performing caret/screen operations needed by the event and display layers.

In normal application code, these methods are usually accessed indirectly
through higher-level modules such as C<TScreen>, C<TDisplay>, C<TEventQueue>,
and mouse/system-error wrappers.

=head1 PLATFORM DISPATCH

At load time, the module determines the active operating system and loads the
corresponding backend module.

Current backend availability in this distribution:

- Windows systems: C<TUI::Drivers::HardwareInfo::Win32>
- Non-Windows systems: no backend module is currently shipped

As of now, this dispatcher is effectively Win32-only. Attempting to load
C<THardwareInfo> on unsupported platforms will fail until additional backend
implementations are added.

Calling code must always refer to the interface via the C<THardwareInfo>
symbol and must not depend on platform-specific module names.

=head1 METHODS

=head2 getPlatform

  my $os = THardwareInfo->getPlatform();

Returns the platform name string.

=head2 getTickCount

  my $ticks = THardwareInfo->getTickCount();

Returns the system tick count.

=head2 clearPendingEvent

  THardwareInfo->clearPendingEvent();

Clears any buffered input event.

=head2 getKeyEvent

  my $bool = THardwareInfo->getKeyEvent($event);

Retrieves the next keyboard event and stores it in the supplied event structure.

=head2 getMouseEvent

  my $bool = THardwareInfo->getMouseEvent($event);

Retrieves the next mouse event and stores it in the supplied event structure.

=head2 getButtonCount

  my $count = THardwareInfo->getButtonCount();

Returns the number of mouse buttons detected.

=head2 getScreenCols

  my $cols = THardwareInfo->getScreenCols();

Returns the number of screen columns.

=head2 getScreenRows

  my $rows = THardwareInfo->getScreenRows();

Returns the number of screen rows.

=head2 getScreenMode

  my $mode = THardwareInfo->getScreenMode();

Returns the current screen mode.

=head2 setScreenMode

  THardwareInfo->setScreenMode($mode);

Sets the screen mode.

=head2 clearScreen

  THardwareInfo->clearScreen($width, $height);

Clears the screen using the specified dimensions.

=head2 allocateScreenBuffer

  my @buffer = THardwareInfo->allocateScreenBuffer();

Allocates a screen buffer suitable for bulk screen updates.

=head2 freeScreenBuffer

  THardwareInfo->freeScreenBuffer(\@buffer);

Releases a previously allocated screen buffer.

=head2 screenWrite

  THardwareInfo->screenWrite($x, $y, $buffer, $len);

Writes raw character data to the screen.

=head2 cursorOn

  THardwareInfo->cursorOn();

Makes the text cursor visible.

=head2 cursorOff

  THardwareInfo->cursorOff();

Hides the text cursor.

=head2 getCaretSize

  my $size = THardwareInfo->getCaretSize();

Returns the current caret size encoding.

=head2 setCaretSize

  THardwareInfo->setCaretSize($size);

Sets the caret size encoding.

=head2 setCaretPosition

  THardwareInfo->setCaretPosition($x, $y);

Sets the caret position.

=head2 isCaretVisible

  my $bool = THardwareInfo->isCaretVisible();

Returns true if the caret is visible.

=head2 setCtrlBrkHandler

  my $ok = THardwareInfo->setCtrlBrkHandler($install);

Installs or removes the Ctrl-Break handler.

=head2 setCritErrorHandler

  my $ok = THardwareInfo->setCritErrorHandler($install);

Installs or removes the critical error handler.

=head1 SEE ALSO

L<TUI::Drivers::HardwareInfo::Win32>,
L<TUI::Drivers::Screen>,
L<TUI::Drivers::HWMouse>,
L<TUI::Drivers::SystemError>

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
