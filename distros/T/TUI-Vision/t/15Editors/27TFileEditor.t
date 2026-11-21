use strict;
use warnings;

use Test::More;
use TUI::toolkit;

use File::Spec;
use File::Temp qw( tempdir );

BEGIN {
  use_ok 'TUI::Drivers::Const', qw( evCommand evNothing );
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Views::Const', qw( :cmXXXX );
  use_ok 'TUI::Editors::Const', qw( efBackupFiles edSaveModify );
  use_ok 'TUI::Editors::Editor';
  use_ok 'TUI::Editors::FileEditor';
}

my $dir = tempdir( CLEANUP => 1 );

sub new_file_editor {
  my ( $name ) = @_;
  return TFileEditor->new(
    bounds     => TRect->new( ax => 0, ay => 0, bx => 40, by => 10 ),
    hScrollBar => undef,
    vScrollBar => undef,
    indicator  => undef,
    fileName   => $name,
  );
}

sub write_file {
  my ( $path, $text ) = @_;
  open my $fh, '>:raw', $path or die "cannot write $path: $!";
  print {$fh} $text;
  close $fh;
}

sub read_file {
  my ( $path ) = @_;
  open my $fh, '<:raw', $path or die "cannot read $path: $!";
  local $/;
  my $text = <$fh>;
  close $fh;
  return $text;
}

subtest 'a missing file yields an empty, valid editor' => sub {
  my $path = File::Spec->catfile( $dir, 'new.txt' );
  my $e = new_file_editor( $path );
  ok( $e->{isValid}, 'editor is valid' );
  is( $e->bufLen(), 0, 'buffer is empty' );
  is( $e->{fileName}, $path, 'file name is kept' );
};

subtest 'an existing file is loaded into the buffer' => sub {
  my $path = File::Spec->catfile( $dir, 'load.txt' );
  write_file( $path, "line one\nline two\n" );
  my $e = new_file_editor( $path );
  ok( $e->{isValid}, 'editor is valid' );
  is( $e->{buffer}, "line one\nline two\n", 'buffer holds the file text' );
  is( $e->bufLen(), 18, 'buffer length matches the file' );
  ok( !$e->{modified}, 'freshly loaded buffer is not modified' );
};

subtest 'save() writes the buffer back to the file' => sub {
  my $path = File::Spec->catfile( $dir, 'save.txt' );
  write_file( $path, "old\n" );
  my $e = new_file_editor( $path );
  $e->insertText( "new ", 4, false );
  ok( $e->{modified}, 'buffer is modified after insertText' );
  ok( $e->save(), 'save returns true' );
  is( read_file( $path ), "new old\n", 'file holds the buffer text' );
  ok( !$e->{modified}, 'save clears the modified flag' );
};

subtest 'efBackupFiles keeps the previous version as .BAK' => sub {
  my $path = File::Spec->catfile( $dir, 'backup.txt' );
  my $bak  = File::Spec->catfile( $dir, 'backup.BAK' );
  write_file( $path, "before\n" );
  my $e = new_file_editor( $path );
  $e->insertText( "after ", 6, false );

  local $TUI::Editors::Editor::editorFlags = efBackupFiles;
  ok( $e->saveFile(), 'saveFile returns true' );
  is( read_file( $bak ), "before\n", 'backup holds the previous content' );
  is( read_file( $path ), "after before\n", 'file holds the new content' );
};

subtest 'valid() asks before discarding modified text' => sub {
  my $path = File::Spec->catfile( $dir, 'valid.txt' );
  write_file( $path, "keep\n" );
  my $e = new_file_editor( $path );
  ok( $e->valid( cmValid ), 'cmValid reports the validity' );
  ok( $e->valid( cmNo ), 'unmodified editor is always valid' );

  $e->insertText( "x", 1, false );
  my @asked;
  local $TUI::Editors::FileEditor::editorDialog = sub {
    push @asked, $_[0];
    return cmCancel;
  };
  ok( !$e->valid( cmYes ), 'cmCancel rejects closing a modified editor' );
  is_deeply( \@asked, [ edSaveModify ], 'user is asked to save the changes' );

  $TUI::Editors::FileEditor::editorDialog = sub { cmNo };
  ok( $e->valid( cmYes ), 'cmNo discards the changes' );
  ok( !$e->{modified}, 'discarding clears the modified flag' );
  is( read_file( $path ), "keep\n", 'file is unchanged after discarding' );
};

subtest 'handleEvent() saves on cmSave and clears the event' => sub {
  my $path = File::Spec->catfile( $dir, 'event.txt' );
  write_file( $path, "" );
  my $e = new_file_editor( $path );
  $e->insertText( "saved", 5, false );

  my $event = TEvent->new(
    what    => evCommand,
    message => { command => cmSave },
  );
  $e->handleEvent( $event );
  is( read_file( $path ), "saved", 'cmSave writes the buffer' );
  is( $event->{what}, evNothing, 'the command event is cleared' );
};

done_testing();
