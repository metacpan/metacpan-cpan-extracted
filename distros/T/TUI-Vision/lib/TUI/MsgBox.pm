package TUI::MsgBox;

use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Import::Into;

use TUI::MsgBox::Const;
use TUI::MsgBox::MsgBoxText;

sub import {
  my $target = caller;
  TUI::MsgBox::Const->import::into( $target, qw( :all ) );
  TUI::MsgBox::MsgBoxText->import::into( $target, qw( /^messageBox|inputBox/ ) );
}

sub unimport {
  my $caller = caller;
  TUI::MsgBox::Const->unimport::out_of( $caller );
  TUI::MsgBox::MsgBoxText->unimport::out_of( $caller );
}

1

__END__

=pod

=head1 NAME

TUI::MsgBox - Message box utilities for the TUI::Vision framework

=head1 SYNOPSIS

  use TUI::MsgBox;

  my $answer = messageBox(
    'Delete selected file?',
    mfConfirmation | mfYesNoCancel,
  );

  if ( $answer == cmYes ) {
    messageBox( 'File deleted.', mfInformation | mfOKButton );
  }

  my $string = '';
  my $res = inputBox(
    'The Title',
    'Enter some text:',
    $string,
    30,
  );

  if ( $res != cmCancel ) {
    # Process confirmed input.
  }

=head1 DESCRIPTION

TUI::MsgBox provides message box and input box utilities for the
TUI::Vision framework. It corresponds to the Turbo Vision message box
subsystem and offers simple modal dialogs for displaying messages,
warnings, confirmations, and text prompts.

This module re-exported:

=over 4

=item * L<Const|TUI::MsgBox::Const> -
Symbolic constants for message box types and button sets.

=item * L<MsgBoxText|TUI::MsgBox::MsgBoxText> -
Functions such as C<messageBox> and C<inputBox>.

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

Copyright (c) 2025-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
