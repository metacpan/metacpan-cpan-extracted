package TUI::Outline;
# ABSTRACT: Outline-related modules for the framework

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Import::Into;

use TUI::Outline::Const;
use TUI::Outline::Node;
use TUI::Outline::OutlineViewer;
use TUI::Outline::Outline;

sub import {
  my $target = caller;
  TUI::Outline::Const->import::into( $target, qw( :all ) );
  TUI::Outline::Node->import::into( $target );
  TUI::Outline::OutlineViewer->import::into( $target );
  TUI::Outline::Outline->import::into( $target );
}

sub unimport {
  my $caller = caller;
  TUI::Outline::Const->unimport::out_of( $caller );
  TUI::Outline::Node->unimport::out_of( $caller );
  TUI::Outline::OutlineViewer->unimport::out_of( $caller );
  TUI::Outline::Outline->unimport::out_of( $caller );
}

1

__END__

=pod

=head1 NAME

TUI::Outline - Outline-related modules for the framework

=head1 SYNOPSIS

  use TUI::Outline;

  # Outline constants (ovXXXX, cmXXXX, cpXXXX) are imported by default
  my $flags = ovExpanded | ovChildren;

=head1 DESCRIPTION

C<TUI::Outline> provides outline-related view classes and functionality for the
L<TUI::Vision> framework.

Concrete outline implementations are provided by modules within the
C<TUI::Outline::*> hierarchy.

Outline-related views are intended for displaying and navigating hierarchical
information within the framework's user interface and follow the concepts of
the original I<Turbo Vision> outline subsystem where practical.

This module re-exports the following modules:

=over 4

=item * L<TUI::Outline::Const>
Symbolic constants for outline views (node flags, commands, and palette
identifiers).

=item * L<TNode|TUI::Outline::Node>
Node of an outline tree (text, children, next sibling, and expanded state).

=item * L<TOutlineViewer|TUI::Outline::OutlineViewer>
Abstract scrollable view that draws and navigates an outline tree.

=item * L<TOutline|TUI::Outline::Outline>
Concrete outline viewer that displays a tree of C<TNode> objects.

=back

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).
