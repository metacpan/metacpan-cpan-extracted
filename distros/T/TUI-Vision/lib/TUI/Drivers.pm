package TUI::Drivers;
use strict;
use warnings;

our $VERSION = '2.0.0';

=encoding utf8

=head1 NAME

TUI::Drivers - Driver abstraction layer for the TUI::Vision framework

=head1 SYNOPSIS

    use TUI::Drivers;

    # Placeholder module.
    # The full driver system will be migrated from TV::Drivers.

=head1 DESCRIPTION

TUI::Drivers provides the hardware and driver abstraction layer for the
TUI::Vision framework. It corresponds to the Turbo Vision driver system
and encapsulates all low-level terminal, keyboard, mouse, and event
handling functionality.

This module re-exported multiple driver components, including:

=over 4

=item * Const  
Symbolic constants for driver and hardware behavior.

=item * HardwareInfo  
Detection of terminal and system capabilities.

=item * Display / Screen  
Low-level screen output and display management.

=item * SystemError  
Driver-level error reporting.

=item * Event / EventQueue  
Keyboard, mouse, and system event handling.

=item * HWMouse / Mouse  
Hardware and logical mouse drivers.

=item * Util  
Internal driver utilities.

=back

This stub does not implement any of these features yet.  
It exists solely to reserve the namespace for the upcoming migration.

=head1 ROADMAP

=over 4

=item * Phase 2  
Migration of TV::Drivers::* modules into TUI::Drivers::*.

=item * Phase 3  
Driver abstraction for Win32 and ncurses.

=item * Phase 4  
Unified event system shared across TUI::Vision.

=item * Phase 5  
Modernization of screen output and terminal capability detection.

=back

=head1 AUTHOR

J. Schneider

=cut

1;
