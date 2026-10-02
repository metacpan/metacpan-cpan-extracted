package TUI::Drivers::SystemError;
# ABSTRACT: defines the class TSystemError

use 5.010;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TSystemError
);

use Devel::StrictMode;
use PerlX::Assert::PP;
use TUI::toolkit::boolean;

use TUI::Drivers::HardwareInfo;

sub TSystemError() { __PACKAGE__ }

# Global variables
our $ctrlBreakHit  = false;
our $saveCtrlBreak = false;

INIT {
  TSystemError->resume();
}

END {
  TSystemError->suspend();
}

sub resume {    # void ($class)
  assert ( $_[0] and !ref $_[0] );
  THardwareInfo->setCtrlBrkHandler( true ) unless STRICT;
  return;
}

sub suspend {    # void ($class)
  assert ( $_[0] and !ref $_[0] );
  THardwareInfo->setCtrlBrkHandler( false ) unless STRICT;
  return;
}

1

__END__

=pod

=head1 NAME

TUI::Drivers::SystemError - system error and Ctrl-Break handling

=head1 SYNOPSIS

  use TUI::Drivers::SystemError;

  # Driver/application lifecycle usually handles this automatically,
  # but manual bracketing is available when needed:
  TSystemError->suspend();
  # ... critical section ...
  TSystemError->resume();

  if ($TUI::Drivers::SystemError::ctrlBreakHit) {
    # React to Ctrl-Break state as needed.
  }

=head1 DESCRIPTION

This module provides system-level error handling facilities used by the 
L<TUI::Vision> driver layer.

The module exposes global state related to Ctrl-Break handling and provides
class methods to suspend and resume system-level interrupt processing. This
functionality is used to coordinate application behavior during critical
sections and shutdown.

In typical applications, C<TSystemError> is coordinated by the application
lifecycle (for example via C<< TApplication->suspend() >> and
C<< TApplication->resume() >>), rather than being called directly in business
logic.

=head2 Commonly Used Features

The most common interaction is checking L</$ctrlBreakHit>, which is set by the
platform backend when a Ctrl-Break condition is observed.

L</suspend> and L</resume> are primarily lifecycle hooks around driver
subsystems. In strict debugging mode, backend Ctrl-Break handler changes are
intentionally skipped.

=head1 VARIABLES

=head2 $ctrlBreakHit

Indicates whether a Ctrl-Break event has occurred (I<Bool>).

This variable is set to a true value whenever the user triggers a Ctrl-Break
interrupt. The flag may be cleared by assigning it a false value.

=head2 $saveCtrlBreak

Compatibility variable (I<Bool>) from the original I<Turbo Vision> DOS 
implementation.

Historically it stored the previous DOS Ctrl-Break flag so that the system 
state could be restored when I<Turbo Vision> released control of the terminal. 
The Perl port does not use this mechanism and the variable is retained only for 
compatibility.

=head1 METHODS

=head2 suspend

  TSystemError->suspend();

Suspends system-level Ctrl-Break handling.

This method disables Ctrl-Break processing while the application performs
critical operations. The previous system state is preserved internally.

=head2 resume

  TSystemError->resume();

Restores system-level Ctrl-Break handling.

This method re-enables Ctrl-Break processing and restores the system state that
was active before C<suspend> was called.

=head1 SEE ALSO

L<THardwareInfo|TUI::Drivers::HardwareInfo>,
L<TEvent|TUI::Drivers::Event>

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
