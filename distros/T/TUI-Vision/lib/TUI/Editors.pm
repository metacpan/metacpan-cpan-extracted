package TUI::Editors;
# ABSTRACT: Editor-related modules for the framework

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Import::Into;

use TUI::Editors::Const;
use TUI::Editors::Indicator;
use TUI::Editors::Editor;
use TUI::Editors::EditWindow;
use TUI::Editors::FileEditor;
use TUI::Editors::Memo;

sub import {
  my $target = caller;
  TUI::Editors::Const->import::into( $target, qw( :all ) );
  TUI::Editors::Indicator->import::into( $target );
  TUI::Editors::Editor->import::into( $target );
  TUI::Editors::EditWindow->import::into( $target );
  TUI::Editors::FileEditor->import::into( $target );
  TUI::Editors::Memo->import::into( $target );
}

sub unimport {
  my $caller = caller;
  TUI::Editors::Const->unimport::out_of( $caller );
  TUI::Editors::Indicator->unimport::out_of( $caller );
  TUI::Editors::Editor->unimport::out_of( $caller );
  TUI::Editors::EditWindow->unimport::out_of( $caller );
  TUI::Editors::FileEditor->unimport::out_of( $caller );
  TUI::Editors::Memo->unimport::out_of( $caller );
}

1

__END__

=head1 NAME

TUI::Editors - Editor components for the TUI::Vision framework

=head1 SYNOPSIS

  use TUI::Objects;
  use TUI::Editors;

  # Typical indicator setup inside a TApplication/TProgram subclass:
  my $indicator = TIndicator->new(
    bounds => TRect->new( ax => 0, ay => 23, bx => 80, by => 24 ),
  );

  $self->insert($indicator);

  # Update the displayed cursor position and modified flag
  $indicator->setValue( TPoint->new(), false );

=head1 DESCRIPTION

C<TUI::Editors> provides the editor components for the TUI::Vision framework.
These modules are compatible with the editor subsystem of the classic
I<Turbo Vision> framework where practical.

This module re-exports the following components:

=over 4

=item * L<TUI::Editors::Const> -
Symbolic constants for editor behavior.

=item * L<TEditor|TUI::Editors::Editor> -
The core multi-line text editor (buffer, cursor, drawing, keyboard and
mouse handling).

=item * L<TFileEditor|TUI::Editors::FileEditor> -
A L<TEditor|TUI::Editors::Editor> bound to a file on disk (load, save,
save as, backup files).

=item * L<TEditWindow|TUI::Editors::EditWindow> -
A L<TWindow|TUI::Views::Window> that hosts a
L<TFileEditor|TUI::Editors::FileEditor> together with its scrollbars and
indicator.

=item * L<TMemo|TUI::Editors::Memo> -
A L<TEditor|TUI::Editors::Editor> that transfers its text as dialog data.

=item * L<TIndicator|TUI::Editors::Indicator> -
A view that displays the cursor position and modified state of an editor.

=back

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 CONTRIBUTORS

Contributors are documented in the POD of the respective framework modules.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).
