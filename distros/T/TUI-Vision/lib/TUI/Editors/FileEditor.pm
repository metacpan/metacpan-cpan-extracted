package TUI::Editors::FileEditor;
# ABSTRACT: text editor view bound to a file on disk

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TFileEditor
  new_TFileEditor
);

use Carp ();
use File::Basename qw( fileparse );
use Storable;
use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  is_HashRef
  is_Object
  is_Str
  :types
);

use TUI::Const qw( EOS );
use TUI::Drivers::Const qw( :evXXXX );
use TUI::Drivers::Event;
use TUI::Editors::Const qw(
  :cmXXXX
  :edXXXX
  :efXXXX
  ufUpdate
);
use TUI::Editors::Editor;
use TUI::Objects::Rect;
use TUI::StdDlg::Util qw( fexpand );
use TUI::Views::Const qw(
  cmCancel
  cmNo
  cmSave
  cmSaveAs
  cmValid
  cmYes
);
use TUI::Views::Util qw( message );

sub TFileEditor() { __PACKAGE__ }
sub name() { 'TFileEditor' }
sub new_TFileEditor { __PACKAGE__->from(@_) }

extends TEditor;

# import global variables
use vars qw(
  $editorDialog
  $editorFlags
); 
{
  *editorDialog = \$TUI::Editors::Editor::editorDialog;
  *editorFlags  = \$TUI::Editors::Editor::editorFlags;
}

# public attributes
has fileName => ( is => 'rw', default => '' );

# declare local variables
my $backupExt = '.BAK';

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      bounds     => Object,
      hScrollBar => Maybe[Object], { alias => 'aHScrollBar' },
      vScrollBar => Maybe[Object], { alias => 'aVScrollBar' },
      indicator  => Maybe[Object], { alias => 'aIndicator'  },
      fileName   => Maybe[Str],    { alias => 'aFileName'   },
    ],
    caller_level => +1,
  );
  my ( $class, $args1 ) = $sig->( @_ );
  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  my $args2 = $class->SUPER::BUILDARGS(
    bounds     => $args1->{bounds},
    hScrollBar => $args1->{hScrollBar},
    vScrollBar => $args1->{vScrollBar},
    indicator  => $args1->{indicator},
    bufSize    => 0,
  );
  return { %$args1, %$args2 };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{fileName} //= EOS;
  if ( length $self->{fileName} ) {
    fexpand( $self->{fileName} );
    $self->{isValid} = $self->loadFile()
      if $self->{isValid};
  }
  return;
}

sub from {    # $obj ($bounds, $aHScrollBar|undef, $aVScrollBar|undef, $aIndicator|undef, $aFileName|undef)
  state $sig = signature(
    method => 1,
    pos    => [
      Object,
      Maybe[Object],
      Maybe[Object],
      Maybe[Object],
      Maybe[Str],
    ],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], hScrollBar => $args[1],
    vScrollBar => $args[2], indicator => $args[3], fileName => $args[4] );
}

sub handleEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  $self->SUPER::handleEvent( $event );
  return 
    if $event->{what} != evCommand;

  SWITCH: for ( $event->{message}{command} ) {
    cmSave == $_ and do {
      $self->save();
      last;
    };
    cmSaveAs == $_ and do {
      $self->saveAs();
      last;
    };
    return;
  } #/ SWITCH: for ( $event->{message}{command} )

  $self->clearEvent( $event );
  return;
}

sub loadFile {    # $bool ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $fh;
  if ( !open $fh, '<:raw', $self->{fileName} ) {
    $self->setBufLen( 0 );
    return true;
  }

  my $fSize = -s $fh // 0;
  my $data  = '';
  my $read  = read $fh, $data, $fSize;
  if ( !defined $read || $read != $fSize ) {
    close $fh;
    &$editorDialog( edReadError, $self->{fileName} );
    return false;
  }
  close $fh;

  $self->{buffer} = $data;
  $self->setBufLen( length $data );
  return true;
}

sub save {    # $bool ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  return length $self->{fileName} 
    ? $self->saveFile() 
    : $self->saveAs();
}

