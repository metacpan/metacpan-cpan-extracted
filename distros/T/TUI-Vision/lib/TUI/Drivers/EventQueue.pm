package TUI::Drivers::EventQueue;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TEventQueue
);

use PerlX::Assert::PP;
use TUI::toolkit::boolean;
use TUI::Drivers::Const qw( 
  :evXXXX 
  :meXXXX
);
use TUI::Drivers::Event;
use TUI::Drivers::HardwareInfo;
use TUI::Drivers::Mouse;
use TUI::Drivers::Screen;

sub TEventQueue() { __PACKAGE__ }

# predeclare global variable names
our $downTicks = 0;

our $mouseEvents  = false;
our $mouseReverse = false;
our $doubleDelay  = 8;
our $repeatDelay  = 8;
our $autoTicks    = 0;
our $autoDelay    = 0;

our $mouse     = TMouse;
our $lastMouse = MouseEventType->new();
our $curMouse  = MouseEventType->new();
our $downMouse = MouseEventType->new();

INIT {
  TEventQueue->resume();
}

END {
  TEventQueue->suspend();
}

sub resume {    # void ($class)
  assert ( $_[0] and !ref $_[0] );
  if ( !$mouse->present() ) {
    $mouse->resume();
  }
  if ( !$mouse->present() ) {
    return;
  }

  $mouse->getEvent( $curMouse );
  $lastMouse = $curMouse;

  THardwareInfo->clearPendingEvent();

  $mouseEvents = true;
  eval {
    TMouse->setRange( 
      $TUI::Drivers::Screen::screenWidth - 1, 
      $TUI::Drivers::Screen::screenHeight - 1 
    )
  };
  return;
} #/ sub resume

sub suspend {    # void ($class)
  assert ( $_[0] and !ref $_[0] );
  $mouse->suspend();
  return;
}

my $ticks = 0;

my $getMouseState = sub {    # $bool ($class, $ev)
  my ( $class, $ev ) = @_;
  assert ( $class and !ref $class );
  assert ( ref $ev );
  $ev->{what} = evNothing;

  return false unless THardwareInfo->getMouseEvent( $curMouse );

  if ( $mouseReverse && $curMouse->{buttons} && $curMouse->{buttons} != 3 ) {
    $curMouse->{buttons} ^= 3;
  }

  # Temporarily save tick count when event was read.
  $ticks = THardwareInfo->getTickCount();
  $ev->{mouse} = $curMouse->clone();
  return true;
}; #/ $getMouseState = sub

sub getMouseEvent {    # void ($class, $ev)
  my ( $class, $ev ) = @_;
  assert ( $class and !ref $class );
  assert ( ref $ev );
  if ( $mouseEvents ) {
    if ( !$class->$getMouseState( $ev ) ) {
      return;
    }

    $ev->{mouse}{eventFlags} = 0;

    if ( !$ev->{mouse}{buttons} && $lastMouse->{buttons} ) {
      $ev->{what} = evMouseUp;
      $lastMouse = $ev->{mouse}->clone();
      return;
    }

    if ( $ev->{mouse}{buttons} && !$lastMouse->{buttons} ) {
      if ( $ev->{mouse}{buttons} == $downMouse->{buttons}
        && $ev->{mouse}{where} == $downMouse->{where}
        && $ticks - $downTicks <= $doubleDelay
        && !( $downMouse->{eventFlags} & meDoubleClick ) )
      {
        $ev->{mouse}{eventFlags} |= meDoubleClick;
      }

      $downMouse  = $ev->{mouse};
      $autoTicks  = $ticks;
      $downTicks  = $ticks;
      $ticks      = 0;
      $autoDelay  = $repeatDelay;
      $ev->{what} = evMouseDown;
      $lastMouse = $ev->{mouse}->clone();
      return;
    } #/ if ( $ev->{mouse}{buttons...})

    $ev->{mouse}{buttons} = $lastMouse->{buttons};

    if ( $ev->{mouse}{where} != $lastMouse->{where} ) {
      $ev->{what} = evMouseMove;
      $ev->{mouse}{eventFlags} |= meMouseMoved;
      $lastMouse = $ev->{mouse}->clone();
      return;
    }

    if ( $ev->{mouse}{buttons} && $ticks - $autoTicks > $autoDelay ) {
      $autoTicks  = $ticks;
      $ticks      = 0;
      $autoDelay  = 1;
      $ev->{what} = evMouseAuto;
      $lastMouse = $ev->{mouse}->clone();
      return;
    }
  } #/ if ( $mouseEvents )

  $ev->{what} = evNothing;
} #/ sub getMouseEvent

