package TUI::StdDlg::ChDirDialog;
# ABSTRACT: Common dialog box for selecting a directory

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TChDirDialog
  new_TChDirDialog
);

use Carp ();
use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  :is
  :types
);

use TUI::Const qw( EOS );
use TUI::Dialogs::Const qw(
  bfDefault
  bfNormal
);
use TUI::Dialogs::Button;
use TUI::Dialogs::Dialog;
use TUI::Dialogs::Label;
use TUI::Dialogs::InputLine;
use TUI::Dialogs::History;
use TUI::Drivers::Const qw(
  evBroadcast
  evCommand
);
use TUI::MsgBox::Const qw(
  mfError
  mfOKButton
);
use TUI::MsgBox::MsgBoxText qw( messageBox );
use TUI::Objects::Rect;
use TUI::StdDlg::Const qw(
  :cmXXXX
  cdHelpButton
  cdNoLoadDir
);
use TUI::StdDlg::Dir qw( setdisk );
use TUI::StdDlg::DirListBox;
use TUI::StdDlg::Util qw(
  driveValid
  fexpand
  getCurDir
);
use TUI::Views::Const qw(
  cmHelp
  cmOK
  ofCentered
);
use TUI::Views::ScrollBar;

sub TChDirDialog() { __PACKAGE__ }
sub name() { 'TChDirDialog' }
sub new_TChDirDialog { __PACKAGE__->from(@_) }

extends TDialog;

# declare global variables
our $changeDirTitle = "Change Directory";
our $dirNameText    = "Directory ~n~ame";
our $dirTreeText    = "Directory ~t~ree";
our $okText         = "O~K~";
our $chdirText      = "~C~hdir";
our $revertText     = "~R~evert";
our $helpText       = "Help";
our $drivesText     = "Drives";
our $invalidText    = "Invalid directory";

# private attributes
has dirInput    => ( is => 'bare' );
has dirList     => ( is => 'bare' );
has okButton    => ( is => 'bare' );
has chDirButton => ( is => 'bare' );

# predeclare private methods
my ( 
  $setUpDialog,
);

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named => [
      options   => PositiveOrZeroInt, { alias => 'aOptions' },
      histId    => PositiveOrZeroInt,
    ],
    caller_level => +1,
  );
  my ( $class, $args1 ) = $sig->( @_ );
  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  my $args2 = $class->SUPER::BUILDARGS(
    bounds => TRect->new( ax => 16, ay => 2, bx => 64, by => 20 ), 
    title  => $changeDirTitle, 
  );
  return { %$args1, %$args2 };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_HashRef $args );
  $self->{options} |= ofCentered;

  $self->{dirInput} = TInputLine->new( 
    bounds => TRect->new( ax => 3, ay => 3, bx => 30, by => 4 ), 
    maxLen => 68,
  );
  $self->insert( $self->{dirInput} );
  $self->insert( TLabel->new(
    bounds => TRect->new( ax => 2, ay => 2, bx => 17, by => 3 ),
    text => $dirNameText,
    link => $self->{dirInput},
  ));
  $self->insert( THistory->new(
    bounds    => TRect->new( ax => 30, ay => 3, bx => 33, by => 4 ),
    link      => $self->{dirInput},
    historyId => $args->{histId},
  ));

  my $sb = TScrollBar->new( 
    bounds => TRect->new( ax => 32, ay => 6, bx => 33, by => 16 )
  );
  $self->insert( $sb );
  $self->{dirList} = TDirListBox->new( 
    bounds     => TRect->new( ax => 3, ay => 6, bx => 32, by => 16 ),
    vScrollBar => $sb,
  );
  $self->insert( $self->{dirList} );
  $self->insert( TLabel->new(
    bounds => TRect->new( ax => 2, ay => 5, bx => 17, by => 6 ),
    text   => $dirTreeText,
    link   => $self->{dirList},
  ));

  $self->{okButton} = TButton->new( 
    bounds  => TRect->new( ax => 35, ay => 3, bx => 46, by => 5 ),
    title   => $okText, 
    command => cmOK, 
    flags   => bfDefault,
  );
  $self->insert( $self->{okButton} );
  $self->{chDirButton} = TButton->new( 
    bounds  => TRect->new( ax => 35, ay => 9, bx => 45, by => 11 ),
    title   => $chdirText, 
    command => cmChangeDir, 
    flags   => bfNormal,
  );
  $self->insert( $self->{chDirButton} );
  $self->insert( TButton->new(
    bounds  => TRect->new( ax => 35, ay => 12, bx => 45, by => 14 ),
    title   => $revertText, 
    command => cmRevert, 
    flags   => bfNormal,
  ));
  if ( $args->{options} & cdHelpButton ) {
    $self->insert( TButton->new(
      bounds  => TRect->new( ax => 35, ay => 15, bx => 45, by => 17 ),
      title   => $helpText,
      command => cmHelp,
      flags   => bfNormal,
    ));
  }
  $self->$setUpDialog()
    unless $args->{options} & cdNoLoadDir;
  $self->selectNext( false );

  return;
}

