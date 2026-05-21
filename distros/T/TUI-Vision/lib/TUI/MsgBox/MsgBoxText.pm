package TUI::MsgBox::MsgBoxText;
# ABSTRACT: Message Box and Input Box functions for TVision

use 5.010;
use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(
  messageBox
  messageBoxRect
  inputBox
  inputBoxRect
);

use Carp ();
use Scalar::Util qw( looks_like_number );
use TUI::toolkit qw(
  :boolean
  :utils
);
use TUI::toolkit::Types qw( :types );

use TUI::App::Program qw(
  $application
  $deskTop
);
use TUI::Dialogs::Const qw(
  bfDefault
  bfNormal
);
use TUI::Dialogs::Button;
use TUI::Dialogs::Dialog;
use TUI::Dialogs::InputLine;
use TUI::Dialogs::Label;
use TUI::Dialogs::StaticText;
use TUI::MsgBox::Const qw(
  :mfXXXX
);
use TUI::Objects::Object;
use TUI::Objects::Rect;
use TUI::Views::Const qw(
  cmYes
  cmNo
  cmOK
  cmCancel
);

# declare global variables
our $yesText         = "~Y~es";
our $noText          = "~N~o";
our $okText          = "O~K~";
our $cancelText      = "Cancel";
our $warningText     = "Warning";
our $errorText       = "Error";
our $informationText = "Information";
our $confirmText     = "Confirm";

# Button caption texts
my @buttonName = (
  $yesText,
  $noText,
  $okText,
  $cancelText,
);

# Commands for each button
my @commands = (
  cmYes,
  cmNo,
  cmOK,
  cmCancel,
);

# Titles for different message box types
my @Titles = (
  $warningText,
  $errorText,
  $informationText,
  $confirmText,
);

sub messageBox {    # $command ($msg|$aOptions, $aOptions|$fmt, @list)
  assert ( @_ >= 2 );
  my $r = TRect->new( ax => 0, ay => 0, bx => 40, by => 9 );
  $r->move(
    int( ( $deskTop->{size}{x} - $r->{b}{x} ) / 2 ),
    int( ( $deskTop->{size}{y} - $r->{b}{y} ) / 2 ),
  );
  return messageBoxRect( $r, @_ );
}

sub messageBoxRect {    # $command ($r, $msg|$aOptions, $aOptions|$fmt, @list)
  my ( $r, $msg, $aOptions );
  if ( looks_like_number $_[2] ) {
    state $sig = signature(
      pos => [Object, Str, PositiveOrZeroInt],
    );
    ( $r, $msg, $aOptions ) = $sig->( @_ );
  }
  else {
    state $sig = signature(
      pos => [Object, PositiveOrZeroInt, Str, ArrayRef, { slurpy => 1 }],
    );
    my ( $fmt, $list );
    ( $r, $aOptions, $fmt, $list ) = $sig->( @_ );
    assert ( defined $fmt and !ref $fmt );
    $msg = sprintf( $fmt, @$list );
  }

  my $dialog;
  my ( $i, $x, $buttonCount );
  my @buttonList;
  my $ccode;

  $dialog = TDialog->new( bounds => $r, title  => $Titles[ $aOptions & 0x3 ] );

  $dialog->insert(
    TStaticText->new(
      bounds => TRect->new(
        ax => 3,
        ay => 2,
        bx => $dialog->{size}{x} - 2,
        by => $dialog->{size}{y} - 3,
      ),
      text => $msg,
    )
  );
  for ( $i = 0, $x = -2, $buttonCount = 0 ; $i < 4 ; $i++ ) {
    if ( $aOptions & ( 0x0100 << $i ) ) {
      $buttonList[$buttonCount] = TButton->new(
        bounds  => TRect->new( ax => 0, ay => 0, bx => 10, by => 2 ),
        title   => $buttonName[$i],
        command => $commands[$i],
        flags   => bfNormal,
      );
      $x += $buttonList[$buttonCount++]->{size}{x} + 2;
    } #/ if ( ( $aOptions & ( 0x0100...)))
  } #/ for ( $i = 0, $x = -2, ...)

  $x = int( ( $dialog->{size}{x} - $x ) / 2 );

  for ( $i = 0 ; $i < $buttonCount ; $i++ ) {
    $dialog->insert( $buttonList[$i] );
    $buttonList[$i]->moveTo( $x, $dialog->{size}{y} - 3 );
    $x += $buttonList[$i]->{size}{x} + 2;
  }

  $dialog->selectNext( false );

  $ccode = $application->execView( $dialog );

  TObject->destroy( $dialog );

  return $ccode;
}; #/ sub messageBoxRect

sub inputBox {    # $command ($Title, $aLabel, $s, $limit)
  assert ( @_ == 4 );
  my $r = TRect->new( ax => 0, ay => 0, bx => 60, by => 8 );
  $r->move(
    int( ( $deskTop->{size}{x} - $r->{b}{x} ) / 2 ),
    int( ( $deskTop->{size}{y} - $r->{b}{y} ) / 2 ),
  );
  return inputBoxRect( $r, @_ );
}

