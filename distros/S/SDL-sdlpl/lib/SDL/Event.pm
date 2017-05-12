#!/usr/bin/perl -w 
#	Event.pm
#
#	A package for handling SDL_Event *
#
#	David J. Goehrig Copyright (C) 2000
#
#	see the file COPYING for terms of use
#

package SDL::Event;
use strict;
use SDL::sdlpl;

BEGIN {
	use Exporter();
	use vars qw(@EXPORT @ISA);
	@ISA = qw(Exporter);
	@EXPORT = qw(&SDL_IGNORE &SDL_ENABLE &SDL_QUERY
		     &SDL_ACTIVEEVENT &SDL_KEYDOWN &SDL_KEYUP
		     &SDL_MOUSEMOTION &SDL_MOUSEBUTTONDOWN 
		     &SDL_MOUSEBUTTONUP &SDL_QUIT &SDL_SYSWMEVENT
		     &SDL_APPMOUSEFOCUS &SDL_APPINPUTFOCUS 
		     &SDL_APPACTIVE &SDL_PRESSED &SDL_RELEASED
		     &SDL_VIDEORESIZE
		     &SDLK_BACKSPACE &SDLK_TAB &SDLK_CLEAR 
		     &SDLK_RETURN &SDLK_PAUSE &SDLK_ESCAPE 
		     &SDLK_SPACE &SDLK_EXCLAIM &SDLK_QUOTEDBL 
		     &SDLK_HASH &SDLK_DOLLAR &SDLK_AMPERSAND 
		     &SDLK_QUOTE &SDLK_LEFTPAREN &SDLK_RIGHTPAREN 
		     &SDLK_ASTERISK &SDLK_PLUS &SDLK_COMMA 
		     &SDLK_MINUS &SDLK_PERIOD &SDLK_SLASH 
		     &SDLK_0 &SDLK_1 &SDLK_2 
		     &SDLK_3 &SDLK_4 &SDLK_5 
		     &SDLK_6 &SDLK_7 &SDLK_8 
		     &SDLK_9 &SDLK_COLON &SDLK_SEMICOLON 
		     &SDLK_LESS &SDLK_EQUALS &SDLK_GREATER 
		     &SDLK_QUESTION &SDLK_AT &SDLK_LEFTBRACKET 
		     &SDLK_BACKSLASH &SDLK_RIGHTBRACKET &SDLK_CARET 
		     &SDLK_UNDERSCORE &SDLK_BACKQUOTE &SDLK_a 
		     &SDLK_b &SDLK_c &SDLK_d 
		     &SDLK_e &SDLK_f &SDLK_g 
		     &SDLK_h &SDLK_i &SDLK_j 
		     &SDLK_k &SDLK_l &SDLK_m 
		     &SDLK_n &SDLK_o &SDLK_p 
		     &SDLK_q &SDLK_r &SDLK_s 
		     &SDLK_t &SDLK_u &SDLK_v 
		     &SDLK_w &SDLK_x &SDLK_y 
		     &SDLK_z &SDLK_DELETE &SDLK_KP0 
		     &SDLK_KP1 &SDLK_KP2 &SDLK_KP3 
		     &SDLK_KP4 &SDLK_KP5 &SDLK_KP6 
		     &SDLK_KP7 &SDLK_KP8 &SDLK_KP9 
		     &SDLK_KP_PERIOD &SDLK_KP_DIVIDE &SDLK_KP_MULTIPLY 
		     &SDLK_KP_MINUS &SDLK_KP_PLUS &SDLK_KP_ENTER 
		     &SDLK_KP_EQUALS &SDLK_UP &SDLK_DOWN 
		     &SDLK_RIGHT &SDLK_LEFT &SDLK_INSERT 
		     &SDLK_HOME &SDLK_END &SDLK_PAGEUP 
		     &SDLK_PAGEDOWN &SDLK_F1 &SDLK_F2 
		     &SDLK_F3 &SDLK_F4 &SDLK_F5 
		     &SDLK_F6 &SDLK_F7 &SDLK_F8 
		     &SDLK_F9 &SDLK_F10 &SDLK_F11 
		     &SDLK_F12 &SDLK_F13 &SDLK_F14 
		     &SDLK_F15 &SDLK_NUMLOCK &SDLK_CAPSLOCK 
		     &SDLK_SCROLLOCK &SDLK_RSHIFT &SDLK_LSHIFT 
		     &SDLK_RCTRL &SDLK_LCTRL &SDLK_RALT 
		     &SDLK_LALT &SDLK_RMETA &SDLK_LMETA 
		     &SDLK_LSUPER &SDLK_RSUPER &SDLK_MODE 
		     &SDLK_HELP &SDLK_PRINT &SDLK_SYSREQ 
		     &SDLK_BREAK &SDLK_MENU &SDLK_POWER 
		     &SDLK_EURO &KMOD_NONE &KMOD_NUM 
		     &KMOD_CAPS &KMOD_LCTRL &KMOD_RCTRL 
		     &KMOD_RSHIFT &KMOD_LSHIFT &KMOD_RALT 
		     &KMOD_LALT &KMOD_CTRL &KMOD_SHIFT 
		     &KMOD_ALT); 
	}

