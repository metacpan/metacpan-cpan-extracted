package TUI::Views;

use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Import::Into;

use TUI::Views::Const;
use TUI::Views::CommandSet;
use TUI::Views::DrawBuffer;
use TUI::Views::Palette;
use TUI::Views::View;
use TUI::Views::Group;
use TUI::Views::Frame;
use TUI::Views::ListViewer;
use TUI::Views::ScrollBar;
use TUI::Views::WindowInit;
use TUI::Views::Window;
use TUI::Views::Util;

sub import {
  my $target = caller;
  TUI::Views::Const->import::into( $target, qw( :all ) );
  TUI::Views::CommandSet->import::into( $target );
  TUI::Views::DrawBuffer->import::into( $target );
  TUI::Views::Palette->import::into( $target );
  TUI::Views::View->import::into( $target );
  TUI::Views::Group->import::into( $target );
  TUI::Views::Frame->import::into( $target );
  TUI::Views::ListViewer->import::into( $target );
  TUI::Views::ScrollBar->import::into( $target );
  TUI::Views::WindowInit->import::into( $target );
  TUI::Views::Window->import::into( $target );
  TUI::Views::Util->import::into( $target, qw( message ) );
}

sub unimport {
  my $caller = caller;
  TUI::Views::Const->unimport::out_of( $caller );
  TUI::Views::CommandSet->unimport::out_of( $caller );
  TUI::Views::DrawBuffer->unimport::out_of( $caller );
  TUI::Views::Palette->unimport::out_of( $caller );
  TUI::Views::View->unimport::out_of( $caller );
  TUI::Views::Group->unimport::out_of( $caller );
  TUI::Views::Frame->unimport::out_of( $caller );
  TUI::Views::ListViewer->unimport::out_of( $caller );
  TUI::Views::ScrollBar->unimport::out_of( $caller );
  TUI::Views::WindowInit->unimport::out_of( $caller );
  TUI::Views::Window->unimport::out_of( $caller );
  TUI::Views::Util->unimport::out_of( $caller );
}

1

__END__

=pod

=head1 NAME

TUI::Views - Core view classes for the TUI::Vision framework

=head1 SYNOPSIS

  use TUI::Objects;
  use TUI::Views;

  # Typical in a TProgram/TApplication method:
  my $w = TWindow->new(
    bounds => TRect->new( ax => 5, ay => 2, bx => 60, by => 18 ),
    title  => 'Log',
    number => 1,
  );

  my $vbar = TScrollBar->new(
    bounds => TRect->new( ax => 53, ay => 1, bx => 54, by => 14 ),
  );
  $w->insert($vbar);

  # Add the window to the current desktop/group owner.
  $deskTop->insert($w);

=head1 DESCRIPTION

TUI::Views provides the core view and windowing subsystem for the
TUI::Vision framework. It corresponds to the Turbo Vision view
architecture and includes all fundamental UI components such as views,
groups, frames, windows, palettes, and drawing buffers.

This module re-exports a wide range of view-related classes, including:

=over 4

=item * L<Const|TUI::Views::Const> -
Symbolic constants for view behavior.

=item * L<TCommandSet|TUI::Views::CommandSet> -
Command and hotkey definitions.

=item * L<TDrawBuffer|TUI::Views::DrawBuffer> -
Low-level drawing buffer for character cell output.

=item * L<TPalette|TUI::Views::Palette> -
Color palette definitions.

=item * L<TView|TUI::Views::View> -
Base class for all visual components.

=item * L<TGroup|TUI::Views::Group> - 
Container for child views.

=item * L<TFrame|TUI::Views::Frame> -
Window frame and border rendering.

=item * L<TListViewer|TUI::Views::ListViewer> -
Scrollable list view.

=item * L<TScrollBar|TUI::Views::ScrollBar> -
Vertical and horizontal scroll bars.

=item * L<TWindowInit|TUI::Views::WindowInit> / L<TWindow|TUI::Views::Window> -
Window initialization and window objects.

=item * L<Util|TUI::Views::Util> -
Utility functions such as C<message>.

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
