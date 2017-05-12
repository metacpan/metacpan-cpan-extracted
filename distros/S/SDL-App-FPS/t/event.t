#!/usr/bin/perl -w

use Test::More tests => 22;
use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, '../blib/lib';
  unshift @INC, '../blib/arch';
  unshift @INC, '.';
  chdir 't' if -d 't';
  use_ok ('SDL::App::FPS::EventHandler');
  }

can_ok ('SDL::App::FPS::EventHandler', qw/ 
  rebind check type kind
  new _init activate is_active deactivate id
  char2key
  _init_mod
  require_all_modifiers
  ignore_additional_modifiers
  /);

use SDL::Event;
use SDL::App::FPS::Button qw/BUTTON_MOUSE_LEFT BUTTON_MOUSE_RIGHT/;
use SDL;

##############################################################################
package DummyEvent;

use SDL::Event;
use SDL;
# a dummy event package to simulate an SDL::Event

sub new { bless { }, 'DummyEvent'; }

sub type { SDL_KEYDOWN; }
sub key_sym { SDLK_SPACE; }
sub key_mod { 0; }

package DummyEventMouse;

use SDL::Event;
use SDL;
# a dummy event package to simulate an SDL::Event

sub new { bless { button => $_[1] }, 'DummyEventMouse'; }

sub type { SDL_MOUSEBUTTONDOWN; }
sub button { $_[0]->{button}; }			# RMB 
sub key_mod { 0; }
sub key_sym { 0; }

##############################################################################

package main;

my $de = 0; sub _deactivated_thing { $de ++; }
my $ac = 0; sub _activated_thing { $ac ++; }

# create eventhandler

my $space_pressed = 0;
my $handler = SDL::App::FPS::EventHandler->new
  ('main', SDL_KEYDOWN, SDLK_SPACE, sub { $space_pressed++; }, );

is (ref($handler), 'SDL::App::FPS::EventHandler', 'handler new worked');
is ($handler->id(), 1, 'handler id is 1');
is ($handler->type(), SDL_KEYDOWN, 'type is SDL_KEYDOWN');
is ($handler->kind(), SDLK_SPACE, 'kind is SDLK_SPACE');
is ($handler->is_active(), 1, 'handler is active');

is ($handler->deactivate(), 0, 'handler is deactive');
is ($handler->is_active(), 0, 'handler is no longer active');
is ($handler->activate(), 1, 'handler is active again');

my $dummyevent = DummyEvent->new();

$handler->deactivate();
$handler->check($dummyevent,$dummyevent->type(),$dummyevent->key_sym());
is ($space_pressed, 0, 'callback was not called');
$handler->activate();
$handler->check($dummyevent,$dummyevent->type(),$dummyevent->key_sym());
is ($space_pressed, 1, 'callback was called');		# bug in v0.07

##############################################################################
# check mouse button events and combinations

# watch for left or right, and is triggered when left is pressed
my $pressed = 0;
$dummyevent = DummyEventMouse->new( BUTTON_MOUSE_LEFT );
$handler = SDL::App::FPS::EventHandler->new
  ('main', SDL_MOUSEBUTTONDOWN, BUTTON_MOUSE_LEFT + BUTTON_MOUSE_RIGHT,
   sub { $pressed++; }, );

$handler->check($dummyevent,$dummyevent->type,$dummyevent->button);
is ($pressed, 1, 'callback was called');
$dummyevent = DummyEventMouse->new( BUTTON_MOUSE_RIGHT );

$handler->check($dummyevent,$dummyevent->type,$dummyevent->button);
is ($pressed, 2, 'callback was called again');
  
is ($handler->require_all_modifiers(), 0, 'require all');
is ($handler->ignore_additional_modifiers(), 1, 'ignore additional');

##############################################################################

$handler = SDL::App::FPS::EventHandler->new
  ('main', SDL_KEYDOWN, [ SDLK_a, SDLK_LSHIFT ],
   sub { $pressed++; }, );

is ($handler->require_all_modifiers(), 0, 'require all');
is ($handler->ignore_additional_modifiers(), 0, 'ignore additional');

is ($handler->require_all_modifiers(1), 1, 'now require all');
is ($handler->require_all_modifiers(), 1, 'still require all');
is ($handler->ignore_additional_modifiers(1), 1, 'now ignore additional');
is ($handler->ignore_additional_modifiers(), 1, 'still ignore additional');

