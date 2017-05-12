#!/usr/bin/perl -w

use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, './lib';
  unshift @INC, '../lib';
  unshift @INC, '../blib/arch/';
  }

use SDL::App::FPS::MyEvent;

my $options = { width => 640, height => 480, max_fps => 40 };

print "Event handlers in groups (C) 2002,2003 by Tels <http://Bloodgate.com/>\n\n";

print "After the first rectangle appeared, press ENTER or the left mouse\n";
print "button to enter the manual move mode. Then use the cursor keys to\n";
print "move it around. Use ENTER or the left mouse button again to let it\n";
print "move around automatically. Repeat until bored, then press q.\n";
print "Quit (q), fullscreen (f) and pause (SPACE) work any time...\n";

print "Starting in 10 seconds...";
for (1..10) { print 10-$_,'..'; sleep(1); }
print "now\n";

my $app = SDL::App::FPS::MyEvent->new( $options );
$app->main_loop();

print "Running time was ", int($app->now() / 10)/100, " seconds\n";
print "Minimum framerate ",int($app->min_fps()*10)/10,
      " fps, maximum framerate ",int($app->max_fps()*10)/10," fps\n";
print "Minimum time per frame ", $app->min_frame_time(),
      " ms, maximum time per frame ", $app->max_frame_time()," ms\n";
print "Thank you for playing!\n";
