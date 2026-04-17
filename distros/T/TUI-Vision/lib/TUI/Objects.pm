package TUI::Objects;
use strict;
use warnings;

our $VERSION = '2.0.0';

=encoding utf8

=head1 NAME

TUI::Objects - Base object classes for the TUI::Vision framework

=head1 SYNOPSIS

    use TUI::Objects;

    # Placeholder module.
    # The full object hierarchy will be migrated from TV::Objects.

=head1 DESCRIPTION

TUI::Objects provides the foundational object layer for the TUI::Vision
framework. It corresponds to the classic Turbo Vision TObject system and
serves as the central hub for all structural classes, including:

=over 4

=item * Object base class  
Lifecycle, ownership, and common behavior.

=item * Geometry classes  
Point, Rect, and related utilities.

=item * Collection classes  
Typed and sorted collections, mirroring the original TVision design.

=item * Constants and shared definitions  
Symbolic constants used throughout the framework.

=back

In the original TV:: namespace, this module re-exported multiple
submodules (Object, Point, Rect, Collection, SortedCollection, etc.)
via C<import> and C<unimport>.  
This stub does not implement that functionality yet.

=head1 ROADMAP

=over 4

=item * Phase 2  
Migration of TV::Objects::* modules into TUI::Objects::*.

=item * Phase 3  
Reintroduction of the import/unimport dispatcher.

=item * Phase 4  
Integration with TUI::toolkit and unified object model.

=back

=head1 AUTHOR

J. Schneider

=cut

1;
