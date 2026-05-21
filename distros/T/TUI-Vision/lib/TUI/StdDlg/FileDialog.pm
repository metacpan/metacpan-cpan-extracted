package TUI::StdDlg::FileDialog;
# ABSTRACT: Common file dialogs

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TFileDialog
  new_TFileDialog
);

use Carp ();
use Scalar::Util qw( readonly );
use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  :is
  :types
);

use TUI::Dialogs::Const qw(
  bfDefault
  bfNormal
);
use TUI::Dialogs::Button;
use TUI::Dialogs::Dialog;
use TUI::Dialogs::Label;
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
  MAXPATH
  :cmXXXX
  :fdXXXX
);
use TUI::StdDlg::Dir qw( :all );
use TUI::StdDlg::FileInfoPane;
use TUI::StdDlg::FileInputLine;
use TUI::StdDlg::FileList;
use TUI::StdDlg::Util qw( :all );
use TUI::Views::Const qw(
  cmCancel
  cmHelp
  cmOK
  cmValid
  ofCentered
);
use TUI::Views::ScrollBar;

sub TFileDialog() { __PACKAGE__ }
sub name() { 'TFileDialog' }
sub new_TFileDialog { __PACKAGE__->from(@_) }

extends TDialog;

# declare global variables
our $filesText        = "~F~iles";
our $openText         = "~O~pen";
our $okText           = "~O~K";
our $replaceText      = "~R~eplace";
our $clearText        = "~C~lear";
our $cancelText       = "~C~ancel";
our $helpText         = "~H~elp";
our $invalidDriveText = "Invalid drive or directory";
our $invalidFileText  = "Invalid file name.";

# public attributes
has fileName  => ( is => 'rw' );
has fileList  => ( is => 'rw' );
has wildCard  => ( is => 'rw', default => sub { die 'required' } );
has directory => ( is => 'rw', default => '' );

# predeclare private methods
my ( 
  $readDirectory,
  $checkDirectory,
);

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named => [
      wildCard  => Str, { alias => 'aWildCard' },
      title     => Str, { alias => 'aTitle' },
      inputName => Str,
      options   => PositiveOrZeroInt, { alias => 'aOptions' },
      histId    => PositiveOrZeroInt,
    ],
    caller_level => +1,
  );
  my ( $class, $args1 ) = $sig->( @_ );
  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  my $args2 = $class->SUPER::BUILDARGS(
    bounds => TRect->new( ax => 15, ay => 1, bx => 64, by => 20 ), 
    title  => $args1->{title}, 
  );
  return { %$args1, %$args2 };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_HashRef $args );
  $self->{options} |= ofCentered;

  $self->{fileName} = TFileInputLine->new( 
    bounds => TRect->new( ax => 3, ay => 3, bx => 31, by => 4 ), 
    maxLen => MAXPATH,
  );

  $self->{fileName}{data} = substr( $self->{wildCard}, 0, MAXPATH );
  $self->insert( $self->{fileName} );
  
  $self->insert( TLabel->new(
    bounds => TRect->new(
      ax => 2,                                ay => 2,
      bx => 3 + length( $args->{inputName} ), by => 3,
    ),
    text => $args->{inputName},
    link => $self->{fileName},
  ));
  $self->insert( THistory->new(
    bounds    => TRect->new( ax => 31, ay => 3, bx => 34, by => 4 ),
    link      => $self->{fileName},
    historyId => $args->{histId},
  ));
  my $sb = TScrollBar->new( 
    bounds => TRect->new( ax => 3, ay => 14, bx => 34, by => 15 )
  );
  $self->insert( $sb );
  $self->insert( $self->{fileList} = TFileList->new( 
    bounds     => TRect->new( ax => 3, ay => 6, bx => 34, by => 14 ),
    vScrollBar => $sb,
  ));
  $self->insert( TLabel->new(
    bounds => TRect->new( ax => 2, ay => 5, bx => 8, by => 6 ),
    text   => $args->{inputName},
    link   => $self->{fileName},
  ));

  my $opt = bfDefault;
  my $r   = TRect->new( ax => 35, ay => 3, bx => 46, by => 5 );
  if ( $args->{options} & fdOpenButton ) {
    $self->insert( TButton->new(
      bounds  => $r,
      title   => $openText,
      command => cmFileOpen,
      flags   => $opt,
    ));
    $opt = bfNormal;
    $r->{a}{y} += 3;
    $r->{b}{y} += 3;
  }

  if ( $args->{options} & fdOKButton ) {
    $self->insert( TButton->new(
      bounds  => $r,
      title   => $okText,
      command => cmFileOpen,
      flags   => $opt,
    ));
    $opt = bfNormal;
    $r->{a}{y} += 3;
    $r->{b}{y} += 3;
  }

  if ( $args->{options} & fdReplaceButton ) {
    $self->insert( TButton->new(
      bounds  => $r,
      title   => $replaceText,
      command => cmFileReplace,
      flags   => $opt,
    ));
    $opt = bfNormal;
    $r->{a}{y} += 3;
    $r->{b}{y} += 3;
  }

  if ( $args->{options} & fdClearButton ) {
    $self->insert( TButton->new(
      bounds  => $r,
      title   => $clearText,
      command => cmFileClear,
      flags   => $opt,
    ));
    $opt = bfNormal;
    $r->{a}{y} += 3;
    $r->{b}{y} += 3;
  }

  $self->insert( TButton->new(
    bounds  => $r,
    title   => $cancelText,
    command => cmCancel,
    flags   => bfNormal,
  ));
  $r->{a}{y} += 3;
  $r->{b}{y} += 3;

  if ( $args->{options} & fdHelpButton ) {
    $self->insert( TButton->new(
      bounds  => $r,
      title   => $helpText,
      command => cmHelp,
      flags   => bfNormal,
    ));
    $opt = bfNormal;
    $r->{a}{y} += 3;
    $r->{b}{y} += 3;
  }

  $self->insert( TFileInfoPane->new(
    bounds => TRect->new( ax => 1, ay => 16, bx => 48, by => 18 )
  ));

  $self->selectNext( false );
  $self->$readDirectory()
    unless $args->{options} & fdNoLoadDir;

  return;
}

