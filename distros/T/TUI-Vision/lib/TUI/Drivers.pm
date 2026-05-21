package TUI::Drivers;

use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Import::Into;

use TUI::Drivers::Const;
use TUI::Drivers::HardwareInfo;
use TUI::Drivers::Display;
use TUI::Drivers::Screen;
use TUI::Drivers::SystemError;
use TUI::Drivers::Event;
use TUI::Drivers::HWMouse;
use TUI::Drivers::Mouse;
use TUI::Drivers::EventQueue;
use TUI::Drivers::Util;

sub import {
  my $target = caller;
  TUI::Drivers::Const->import::into( $target, qw( :all ) );
  TUI::Drivers::HardwareInfo->import::into( $target );
  TUI::Drivers::Display->import::into( $target );
  TUI::Drivers::Screen->import::into( $target );
  TUI::Drivers::SystemError->import::into( $target );
  TUI::Drivers::Event->import::into( $target );
  TUI::Drivers::HWMouse->import::into( $target );
  TUI::Drivers::Mouse->import::into( $target );
  TUI::Drivers::EventQueue->import::into( $target );
  TUI::Drivers::Util->import::into( $target, qw( /\S+/ ) );
}

sub unimport {
  my $caller = caller;
  TUI::Drivers::Const->unimport::out_of( $caller );
  TUI::Drivers::HardwareInfo->unimport::out_of( $caller );
  TUI::Drivers::Display->unimport::out_of( $caller );
  TUI::Drivers::Screen->unimport::out_of( $caller );
  TUI::Drivers::SystemError->unimport::out_of( $caller );
  TUI::Drivers::Event->unimport::out_of( $caller );
  TUI::Drivers::HWMouse->unimport::out_of( $caller );
  TUI::Drivers::Mouse->unimport::out_of( $caller );
  TUI::Drivers::EventQueue->unimport::out_of( $caller );
  TUI::Drivers::Util->unimport::out_of( $caller );
}

1

__END__

=pod

=head1 NAME

TUI::Drivers - Driver abstraction layer for the TUI::Vision framework

=head1 SYNOPSIS

  use TUI::Drivers;

  # Access common driver symbols from one import.
  my $cols = TScreen->getCols();
  my $rows = TScreen->getRows();

  my $ticks = THardwareInfo->getTickCount();
  my $ctrl_q = getCtrlCode('Q');

  if ( TMouse->present() ) {
    TMouse->show();
  }

=head1 DESCRIPTION

TUI::Drivers is the driver-layer collector for TUI::Vision.

Using C<use TUI::Drivers;> imports the common driver symbols from the
individual driver modules into the caller package. This includes constants,
hardware/display access, event structures and queues, mouse support, and
driver utility functions.

The module itself does not implement driver logic; it provides a convenient
single import point for the underlying driver components.

It re-exports symbols from the following components:

=over 4

=item * C<Const|TUI::Drivers::Const> - 
Symbolic constants for driver and hardware behavior.

=item * L<THardwareInfo|TUI::Drivers::HardwareInfo> -
Platform-dependent hardware backend access.

=item * L<TDisplay|TUI::Drivers::Display> / L<TScreen|TUI::Drivers::Screen> -
Low-level display and global screen mode/state management.

=item * L<TSystemError|TUI::Drivers::SystemError> -
Driver-level Ctrl-Break/system handler coordination.

=item * L<TEvent|TUI::Drivers::Event> / L<EventQueue|TUI::Drivers::EventQueue> -
Keyboard, mouse, and system event handling.

=item * L<TMouse|TUI::Drivers::Mouse> -
Public mouse driver interface.

=item * L<Util|TUI::Drivers::Util> -
Driver utility functions for key-code conversions and related helpers.

=back

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