sub saveAs {    # $bool ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $res = false;
  if ( &$editorDialog( edSaveAs, $self->{fileName} ) != cmCancel ) {
    fexpand( $self->{fileName} );
    message( $self->{owner}, evBroadcast, cmUpdateTitle, undef );
    $res = $self->saveFile();
    $self->{fileName} = EOS
      if $self->isClipboard();
  }
  return $res;
}

sub saveFile {    # $bool ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );

  if ( $editorFlags & efBackupFiles ) {
    my ( $file, $dir, $ext ) = fileparse( $self->{fileName}, qr/\.[^.]*/ );
    my $backupName = $dir . $file . $backupExt;
    unlink $backupName;
    rename $self->{fileName}, $backupName;
  }

  my $fh;
  if ( !open $fh, '>:raw', $self->{fileName} ) {
    &$editorDialog( edCreateError, $self->{fileName} );
    return false;
  }

  my $written = print {$fh} $self->{buffer};
  my $closed  = close $fh;
  if ( !$written || !$closed ) {
    &$editorDialog( edWriteError, $self->{fileName} );
    return false;
  }

  $self->{modified} = false;
  $self->update( ufUpdate );
  return true;
}

sub shutDown {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->setCmdState( cmSave, false );
  $self->setCmdState( cmSaveAs, false );
  $self->SUPER::shutDown();
  return;
}

sub updateCommands {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->SUPER::updateCommands();
  $self->setCmdState( cmSave, true );
  $self->setCmdState( cmSaveAs, true );
  return;
}

sub valid {    # $bool ($command)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  my ( $self, $command ) = $sig->( @_ );
  return $self->{isValid} if $command == cmValid;

  if ( $self->{modified} ) {
    my $d = length $self->{fileName} ? edSaveModify : edSaveUntitled;
    my $result = &$editorDialog( $d, $self->{fileName} );
    SWITCH: for ( $result ) {
      cmYes == $_ and return $self->save();
      cmNo  == $_ and do {
        $self->{modified} = false;
        return true;
      };
      cmCancel == $_ and return false;
    } #/ SWITCH: for ( $result )
  }
  return true;
}

sub write :method {    # void ($os)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $os ) = $sig->( @_ );
  $self->SUPER::write( $os );
  $os->put(
    $self->{fileName}, $self->{selStart}, $self->{selEnd}, $self->{curPtr},
  );
  return;
}

sub read :method {    # $self ($is)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $is ) = $sig->( @_ );
  $self->SUPER::read( $is );
  $self->{fileName} = $is->get();
  if ( $self->{isValid} ) {
    $self->{isValid} = $self->loadFile();
    my $sStart = $is->get();
    my $sEnd   = $is->get();
    my $curs   = $is->get();
    if ( $self->{isValid} && $sEnd <= $self->bufLen() ) {
      $self->setSelect( $sStart, $sEnd, $curs == $sStart ? true : false );
      $self->trackCursor( true );
    }
  }
  return $self;
}

sub build {    # $obj ()
  my ( $class ) = @_;
  assert ( @_ == 1 );
  assert ( is_Str $class );
  assert ( Storable::is_retrieving );
  return $class->new(
    bounds     => TRect->new(),
    hScrollBar => undef,
    vScrollBar => undef,
    indicator  => undef,
    fileName   => '',
  );
}

1

__END__

=pod

=head1 NAME

TUI::Editors::FileEditor - text editor view bound to a file on disk

=head1 HIERARCHY

  TObject
    TView
      TEditor
        TFileEditor

=head1 SYNOPSIS

  use TUI::Objects;
  use TUI::Editors;

  my $editor = TFileEditor->new(
    bounds     => TRect->new( ax => 0, ay => 1, bx => 79, by => 23 ),
    hScrollBar => $hScrollBar,
    vScrollBar => $vScrollBar,
    indicator  => $indicator,
    fileName   => 'notes.txt',
  );
  $self->insert( $editor );

=head1 DESCRIPTION

C<TFileEditor> is a L<TEditor|TUI::Editors::Editor> that is associated with a
file. It loads the file into the editor buffer when it is created and writes
the buffer back to the file when it is saved.