1

__END__

=pod

=head1 NAME

TUI::Drivers::EventQueue - internal mouse event queue and dispatcher

=head1 HIERARCHY

  TEventQueue (internal manager)
    used by TEvent and the event system

=head1 SYNOPSIS

  use TUI::Drivers::EventQueue;
  use TUI::Drivers::Event;

  my $event = TEvent->new;
  TEventQueue->getMouseEvent($event);

=head1 DESCRIPTION

C<TEventQueue> implements the low-level event queue responsible for collecting
and dispatching mouse events within the TUI::Vision framework.

This module manages mouse state, button transitions, double-click detection,
auto-repeat handling, and movement tracking. It serves as the bridge between
hardware input and the higher-level C<TEvent> abstraction.

C<TEventQueue> is an internal framework component. Application code normally
interacts with events through C<TEvent> and should not depend directly on this
module.

=head2 Commonly Used Features

In typical runtime flow, C<TEventQueue> is started and stopped automatically
via C<resume()> and C<suspend()> during driver/application lifecycle handling.
The most frequently used operation is C<getMouseEvent($event)>, which updates a
provided C<TEvent> instance in-place and sets C<< $event->{what} >> to one of
C<evMouseDown>, C<evMouseUp>, C<evMouseMove>, C<evMouseAuto>, or C<evNothing>.

Configuration usually centers on timing and behavior globals such as
C<$doubleDelay>, C<$repeatDelay>, and C<$mouseReverse>. These values influence
double-click recognition, mouse auto-repeat generation, and button mapping,
and are primarily relevant for driver-level customization rather than
application-level dialog/view code.

=head1 VARIABLES

The following global variables control event timing and mouse state
handling in C<TEventQueue>.

=head2 $downTicks

Counts the number of ticks since the last mouse button press.

=head2 $mouseEvents

Indicates whether mouse events are currently enabled.

=head2 $mouseReverse

Indicates whether mouse button order is reversed.

=head2 $doubleDelay

Defines the delay (in ticks) used to detect double-click events.

=head2 $repeatDelay

Defines the delay (in ticks) before auto-repeat events are generated.

=head2 $autoTicks

Counts ticks used for auto-repeat handling.

=head2 $autoDelay

Defines the delay before auto-repeat processing starts.

=head2 $mouse

Holds the current C<TMouse> driver instance.

=head2 $lastMouse

Stores the previous mouse event state.

=head2 $curMouse

Stores the current mouse event state.

=head2 $downMouse

Stores the mouse event state at the time the button was pressed.

=head1 METHODS

=head2 resume

  TEventQueue->resume();

Initializes mouse handling and enables mouse event processing.

This method is called automatically during program startup.

=head2 suspend

  TEventQueue->suspend();

Suspends mouse handling and releases related resources.

This method is called automatically during program shutdown.

=head2 getMouseEvent

  TEventQueue->getMouseEvent($event);

Retrieves the next mouse event and populates the provided C<TEvent> object.

If no mouse event is available, the event's C<what> field is set to
C<evNothing>.

This method is a low-level helper used internally by C<TEvent>. Application
code should normally call C<TEvent-E<gt>getMouseEvent> instead.

=head1 IMPLEMENTATION DETAILS

Following the original Turbo Vision design, C<TEventQueue> is implemented as a
singleton class with class methods and global state. 

=head2 Scope and limitations

C<TEventQueue> processes mouse events only.

Keyboard events are handled separately through C<TEvent-E<gt>getKeyEvent> and
are not part of this queue.

=head2 Lifecycle

The event queue is automatically activated when the module is loaded and
suspended when the program terminates.

This behavior is managed internally and does not require explicit setup by
application code.

=head2 Event generation

C<TEventQueue> generates the following mouse-related event types:

=over

=item *

C<evMouseDown>

=item *

C<evMouseUp>

=item *

C<evMouseMove>

=item *

C<evMouseAuto>

=back

Additional mouse flags such as double-click detection and movement indicators
are encoded in the mouse event data.

=head2 Internal state

C<TEventQueue> maintains internal state for tracking mouse position, button
state transitions, and timing information required for double-click and
auto-repeat detection.

These details are considered implementation-specific and are not part of the
public API.

=head1 SEE ALSO

L<TUI::Drivers::Event>,
L<TUI::Drivers::Const>,
L<TUI::Drivers::HardwareInfo>,
L<TUI::Drivers::Mouse>

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