sub from {    # $obj ($aOptions, $histId)
  state $sig = signature(
    method => 1,
    pos    => [PositiveOrZeroInt, PositiveOrZeroInt],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( options => $args[0], histId => $args[1] );
}

sub dataSize {    # $dSize ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  $sig->( @_ );
  return 0;
}

sub getData {    # void (\@rec)
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike],
  );
  $sig->( @_ );
  return;
}

sub handleEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  $self->SUPER::handleEvent( $event );
  if ( $event->{what} == evCommand ) {
    my $curDir = '';
    SWITCH: for ( $event->{message}{command} ) {
      cmRevert == $_ and do {
        getCurDir( $curDir );
        last;
      };
      cmChangeDir == $_ and do {
        my $p = $self->{dirList}->list()->at( $self->{dirList}{focused} );
        $curDir = $p->dir();
        if ( $curDir eq $drivesText ) {
          last;
        }
        elsif ( length( $curDir ) && driveValid( substr( $curDir, 0, 1 ) ) ) {
          $curDir .= "\\"
            if substr( $curDir, -1, 1 ) ne '\\';
        }
        else {
          return;
        }
        last;
      };
      # Handle directory selection.
      cmDirSelection == $_ and do {
        $self->{chDirButton}->makeDefault( !!$event->{message}{infoPtr} );
        return;    # Note: return (not last) like in the original code
      };
      DEFAULT: {
        return;
      };
    }
    $self->{dirList}->newDirectory( $curDir );
    my $len = length( $curDir );
    if ( $len > 3 && substr( $curDir, -1, 1 ) eq '\\' ) {
      substr( $curDir, $len - 1 ) = EOS;
    }
    $self->{dirInput}{data} = $curDir;
    $self->{dirInput}->drawView();
    $self->{dirList}->select();
    $self->clearEvent( $event );
  }

  return;
} #/ sub handleEvent

sub setData {    # void (\@rec)
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike],
  );
  $sig->( @_ );
  return;
}

my $changeDir = sub {    # $int ($path)
  my ( $path ) = @_;
  assert ( @_ == 1 );
  assert ( is_Str $path );
  if ( length( $path ) && substr( $path, 1, 1 ) eq ':' ) {
    setdisk( ord( uc substr( $path, 0, 1 ) ) - ord( 'A' ) );
  }
  return chdir( $path ) ? 0 : -1;
};

sub valid {    # $bool ($command)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  my ( $self, $command ) = $sig->( @_ );

  return true 
    if $command == cmOK;

  my $path = $self->{dirInput}{data};

  # BUG FIX - EFW - Tue 05/16/95
  # Ignore "Drives" line if switching drives.
  $path = ''
    if $path ne $drivesText;

  # If it was "Drives" or the input line was blank, issue a
  # cmChangeDir event to select the current drive/directory.
  if ( $path ne '' ) {
    my $event = TEvent->new();
    $event->{what} = evCommand;
    $event->{message}{command} = cmChangeDir;
    $self->putEvent( $event );
    return false;
  }

  # Otherwise, expand and check the path.
  fexpand( $path );

  my $len = length( $path );
  if ( $len > 3 && substr( $path, -1, 1 ) eq '\\' ) {
    substr( $path, $len - 1 ) = EOS;
  }

  if ( &$changeDir( $path ) != 0 ) {
    messageBox( $invalidText, mfError | mfOKButton );
    return false;
  }
  return true;
}

