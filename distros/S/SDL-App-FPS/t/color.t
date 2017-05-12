#!/usr/bin/perl -w

use Test::More tests => 58;
use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, '../blib/lib';
  unshift @INC, '../blib/arch';
  unshift @INC, '.';
  chdir 't' if -d 't';
  use_ok ('SDL::App::FPS::Color');
  }

can_ok ('SDL::App::FPS::Color', qw/
   darken lighten blend desaturate
  /);
# fail due to AUTOLOAD. Should we add a can() method to cater for these?
#  red green blue orange yellow purple
#  white black gray lightgray darkgray
#  lightred darkred lightblue darkblue lightgreen darkgreen 

foreach my $name (qw/
  red green blue orange yellow purple magenta cyan brown
  white black gray lightgray darkgray
  lightred darkred lightblue darkblue lightgreen darkgreen
  /)
  {
  my $cname = uc($name);
  my $color = SDL::App::FPS::Color->$cname();
  is (ref($color), 'SDL::Color', "$cname");
  }

my $c = 'SDL::App::FPS::Color';
my $red = $c->RED();
my $green = $c->GREEN();
my $blue = $c->BLUE();
my $white = $c->WHITE();
my $black = $c->BLACK();


is ($c->darken($red,0.5)->r(), 0x7f, 'dark red is half red');

is ($c->darken($red,1)->r(), 0, 'result is black');
is ($c->darken($red,1)->g(), 0, 'result is black');
is ($c->darken($red,1)->b(), 0, 'result is black');

is ($c->darken($red,0)->r(), 0xff, 'result is red');
is ($c->darken($red,0)->g(), 0, 'result is red');
is ($c->darken($red,0)->b(), 0, 'result is red');

is ($c->lighten($red,0.5)->g(), 0x7f, 'light red is half green');
is ($c->lighten($red,0.5)->b(), 0x7f, 'light red is half blue');

is ($c->lighten($red,1)->r(), 0xff, 'result is white');
is ($c->lighten($red,1)->g(), 0xff, 'result is white');
is ($c->lighten($red,1)->b(), 0xff, 'result is white');

is ($c->lighten($red,0)->r(), 0xff, 'result is red');
is ($c->lighten($red,0)->g(), 0, 'result is red');
is ($c->lighten($red,0)->b(), 0, 'result is red');

is ($c->blend($red,$green,0.5)->r(), 0x7f, 'result is 50% red');
is ($c->blend($red,$green,0.5)->g(), 0x7f, 'result is 50% green');
is ($c->blend($red,$green,0.5)->b(), 0, 'result is 0% blue');

# (0xff * 0.5 + 0 + 0) / 3
is ($c->desaturate($red,0.5)->r(), 0x2a, 'result is 50% red');
is ($c->desaturate($red,0.5)->g(), 0x2a, 'result is 50% green');
is ($c->desaturate($red,0.5)->b(), 0x2a, 'result is 50% blue');

# (0xff * 1 + 0 + 0) / 3
is ($c->desaturate($green,0.5)->r(), 85, 'result is 50% red');
is ($c->desaturate($green,0.5)->g(), 85, 'result is 50% green');
is ($c->desaturate($green,0.5)->b(), 85, 'result is 50% blue');

# (0xff * 0.5 * 3) / 3
is ($c->desaturate($white,0.5)->r(), 212, 'result is 50% red');
is ($c->desaturate($white,0.5)->g(), 212, 'result is 50% green');
is ($c->desaturate($white,0.5)->b(), 212, 'result is 50% blue');

##############################################################################
# invert

is ($c->invert($white)->r(), 0, 'white is black');
is ($c->invert($white)->g(), 0, 'white is black');
is ($c->invert($white)->b(), 0, 'white is black');

is ($c->invert($black)->r(), 255, 'black is white is black');
is ($c->invert($black)->g(), 255, 'black is white');
is ($c->invert($black)->b(), 255, 'black is white');

is ($c->invert($blue)->r(), 255, 'blue is yellow');
is ($c->invert($blue)->g(), 255, 'blue is yellow');
is ($c->invert($blue)->b(), 0, 'blue is yellow');

