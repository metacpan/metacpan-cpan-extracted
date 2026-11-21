use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Help::Const';
  use_ok 'TUI::Help::RefTable';
  use_ok 'TUI::Help::HelpBase';
  use_ok 'TUI::Help::HelpIndex';
  use_ok 'TUI::Help::TopicDefinition';
  use_ok 'TUI::Help::HelpTopic';
  use_ok 'TUI::Help::HelpFile';
  use_ok 'TUI::Help::HelpViewer';
  use_ok 'TUI::Help::HelpWindow';
  use_ok 'TUI::Objects';
}

isa_ok( TRefTable->new( limit => 10, delta => 5 ), TRefTable() );
isa_ok( THelpIndex->new(), THelpIndex() );
isa_ok( THelpTopic->new(), THelpTopic() );
isa_ok( TTopicDefinition->new( topic => 'Introduction', value => 100 ),
  TTopicDefinition() );
isa_ok( TParagraph->new( next => undef, wrap => 0, size => 0, text => '' ),
  'TParagraph' );
isa_ok( TCrossRef->new( ref => 0, offset => 0, length => 0 ), 'TCrossRef' );
isa_ok( TReference->new( topic => '', resolved => 0, val => 0 ),
  'TReference' );

open my $stream, '<', \'' or die;
my $helpFile = THelpFile->new( stream => $stream );
isa_ok( $helpFile, THelpFile() );
isa_ok( THelpViewer->new(
  bounds     => TRect->new( ax => 0, ay => 0, bx => 20, by => 5 ),
  hScrollBar => undef,
  vScrollBar => undef,
  hFile      => $helpFile,
  context    => 0,
), THelpViewer() );
isa_ok( THelpWindow->new( hFile => $helpFile, context => 0 ), THelpWindow() );

done_testing();
