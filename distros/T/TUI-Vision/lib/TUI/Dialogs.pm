package TUI::Dialogs;
use strict;
use warnings;

our $VERSION = '2.0.0';

=encoding utf8

=head1 NAME

TUI::Dialogs - Dialog components for the TUI::Vision framework

=head1 SYNOPSIS

    use TUI::Dialogs;

    # Placeholder module.
    # The full dialog system will be migrated from TV::Dialogs.

=head1 DESCRIPTION

TUI::Dialogs provides the dialog and widget layer for the TUI::Vision
framework. It corresponds to the Turbo Vision dialog subsystem and
includes a wide range of interactive UI components.

This module re-exported numerous dialog-related classes, including:

=over 4

=item * Const  
Symbolic constants for dialog behavior.

=item * History and HistoryViewer  
History lists, history windows, and history initialization.

=item * Basic widgets  
Button, Label, StaticText, InputLine, ParamText.

=item * Selection widgets  
CheckBoxes, MultiCheckBoxes, RadioButtons, Cluster.

=item * List widgets  
ListBox, StrItem.

=item * Utility modules  
Dialog helpers and internal utilities.

=back

This stub does not implement any of these features yet.  
It exists solely to reserve the namespace for the upcoming migration.

=head1 ROADMAP

=over 4

=item * Phase 2  
Migration of TV::Dialogs::* modules into TUI::Dialogs::*.

=item * Phase 3  
Reintroduction of the import/unimport dispatcher.

=item * Phase 4  
Integration with TUI::Views and TUI::Objects for unified widget behavior.

=item * Phase 5  
Modernization of history handling and dialog layout logic.

=back

=head1 AUTHOR

J. Schneider

=cut

1;
