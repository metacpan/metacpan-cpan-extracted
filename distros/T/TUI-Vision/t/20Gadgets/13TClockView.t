use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Gadgets::ClockView';
}

{
  package MyClockView;
  use TUI::toolkit;
  extends 'TUI::Gadgets::ClockView';
  sub writeLine { ::pass 'writeLine()'  }
  sub drawView  { ::pass 'drawView()' }
  $INC{"MyClockView.pm"} = 1;
}

my $view;
subtest 'TClockView->new()' => sub {
  require_ok( 'MyClockView' );
  $view = MyClockView->new( bounds => TRect->new() );
  isa_ok( $view, TClockView );
};

subtest 'draw()' => sub {
  can_ok( $view, 'draw' );
  lives_ok { $view->draw() } 'draw() does not die';
};

subtest 'update()' => sub {
  can_ok( $view, 'update' );
  lives_ok { $view->update() } 'update() does not die';
};

subtest 'fields' => sub {
  ok( $view->{curTime}, "'curTime' is defined and not empty" );
  like( $view->{curTime}, qr/^\d\d:\d\d:\d\d$/, 
    "'curTime' has a valid format" );

  ok( $view->{lastTime}, "'lastTime' is defined and not empty" );
  like( $view->{lastTime}, qr/^\d\d:\d\d:\d\d$/, 
    "'lastTime' has a valid format" );
};

done_testing();