#
# Constants
#

sub SDL_IGNORE { return SDL::sdlpl::sdl_ignore(); }
sub SDL_ENABLE { return SDL::sdlpl::sdl_enable(); }
sub SDL_QUERY { return SDL::sdlpl::sdl_query(); }
sub SDL_ACTIVEEVENT { return SDL::sdlpl::sdl_active_event(); }
sub SDL_KEYDOWN { return SDL::sdlpl::sdl_key_down(); }
sub SDL_KEYUP { return SDL::sdlpl::sdl_key_up(); }
sub SDL_MOUSEMOTION { return SDL::sdlpl::sdl_mouse_motion(); }
sub SDL_MOUSEBUTTONDOWN { return SDL::sdlpl::sdl_mouse_button_down(); }
sub SDL_MOUSEBUTTONUP { return SDL::sdlpl::sdl_mouse_button_up(); }
sub SDL_QUIT { return SDL::sdlpl::sdl_quit(); }
sub SDL_SYSWMEVENT { return SDL::sdlpl::sdl_sys_wm_event(); }
sub SDL_APPMOUSEFOCUS { return SDL::sdlpl::sdl_app_mouse_focus(); }
sub SDL_APPINPUTFOCUS { return SDL::sdlpl::sdl_app_input_focus(); }
sub SDL_APPACTIVE { return SDL::sdlpl::sdl_app_active(); }
sub SDL_PRESSED { return SDL::sdlpl::sdl_pressed(); }
sub SDL_RELEASED { return SDL::sdlpl::sdl_released(); }
sub SDL_VIDEORESIZE { return SDL::sdlpl::sdl_videoresize (); }
#
# Event Constructor / Destructor
#

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	$self->{-event} = SDL::sdlpl::sdl_new_event();
	bless $self, $class;
	return $self;
}

sub DESTROY {
	my $self = shift;
	SDL::sdlpl::sdl_free_event($self->{-event});
}

#
# Event typing
#

sub type {
	my $self = shift;
	return SDL::sdlpl::sdl_event_type($self->{-event});
}

#
# Polling and Waiting
#

sub pump {
	SDL::sdlpl::sdl_pump_events();
}

sub poll {
	my $self = shift;
	return SDL::sdlpl::sdl_poll_event($self->{-event});
}

sub wait {
	my $self = shift;
	return SDL::sdlpl::sdl_wait_event($self->{-event});
}

#
# set Event blocking & enabling
#

sub set { 
	my $self = shift;
	my $type = shift;
	my $state = shift;
	return SDL::sdlpl::sdl_event_state($type,$state);
}

#
# unicode and key repeat
#

