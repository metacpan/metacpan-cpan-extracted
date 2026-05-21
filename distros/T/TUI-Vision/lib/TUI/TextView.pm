package TUI::TextView;

use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Import::Into;

use TUI::TextView::TextDevice;
use TUI::TextView::Terminal;

sub import {
  my $target = caller;
  TUI::TextView::TextDevice->import::into( $target );
  TUI::TextView::Terminal->import::into( $target );
}

sub unimport {
  my $caller = caller;
  TUI::TextView::TextDevice->unimport::out_of( $caller );
  TUI::TextView::Terminal->unimport::out_of( $caller );
}

1

__END__

=pod

=head1 NAME

TUI::TextView - Text rendering components for the TUI::Vision framework

=head1 SYNOPSIS

  use TUI::Objects;
  use TUI::Views;
  use TUI::TextView;

  my $hbar = TScrollBar->new(
    bounds => TRect->new( ax => 1, ay => 10, bx => 39, by => 11 ),
  );
  my $vbar = TScrollBar->new(
    bounds => TRect->new( ax => 39, ay => 1, bx => 40, by => 10 ),
  );

  my $terminal = TTerminal->new(
    bounds     => TRect->new( ax => 1, ay => 1, bx => 39, by => 10 ),
    hScrollBar => $hbar,
    vScrollBar => $vbar,
    bufSize    => 4096,
  );

  # TextDevice/TTerminal can be used through tied-handle methods.
  tie *TXT, TTerminal, (
    bounds     => TRect->new( ax => 1, ay => 1, bx => 39, by => 10 ),
    hScrollBar => $hbar,
    vScrollBar => $vbar,
    bufSize    => 4096,
  );
  print TXT "hello from terminal\n";

=head1 DESCRIPTION

TUI::TextView provides the text rendering subsystem for the TUI::Vision
framework. It corresponds to the Turbo Vision text device and terminal
abstraction layers and is responsible for low-level text output,
character cell handling, and terminal interaction.

This module re-exports:

=over 4

=item * L<TTextDevice|TUI::TextView::TextDevice> -
A low-level abstraction for text output devices.

=item * L<TTerminal|TUI::TextView::Terminal> -
Terminal-specific rendering and control sequences.

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

Copyright (c) 2025-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
