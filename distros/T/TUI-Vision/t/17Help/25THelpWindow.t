use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Help::HelpWindow';
  use_ok 'TUI::Help::HelpFile';
  use_ok 'TUI::Help::HelpViewer';
  use_ok 'TUI::Views::Const', qw( ofCentered );
  use_ok 'TUI::Views::Window';
}

my $source = ".topic Start=10\n"
  . "See {next:Later}.\n"
  . ".topic Later=20\n"
  . "Plain text.\n";

sub new_window {
  open my $stream, '<:raw', \$source or die $!;
  my $helpFile = THelpFile->new( stream => $stream );
  return THelpWindow->new( hFile => $helpFile, context => 10 );
}

subtest 'construction creates a centered 50x18 help window' => sub {
  my $window = new_window();
  isa_ok( $window, 'TUI::Help::HelpWindow' );
  isa_ok( $window, 'TUI::Views::Window' );
  is( $window->title, 'Help', 'title is Help' );
  is( $window->size->{x}, 50, 'width is 50' );
  is( $window->size->{y}, 18, 'height is 18' );
  ok( $window->options & ofCentered, 'ofCentered is set' );
};

subtest 'window hosts a viewer with both scroll bars' => sub {
  my $window = new_window();
  my $viewer = $window->firstThat( sub {
    $_[0]->isa( 'TUI::Help::HelpViewer' ) } );
  isa_ok( $viewer, 'TUI::Help::HelpViewer' );
  ok( $viewer->{hScrollBar}, 'viewer has a horizontal scroll bar' );
  ok( $viewer->{vScrollBar}, 'viewer has a vertical scroll bar' );
  is( $viewer->topic->getNumCrossRefs, 1,
    'viewer shows the requested topic' );
};

subtest 'getPalette returns a palette' => sub {
  isa_ok( new_window()->getPalette, 'TUI::Views::Palette' );
};

done_testing();