sub set_unicode {
	my $self = shift;
	my $toggle = shift;
	return SDL::sdlpl::sdl_enable_unicode($toggle);
}

sub set_key_repeat {
	my $self = shift;
	my $delay = shift;
	my $interval = shift;
	return SDL::sdlpl::sdl_enable_key_repeat($delay,$interval);
}


#
# Active Events	
#

sub active_gain {
	my $self = shift;
	return SDL::sdlpl::sdl_active_event_gain($self->{-event});
}

sub active_state {
	my $self = shift;
	return SDL::sdlpl::sdl_active_event_state($self->{-event});
}

#
# Key Events
#

sub key_state {
	my $self = shift;
	return SDL::sdlpl::sdl_key_event_state($self->{-event});
}

sub key_sym {
	my $self = shift;
	return SDL::sdlpl::sdl_key_event_sym($self->{-event});
}

sub key_name {
	my $self = shift;
	return SDL::sdlpl::sdl_get_key_name(SDL::sdlpl::sdl_key_event_sym($self->{-event}));
}

sub key_mod {
	my $self = shift;
	return SDL::sdlpl::sdl_key_event_mod($self->{-event});
}

sub key_unicode {
	my $self = shift;
	return SDL::sdlpl::sdl_key_event_unicode($self->{-event});
}

sub key_scancode {
	my $self = shift;
	return SDL::sdlpl::sdl_key_event_scancode($self->{-event});
}

#
# Motion events
#

sub motion_state {
	my $self = shift;
	return SDL::sdlpl::sdl_mouse_motion_state($self->{-event});
}

sub motion_x {
	my $self = shift;
	return SDL::sdlpl::sdl_mouse_motion_x($self->{-event});
}

sub motion_y {
	my $self = shift;
	return SDL::sdlpl::sdl_mouse_motion_y($self->{-event});
}

sub motion_xrel {
	my $self = shift;
	return SDL::sdlpl::sdl_mouse_motion_xrel($self->{-event});
}

sub motion_yrel {
	my $self = shift;
	return SDL::sdlpl::sdl_mouse_motion_yrel($self->{-event});
}

#
# Button events
#

sub button_state {
	my $self = shift;
	return SDL::sdlpl::sdl_mouse_button_state($self->{-event});
}

sub button_x {
	my $self = shift;
	return SDL::sdlpl::sdl_mouse_button_x($self->{-event});
}

sub button_y {
	my $self = shift;
	return SDL::sdlpl::sdl_mouse_button_y($self->{-event});
}

sub button {
	my $self = shift;
	return SDL::sdlpl::sdl_mouse_button_button($self->{-event});
}

sub resize_width {
	my $self = shift;
	return SDL::sdlpl::sdl_resize_width($self->{-event});
}

sub resize_height {
	my $self = shift;
	return SDL::sdlpl::sdl_resize_height($self->{-event});
}


#
#	Keys and Mods
#

