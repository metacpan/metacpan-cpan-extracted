package TUI::Drivers::Mouse;
# ABSTRACT: Public mouse driver interface

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TMouse
);

use TUI::Drivers::HWMouse;

sub TMouse() { __PACKAGE__ }

use parent THWMouse;

1

__END__

=pod

=head1 NAME

TUI::Drivers::Mouse - public mouse driver interface

=head1 SYNOPSIS

  use TUI::Drivers::Mouse;

  # Public driver-layer mouse API
  TMouse->resume();

  if ( TMouse->present() ) {
    TMouse->show();
    TMouse->setRange(79, 24);

    my %event;
    TMouse->getEvent(\%event);

    TMouse->hide();
  }

  TMouse->suspend();

=head1 DESCRIPTION

This module provides the public entry point for mouse handling in the 
L<TUI::Vision> driver layer.

The module exports the symbolic name C<TMouse>, which resolves to the underlying
hardware mouse implementation. All mouse-related operations are delegated to
L<THWMouse|TUI::Drivers::HWMouse>.

This module does not implement any logic of its own and exists to provide a
user-facing interface.

C<TMouse> is a class-style interface. It must not be instantiated.

=head2 Commonly Used Features

Within the driver stack, L<THWMouse|TUI::Drivers::HWMouse> is used to 
coordinate backend mouse startup/shutdown (L</resume>/L</suspend>), query 
availability (L</present>), and read raw mouse state (L</getEvent>).

For complete interface documentation and application-facing usage, see
L<TMouse|TUI::Drivers::Mouse>.

=head1 METHODS

=head2 show

  TMouse->show();

Makes the mouse cursor visible.

=head2 hide

  TMouse->hide();

Hides the mouse cursor.

=head2 setRange

  TMouse->setRange($rx, $ry);

Sets the horizontal and vertical movement range of the mouse.

=head2 getEvent

  TMouse->getEvent(\%event);

Retrieves the next mouse event and stores it in the supplied event structure.

=head2 present

  my $bool = TMouse->present();

Returns true if mouse hardware is available.

=head2 inhibit

  TMouse->inhibit();

Temporarily disables mouse event processing.

=head2 resume

  TMouse->resume();

Initializes mouse handling.

=head2 suspend

  TMouse->suspend();

Disables mouse handling.

=head1 SEE ALSO

L<THWMouse|TUI::Drivers::HWMouse>

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
