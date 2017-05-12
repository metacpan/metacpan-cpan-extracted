#!/usr/bin/perl -w

# Shows mouse-over, context-"menus", bubble-help and button click events
# click the buttons with right and left and move the mouse over the red
# rectangle
# ' q' for quit, 'f' for fullscreen

use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, './lib';
  unshift @INC, '../lib';
  unshift @INC, '../blib/arch/';
  }

use SDL::App::FPS::MyMouse;

my $options = { width => 640, height => 480, max_fps => 15};

print
  "Mouse demo v0.01 (C) 2003 by Tels <http://Bloodgate.com/>\n\n";

my $app = SDL::App::FPS::MyMouse->new( $options );
$app->main_loop();

print "Running time was ", int($app->now() / 10)/100, " seconds\n";
print "Minimum framerate ",int($app->min_fps()*10)/10,
      " fps, maximum framerate ",int($app->max_fps()*10)/10," fps\n";
print "Minimum time per frame ", $app->min_frame_time(),
      " ms, maximum time per frame ", $app->max_frame_time()," ms\n";
print "Thank you for playing!\n";
