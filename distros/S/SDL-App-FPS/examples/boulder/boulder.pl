#!/usr/bin/perl -w

# Simple game, involving a guy, big boulders and diamonds, all in a cave

# keypad plus and minus to zoom
# ' q' for quit, 'f' for fullscreen, SPACE for pause
# drag the window corner to resize window
# cursor keys to move him around
# button for quit, starting anew, buttons to load/save game,
# F6 for quicksave, F9 for quickload

use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, './lib';
  unshift @INC, '../../lib';
  unshift @INC, '../../blib/arch/';
  }

use SDL::App::FPS::MyBoulder;

my $options = { width => 640, height => 480, max_fps => 25 };

print
  "Boulder demo v0.02 (C) 2003 by Tels <http://Bloodgate.com/>\n\n";

my $app = SDL::App::FPS::MyBoulder->new( $options );
$app->main_loop();

print "Running time was ", int($app->now() / 10)/100, " seconds\n";
print "Minimum framerate ",int($app->min_fps()*10)/10,
      " fps, maximum framerate ",int($app->max_fps()*10)/10," fps\n";
print "Minimum time per frame ", $app->min_frame_time(),
      " ms, maximum time per frame ", $app->max_frame_time()," ms\n";
print "Thank you for playing!\n";
