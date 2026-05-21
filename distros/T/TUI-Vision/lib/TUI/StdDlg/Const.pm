package TUI::StdDlg::Const;

use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT_OK = qw(
);

our %EXPORT_TAGS = (

  cdXXXX => [qw(
    cdNormal
    cdNoLoadDir
    cdHelpButton
  )],

  cmXXXX => [qw(
    cmFileOpen
    cmFileReplace
    cmFileClear
    cmFileInit
    cmChangeDir
    cmRevert
    cmDirSelection

    cmFileFocused
    cmFileDoubleClicked
  )],

  cpXXXX => [qw(
    cpInfoPane
  )],
 
  fdXXXX => [qw(
    fdOKButton
    fdOpenButton
    fdReplaceButton
    fdClearButton
    fdHelpButton
    fdNoLoadDir
  )],

  FA_ => [qw(
    FA_NORMAL
    FA_RDONLY
    FA_HIDDEN
    FA_SYSTEM
    FA_LABEL
    FA_DIREC
    FA_ARCH
  )],

  _A_ => [qw(
    _A_NORMAL
    _A_RDONLY
    _A_HIDDEN
    _A_SYSTEM
    _A_VOLID
    _A_SUBDIR
    _A_ARCH
  )],

  DIR => [qw(
    WILDCARDS
    EXTENSION
    FILENAME
    DIRECTORY
    DRIVE
  )],

  MAX => [qw(
    MAXDRIVE
    MAXPATH
    MAXDIR
    MAXFILE
    MAXEXT
  )],

);

# add all the other %EXPORT_TAGS ":class" tags to the ":all" class and
# @EXPORT_OK, deleting duplicates
{
  my %seen;
  push
    @EXPORT_OK,
      grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}}
        foreach keys %EXPORT_TAGS;
  push
    @{$EXPORT_TAGS{all}},
      @EXPORT_OK;
}

# Commands

use constant {
  cmFileOpen     => 1001,    # Returned from TFileDialog when Open pressed
  cmFileReplace  => 1002,    # Returned from TFileDialog when Replace pressed
  cmFileClear    => 1003,    # Returned from TFileDialog when Clear pressed
  cmFileInit     => 1004,    # Used by TFileDialog internally
  cmChangeDir    => 1005,
  cmRevert       => 1006,    # Used by TChDirDialog internally
  cmDirSelection => 1007,    # ! New event - Used by TChDirDialog internally ..
                             # .. and TDirListbox externally
};

# Messages

use constant {
  cmFileFocused       => 102,    # A new file was focused in the TFileList
  cmFileDoubleClicked => 103,    # A file was selected in the TFileList
};

# TFileInfoPane palette layout

use constant cpInfoPane => "\x1E";

# TFileDialog options

use constant {
  fdOKButton      => 0x0001,    # Put an OK button in the dialog
  fdOpenButton    => 0x0002,    # Put an Open button in the dialog
  fdReplaceButton => 0x0004,    # Put a Replace button in the dialog
  fdClearButton   => 0x0008,    # Put a Clear button in the dialog
  fdHelpButton    => 0x0010,    # Put a Help button in the dialog
  fdNoLoadDir     => 0x0100,    # Do not load the current directory
                                # contents into the dialog at BUILD.
                                # This means you intend to change the
                                # wildCard by using setData or store
                                # the dialog on a stream.
};

# TChDirDialog options

use constant {
  cdNormal     => 0x0000,    # Option to use dialog immediately
  cdNoLoadDir  => 0x0001,    # Option to init the dialog to store on a stream
  cdHelpButton => 0x0002,    # Put a help button in the dialog
};

# DOS-Attributes for File Dialogs

use constant {
  FA_NORMAL => 0x00,    # Normal file, no attributes
  FA_RDONLY => 0x01,    # Read only attribute
  FA_HIDDEN => 0x02,    # Hidden file
  FA_SYSTEM => 0x04,    # System file
  FA_LABEL  => 0x08,    # Volume label
  FA_DIREC  => 0x10,    # Directory
  FA_ARCH   => 0x20,    # Archive
};

# MSC names for file attributes

use constant {
  _A_NORMAL => 0x00,    # Normal file, no attributes
  _A_RDONLY => 0x01,    # Read only attribute
  _A_HIDDEN => 0x02,    # Hidden file
  _A_SYSTEM => 0x04,    # System file
  _A_VOLID  => 0x08,    # Volume label
  _A_SUBDIR => 0x10,    # Directory
  _A_ARCH   => 0x20,    # Archive
};

# Borland-RTL-Attributes for File Dialogs

use constant {
  WILDCARDS => 0x01,
  EXTENSION => 0x02,
  FILENAME  => 0x04,
  DIRECTORY => 0x08,
  DRIVE     => 0x10,
};

use constant {
  MAXDRIVE  => 3,
  MAXPATH   => 260,
  MAXDIR    => 256,
  MAXFILE   => 256,
  MAXEXT    => 256,
};

1

__END__

=pod

=head1 NAME

TUI::StdDlg::Const - constants for standard dialog components

=head1 SYNOPSIS

  use TUI::StdDlg::Const qw(:all);

  # or import specific constant groups
  use TUI::StdDlg::Const qw(:cmXXXX :fdXXXX);
  
=head1 DESCRIPTION

C<TUI::StdDlg::Const> defines the constants used by the TUI::Vision standard
dialog subsystem.

The constants in this module are grouped by purpose and exported via tag-based
export groups. They are used by standard dialogs, list boxes, and related helper
classes to control behavior, command handling, palette selection, and file
attribute filtering.

This module only defines constants. The semantic meaning and practical usage of
these constants is documented in the corresponding higher-level modules, most
notably C<TUI::StdDlg> and the individual dialog classes.

=head1 CONSTANTS

=head2 Command constants (cmXXXX)

Command identifiers used by standard dialogs and list views.

These values are delivered via C<$event-E<gt>{command}> and are handled by dialog
and view classes.

=head2 File dialog option flags (fdXXXX)

Option flags controlling the layout and behavior of file dialogs.

These flags may be combined and passed to file dialog constructors.

=head2 Change directory dialog options (cdXXXX)

Option flags used by the change directory dialog.

=head2 Palette identifiers (cpXXXX)

Palette identifiers used by standard dialog views.

These constants identify palette entries within a dialog's palette and are used
internally by dialog components.

=head2 File attribute flags (FA_* and _A_*)

File attribute constants used for filtering and identifying file system entries
in file and directory dialogs.

=head2 Path component identifiers (DIR)

Constants identifying components of a file path.

=head2 Path and name size limits (MAX)

Constants defining maximum sizes for path and name components.

=head1 EXPORT TAGS

Constants are exported using tag-based export groups corresponding to the
functional groups described above.

An additional C<:all> export tag is provided to import all constants at once.

=head1 SEE ALSO

L<TUI::StdDlg>,
L<TUI::StdDlg::FileDialog>,
L<TUI::StdDlg::ChDirDialog>,
L<TUI::StdDlg::FileCollection>

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

=cut
