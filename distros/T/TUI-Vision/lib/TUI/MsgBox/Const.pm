package TUI::MsgBox::Const;
# ABSTRACT: constants for message box dialogs

use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT_OK = qw(
);

our %EXPORT_TAGS = (

  mfXXXX => [qw(
    mfWarning
    mfError
    mfInformation
    mfConfirmation

    mfYesButton
    mfNoButton
    mfOKButton
    mfCancelButton

    mfYesNoCancel
    mfOKCancel
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

# Message box classes

use constant {
  mfWarning      => 0x0000,    # Display a Warning box
  mfError        => 0x0001,    # Display a Error box
  mfInformation  => 0x0002,    # Display an Information Box
  mfConfirmation => 0x0003,    # Display a Confirmation Box
};

# Message box button flags

use constant {
  mfYesButton    => 0x0100,    # Put a Yes button into the dialog
  mfNoButton     => 0x0200,    # Put a No button into the dialog
  mfOKButton     => 0x0400,    # Put an OK button into the dialog
  mfCancelButton => 0x0800,    # Put a Cancel button into the dialog
};

use constant mfYesNoCancel => mfYesButton | mfNoButton | mfCancelButton;
                               # Standard Yes, No, Cancel dialog
use constant mfOKCancel => mfOKButton | mfCancelButton;
                               # Standard OK, Cancel dialog
                               
1

__END__

=pod

=head1 NAME

TUI::MsgBox::Const - constants for message box dialogs

=head1 SYNOPSIS

  use TUI::MsgBox::Const qw(:all);

  # or import specific constant groups
  use TUI::MsgBox::Const qw(:mfXXXX);

=head1 DESCRIPTION

C<TUI::MsgBox::Const> defines constants used by TUI::Vision message box
dialogs.

The constants in this module are grouped by purpose and exported via tag-based
export groups. They are used to control the type of message box displayed and
the set of buttons shown to the user.

This module only defines constants. The semantic meaning and practical usage of
these constants is documented in higher-level modules such as C<TUI::MsgBox>
and the message box helper functions.

=head1 CONSTANTS

=head2 Message box flags (mfXXXX)

Flags controlling the appearance and behavior of message box dialogs.

These constants are used to select the message box class (such as warning,
error, information, or confirmation) and to configure which buttons are
displayed in the dialog.

=head1 EXPORT TAGS

Constants are exported using the following tag-based export groups:

=over

=item *

C<:mfXXXX> - message box flags

=item *

C<:all> - import all constants

=back

=head1 SEE ALSO

L<TUI::MsgBox>,
L<TUI::Dialogs::Dialog>,
L<TUI::Dialogs::Button>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2025-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