sub SDLK_BACKSPACE { return SDL::sdlpl::sdl_key_BACKSPACE(); }
sub SDLK_TAB { return SDL::sdlpl::sdl_key_TAB(); }
sub SDLK_CLEAR { return SDL::sdlpl::sdl_key_CLEAR(); }
sub SDLK_RETURN { return SDL::sdlpl::sdl_key_RETURN(); }
sub SDLK_PAUSE { return SDL::sdlpl::sdl_key_PAUSE(); }
sub SDLK_ESCAPE { return SDL::sdlpl::sdl_key_ESCAPE(); }
sub SDLK_SPACE { return SDL::sdlpl::sdl_key_SPACE(); }
sub SDLK_EXCLAIM { return SDL::sdlpl::sdl_key_EXCLAIM(); }
sub SDLK_QUOTEDBL { return SDL::sdlpl::sdl_key_QUOTEDBL(); }
sub SDLK_HASH { return SDL::sdlpl::sdl_key_HASH(); }
sub SDLK_DOLLAR { return SDL::sdlpl::sdl_key_DOLLAR(); }
sub SDLK_AMPERSAND { return SDL::sdlpl::sdl_key_AMPERSAND(); }
sub SDLK_QUOTE { return SDL::sdlpl::sdl_key_QUOTE(); }
sub SDLK_LEFTPAREN { return SDL::sdlpl::sdl_key_LEFTPAREN(); }
sub SDLK_RIGHTPAREN { return SDL::sdlpl::sdl_key_RIGHTPAREN(); }
sub SDLK_ASTERISK { return SDL::sdlpl::sdl_key_ASTERISK(); }
sub SDLK_PLUS { return SDL::sdlpl::sdl_key_PLUS(); }
sub SDLK_COMMA { return SDL::sdlpl::sdl_key_COMMA(); }
sub SDLK_MINUS { return SDL::sdlpl::sdl_key_MINUS(); }
sub SDLK_PERIOD { return SDL::sdlpl::sdl_key_PERIOD(); }
sub SDLK_SLASH { return SDL::sdlpl::sdl_key_SLASH(); }
sub SDLK_0 { return SDL::sdlpl::sdl_key_0(); }
sub SDLK_1 { return SDL::sdlpl::sdl_key_1(); }
sub SDLK_2 { return SDL::sdlpl::sdl_key_2(); }
sub SDLK_3 { return SDL::sdlpl::sdl_key_3(); }
sub SDLK_4 { return SDL::sdlpl::sdl_key_4(); }
sub SDLK_5 { return SDL::sdlpl::sdl_key_5(); }
sub SDLK_6 { return SDL::sdlpl::sdl_key_6(); }
sub SDLK_7 { return SDL::sdlpl::sdl_key_7(); }
sub SDLK_8 { return SDL::sdlpl::sdl_key_8(); }
sub SDLK_9 { return SDL::sdlpl::sdl_key_9(); }
sub SDLK_COLON { return SDL::sdlpl::sdl_key_COLON(); }
sub SDLK_SEMICOLON { return SDL::sdlpl::sdl_key_SEMICOLON(); }
sub SDLK_LESS { return SDL::sdlpl::sdl_key_LESS(); }
sub SDLK_EQUALS { return SDL::sdlpl::sdl_key_EQUALS(); }
sub SDLK_GREATER { return SDL::sdlpl::sdl_key_GREATER(); }
sub SDLK_QUESTION { return SDL::sdlpl::sdl_key_QUESTION(); }
sub SDLK_AT { return SDL::sdlpl::sdl_key_AT(); }
sub SDLK_LEFTBRACKET { return SDL::sdlpl::sdl_key_LEFTBRACKET(); }
sub SDLK_BACKSLASH { return SDL::sdlpl::sdl_key_BACKSLASH(); }
sub SDLK_RIGHTBRACKET { return SDL::sdlpl::sdl_key_RIGHTBRACKET(); }
sub SDLK_CARET { return SDL::sdlpl::sdl_key_CARET(); }
sub SDLK_UNDERSCORE { return SDL::sdlpl::sdl_key_UNDERSCORE(); }
sub SDLK_BACKQUOTE { return SDL::sdlpl::sdl_key_BACKQUOTE(); }
sub SDLK_a { return SDL::sdlpl::sdl_key_a(); }
sub SDLK_b { return SDL::sdlpl::sdl_key_b(); }
sub SDLK_c { return SDL::sdlpl::sdl_key_c(); }
sub SDLK_d { return SDL::sdlpl::sdl_key_d(); }
sub SDLK_e { return SDL::sdlpl::sdl_key_e(); }
sub SDLK_f { return SDL::sdlpl::sdl_key_f(); }
sub SDLK_g { return SDL::sdlpl::sdl_key_g(); }
sub SDLK_h { return SDL::sdlpl::sdl_key_h(); }
sub SDLK_i { return SDL::sdlpl::sdl_key_i(); }
sub SDLK_j { return SDL::sdlpl::sdl_key_j(); }
sub SDLK_k { return SDL::sdlpl::sdl_key_k(); }
sub SDLK_l { return SDL::sdlpl::sdl_key_l(); }
sub SDLK_m { return SDL::sdlpl::sdl_key_m(); }
sub SDLK_n { return SDL::sdlpl::sdl_key_n(); }
sub SDLK_o { return SDL::sdlpl::sdl_key_o(); }
sub SDLK_p { return SDL::sdlpl::sdl_key_p(); }
sub SDLK_q { return SDL::sdlpl::sdl_key_q(); }
sub SDLK_r { return SDL::sdlpl::sdl_key_r(); }
sub SDLK_s { return SDL::sdlpl::sdl_key_s(); }
sub SDLK_t { return SDL::sdlpl::sdl_key_t(); }
sub SDLK_u { return SDL::sdlpl::sdl_key_u(); }
sub SDLK_v { return SDL::sdlpl::sdl_key_v(); }
sub SDLK_w { return SDL::sdlpl::sdl_key_w(); }
sub SDLK_x { return SDL::sdlpl::sdl_key_x(); }
sub SDLK_y { return SDL::sdlpl::sdl_key_y(); }
sub SDLK_z { return SDL::sdlpl::sdl_key_z(); }
sub SDLK_DELETE { return SDL::sdlpl::sdl_key_DELETE(); }
sub SDLK_KP0 { return SDL::sdlpl::sdl_key_KP0(); }
sub SDLK_KP1 { return SDL::sdlpl::sdl_key_KP1(); }
sub SDLK_KP2 { return SDL::sdlpl::sdl_key_KP2(); }
sub SDLK_KP3 { return SDL::sdlpl::sdl_key_KP3(); }
sub SDLK_KP4 { return SDL::sdlpl::sdl_key_KP4(); }
sub SDLK_KP5 { return SDL::sdlpl::sdl_key_KP5(); }
sub SDLK_KP6 { return SDL::sdlpl::sdl_key_KP6(); }
sub SDLK_KP7 { return SDL::sdlpl::sdl_key_KP7(); }
sub SDLK_KP8 { return SDL::sdlpl::sdl_key_KP8(); }
sub SDLK_KP9 { return SDL::sdlpl::sdl_key_KP9(); }
sub SDLK_KP_PERIOD { return SDL::sdlpl::sdl_key_KP_PERIOD(); }
sub SDLK_KP_DIVIDE { return SDL::sdlpl::sdl_key_KP_DIVIDE(); }
sub SDLK_KP_MULTIPLY { return SDL::sdlpl::sdl_key_KP_MULTIPLY(); }
sub SDLK_KP_MINUS { return SDL::sdlpl::sdl_key_KP_MINUS(); }
sub SDLK_KP_PLUS { return SDL::sdlpl::sdl_key_KP_PLUS(); }
sub SDLK_KP_ENTER { return SDL::sdlpl::sdl_key_KP_ENTER(); }
sub SDLK_KP_EQUALS { return SDL::sdlpl::sdl_key_KP_EQUALS(); }
sub SDLK_UP { return SDL::sdlpl::sdl_key_UP(); }
sub SDLK_DOWN { return SDL::sdlpl::sdl_key_DOWN(); }
sub SDLK_RIGHT { return SDL::sdlpl::sdl_key_RIGHT(); }
sub SDLK_LEFT { return SDL::sdlpl::sdl_key_LEFT(); }
sub SDLK_INSERT { return SDL::sdlpl::sdl_key_INSERT(); }
sub SDLK_HOME { return SDL::sdlpl::sdl_key_HOME(); }
sub SDLK_END { return SDL::sdlpl::sdl_key_END(); }
sub SDLK_PAGEUP { return SDL::sdlpl::sdl_key_PAGEUP(); }
sub SDLK_PAGEDOWN { return SDL::sdlpl::sdl_key_PAGEDOWN(); }
sub SDLK_F1 { return SDL::sdlpl::sdl_key_F1(); }
sub SDLK_F2 { return SDL::sdlpl::sdl_key_F2(); }
sub SDLK_F3 { return SDL::sdlpl::sdl_key_F3(); }
sub SDLK_F4 { return SDL::sdlpl::sdl_key_F4(); }
sub SDLK_F5 { return SDL::sdlpl::sdl_key_F5(); }
sub SDLK_F6 { return SDL::sdlpl::sdl_key_F6(); }
sub SDLK_F7 { return SDL::sdlpl::sdl_key_F7(); }
sub SDLK_F8 { return SDL::sdlpl::sdl_key_F8(); }
sub SDLK_F9 { return SDL::sdlpl::sdl_key_F9(); }
sub SDLK_F10 { return SDL::sdlpl::sdl_key_F10(); }
sub SDLK_F11 { return SDL::sdlpl::sdl_key_F11(); }
sub SDLK_F12 { return SDL::sdlpl::sdl_key_F12(); }
sub SDLK_F13 { return SDL::sdlpl::sdl_key_F13(); }
sub SDLK_F14 { return SDL::sdlpl::sdl_key_F14(); }
sub SDLK_F15 { return SDL::sdlpl::sdl_key_F15(); }
sub SDLK_NUMLOCK { return SDL::sdlpl::sdl_key_NUMLOCK(); }
sub SDLK_CAPSLOCK { return SDL::sdlpl::sdl_key_CAPSLOCK(); }
sub SDLK_SCROLLOCK { return SDL::sdlpl::sdl_key_SCROLLOCK(); }
sub SDLK_RSHIFT { return SDL::sdlpl::sdl_key_RSHIFT(); }
sub SDLK_LSHIFT { return SDL::sdlpl::sdl_key_LSHIFT(); }
sub SDLK_RCTRL { return SDL::sdlpl::sdl_key_RCTRL(); }
sub SDLK_LCTRL { return SDL::sdlpl::sdl_key_LCTRL(); }
sub SDLK_RALT { return SDL::sdlpl::sdl_key_RALT(); }
sub SDLK_LALT { return SDL::sdlpl::sdl_key_LALT(); }
sub SDLK_RMETA { return SDL::sdlpl::sdl_key_RMETA(); }
sub SDLK_LMETA { return SDL::sdlpl::sdl_key_LMETA(); }
sub SDLK_LSUPER { return SDL::sdlpl::sdl_key_LSUPER(); }
sub SDLK_RSUPER { return SDL::sdlpl::sdl_key_RSUPER(); }
sub SDLK_MODE { return SDL::sdlpl::sdl_key_MODE(); }
sub SDLK_HELP { return SDL::sdlpl::sdl_key_HELP(); }
sub SDLK_PRINT { return SDL::sdlpl::sdl_key_PRINT(); }
sub SDLK_SYSREQ { return SDL::sdlpl::sdl_key_SYSREQ(); }
sub SDLK_BREAK { return SDL::sdlpl::sdl_key_BREAK(); }
sub SDLK_MENU { return SDL::sdlpl::sdl_key_MENU(); }
sub SDLK_POWER { return SDL::sdlpl::sdl_key_POWER(); }
sub SDLK_EURO { return SDL::sdlpl::sdl_key_EURO(); }