sub shutDown {    # void ($self)
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->{dirList}     = undef;
  $self->{dirInput}    = undef;
  $self->{okButton}    = undef;
  $self->{chDirButton} = undef;
  $self->SUPER::shutDown();
  return;
}

$setUpDialog = sub {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( is_Object $self );

  if ( $self->{dirList} ) {
    my $curDir = '';
    getCurDir( $curDir );
    $self->{dirList}->newDirectory( $curDir );
    if ( $self->{dirInput} ) {
      my $len = length $curDir;
      if ( $len > 3 && substr( $curDir, $len - 1, 1 ) eq '\\' ) {
        substr( $curDir, $len - 1 ) = EOS;
      }
      $self->{dirInput}{data} = $curDir;
      $self->{dirInput}->drawView();
    }
  }

  return;
}; #/ $setUpDialog = sub

1

__END__

=pod

=head1 NAME

TUI::StdDlg::ChDirDialog - common dialog for selecting a directory

=head1 HIERARCHY

  TObject
    TView
      TGroup
        TWindow
          TDialog
            TChDirDialog

=head1 SYNOPSIS

  use TUI::StdDlg;

  my $dlg = new_TChDirDialog(
    $options,
    $histId
  );

  my $result = $deskTop->execView($dlg);

=head1 DESCRIPTION

C<TChDirDialog> implements the standard TUI::Vision dialog used for selecting
and changing directories.

The dialog presents a directory list, an input line for the directory path,
and command buttons. It allows navigation through the directory hierarchy
using keyboard and mouse input and returns the selected directory to the
caller.

=head1 VARIABLES

The following global variables define the default labels and messages
used by C<TChDirDialog>.

=head2 $changeDirTitle

Title text of the change directory dialog.

=head2 $dirNameText

Label text for the directory name input field.

=head2 $dirTreeText

Label text for the directory tree view.

=head2 $okText

Label text for the confirmation button.

=head2 $chdirText

Label text for the change directory action.

=head2 $revertText

Label text for the revert action.

=head2 $helpText

Label text for the help command.

=head2 $drivesText

Label text for the drives selection area.

=head2 $invalidText

Message text displayed for an invalid directory.

=head1 CONSTRUCTOR

=head2 new

  my $dlg = TChDirDialog->new(
    options => $options,
    histId  => $histId
  );

Creates a new change-directory dialog.

=over

=item options

Dialog option flags controlling behavior and appearance (I<Int>).

=item histId

History identifier used for directory input history (I<Int>).

=back

=head2 new_TChDirDialog

  my $dlg = new_TChDirDialog($options, $histId);

Factory-style constructor using positional arguments.

=head1 METHODS

=head2 dataSize

  my $size = $dlg->dataSize();

Returns the number of scalar values transferred via C<getData> and C<setData>.

=head2 getData

  $dlg->getData(\@record);

Stores the selected directory into the supplied record.

=head2 handleEvent

  $dlg->handleEvent($event);

Processes keyboard and command events for directory navigation and selection.

=head2 setData

  $dlg->setData(\@record);

Initializes the dialog state from external input.

=head2 shutDown

  $dlg->shutDown();

Releases dialog resources during shutdown.

=head2 valid

  my $bool = $dlg->valid($command);

Checks whether the dialog should accept the specified command.

=head1 SEE ALSO

L<TUI::StdDlg::DirListBox>,
L<TUI::StdDlg::DirEntry>,
L<TUI::Dialogs::Dialog>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 CONTRIBUTORS

=over

=item * Eric Woodruff

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 1995, 2026 the L</AUTHORS> and L</CONTRIBUTORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is 
part of the distribution). 

=cut
