package TUI::Views;
use strict;
use warnings;

our $VERSION = '2.0.0';

=encoding utf8

=head1 NAME

TUI::Views - Core view classes for the TUI::Vision framework

=head1 SYNOPSIS

    use TUI::Views;

    # Placeholder module.
    # The full view system will be migrated from TV::Views.

=head1 DESCRIPTION

TUI::Views provides the core view and windowing subsystem for the
TUI::Vision framework. It corresponds to the Turbo Vision view
architecture and includes all fundamental UI components such as views,
groups, frames, windows, palettes, and drawing buffers.

This module re-exported a wide range of view-related classes, including:

=over 4

=item * Const  
Symbolic constants for view behavior.

=item * CommandSet  
Command and hotkey definitions.

=item * DrawBuffer  
Low-level drawing buffer for character cell output.

=item * Palette  
Color palette definitions.

=item * View  
Base class for all visual components.

=item * Group  
Container for child views.

=item * Frame  
Window frame and border rendering.

=item * ListViewer  
Scrollable list view.

=item * ScrollBar  
Vertical and horizontal scroll bars.

=item * WindowInit / Window  
Window initialization and window objects.

=item * Util  
Utility functions such as C<message>.

=back

This stub does not implement any of these features yet.  
It exists solely to reserve the namespace for the upcoming migration.

=head1 ROADMAP

=over 4

=item * Phase 2  
Migration of all TV::Views::* modules into TUI::Views::*.

=item * Phase 3  
Integration with TUI::Drivers for unified rendering.

=item * Phase 4  
Modernization of view layout, event dispatching, and palette handling.

=item * Phase 5  
Extended widget support and improved window management.

=back

=head1 AUTHOR

J. Schneider

=cut

1;
