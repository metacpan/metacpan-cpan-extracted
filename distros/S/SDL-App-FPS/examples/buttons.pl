#!/usr/bin/perl -w

# a simple game, press 'f' to toggle fullscreen, space to pause it, and
# ' q' for quit

# Hit each rectangle with the left mouse button, until all have vanished - then
# you win. If there are ever more than 20, you loose.

use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, './lib';
  unshift @INC, '../lib';
  unshift @INC, '../blib/arch/';
  }

use SDL::App::FPS::MyButt;	# grab MyButt and use it

my $options = { width => 800, height => 600, max_fps => 40};

print
  "Buttons v0.02 (C) 2003, 2006 by Tels <http://Bloodgate.com/>\n\n";

my $app = SDL::App::FPS::MyButt->new( $options );
$app->main_loop();

if ($app->{won} == 1)
  {
  print "You won! Hurra!\n\n";
  }
else
  {
  print "You lost! Next time try harder!\n\n";
  }

print "Your score: $app->{score}\n\n";

print "Running time was ", int($app->now() / 10)/100, " seconds\n";
print "Minimum framerate ",int($app->min_fps()*10)/10,
      " fps, maximum framerate ",int($app->max_fps()*10)/10," fps\n";
print "Minimum time per frame ", $app->min_frame_time(),
      " ms, maximum time per frame ", $app->max_frame_time()," ms\n";
print "Maximum number of rectangles: $app->{max}\n\n";
print "Thank you for playing!\n";
