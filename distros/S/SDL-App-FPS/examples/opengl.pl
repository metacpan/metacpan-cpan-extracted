#!/usr/bin/perl -w

# spinning cube in OpenGL

use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, './lib';
  unshift @INC, '../lib';
  unshift @INC, '../blib/arch/';
  }

use SDL::App::FPS::MyOpenGL;

print
  "SDL::App::FPS OpenGL Demo v0.01 (C) 2002,2003 by Tels <http://Bloodgate.com/>\n\n";

my $app = SDL::App::FPS::MyOpenGL->new( config => 'config/opengl.cfg' );

print "\nPress '", $app->event_bound_to('fullscreen'),"' for ",
      "toggling fullscreen mode, ";
print "'", $app->event_bound_to('quit'),"' for quit, and '",
      $app->event_bound_to('pause'),"' for pause.\n";

$app->main_loop();

print "\nRunning time was ", int($app->now() / 10)/100, " seconds\n";
print "Minimum framerate ",int($app->min_fps()*10)/10,
      " fps, maximum framerate ",int($app->max_fps()*10)/10," fps\n";
print "Minimum time per frame ", $app->min_frame_time(),
      " ms, maximum time per frame ", $app->max_frame_time()," ms\n";
print "Thank you for playing!\n";
