use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::App::Const';
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::App::Background';
  use_ok 'TUI::App::DeskInit';
  use_ok 'TUI::App::DeskTop';
  use_ok 'TUI::App::ProgInit';
  use_ok 'TUI::App::Program';
  use_ok 'TUI::App::Application';
}

isa_ok(
  TBackground->new( bounds => TRect->new(), pattern => '#' ),
  TBackground
);
isa_ok( TDeskInit->new( cBackground => sub { } ), TDeskInit );
isa_ok( TDeskTop->new( bounds => TRect->new() ),  TDeskTop );
isa_ok( TProgInit->new(
  cStatusLine => sub { },
  cMenuBar    => sub { },
  cDeskTop    => sub { },
), TProgInit );
ok( TProgram->can( 'new' ), 'TProgram->new() exists' );
ok( TApplication->can( 'new' ), 'TApplication->new_() exists' );

done_testing();