sub KMOD_NONE { return SDL::sdlpl::sdl_mod_NONE(); }
sub KMOD_NUM { return SDL::sdlpl::sdl_mod_NUM(); }
sub KMOD_CAPS { return SDL::sdlpl::sdl_mod_CAPS(); }
sub KMOD_LCTRL { return SDL::sdlpl::sdl_mod_LCTRL(); }
sub KMOD_RCTRL { return SDL::sdlpl::sdl_mod_RCTRL(); }
sub KMOD_RSHIFT { return SDL::sdlpl::sdl_mod_RSHIFT(); }
sub KMOD_LSHIFT { return SDL::sdlpl::sdl_mod_LSHIFT(); }
sub KMOD_RALT { return SDL::sdlpl::sdl_mod_RALT(); }
sub KMOD_LALT { return SDL::sdlpl::sdl_mod_LALT(); }
sub KMOD_CTRL { return SDL::sdlpl::sdl_mod_CTRL(); }
sub KMOD_SHIFT { return SDL::sdlpl::sdl_mod_SHIFT(); }
sub KMOD_ALT { return SDL::sdlpl::sdl_mod_ALT(); }

1;

__END__;

=head1 NAME

SDL::Event - a SDL perl extension

=head1 SYNOPSIS

 $event = new SDL::Event;