sub from {    # $obj ($aWildCard, $aTitle, $inputName, $aOptions, $histId)
  state $sig = signature(
    method => 1,
    pos    => [Str, Str, Str, PositiveOrZeroInt, PositiveOrZeroInt],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( wildCard => $args[0], title => $args[1], 
    inputName => $args[2], options => $args[3], histId => $args[4] );
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{directory} = undef;
  return;
}

sub getData {    # void (\@rec)
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike],
  );
  my ( $self, $rec ) = $sig->( @_ );
  $self->getFileName( $rec->[0] = '' );
  return;
}

my $relativePath = sub {    # $bool ($path)
  my ( $path ) = @_;
  assert ( @_ == 1 );
  assert ( is_Str $path );
  return ( length( $path )
      && ( substr( $path, 0, 1 ) eq '\\' || substr( $path, 1, 1 ) eq ':' ) );
};

my $noWildChars = sub {    # void ($dest, $src)
  my ( $dest, $src ) = @_;
  assert ( @_ == 2 );
  assert ( is_Str $dest );
  assert ( is_Str $src );
  assert ( not readonly $_[0] );
  $src =~ s/[?*]//g;
  $_[0] = $src;
  return;
};

my $trim = sub {    # void ($dest, $src)
  my ( $dest, $src ) = @_;
  assert ( @_ == 2 );
  assert ( is_Str $dest );
  assert ( is_Str $src );
  assert ( not readonly $_[0] );
  $src =~ s/^\s+//;
  if ( $src =~ /^(\S+)/ ) {
    $dest = $1;
  }
  else {
    $dest = '';
  }
  $_[0] = $dest;
  return;
};

