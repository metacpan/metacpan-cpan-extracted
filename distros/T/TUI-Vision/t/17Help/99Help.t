use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Help';
  use_ok 'TUI::Objects';
}

isa_ok( new_TRefTable( 10, 5 ), TRefTable() );
isa_ok( new_THelpIndex(), THelpIndex() );
isa_ok( new_THelpTopic(), THelpTopic() );
isa_ok( new_TTopicDefinition( 'Introduction', 100 ), TTopicDefinition() );
open my $stream, '<', \'' or die;
my $helpFile = new_THelpFile( $stream );
isa_ok( $helpFile, THelpFile() );
isa_ok( new_THelpViewer(
  TRect->new( ax => 0, ay => 0, bx => 20, by => 5 ),
  undef, undef, $helpFile, 0 ), THelpViewer() );
isa_ok( new_THelpWindow( $helpFile, 0 ), THelpWindow() );

done_testing();
