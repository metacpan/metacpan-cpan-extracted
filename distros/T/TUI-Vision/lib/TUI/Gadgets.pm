package TUI::Gadgets;
use strict;
use warnings;

our $VERSION = '2.0.0';

=encoding utf8

=head1 NAME

TUI::Gadgets - Optional UI gadgets for the TUI::Vision framework

=head1 SYNOPSIS

    use TUI::Gadgets;

    # Placeholder module.
    # The full gadget set will be migrated from TV::Gadgets.

=head1 DESCRIPTION

TUI::Gadgets provides optional visual components for the TUI::Vision
framework. These modules extend the core UI with additional views and
diagnostic tools, similar to the classic Turbo Vision gadget set.

This module re-exported several non-essential but useful UI components, 
including:

=over 4

=item * Const  
Symbolic constants for gadget behavior.

=item * PrintConstants  
Utility for printing symbolic values.

=item * ClockView  
A live clock widget.

=item * EventViewer  
A real-time event inspection tool.

=item * HeapView  
A memory usage visualization widget.

=back

This stub does not implement any of these features yet.  
It exists solely to reserve the namespace for the upcoming migration.

=head1 ROADMAP

=over 4

=item * Phase 2  
Migration of TV::Gadgets::* modules into TUI::Gadgets::*.

=item * Phase 3  
Integration with TUI::Views and TUI::Objects.

=item * Phase 4  
Optional gadget registration and dynamic loading.

=back

=head1 AUTHOR

J. Schneider

=cut

1;