The editor handles the C<cmSave> and C<cmSaveAs> commands and asks the user
before discarding modified text through the C<$editorDialog> callback of
L<TEditor|TUI::Editors::Editor>. When the global C<$editorFlags> contain
C<efBackupFiles>, the previous version of the file is renamed to a file with
the extension C<.BAK> before it is overwritten.

The text buffer of L<TEditor|TUI::Editors::Editor> is a plain Perl string, so
the buffer allocation methods of I<Turbo Vision> (C<initBuffer>, C<doneBuffer>
and C<setBufSize>) are inherited unchanged.

=head1 ATTRIBUTES

=head2 fileName

Name of the file associated with the editor (I<Str>). The name is expanded to
a full path when it is set by the constructor or by C<saveAs>. An empty string
means the editor is untitled.

=head1 CONSTRUCTOR

=head2 new

  my $editor = TFileEditor->new(
    bounds     => $bounds,
    hScrollBar => $hScrollBar | undef,
    vScrollBar => $vScrollBar | undef,
    indicator  => $indicator  | undef,
    fileName   => $fileName   | undef,
  );

Creates a new file editor. If C<fileName> is a non-empty string, the file is
loaded into the buffer. A file that does not exist yields an empty buffer.

=over

=item bounds

Bounding rectangle of the view (L<TRect|TUI::Objects::Rect>).

=item hScrollBar

Optional horizontal scroll bar (L<TScrollBar|TUI::Views::ScrollBar> or 
C<undef>).

=item vScrollBar

Optional vertical scroll bar (L<TScrollBar|TUI::Views::ScrollBar> or C<undef>).

=item indicator

Optional position indicator (L<TIndicator|TUI::Editors::Indicator> or C<undef>).

=item fileName

Optional name of the file to edit (I<Str>).

=back

=head2 new_TFileEditor

  my $editor = new_TFileEditor(
    $bounds,
    $hScrollBar | undef,
    $vScrollBar | undef,
    $indicator  | undef,
    $fileName   | undef,
  );

Factory-style constructor using positional arguments.

=head1 METHODS

=head2 handleEvent

  $editor->handleEvent( $event );

Handles the inherited editor events. A C<cmSave> command saves the file and a
C<cmSaveAs> command calls L</saveAs>. Both commands clear the event.

=head2 loadFile

  my $bool = $editor->loadFile();

Loads the file named by L</fileName> into the buffer and returns true. A file
that cannot be opened is treated as a new, empty file. If the file cannot be
read completely, the C<edReadError> message is passed to C<$editorDialog> and
false is returned.

=head2 save

  my $bool = $editor->save();

Saves the buffer to L</fileName>. Calls L</saveAs> if the editor is untitled.

=head2 saveAs

  my $bool = $editor->saveAs();

Asks the user for a new file name through C<$editorDialog> with the
C<edSaveAs> message and saves the buffer to it. The file name is expanded to a
full path. Returns false if the user cancels.

=head2 saveFile

  my $bool = $editor->saveFile();

Writes the buffer to L</fileName>. If C<efBackupFiles> is set in
C<$editorFlags>, the existing file is first renamed to the backup name with the 
C<.BAK> extension. Returns false and passes the C<edCreateError> or 
C<edWriteError> to C<$editorDialog> on failure.

=head2 shutDown

  $editor->shutDown();

Disables the C<cmSave> and C<cmSaveAs> commands and shuts the view down.

=head2 updateCommands

  $editor->updateCommands();

Enables the C<cmSave> and C<cmSaveAs> commands in addition to the editor
commands.

=head2 valid

  my $bool = $editor->valid( $command );

For C<cmValid>, returns the validity of the editor attribute (C<isValid>). For 
any other command, a modified buffer triggers the C<edSaveModify> or
C<edSaveUntitled> message through C<$editorDialog>. C<cmYes> saves the file,
C<cmNo> discards the changes and C<cmCancel> rejects the command.

=head1 SEE ALSO

L<TEditor|TUI::Editors::Editor>,
L<TIndicator|TUI::Editors::Indicator>,
L<TFileViewer|TUI::Gadgets::FileViewer>

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
