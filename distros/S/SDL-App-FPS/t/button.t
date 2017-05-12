#!/usr/bin/perl -w

use Test::More tests => 38;
use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, '../blib/lib';
  unshift @INC, '../blib/arch';
  unshift @INC, '.';
  chdir 't' if -d 't';
  use_ok ('SDL::App::FPS::Button');
  }

can_ok ('SDL::App::FPS::Button', qw/ 
  new _init activate deactivate is_active id
  x y width height move_to resize _hit_rect _hit_elliptic check
  BUTTON_RECTANGULAR
  BUTTON_ELLIPTIC
  
  BUTTON_MOUSE_LEFT
  BUTTON_MOUSE_RIGHT
  BUTTON_MOUSE_MIDDLE
  
  BUTTON_IN
  BUTTON_OUT
  BUTTON_HOVER
  BUTTON_CLICK
  BUTTON_PRESSED
  BUTTON_UP
  BUTTON_RELEASED
  BUTTON_DOWN
  /);

##############################################################################
package DummyEvent;

use SDL::Event;
use SDL;
# a dummy event package to simulate an SDL::Event

sub new { bless { }, 'DummyEvent'; }

sub type { SDL_MOUSEBUTTONDOWN; }

sub button { SDL::App::FPS::Button::BUTTON_MOUSE_LEFT; }

sub motion_x { 2; }
sub motion_y { 2; }

##############################################################################

package main;

my $de = 0; sub _deactivated_thing { $de ++; }
my $ac = 0; sub _activated_thing { $ac ++; }

# create button

my $pressed = {};

my $button = SDL::App::FPS::Button->new
  ( 'main', 11, 22, 23, 83,
   SDL::App::FPS::Button::BUTTON_CLICK,
   SDL::App::FPS::Button::BUTTON_RECTANGULAR,
   SDL::App::FPS::Button::BUTTON_MOUSE_LEFT,
   sub { my ($self,$button) = @_;
    is ($self, 'main', 'app got passed ok');
    $pressed->{$button->id()}++; 
   },
  );

is (ref($button), 'SDL::App::FPS::Button', 'button new worked');
is ($button->id(), 1, 'button id is 1');
is ($button->x(), 11, 'x is 11');
is ($button->y(), 22, 'y is 22');
is ($button->width(), 23, 'w is 23');
is ($button->height(), 83, 'h is 83');
is ($button->x(5), 5, 'x is now 5');
is ($button->y(6), 6, 'y is now 6');
is ($button->width(8), 8, 'w is now 8');
is ($button->height(10), 10, 'h is now 10');
is ($button->x(), 5, 'x is still 5');
is ($button->y(), 6, 'y is still 6');
is ($button->width(), 8, 'w is still 8');
is ($button->height(), 10, 'h is still 10');

is ($button->_hit_rect(5,6), 1, '5,6 hit');
is ($button->_hit_rect(1,1), 1, '1,1 still hit (ul)');
is ($button->_hit_rect(9,1), 1, '9,1 still hit (ur)');
is ($button->_hit_rect(1,11), 1, '1,11 still hit (ll)');
is ($button->_hit_rect(9,11), 1, '9,11 still hit (lr)');
is ($button->_hit_rect(0,1), 0, '0,1 no hit');
is ($button->_hit_rect(10,1), 0, '10,1 no hit');
is ($button->_hit_rect(5,0), 0, '5,0 no hit');
is ($button->_hit_rect(5,12), 0, '5,12 no hit');

is ($button->is_active(), 1, 'handler is active');
is ($button->deactivate(), 0, 'handler is deactive');
is ($button->is_active(), 0, 'handler is no longer active');
is ($button->activate(), 1, 'handler is active again');


my $dummyevent = DummyEvent->new();

$button->deactivate();
$button->check($dummyevent,$dummyevent->type);
is ($pressed->{$button->id()} || 0, 0, 'callback was not called');
$button->activate();
$button->check($dummyevent,$dummyevent->type);
is ($pressed->{$button->id()}|| 0, 0, 'callback was not called');

$button = SDL::App::FPS::Button->new
  ( 'main', 11, 22, 20, 40,
   SDL::App::FPS::Button::BUTTON_DOWN,
   SDL::App::FPS::Button::BUTTON_RECTANGULAR,
   SDL::App::FPS::Button::BUTTON_MOUSE_LEFT,
   sub { my ($self,$button,@args) = @_;
    is ($self, 'main', 'app got passed ok');
    is (scalar @args, 2, '2 additional args');
    is ($args[0], 123, 'first ok');
    is ($args[1], 345, 'second ok');
    $pressed->{$button->id()}++; 
   }, 123, 345
  );
$button->check($dummyevent,$dummyevent->type);
is ($pressed->{$button->id()}, 1, 'callback was ok');


is ($button->height(0), 1, 'h is never 0');
is ($button->width(0), 1, 'w is never 0');

