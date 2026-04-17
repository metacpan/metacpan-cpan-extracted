package TUI::StdDlg;
use strict;
use warnings;

our $VERSION = '2.0.0';

=encoding utf8

=head1 NAME

TUI::StdDlg - Standard dialogs for the TUI::Vision framework

=head1 SYNOPSIS

    use TUI::StdDlg;

    # Placeholder module.
    # The full standard dialog set will be migrated from TV::StdDlg.

=head1 DESCRIPTION

TUI::StdDlg provides the standard dialog set for the TUI::Vision
framework. It corresponds to the Turbo Vision standard dialogs and
includes high-level components such as file dialogs, directory dialogs,
and specialized list boxes.

This module re-exported:

=over 4

=item * Const  
Symbolic constants for standard dialog behavior.

=item * FileCollection  
Support structures for file and directory dialogs.

=item * SortedListBox  
A list box widget with automatic sorting.

=back

Additional Turbo Vision standard dialogs (file dialog, directory dialog,
input dialogs, message dialogs, etc.) are planned but not yet included
in the Perl port.

This stub does not implement any of these features yet.  
It exists solely to reserve the namespace for the upcoming migration.

=head1 ROADMAP

=over 4

=item * Phase 2  
Migration of TV::StdDlg::Const, FileCollection, and SortedListBox.

=item * Phase 3  
Implementation of file and directory dialogs.

=item * Phase 4  
Integration with TUI::Dialogs and TUI::Views.

=item * Phase 5  
Unified API for standard dialogs across all drivers.

=back

=head1 AUTHOR

J. Schneider

=cut

1;