sub inputBoxRect {    # $command ($bounds, $Title, $aLabel, \@s, $limit)
  state $sig = signature(
    pos => [Object, Str, Str, ArrayLike, PositiveOrZeroInt],
  );
  my ( $bounds, $Title, $aLabel, $s, $limit ) = $sig->( @_ );

  my $dialog;
  my $control;
  my $r;
  my $c;

  $dialog = TDialog->new( bounds => $bounds, title => $Title );
  $r = TRect->new(
    ax => 4 + length( $aLabel ),  ay => 2,
    bx => $dialog->{size}{x} - 3, by => 3,
  );
  $control = TInputLine->new( bounds => $r, maxLen => $limit );
  $dialog->insert( $control );

  $r = TRect->new( ax => 2, ay => 2, bx => 3 + length( $aLabel ), by => 3 );
  $dialog->insert(
    TLabel->new( bounds => $r, text => $aLabel, link => $control )
  );

  $r = TRect->new(
    ax => $dialog->{size}{x} - 24, ay => $dialog->{size}{y} - 4,
    bx => $dialog->{size}{x} - 14, by => $dialog->{size}{y} - 2,
  );
  $dialog->insert(
    TButton->new(
      bounds  => $r,
      title   => $okText,
      command => cmOK,
      flags   => bfDefault,
    )
  );

  $r->{a}{x} += 12;
  $r->{b}{x} += 12;
  $dialog->insert(
    TButton->new(
      bounds  => $r,
      title   => $cancelText,
      command => cmCancel,
      flags   => bfNormal,
    )
  );

  $r->{a}{x} += 12;
  $r->{b}{x} += 12;
  $dialog->selectNext( false );
  $dialog->setData( $s );
  $c = $application->execView( $dialog );
  if ( $c != cmCancel ) {
    $dialog->getData( $s );
  }
  TObject->destroy( $dialog );
  return $c;
} #/ sub inputBoxRect

1

__END__

=pod

=head1 NAME

TUI::MsgBox::MsgBoxText - message box and input box helper functions

=head1 SYNOPSIS

  use TUI::MsgBox::MsgBoxText;

  my $cmd = inputBox(
    'The Title',
    'Enter some text:',
    $string,
    30
  );

  my $cmd = messageBox(
    'Problem renaming %s',
    mfError | mfOkButton | mfCancelButton,
    $fileName
  );

=head1 DESCRIPTION

C<TUI::MsgBox::MsgBoxText> provides a set of convenience functions for 
displaying simple message boxes and input dialogs in TUI::Vision applications.

This module implements functional equivalents of the Turbo Vision
C<inputBox>, C<messageBox>, and related helper routines found in the original
demo sources.

All functions in this module are implemented as plain subroutines. No objects
are created or required.

These functions may only be used within a running TUI::Vision application.

=head1 VARIABLES

The following global variables define the default text labels used by
message boxes.

=head2 $yesText

Label text for the affirmative response button.

=head2 $noText

Label text for the negative response button.

=head2 $okText

Label text for the confirmation button.

=head2 $cancelText

Label text for the cancel action.

=head2 $warningText

Title text used for warning message boxes.

=head2 $errorText

Title text used for error message boxes.

=head2 $informationText

Title text used for informational message boxes.

=head2 $confirmText

Title text used for confirmation message boxes.

=head1 FUNCTIONS

=head2 inputBox

  my $command = inputBox($title, $label, $string, $limit);

Displays a modal dialog containing a single input field.

=over

=item title

Dialog window title (I<Str>).

=item label

Prompt text displayed next to the input field (I<Str>).

=item string

Initial value of the input field. The value may be modified by the user.

=item limit

Maximum length of the input string (I<Int>).

=back

Returns either C<cmOk> or C<cmCancel> depending on user selection.

=head2 inputBoxRect

  my $command = inputBoxRect($bounds, $title, $label, \$string, $limit);

Identical to C<inputBox>, but allows explicit control over dialog position and
size.

=over

=item bounds

Bounding rectangle of the dialog (I<TRect>).

=item title

Dialog window title (I<Str>).

=item label

Prompt text displayed next to the input field (I<Str>).

=item string

Scalar reference receiving the edited text.

=item limit

Maximum length of the input string (I<Int>).

=back

Returns either C<cmOk> or C<cmCancel>.

=head2 messageBox

  my $command = messageBox($message, $options, @params);

Displays a formatted message box with configurable buttons and style.

The message string and optional parameters are formatted using TUI::Vision
formatting rules.

=over

=item message

Message format string (I<Str>).

=item options

Bitmask selecting message type and button layout (I<Int>).

=item params

Optional parameters inserted into the message string.

=back

Returns one of C<cmOk>, C<cmCancel>, C<cmYes>, or C<cmNo>.

=head2 messageBoxRect

  my $command = messageBoxRect($bounds, $message, $options, @params);

Identical to C<messageBox>, but allows explicit control over dialog position and
size.

=over

=item bounds

Bounding rectangle of the message box (I<TRect>).

=item message

Message format string (I<Str>).

=item options

Bitmask selecting message type and button layout (I<Int>).

=item params

Optional parameters inserted into the message string.

=back

Returns one of C<cmOk>, C<cmCancel>, C<cmYes>, or C<cmNo>.

=head1 MESSAGE BOX OPTIONS

Message box appearance and buttons are controlled via option flags.

Message types:

=over

=item *

C<mfWarning>

=item *

C<mfError>

=item *

C<mfInformation>

=item *

C<mfConfirmation>

=back

Button flags:

=over

=item *

C<mfYesButton>

=item *

C<mfNoButton>

=item *

C<mfOkButton>

=item *

C<mfCancelButton>

=item *

C<mfYesNoCancel>

=item *

C<mfOkCancel>

=back

=head1 IMPORTANT

These functions require a running TUI::Vision application environment.
They must not be used outside of a TUI::Vision program.

=head1 SEE ALSO

L<TUI::Dialogs::Dialog>,
L<TUI::Dialogs::StaticText>,
L<TUI::Dialogs::InputLine>

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

