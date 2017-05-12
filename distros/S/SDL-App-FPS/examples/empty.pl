#!/usr/bin/perl -w

use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, './lib';
  unshift @INC, '../lib';
  unshift @INC, '../blib/arch/';
  }

use SDL::App::FPS::Empty;

my $options = { width => 640, height => 480, max_fps => 500 };

print "Empty benchmark v0.01 (C) 2002-2003 by Tels <http://Bloodgate.com/>\n\n";

my $app = SDL::App::FPS::Empty->new( $options );
$app->main_loop();

print "Running time was ", int($app->now() / 10)/100, " seconds\n";
print "Minimum framerate ",$app->min_fps(),
      " fps, maximum framerate ",$app->max_fps()," fps\n";
print "Minimum time per frame ", $app->min_frame_time(),
      " ms, maximum time per frame ", $app->max_frame_time()," ms\n";
print "Thank you for playing!\n";