sub getFileName {    # void ($s)
  state $sig = signature(
    method => Object,
    pos    => [Maybe[Str]],
  );
  my ( $self, $s ) = $sig->( @_ );
  assert ( not readonly $_[1] );

  my $buf   = '';
  my $drive = '';
  my $path  = '';
  my $name  = '';
  my $ext   = '';
  my $TName = '';
  my $TExt  = '';

  &$trim( $buf, $self->{fileName}{data} );
  if ( &$relativePath( $buf ) ) {
    $buf = $self->{directory};
    &$trim( local $_ = '', $self->{fileName}{data} );
    substr( $buf, length( $buf ) ) = $_;
  }

  # Resolve relative names against the currently selected directory.
  fexpand( $buf, $self->{directory} );
  fnsplit( $buf, $drive, $path, $name, $ext );

  if ( ( $name eq '' || $ext eq '' ) && !isDir( $buf ) ) {
    fnsplit( $self->{wildCard}, undef, undef, $TName, $TExt );
    if ( $name eq '' && $ext eq '' ) {
      fnmerge( $buf, $drive, $path, $TName, $TExt );
    }
    elsif ( $name eq '' ) {
      fnmerge( $buf, $drive, $path, $TName, $ext );
    }
    elsif ( $ext eq '' ) {
      if ( isWild( $name ) ) {
        fnmerge( $buf, $drive, $path, $name, $TExt );
      }
      else {
        fnmerge( $buf, $drive, $path, $name, undef );
        &$noWildChars( local $_ = '', $TExt );
        substr( $buf, length( $buf ) ) = $_;
      }
    }
  } #/ if ( ( $name eq '' || ...))

  $_[1] = $buf;
  return;
}

sub handleEvent {    # void ($event)
  no warnings 'uninitialized';
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  $self->SUPER::handleEvent( $event );
  if ( $event->{what} == evCommand ) {
    SWITCH: for ( $event->{message}{command} ) {
      cmFileOpen    == $_ ||
      cmFileReplace == $_ ||
      cmFileClear   == $_ and do {
        $self->endModal( $event->{message}{command} );
        $self->clearEvent( $event );
        last;
      };
      DEFAULT: {
        last;
      }
    }
  }
  elsif ( $event->{what} == evBroadcast
       && $event->{message}{command} == cmFileDoubleClicked
  ) {
    $event->{what} = evCommand;
    $event->{message}{command} = cmOK;
    $self->putEvent( $event );
    $self->clearEvent( $event );
  }

  return;
} #/ sub handleEvent

sub setData {    # void (\@rec)
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike],
  );
  my ( $self, $rec ) = $sig->( @_ );
  $self->SUPER::setData( $rec );
  if ( length $rec->[0] && isWild( $rec->[0] ) ) {
    $self->valid( cmFileInit );
    $self->{fileName}->select();
  }
  return;
}

sub valid {    # $bool ($command)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  my ( $self, $command ) = $sig->( @_ );

  my ( $fName, $drive, $dir, $name, $ext ) = ( '', '', '', '', '' );

  return false 
    unless $self->SUPER::valid( $command );
        
  # The base TDialog::valid() doesn't handle these.
  return true 
    if $command == cmValid || $command == cmCancel || $command == cmFileClear;

  $self->getFileName( $fName );

  if ( isWild( $fName ) ) {
    fnsplit( $fName, $drive, $dir, $name, $ext );
    my $path = $drive . $dir;

    if ( $self->$checkDirectory( $path ) ) {
      $self->{directory} = $path;
      $self->{wildCard} = $name . $ext;
      if ( $command != cmFileInit ) {
        $self->{fileList}->select();
      }
      $self->{fileList}->readDirectory( $self->{directory}, $self->{wildCard} );
    }

    return false;
  } #/ if ( isWild( $fName ) )

  if ( isDir( $fName ) ) {
    if ( $self->$checkDirectory( $fName ) ) {

      # BUG FIX - EFW - Fixed incorrect addition of an
      # additional backslash under certain circumstances.
      $fName .= '\\'
        if $fName !~ /\\$/;

      $self->{directory} = $fName;
      if ( $command != cmFileInit ) {
        $self->{fileList}->select();
      }
      $self->{fileList}->readDirectory( $self->{directory}, $self->{wildCard} );
    }

    return false;
  } #/ if ( isDir( $fName ) )

  if ( validFileName( $fName ) ) {
    return true
  }

  messageBox( $invalidDriveText, mfError | mfOKButton );
  return false;
}

sub shutDown {    # void ($self)
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->{fileName} = undef;
  $self->{fileList} = undef;
  $self->SUPER::shutDown();
  return;
}

