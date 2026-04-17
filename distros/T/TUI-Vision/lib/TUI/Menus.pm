package TUI::Menus;
use strict;
use warnings;

our $VERSION = '2.0.0';

=encoding utf8

=head1 NAME

TUI::Menus - Menu and status line system for the TUI::Vision framework

=head1 SYNOPSIS

    use TUI::Menus;

    # Placeholder module.
    # The full menu system will be migrated from TV::Menus.

=head1 DESCRIPTION

TUI::Menus provides the menu and status line subsystem for the
TUI::Vision framework. It corresponds to the Turbo Vision menu
architecture and includes all components required for building
interactive menu bars, pull-down menus, popup menus, and status lines.

This module re-exported a wide range of menu-related classes, including:

=over 4

=item * Const  
Symbolic constants for menu behavior.

=item * Menu, MenuItem, SubMenu  
Core menu structures.

=item * MenuView, MenuBar, MenuBox  
Visual menu components.

=item * StatusItem, StatusDef, StatusLine  
Status line and hotkey definitions.

=item * MenuPopup (planned)  
Popup menu support, not yet included in the Perl port.

=back

This stub does not implement any of these features yet.  
It exists solely to reserve the namespace for the upcoming migration.

=head1 ROADMAP

=over 4

=item * Phase 2  
Migration of TV::Menus::* modules into TUI::Menus::*.

=item * Phase 3  
Reintroduction of the import/unimport dispatcher.

=item * Phase 4  
Integration with TUI::Views and TUI::Dialogs.

=item * Phase 5  
Implementation of popup menus and dynamic menu generation.

=back

=head1 AUTHOR

J. Schneider

=cut

1;
