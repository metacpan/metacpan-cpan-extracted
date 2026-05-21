package TUI::Gadgets;

use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Import::Into;

use TUI::Gadgets::Const;
use TUI::Gadgets::PrintConstants;
use TUI::Gadgets::ClockView;
use TUI::Gadgets::EventViewer;
use TUI::Gadgets::HeapView;

sub import {
  my $target = caller;
  TUI::Gadgets::Const->import::into( $target, qw( :all ) );
  TUI::Gadgets::PrintConstants->import::into( $target );
  TUI::Gadgets::ClockView->import::into( $target );
  TUI::Gadgets::EventViewer->import::into( $target );
  TUI::Gadgets::HeapView->import::into( $target );
}

sub unimport {
  my $caller = caller;
  TUI::Gadgets::Const->unimport::out_of( $caller );
  TUI::Gadgets::PrintConstants->unimport::out_of( $caller );
  TUI::Gadgets::ClockView->unimport::out_of( $caller );
  TUI::Gadgets::EventViewer->unimport::out_of( $caller );
  TUI::Gadgets::HeapView->unimport::out_of( $caller );
}

1

__END__

=pod

=head1 NAME

TUI::Gadgets - Optional UI gadgets for the TUI::Vision framework

=head1 SYNOPSIS

  use TUI::Objects;
  use TUI::Gadgets;

  # Typical gadget setup inside a TApplication/TProgram subclass:
  my $clock = TClockView->new(
    bounds => TRect->new( ax => 71, ay => 0, bx => 80, by => 1 ),
  );

  my $heap = THeapView->new(
    bounds => TRect->new( ax => 67, ay => 24, bx => 80, by => 25 ),
  );

  my $eventViewer = TEventViewer->new(
    bounds  => TRect->new( ax => 5, ay => 2, bx => 75, by => 20 ),
    bufSize => 32 * 1024,
  );

  $self->insert($clock);
  $self->insert($heap);
  $self->insert($eventViewer);

  sub idle {
    my $self = shift;
    $self->SUPER::idle();
    $self->{clock}->update();
    $self->{heap}->update();
    return;
  }

=head1 DESCRIPTION

TUI::Gadgets provides optional visual components for the TUI::Vision
framework. These modules extend the core UI with additional views and
diagnostic tools, similar to the classic Turbo Vision gadget set.

This module re-exported several non-essential but useful UI components, 
including:

=over 4

=item * L<Const|TUI::Gadgets::Const> -
Symbolic constants for gadget behavior.

=item * L<PrintConstants|TUI::Gadgets::PrintConstants> -
Utility for printing symbolic values.

=item * L<TClockView|TUI::Gadgets::ClockView> -
A live clock widget.

=item * L<TEventViewer|TUI::Gadgets::EventViewer> -
A real-time event inspection tool.

=item * L<THeapView|TUI::Gadgets::HeapView> -
A memory usage visualization widget.

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

Copyright (c) 2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