$readDirectory = sub {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( is_Object $self );
  my $curDir = '';
  getCurDir( $curDir );
  $self->{directory} = $curDir;
  $self->{fileList}->readDirectory( $self->{wildCard} );
  return;
};

$checkDirectory = sub {    # $bool ($str)
  my ( $self, $str ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Str $str );
  if ( pathValid( $str ) ) {
    return true 
  } 
  else {
    messageBox( $invalidDriveText, mfError | mfOKButton );
    $self->{fileName}->select();
    return false;
  }
};

1

__END__

=pod

=head1 NAME

TUI::StdDlg::FileDialog - common file selection dialog

=head1 HIERARCHY

  TObject
    TView
      TGroup
        TWindow
          TDialog
            TFileDialog

=head1 SYNOPSIS

  use TUI::StdDlg;
  use TUI::MsgBox;

  my @fileName = ('*.*');

  my $dialog = TFileDialog->new(
    wildCard  => $fileName[0],
    title     => 'Open File',
    inputName => '~F~ile Name',
    options   => fdOpenButton,
    histId    => 1,
  );

  if ( $application->executeDialog($dialog, \@fileName) != cmCancel ) {
    messageBox( "'$fileName[0]' was entered", mfOkButton );
  }
  
=head1 DESCRIPTION

C<TFileDialog> implements the standard TUI::Vision file dialog used for
opening, replacing, or selecting files.

The dialog combines several specialized views, including a file list, an input
line for file names, and an information pane displaying details about the
currently focused file. It manages directory navigation, wildcard filtering,
and user interaction through keyboard and mouse input.

=head1 VARIABLES

The following global variables define the default labels and messages
used by C<TFileDialog>.

=head2 $filesText

Label text for the files list section.

=head2 $openText

Label text for the open action.

=head2 $okText

Label text for the confirmation button.

=head2 $replaceText

Label text for the replace action.

=head2 $clearText

Label text for the clear action.

=head2 $cancelText

Label text for the cancel action.

=head2 $helpText

Label text for the help command.

=head2 $invalidDriveText

Message text displayed for an invalid drive or directory.

=head2 $invalidFileText

Message text displayed for an invalid file name.

=head1 ATTRIBUTES

The following attributes are part of the public dialog state and may be queried
or updated during dialog execution.

=over

=item fileName

The currently selected file name (I<Str>).

=item fileList

Reference to the file list view used by the dialog (I<TFileList>).

=item wildCard

Current wildcard filter applied to the file list (I<Str>).

=item directory

Current directory shown by the dialog (I<Str>).

=back

=head1 CONSTRUCTOR

=head2 new

  my $dlg = TFileDialog->new(
    wildCard  => $wildCard,
    title     => $title,
    inputName => $inputName,
    options   => $options,
    histId    => $histId
  );

Creates a new file dialog.

=over

=item wildCard

Wildcard pattern used to filter displayed files (I<Str>).

=item title

Dialog window title (I<Str>).

=item inputName

Initial file name shown in the input line (I<Str>).

=item options

Dialog option flags controlling behavior and appearance (I<Int>).

=item histId

History identifier used for filename input history (I<Int>).

=back

=head2 new_TFileDialog

  my $dlg = new_TFileDialog(
    $wildCard,
    $title,
    $inputName,
    $options,
    $histId
  );

Factory-style constructor using positional arguments.

=head1 METHODS

=head2 getData

  $dlg->getData(\@record);

Stores the dialog result into the supplied record.

=head2 getFileName

  my $name = $dlg->getFileName($string);

Returns the selected file name.

=head2 handleEvent

  $dlg->handleEvent($event);

Processes keyboard and command events for dialog interaction.

=head2 setData

  $dlg->setData(\@record);

Restores dialog state from external input.

=head2 shutDown

  $dlg->shutDown();

Releases dialog resources during shutdown.

=head2 valid

  my $bool = $dlg->valid($command);

Checks whether the dialog should accept the specified command.

=head1 SEE ALSO

L<TUI::StdDlg::FileList>,
L<TUI::StdDlg::FileInputLine>,
L<TUI::StdDlg::FileInfoPane>,
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
