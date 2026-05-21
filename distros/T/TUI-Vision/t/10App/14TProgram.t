use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::App::DeskTop';
  use_ok 'TUI::App::Program';
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Menus::MenuBar';
  use_ok 'TUI::Menus::StatusLine';
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Views::Const', qw( cmCancel );
  use_ok 'TUI::Views::Palette';
  use_ok 'TUI::Views::View';
}

# Test initDeskTop method
subtest 'initDeskTop' => sub {
  can_ok( TProgram, 'initDeskTop' );
  my $desktop = TProgram->initDeskTop( TRect->new() );
  isa_ok( $desktop, TDeskTop, 'initDeskTop returns a TDeskTop object' );
};

# Test initMenuBar method
subtest 'initMenuBar' => sub {
  can_ok( TProgram, 'initMenuBar' );
  my $menuBar = TProgram->initMenuBar( TRect->new() );
  isa_ok( $menuBar, TMenuBar, 'initMenuBar returns a TMenuBar object' );
};

# Test initStatusLine method
subtest 'initStatusLine' => sub {
  can_ok( TProgram, 'initStatusLine' );
  my $statusLine = TProgram->initStatusLine( TRect->new() );
  isa_ok( $statusLine, TStatusLine,
    'initStatusLine returns a TStatusLine object' );
};

my $program;

# Test object creation
subtest 'object creation' => sub {
  $program = TProgram->new();
  isa_ok( $program, TProgram, 'Object is of class TProgram' );
  isa_ok( $TUI::App::Program::deskTop, TDeskTop, 
    '$desktop is of class TDesktop' );
};

# Test canMoveFocus method
subtest 'canMoveFocus' => sub {
  can_ok( $program, 'canMoveFocus' );
  is( $program->canMoveFocus(), 1, 'canMoveFocus returns correct value' );
};

# Test executeDialog method
subtest 'executeDialog' => sub {
  can_ok( $program, 'executeDialog' );
  my $dialog = TView->new( bounds => TRect->new() );
  is( $program->executeDialog( $dialog, undef ), cmCancel,
    'executeDialog returns correct value'
);
};

# Test getEvent method
subtest 'getEvent' => sub {
  can_ok( $program, 'getEvent' );
  my $event = TEvent->new();
  lives_ok { $program->getEvent( $event ) } 'getEvent works correctly';
};

# Test getPalette method
subtest 'getPalette' => sub {
  can_ok( $program, 'getPalette' );
  my $palette = $program->getPalette();
  isa_ok( $palette, TPalette, 'getPalette returns a TPalette object' );
};

# Test handleEvent method
subtest 'handleEvent' => sub {
  can_ok( $program, 'handleEvent' );
  my $event = TEvent->new();
  lives_ok { $program->handleEvent( $event ) } 'handleEvent works correctly';
};

# Test putEvent method
subtest 'putEvent' => sub {
  can_ok( $program, 'putEvent' );
  my $event = TEvent->new();
  lives_ok { $program->putEvent( $event ) } 'putEvent works correctly';
};

# Test idle method
subtest 'idle' => sub {
  can_ok( $program, 'idle' );
  lives_ok { $program->idle() } 'idle works correctly';
};

# Test insertWindow method
subtest 'insertWindow' => sub {
  can_ok( $program, 'insertWindow' );
  my $window = TView->new( bounds => TRect->new );
  is( $program->insertWindow( $window ), $window,
    'insertWindow returns correct value' );
};

# Test validView method
subtest 'validView' => sub {
  can_ok( $program, 'validView' );
  my $window = TView->new( bounds => TRect->new );
  is( $program->validView( $window ), $window,
    'validView returns correct value' );
};

# Test outOfMemory method
subtest 'outOfMemory' => sub {
  can_ok( $program, 'outOfMemory' );
  lives_ok { $program->outOfMemory() } 'outOfMemory works correctly';
};

# Test initScreen method
subtest 'initScreen' => sub {
  can_ok( $program, 'initScreen' );
  lives_ok { $program->initScreen() } 'initScreen works correctly';
};

# Test setScreenMode method
subtest 'setScreenMode' => sub {
  can_ok( $program, 'setScreenMode' );
  lives_ok { $program->setScreenMode( 0 ) } 'setScreenMode works correctly';
};

# Test shutDown method
subtest 'shutDown' => sub {
  can_ok( $program, 'shutDown' );
  lives_ok { $program->shutDown() } 'shutDown works correctly';
};

done_testing();
