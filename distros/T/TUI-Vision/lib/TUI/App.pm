package TUI::App;
use strict;
use warnings;

our $VERSION = '2.0.0';

=encoding utf8

=head1 NAME

TUI::App - Application layer for the TUI::Vision framework

=head1 SYNOPSIS

    use TUI::App;

    # Placeholder module.
    # The full application framework will be migrated from TV::App.

=head1 DESCRIPTION

TUI::App represents the application-level framework of TUI::Vision.
It corresponds to the Turbo Vision TProgram and TApplication layer and
provides the structural foundation for building complete TUI programs.

This module re-exported multiple application components, including:

=over 4

=item * Const  
Symbolic constants for application behavior.

=item * Background  
Default background view and screen initialization.

=item * DeskInit / DeskTop  
Desktop initialization and window management.

=item * ProgInit  
Program startup sequence.

=item * Program  
Main program loop and event dispatching.

=item * Application  
High-level application object.

=back

This stub does not implement any of these features yet.  
It exists solely to reserve the namespace for the upcoming migration.

=head1 ROADMAP

=over 4

=item * Phase 2  
Migration of TV::App::* modules into TUI::App::*.

=item * Phase 3  
Reintroduction of the import/unimport dispatcher.

=item * Phase 4  
Integration with TUI::Vision event loop and driver abstraction.

=back

=head1 AUTHOR

J. Schneider

=cut

1;