=head1 DESCRIPTION

	SDL::Event->new(); creates a SDL_Event structure, into
which events may be stored.

$event->type()

	This function returns the event type which will be one of
the values: SDL_ACTIVEEVENT, SDL_KEYDOWN, SDL_KEYUP, SDL_MOUSEMOTION, 
SDL_MOUSEBUTTONDOWN, SDL_MOUSEBUTTONUP, SDL_QUIT,SDL_SYSWMEVENT.

=head2 Gathering Events

	$event->poll();
	$event->pump();
	$event->wait();

These three methods can be used to gather new events.  Poll and pump
should be used together.  Pump will collect events, and poll will
read events from the stack, returning 0 if no events were found.
Similarly wait will wait for an event to occur, and then return.

=head2 Active Events

These events indicate a change in the state of the application. The
methods which access the event's properties are:

	$event->gain();
	$event->state();

The possible states that an event may return are: SDL_APPMOUSEFOCUS,
SDL_APPINPUTFOCUS, and SDL_APPACTIVE.

=head2 Key Events

Everytime a key is pressed or release, while the app has input focus, 
a key event will be generated.  The following methods provide access
to the event's fileds:

	$event->key_state();
	$event->key_name();
	$event->key_sym();
	$event->key_mod();
	$event->key_unicode();
	$event->key_scancode();

