package TUI::MsgBox;
use strict;
use warnings;

our $VERSION = '2.0.0';

=encoding utf8

=head1 NAME

TUI::MsgBox - Message box utilities for the TUI::Vision framework

=head1 SYNOPSIS

    use TUI::MsgBox;

    # Placeholder module.
    # The full message box system will be migrated from TV::MsgBox.

=head1 DESCRIPTION

TUI::MsgBox provides message box and input box utilities for the
TUI::Vision framework. It corresponds to the Turbo Vision message box
subsystem and offers simple modal dialogs for displaying messages,
warnings, confirmations, and text prompts.

This module re-exported:

=over 4

=item * Const  
Symbolic constants for message box types and button sets.

=item * MsgBoxText  
Functions such as C<messageBox> and C<inputBox>.

=back

This stub does not implement any of these features yet.  
It exists solely to reserve the namespace for the upcoming migration.

=head1 ROADMAP

=over 4

=item * Phase 2  
Migration of TV::MsgBox::Const and TV::MsgBox::MsgBoxText.

=item * Phase 3  
Integration with TUI::Dialogs and TUI::Views.

=item * Phase 4  
Unified modal dialog API for TUI::Vision.

=back

=head1 AUTHOR

J. Schneider

=cut

1;
