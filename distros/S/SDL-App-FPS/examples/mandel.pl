#!/usr/bin/perl -w

# a simple game, press 'f' to toggle fullscreen, space to pause it, and
# q for quit.

use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, './lib';
  unshift @INC, '../lib';
  unshift @INC, '../blib/arch/';
  }

use SDL::App::FPS::MyMandel;

print "SDL Mandelbrot (C) v0.03 2002,2003,2006 by Tels <http://Bloodgate.com/>\n\n";

if (SDL::App::FPS::MyMandel::use_perl() == 0)
  {
  print "\n Warning: Cannot find Math::Fractal::Mandelbrot,",
        " for more speed please install\n it from search.cpan.org.",
        " Using Perl code as fallback.\n\n";
  }
else
  {
  print "\n Using Math::Fractal::Mandelbrot v",
  "$Math::Fractal::Mandelbrot::VERSION as speed-booster.\n\n";
  }

my $app = SDL::App::FPS::MyMandel->new( config => 'config/mandel.cfg' );
$app->main_loop();

print "Running time was ", int($app->now() / 10)/100, " seconds\n";
print "Minimum framerate ",int($app->min_fps()*10)/10,
      " fps, maximum framerate ",int($app->max_fps()*10)/10," fps\n";
print "Minimum time per frame ", $app->min_frame_time(),
      " ms, maximum time per frame ", $app->max_frame_time()," ms\n";
print "Thank you for playing!\n";