Key_state will return either SDL_PRESSED or SDL_RELEASED.  Key_name
will return a string giving the name of the key.  Sym will return
the SDL key symbol code, which can be checked against the SDLK_*
entries as specified in the SDL documentation. (ie sym 27 is
SDLK_ESCAPE).  Likewise, key_mod will return the current modifier
state of the key and can be or'ed against the KMOD_* masks as per
the SDL documentation.

To enable unicode support, one must first call

	$event->set_unicode(1);

there after each event will fill out the unicode field.  The key_unicode
function returns the integer of the unicode key.  Similarly, key_scancode
will return the raw scancode from the key event.

=head2 Mouse Events

There are two types of mouse related events, motion and button.  The
exact type is important as there are separate methodss for reading
from each.  For motion events one should use:

	$event->motion_state();
	$event->motion_x();
	$event->motion_y();
	$event->motion_xrel();
	$event->motion_yrel();

For button events the following are applicable:
	
	$event->button_state();
	$event->button_x();
	$event->button_y();
	$event->button();

Button_state will either be SDL_PRESSED or SDL_RELEASED, while button will
contain the number of the button pressed, 1, 2, 3, etc.

=head2 Other things

Additionally, you can use the method 'set' to make the SDL ignore
or re-enable event types.  For example, you can ignore all 
SDL_SYSWMEVENT events with the command:

	$event->set(SDL_SYSWMEVENT,SDL_IGNORE);

This is highly recommended as you will have to process fewer events 
this way.  You can also enable key repeats using the method:

	$event->set_key_repeat(delay,interval);

It should be noted that there is currently no support for the SYSWMEVENT
events in this structure, as these are really best dealt with C level
code.  This may change in the future.

=head1 AUTHOR

David J. Goehrig

=head1 SEE ALSO

perl(1) SDL::App(3).

=cut
