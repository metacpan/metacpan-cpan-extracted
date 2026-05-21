package TUI::Dialogs;

use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Import::Into;

use TUI::Dialogs::Const;
use TUI::Dialogs::HistoryViewer::HistList;
use TUI::Dialogs::Util;
use TUI::Dialogs::Button;
use TUI::Dialogs::CheckBoxes;
use TUI::Dialogs::Cluster;
use TUI::Dialogs::Dialog;
use TUI::Dialogs::HistInit;
use TUI::Dialogs::HistoryViewer;
use TUI::Dialogs::HistoryWindow;
use TUI::Dialogs::History;
use TUI::Dialogs::InputLine;
use TUI::Dialogs::Label;
use TUI::Dialogs::ListBox;
use TUI::Dialogs::MultiCheckBoxes;
use TUI::Dialogs::ParamText;
use TUI::Dialogs::RadioButtons;
use TUI::Dialogs::StaticText;
use TUI::Dialogs::StrItem;

sub import {
  my $target = caller;
  TUI::Dialogs::Const->import::into( $target, qw( :all ) );
  TUI::Dialogs::HistoryViewer::HistList->import::into( $target, qw( /\S+/) );
  TUI::Dialogs::Util->import::into( $target, qw( /\S+/) );
  TUI::Dialogs::Button->import::into( $target );
  TUI::Dialogs::CheckBoxes->import::into( $target );
  TUI::Dialogs::Cluster->import::into( $target );
  TUI::Dialogs::Dialog->import::into( $target );
  TUI::Dialogs::HistInit->import::into( $target );
  TUI::Dialogs::HistoryViewer->import::into( $target );
  TUI::Dialogs::HistoryWindow->import::into( $target );
  TUI::Dialogs::History->import::into( $target );
  TUI::Dialogs::InputLine->import::into( $target );
  TUI::Dialogs::Label->import::into( $target );
  TUI::Dialogs::ListBox->import::into( $target );
  TUI::Dialogs::MultiCheckBoxes->import::into( $target );
  TUI::Dialogs::ParamText->import::into( $target );
  TUI::Dialogs::RadioButtons->import::into( $target );
  TUI::Dialogs::StaticText->import::into( $target );
  TUI::Dialogs::StrItem->import::into( $target );
}

sub unimport {
  my $caller = caller;
  TUI::Dialogs::Const->unimport::out_of( $caller );
  TUI::Dialogs::HistoryViewer::HistList::out_of( $caller );
  TUI::Dialogs::Util->unimport::out_of( $caller );
  TUI::Dialogs::Button->unimport::out_of( $caller );
  TUI::Dialogs::CheckBoxes->unimport::out_of( $caller );
  TUI::Dialogs::Cluster->unimport::out_of( $caller );
  TUI::Dialogs::Dialog->unimport::out_of( $caller );
  TUI::Dialogs::HistInit::out_of( $caller );
  TUI::Dialogs::HistoryViewer::out_of( $caller );
  TUI::Dialogs::HistoryWindow::out_of( $caller );
  TUI::Dialogs::History::out_of( $caller );
  TUI::Dialogs::InputLine->unimport::out_of( $caller );
  TUI::Dialogs::Label->unimport::out_of( $caller );
  TUI::Dialogs::ListBox->unimport::out_of( $caller );
  TUI::Dialogs::MultiCheckBoxes->unimport::out_of( $caller );
  TUI::Dialogs::ParamText->unimport::out_of( $caller );
  TUI::Dialogs::RadioButtons->unimport::out_of( $caller );
  TUI::Dialogs::StaticText->unimport::out_of( $caller );
  TUI::Dialogs::StrItem->unimport::out_of( $caller );
}

1

__END__

=pod

=head1 NAME

TUI::Dialogs - Dialog components for the TUI::Vision framework

=head1 SYNOPSIS

  use TUI::Objects;
  use TUI::Views;
  use TUI::Dialogs;

  # Typical modal dialog flow:
  my $dlg = TDialog->new(
    bounds => TRect->new( ax => 0, ay => 0, bx => 38, by => 12 ),
    title  => 'Find',
  );
  $dlg->{options} |= ofCentered;

  my $input = TInputLine->new(
    bounds => TRect->new( ax => 3, ay => 3, bx => 32, by => 4 ),
    maxLen => 80,
  );
  $dlg->insert($input);
  $dlg->insert( TLabel->new(
    bounds => TRect->new( ax => 2, ay => 2, bx => 15, by => 3 ),
    text   => '~T~ext to find',
    link   => $input,
  ));

  $dlg->insert( TButton->new(
    bounds  => TRect->new( ax => 14, ay => 9, bx => 24, by => 11 ),
    title   => 'O~K~',
    command => cmOK,
    flags   => bfDefault,
  ));
  $dlg->insert( TButton->new(
    bounds  => TRect->new( ax => 26, ay => 9, bx => 36, by => 11 ),
    title   => 'Cancel',
    command => cmCancel,
    flags   => bfNormal,
  ));

  my $result = $deskTop->execView($dlg);

=head1 DESCRIPTION

TUI::Dialogs provides the dialog and widget layer for the TUI::Vision
framework. It corresponds to the Turbo Vision dialog subsystem and
includes a wide range of interactive UI components.

This module re-exports numerous dialog-related classes, including:

=over 4

=item * L<Const|TUI::Dialogs::Const>
Symbolic constants for dialog behavior.

=item * History-related components - 
L<THistory|TUI::Dialogs::History>, 
L<THistoryViewer|TUI::Dialogs::HistoryViewer>, 
L<THistList|TUI::Dialogs::HistoryViewer::HistList>, 
L<THistoryWindow|TUI::Dialogs::HistoryWindow>, 
and L<THistInit|TUI::Dialogs::HistInit>

=item * Basic widgets - 
L<TButton|TUI::Dialogs::Button>, L<TLabel|TUI::Dialogs::Label>,
L<TStaticText|TUI::Dialogs::StaticText>, L<TInputLine|TUI::Dialogs::InputLine>, 
L<TParamText|TUI::Dialogs::ParamText>.

=item * Selection widgets - 
L<TCheckBoxes|TUI::Dialogs::CheckBoxes>, 
L<TMultiCheckBoxes|TUI::Dialogs::MultiCheckBoxes>, 
L<TRadioButtons|TUI::Dialogs::RadioButtons>, L<TCluster|TUI::Dialogs::Cluster>.

=item * List widgets - 
L<TListBox|TUI::Dialogs::ListBox>, L<TStrItem|TUI::Dialogs::StrItem>.

=item * L<Utility|TUI::Dialogs::Util> modules - 
Dialog helpers and internal utilities.

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

=cut
