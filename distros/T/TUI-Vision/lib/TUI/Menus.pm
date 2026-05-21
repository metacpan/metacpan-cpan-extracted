package TUI::Menus;

use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Import::Into;

use TUI::Menus::Const;
use TUI::Menus::Menu;
use TUI::Menus::MenuItem;
use TUI::Menus::SubMenu;
use TUI::Menus::MenuView;
use TUI::Menus::MenuBar;
use TUI::Menus::MenuBox;
use TUI::Menus::StatusItem;
use TUI::Menus::StatusDef;
use TUI::Menus::StatusLine;

sub import {
  my $target = caller;
  TUI::Menus::Const->import::into( $target, qw( :all ) );
  TUI::Menus::Menu->import::into( $target );
  TUI::Menus::MenuItem->import::into( $target );
  TUI::Menus::SubMenu->import::into( $target );
  TUI::Menus::MenuView->import::into( $target );
  TUI::Menus::MenuBar->import::into( $target );
  TUI::Menus::MenuBox->import::into( $target );
  TUI::Menus::StatusItem->import::into( $target );
  TUI::Menus::StatusDef->import::into( $target );
  TUI::Menus::StatusLine->import::into( $target );
}

sub unimport {
  my $caller = caller;
  TUI::Menus::Const->unimport::out_of( $caller );
  TUI::Menus::Menu->unimport::out_of( $caller );
  TUI::Menus::MenuItem->unimport::out_of( $caller );
  TUI::Menus::SubMenu->unimport::out_of( $caller );
  TUI::Menus::MenuView->unimport::out_of( $caller );
  TUI::Menus::MenuBar->unimport::out_of( $caller );
  TUI::Menus::MenuBox->unimport::out_of( $caller );
  TUI::Menus::StatusItem->unimport::out_of( $caller );
  TUI::Menus::StatusDef->unimport::out_of( $caller );
  TUI::Menus::StatusLine->unimport::out_of( $caller );
}

1

__END__

=pod

=head1 NAME

TUI::Menus - Menu and status line system for the TUI::Vision framework

=head1 SYNOPSIS

  use TUI::Objects;
  use TUI::App;
  use TUI::Menus;

  # Typical in a TApplication/TProgram subclass:
  sub initMenuBar {
    my ( $class, $r ) = @_;
    $r->{b}{y} = $r->{a}{y} + 1;
    return TMenuBar->new(
      bounds => $r,
      menu   =>
        new_TSubMenu( '~F~ile', hcNoContext ) +
          new_TMenuItem( '~O~pen...', cmOpen, kbF3, hcNoContext, 'F3' ) +
          newLine +
          new_TMenuItem( 'E~x~it', cmQuit, kbAltX, hcNoContext, 'Alt-X' ) +
        new_TSubMenu( '~H~elp', hcNoContext ) +
          new_TMenuItem( '~A~bout', cmAbout, hcNoContext ),
    );
  }

  sub initStatusLine {
    my ( $class, $r ) = @_;
    $r->{a}{y} = $r->{b}{y} - 1;
    return new_TStatusLine( $r,
      new_TStatusDef( 0, 0xFFFF ) +
        new_TStatusItem( '~Alt-X~ Exit', kbAltX, cmQuit ) +
        new_TStatusItem( '~F10~ Menu', kbF10, cmMenu ) +
        new_TStatusItem( '~F1~ Help', kbF1, cmHelp )
    );
  }

=head1 DESCRIPTION

TUI::Menus provides the menu and status line subsystem for the
TUI::Vision framework. It corresponds to the Turbo Vision menu
architecture and includes all components required for building
interactive menu bars, pull-down menus, popup menus, and status lines.

This module re-exported a wide range of menu-related classes, including:

=over 4

=item * L<Const|TUI::Menus::Const> - 
Symbolic constants for menu behavior.

=item * L<TMenu|TUI::Menus::Menu>, L<TMenuItem|TUI::Menus::MenuItem>, 
L<TSubMenu|TUI::Menus::SubMenu> -
Core menu structures.

=item * L<TMenuView|TUI::Menus::MenuView>, L<TMenuBar|TUI::Menus::MenuBar>, 
L<TMenuBox|TUI::Menus::MenuBox> -
Visual menu components.

=item * L<TStatusItem|TUI::Menus::StatusItem>, 
L<TStatusDef|TUI::Menus::StatusDef>, L<TStatusLine|TUI::Menus::StatusLine> -
Status line and hotkey definitions.

=item * MenuPopup (planned)  
Popup menu support, not yet included in the Perl port.

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

