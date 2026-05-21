package TUI::Drivers::HWMouse;
# ABSTRACT: defines the class THWMouse

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  THWMouse
);

use Devel::StrictMode;
use PerlX::Assert::PP;
use Scalar::Util qw( looks_like_number );
use TUI::toolkit::boolean;

use TUI::Drivers::HardwareInfo;

sub THWMouse() { __PACKAGE__ }

# predeclare global variable names
our $buttonCount      = 0;
our $handlerInstalled = false;
our $noMouse          = false;

INIT {
  THWMouse->resume();
}

END {
  THWMouse->suspend();
}

sub show {    # void ($class)
  assert ( $_[0] and !ref $_[0] );
  THardwareInfo->cursorOn();
  return;
}

sub hide {    # void ($class)
  assert ( $_[0] and !ref $_[0] );
  THardwareInfo->cursorOff();
  return;
}

sub setRange {    # void ($class, $rx, $ry)
  my ( $class, $rx, $ry ) = @_;
  assert ( $class and !ref $class );
  assert ( looks_like_number $rx );
  assert ( looks_like_number $ry );
  warn 'Unimplemented' if STRICT;
  return;
}

sub getEvent {    # void ($class, \%me)
  my ( $class, $me ) = @_;
  assert ( $class and !ref $class );
  assert ( ref $me );
  $me->{buttons}  = 0;
  $me->{where}{x} = 0;
  $me->{where}{y} = 0;
  $me->{eventFlags} = 0;
  return;
}

sub present {    # $bool ($class)
  assert ( $_[0] and !ref $_[0] );
  return $buttonCount != 0;
}

sub suspend {    # void ($class)
  my $class = shift;
  assert ( $class and !ref $class );
  $class->hide();
  $buttonCount = false;
  return;
}

sub resume {    # void ($class)
  my $class = shift;
  assert ( $class and !ref $class );
  $buttonCount = THardwareInfo->getButtonCount();
  $class->show();
  return;
}

sub inhibit {    # void ($class)
  assert ( $_[0] and !ref $_[0] );
  $noMouse = true;
  return;
}

1

__END__

=pod

=head1 NAME

TUI::Drivers::HWMouse - internal low-level hardware mouse backend

=head1 SYNOPSIS

  use TUI::Drivers::HWMouse;

  # Internal backend usage only:
  THWMouse->resume();
  THWMouse->suspend();

=head1 DESCRIPTION

C<THWMouse> implements low-level mouse handling for the Turbo
Vision driver layer.

This module is an internal backend API. External code should use
L<TUI::Drivers::Mouse> (C<TMouse>) as the public mouse interface.

The module maintains global mouse state and backend hooks used by the
driver stack.

C<THWMouse> is not an object-oriented class. It must not be instantiated. All
interaction is performed through class method calls.

Mouse handling is initialized automatically when the module is loaded and is
suspended automatically when the program terminates.

The behavior and internals here are backend-focused and may change as the
driver implementation evolves. Public callers should depend on
L<TUI::Drivers::Mouse> instead.

=head1 VARIABLES

=head2 $buttonCount

Contains the number of mouse buttons detected on the system.

=head2 $handlerInstalled

Indicates whether the mouse event handler is currently installed.

=head2 $noMouse

Indicates whether mouse hardware is available.

=head1 METHODS

The backend exposes class methods with the same operational surface used by
C<TMouse> (for example C<show()>, C<hide()>, C<getEvent()>, C<present()>,
C<resume()>, and C<suspend()>).

Their public-facing semantics are documented in L<TUI::Drivers::Mouse>.

=head1 SEE ALSO

L<TUI::Drivers::Mouse>,
L<TUI::Drivers::HardwareInfo>,
L<TUI::Drivers::Event>

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
