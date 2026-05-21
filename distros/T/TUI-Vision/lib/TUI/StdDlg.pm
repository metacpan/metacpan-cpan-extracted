package TUI::StdDlg;

use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Import::Into;

use TUI::StdDlg::Const;
use TUI::StdDlg::ChDirDialog;
use TUI::StdDlg::Dir;
use TUI::StdDlg::DirCollection;
use TUI::StdDlg::DirEntry;
use TUI::StdDlg::DirListBox;
use TUI::StdDlg::Dos;
use TUI::StdDlg::Util;
use TUI::StdDlg::FileCollection;
use TUI::StdDlg::FileDialog;
use TUI::StdDlg::FileInfoPane;
use TUI::StdDlg::FileInputLine;
use TUI::StdDlg::FileList;
use TUI::StdDlg::SortedListBox;

sub import {
  my $target = caller;
  TUI::StdDlg::Const->import::into( $target, qw( :all ) );
  TUI::StdDlg::Dos->import::into( $target, qw( /\S+/ ) );
  TUI::StdDlg::Dir->import::into( $target, qw( /\S+/ ) );
  TUI::StdDlg::Util->import::into( $target, qw( /\S+/ ) );
  TUI::StdDlg::ChDirDialog->import::into( $target );
  TUI::StdDlg::DirCollection->import::into( $target );
  TUI::StdDlg::DirEntry->import::into( $target );
  TUI::StdDlg::DirListBox->import::into( $target );
  TUI::StdDlg::FileCollection->import::into( $target );
  TUI::StdDlg::FileDialog->import::into( $target );
  TUI::StdDlg::FileInfoPane->import::into( $target );
  TUI::StdDlg::FileInputLine->import::into( $target );
  TUI::StdDlg::FileList->import::into( $target );
  TUI::StdDlg::SortedListBox->import::into( $target );
}

sub unimport {
  my $caller = caller;
  TUI::StdDlg::Const->unimport::out_of( $caller );
  TUI::StdDlg::Dos->unimport::out_of( $caller );
  TUI::StdDlg::Dir->unimport::out_of( $caller );
  TUI::StdDlg::Util->unimport::out_of( $caller );
  TUI::StdDlg::ChDirDialog->unimport::out_of( $caller );
  TUI::StdDlg::DirCollection->unimport::out_of( $caller );
  TUI::StdDlg::DirEntry->unimport::out_of( $caller );
  TUI::StdDlg::DirListBox->unimport::out_of( $caller );
  TUI::StdDlg::FileCollection->unimport::out_of( $caller );
  TUI::StdDlg::FileDialog->unimport::out_of( $caller );
  TUI::StdDlg::FileInfoPane->unimport::out_of( $caller );
  TUI::StdDlg::FileInputLine->unimport::out_of( $caller );
  TUI::StdDlg::FileList->unimport::out_of( $caller );
  TUI::StdDlg::SortedListBox->unimport::out_of( $caller );
}

1

__END__

=pod

=head1 NAME

TUI::StdDlg - Standard dialogs for the TUI::Vision framework

=head1 SYNOPSIS

  use TUI::App;
  use TUI::StdDlg;

  # Typical in a TProgram/TApplication command handler:
  my @fileName = ('*.*');
  my $fileDlg = TFileDialog->new(
    wildCard  => $fileName[0],
    title     => 'Open File',
    inputName => '~F~ile Name',
    options   => fdOpenButton,
    histId    => 1,
  );

  if ( $application->executeDialog($fileDlg, \@fileName) != cmCancel ) {
    # $fileName[0] now contains the selected file.
  }

  my $dirDlg = TChDirDialog->new(
    options => 0,
    histId  => 1,
  );
  $application->executeDialog($dirDlg, undef);

=head1 DESCRIPTION

TUI::StdDlg provides the standard dialog set for the TUI::Vision
framework. It corresponds to the Turbo Vision standard dialogs and
includes high-level components such as file dialogs, directory dialogs,
and specialized list boxes.

This module re-exported:

=over 4

=item * L<Const|TUI::StdDlg::Const> -
Symbolic constants for standard dialog behavior.

=item * L<TFileCollection|TUI::StdDlg::FileCollection> / 
L<TDirCollection|TUI::StdDlg::DirCollection> -
Support structures for file and directory dialogs.

=item * L<TSortedListBox|TUI::StdDlg::SortedListBox> -
A list box widget with automatic sorting.

=item * Additional standard dialogs -
Like L<file dialog|TUI::StdDlg::FileDialog>, 
L<directory dialog|TUI::StdDlg::ChDirDialog>, and related components.

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
