// sdlpl.xs
//
// These are the binding for SDL, SDL_mixer, and SDL_image
//
// Fri May 26 10:35:25 EDT 2000 added SFont support
//
// Please be aware of the following truths:
//
// Simple DirectMedia Layer by Sam Lantinga <slouken@devolution.com>
// SDL_mixer by Sam Lantinga
// SDL_image also by Sam Lantinga
//
// SFont by Karl Bartel <karlb@gmx.net>
//
// sdlpl by David J. Goehrig 
//
// bonus bits by Wayne Keenan
//
// David J. Goehrig Copyright (C) 2000
//
// This software is under the GNU Library General Public License (LGPL)
// see the file COPYING for terms of use

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <SDL.h>
#include <SDL_byteorder.h>
#include <SDL_image.h>
#include <SDL_mixer.h>

Uint8 * keystates;

MODULE = SDL::sdlpl		PACKAGE = SDL::sdlpl
PROTOTYPES : DISABLE

char *
sdl_get_error ()
	CODE:
		RETVAL = SDL_GetError();
	OUTPUT:
		RETVAL

void
sdl_clear_error ()
	CODE:
		SDL_ClearError();
	

Uint32
sdl_init_audio ()
	CODE:
		RETVAL = SDL_INIT_AUDIO;
	OUTPUT:
		RETVAL

Uint32
sdl_init_video ()
	CODE:
		RETVAL = SDL_INIT_VIDEO;
	OUTPUT:
		RETVAL

Uint32
sdl_init_cdrom ()
	CODE:
		RETVAL = SDL_INIT_CDROM;
	OUTPUT:
		RETVAL

Uint32
sdl_init_timer ()
	CODE:
		RETVAL = SDL_INIT_TIMER;
	OUTPUT:
		RETVAL

Uint32
sdl_init_joystick ()
	CODE:
		RETVAL = SDL_INIT_JOYSTICK;
	OUTPUT:
		RETVAL

Uint32
sdl_init_noparachute ()
	CODE:
		RETVAL = SDL_INIT_NOPARACHUTE;
	OUTPUT:
		RETVAL

Uint32
sdl_init_eventthread ()
	CODE:
		RETVAL = SDL_INIT_EVENTTHREAD;
	OUTPUT:
		RETVAL

Uint32
sdl_init_everything ()
	CODE:
		RETVAL = SDL_INIT_EVERYTHING;
	OUTPUT:
		RETVAL




int
sdl_init ( flags )
	Uint32 flags
	CODE:
		RETVAL = SDL_Init(flags);
	OUTPUT:
		RETVAL

void
sdl_fini ( )
	CODE:
		SDL_Quit();



int
sdl_compiled_version_minor ()
	CODE:
	        SDL_version compiled;
	        SDL_VERSION(&compiled);
		RETVAL = compiled.minor;
	OUTPUT:
		RETVAL

int
sdl_compiled_version_major ()
	CODE:
       		SDL_version compiled;
	        SDL_VERSION(&compiled);
		RETVAL = compiled.minor;
	OUTPUT:
		RETVAL

int
sdl_compiled_version_patch ()
	CODE:
	        SDL_version compiled;
	        SDL_VERSION(&compiled);
		RETVAL = compiled.patch;
	OUTPUT:
		RETVAL

int
sdl_linked_version_minor ()
	CODE:
		RETVAL = SDL_Linked_Version()->minor;
	OUTPUT:
		RETVAL

int
sdl_linked_version_major ()
	CODE:		        
		RETVAL = SDL_Linked_Version()->major;
	OUTPUT:
		RETVAL

int
sdl_linked_version_patch ()
	CODE:
		RETVAL = SDL_Linked_Version()->patch;
	OUTPUT:
		RETVAL

int
sdl_endianess ()
	CODE:
		RETVAL = (SDL_BYTEORDER == SDL_LIL_ENDIAN) ? 0 : 1;
	OUTPUT:
		RETVAL



Uint8
sdl_quit ()
	CODE:
		RETVAL = SDL_QUIT;
	OUTPUT:
		RETVAL	

void
sdl_delay ( ms )
	int ms
	CODE:
		SDL_Delay(ms);

Uint32
sdl_get_ticks ()
	CODE:
		RETVAL = SDL_GetTicks();
	OUTPUT:
		RETVAL

int
sdl_set_timer ( interval, callback )
	Uint32 interval
	SDL_TimerCallback callback
	CODE:
		RETVAL = SDL_SetTimer(interval,callback);
	OUTPUT:
		RETVAL

int
sdl_cd_num_drives ()
	CODE:
		RETVAL = SDL_CDNumDrives();
	OUTPUT:
		RETVAL

char *
sdl_cd_name ( drive )
	int drive
	CODE:
		RETVAL = strdup(SDL_CDName(drive));
	OUTPUT:
		RETVAL

SDL_CD *
sdl_cd_open ( drive )
	int drive
	CODE:
		RETVAL = SDL_CDOpen(drive);
	OUTPUT:
		RETVAL

char *
sdl_cd_track_listing ( cd )
	SDL_CD *cd
	CODE:
		int i,m,s,f;
		FILE *fp;
		size_t len;
		SDL_CDStatus(cd);
		fp = (FILE *) open_memstream(&RETVAL,&len);
		for (i=0;i<cd->numtracks; ++i) {
			FRAMES_TO_MSF(cd->track[i].length,&m,&s,&f);
			if (f > 0) s++;
			fprintf(fp,"Track index: %d, id: %d, time: %2d.%2d\n",
				i,cd->track[i].id,m,s);
		}
		fclose(fp);
	OUTPUT:
		RETVAL

Uint8
sdl_cd_track_id ( track )
	SDL_CDtrack *track
	CODE:
		RETVAL = track->id;
	OUTPUT:
		RETVAL

Uint8
sdl_cd_track_type ( track )
	SDL_CDtrack *track
	CODE:
		RETVAL = track->type;
	OUTPUT:
		RETVAL

Uint16
sdl_cd_track_length ( track )
	SDL_CDtrack *track
	CODE:
		RETVAL = track->length;
	OUTPUT:
		RETVAL

Uint32
sdl_cd_track_offset ( track )
	SDL_CDtrack *track
	CODE:
		RETVAL = track->offset;
	OUTPUT: 
		RETVAL

char *
sdl_cd_status ( cd )
	SDL_CD *cd 
	CODE:
		switch ( SDL_CDStatus(cd) ) {
			case CD_TRAYEMPTY:	RETVAL = "empty"; break;
			case CD_STOPPED:	RETVAL = "stopped"; break;
			case CD_PLAYING:	RETVAL = "playing"; break;
			case CD_PAUSED:		RETVAL = "paused"; break;
			case CD_ERROR:		RETVAL = "error"; break;
		}
	OUTPUT:
		RETVAL

int
sdl_cd_play_tracks ( cd, start_track, ntracks, start_frame, nframes )
	SDL_CD *cd
	int start_track
	int ntracks
	int start_frame
	int nframes
	CODE:
		RETVAL = SDL_CDPlayTracks(cd,start_track,start_frame,ntracks,nframes);
	OUTPUT:
		RETVAL

int
sdl_cd_play ( cd, start, length )
	SDL_CD *cd
	int start
	int length
	CODE:
		RETVAL = SDL_CDPlay(cd,start,length);
	OUTPUT:
		RETVAL

int
sdl_cd_pause ( cd )
	SDL_CD *cd
	CODE:
		RETVAL = SDL_CDPause(cd);
	OUTPUT:
		RETVAL

int
sdl_cd_resume ( cd )
	SDL_CD *cd
	CODE:
		RETVAL = SDL_CDResume(cd);
	OUTPUT:
		RETVAL

int
sdl_cd_stop ( cd )
	SDL_CD *cd
	CODE:
		RETVAL = SDL_CDStop(cd);
	OUTPUT:
		RETVAL

int
sdl_cd_eject ( cd )
	SDL_CD *cd
	CODE:
		RETVAL = SDL_CDEject(cd);
	OUTPUT:
		RETVAL

void
sdl_cd_close ( cd )
	SDL_CD *cd
	CODE:
		SDL_CDClose(cd);
	
int
sdl_cd_id ( cd )
	SDL_CD *cd
	CODE:
		RETVAL = cd->id;
	OUTPUT: 
		RETVAL

int
sdl_cd_numtracks ( cd )
	SDL_CD *cd
	CODE:
		RETVAL = cd->numtracks;
	OUTPUT:
		RETVAL

int
sdl_cd_cur_track ( cd )
	SDL_CD *cd
	CODE:
		RETVAL = cd->cur_track;
	OUTPUT:
		RETVAL

int
sdl_cd_cur_frame ( cd )
	SDL_CD *cd
	CODE:
		RETVAL = cd->cur_frame;
	OUTPUT:
		RETVAL

SDL_CDtrack *
sdl_cd_track ( cd, number )
	SDL_CD *cd
	int number
	CODE:
		RETVAL = (SDL_CDtrack *)(cd->track + number);
	OUTPUT:
		RETVAL

void
sdl_pump_events ()
	CODE:
		SDL_PumpEvents();

SDL_Event *
sdl_new_event ()
	CODE:	
		RETVAL = (SDL_Event *) safemalloc (sizeof(SDL_Event));
	OUTPUT:
		RETVAL

void
sdl_free_event ( e )
	SDL_Event *e
	CODE:
		safefree(e);

int
sdl_poll_event ( e )
	SDL_Event *e
	CODE:
		RETVAL = SDL_PollEvent(e);
	OUTPUT:
		RETVAL

int
sdl_wait_event ( e )
	SDL_Event *e
	CODE:
		RETVAL = SDL_WaitEvent(e);
	OUTPUT:
		RETVAL

Uint8
sdl_event_state ( type, state )
	Uint8 type
	int state
	CODE:
		RETVAL = SDL_EventState(type,state);
	OUTPUT:
		RETVAL 

int
sdl_ignore ()
	CODE:
		RETVAL = SDL_IGNORE;
	OUTPUT:
		RETVAL

int
sdl_enable ()
	CODE:
		RETVAL = SDL_ENABLE;
	OUTPUT:
		RETVAL

int
sdl_query ()
	CODE:	
		RETVAL = SDL_QUERY;
	OUTPUT:
		RETVAL

Uint8
sdl_active_event ()
	CODE:
		RETVAL = SDL_ACTIVEEVENT;
	OUTPUT:
		RETVAL	

Uint8
sdl_key_down ()
	CODE:
		RETVAL = SDL_KEYDOWN;
	OUTPUT:
		RETVAL	

Uint8
sdl_key_up ()
	CODE:
		RETVAL = SDL_KEYUP;
	OUTPUT:
		RETVAL	

Uint8
sdl_mouse_motion ()
	CODE:
		RETVAL = SDL_MOUSEMOTION;
	OUTPUT:
		RETVAL	

Uint8
sdl_mouse_button_down ()
	CODE:
		RETVAL = SDL_MOUSEBUTTONDOWN;
	OUTPUT:
		RETVAL	

Uint8
sdl_mouse_button_up ()
	CODE:
		RETVAL = SDL_MOUSEBUTTONUP;
	OUTPUT:
		RETVAL	


Uint8
sdl_sys_wm_event ()
	CODE:
		RETVAL = SDL_SYSWMEVENT;
	OUTPUT:
		RETVAL	

Uint8
sdl_event_type ( e )
	SDL_Event *e
	CODE:
		RETVAL = e->type;
	OUTPUT:
		RETVAL

Uint8
sdl_active_event_gain ( e )
	SDL_Event *e
	CODE:
		RETVAL = e->active.gain;
	OUTPUT:	
		RETVAL

Uint8
sdl_active_event_state ( e )
	SDL_Event *e
	CODE:
		RETVAL = e->active.state;
	OUTPUT:
		RETVAL

Uint8
sdl_app_mouse_focus ()
	CODE:
		RETVAL = SDL_APPMOUSEFOCUS;
	OUTPUT:
		RETVAL

Uint8
sdl_app_input_focus ()
	CODE:
		RETVAL = SDL_APPINPUTFOCUS;
	OUTPUT:
		RETVAL

Uint8
sdl_app_active ()
	CODE:
		RETVAL = SDL_APPACTIVE;
	OUTPUT:
		RETVAL

Uint8
sdl_key_event_state ( e )
	SDL_Event *e
	CODE:
		RETVAL = e->key.state;
	OUTPUT:
		RETVAL

int
sdl_key_BACKSPACE ()
	CODE:
		RETVAL = SDLK_BACKSPACE;
	OUTPUT:
		RETVAL

int
sdl_key_TAB ()
	CODE:
		RETVAL = SDLK_TAB;
	OUTPUT:
		RETVAL

int
sdl_key_CLEAR ()
	CODE:
		RETVAL = SDLK_CLEAR;
	OUTPUT:
		RETVAL

int
sdl_key_RETURN ()
	CODE:
		RETVAL = SDLK_RETURN;
	OUTPUT:
		RETVAL

int
sdl_key_PAUSE ()
	CODE:
		RETVAL = SDLK_PAUSE;
	OUTPUT:
		RETVAL

int
sdl_key_ESCAPE ()
	CODE:
		RETVAL = SDLK_ESCAPE;
	OUTPUT:
		RETVAL

int
sdl_key_SPACE ()
	CODE:
		RETVAL = SDLK_SPACE;
	OUTPUT:
		RETVAL

int
sdl_key_EXCLAIM ()
	CODE:
		RETVAL = SDLK_EXCLAIM;
	OUTPUT:
		RETVAL

int
sdl_key_QUOTEDBL ()
	CODE:
		RETVAL = SDLK_QUOTEDBL;
	OUTPUT:
		RETVAL

int
sdl_key_HASH ()
	CODE:
		RETVAL = SDLK_HASH;
	OUTPUT:
		RETVAL

int
sdl_key_DOLLAR ()
	CODE:
		RETVAL = SDLK_DOLLAR;
	OUTPUT:
		RETVAL

int
sdl_key_AMPERSAND ()
	CODE:
		RETVAL = SDLK_AMPERSAND;
	OUTPUT:
		RETVAL

int
sdl_key_QUOTE ()
	CODE:
		RETVAL = SDLK_QUOTE;
	OUTPUT:
		RETVAL

int
sdl_key_LEFTPAREN ()
	CODE:
		RETVAL = SDLK_LEFTPAREN;
	OUTPUT:
		RETVAL

int
sdl_key_RIGHTPAREN ()
	CODE:
		RETVAL = SDLK_RIGHTPAREN;
	OUTPUT:
		RETVAL

int
sdl_key_ASTERISK ()
	CODE:
		RETVAL = SDLK_ASTERISK;
	OUTPUT:
		RETVAL

int
sdl_key_PLUS ()
	CODE:
		RETVAL = SDLK_PLUS;
	OUTPUT:
		RETVAL

int
sdl_key_COMMA ()
	CODE:
		RETVAL = SDLK_COMMA;
	OUTPUT:
		RETVAL

int
sdl_key_MINUS ()
	CODE:
		RETVAL = SDLK_MINUS;
	OUTPUT:
		RETVAL

int
sdl_key_PERIOD ()
	CODE:
		RETVAL = SDLK_PERIOD;
	OUTPUT:
		RETVAL

int
sdl_key_SLASH ()
	CODE:
		RETVAL = SDLK_SLASH;
	OUTPUT:
		RETVAL

int
sdl_key_0 ()
	CODE:
		RETVAL = SDLK_0;
	OUTPUT:
		RETVAL

int
sdl_key_1 ()
	CODE:
		RETVAL = SDLK_1;
	OUTPUT:
		RETVAL

int
sdl_key_2 ()
	CODE:
		RETVAL = SDLK_2;
	OUTPUT:
		RETVAL

int
sdl_key_3 ()
	CODE:
		RETVAL = SDLK_3;
	OUTPUT:
		RETVAL

int
sdl_key_4 ()
	CODE:
		RETVAL = SDLK_4;
	OUTPUT:
		RETVAL

int
sdl_key_5 ()
	CODE:
		RETVAL = SDLK_5;
	OUTPUT:
		RETVAL

int
sdl_key_6 ()
	CODE:
		RETVAL = SDLK_6;
	OUTPUT:
		RETVAL

int
sdl_key_7 ()
	CODE:
		RETVAL = SDLK_7;
	OUTPUT:
		RETVAL

int
sdl_key_8 ()
	CODE:
		RETVAL = SDLK_8;
	OUTPUT:
		RETVAL

int
sdl_key_9 ()
	CODE:
		RETVAL = SDLK_9;
	OUTPUT:
		RETVAL

int
sdl_key_COLON ()
	CODE:
		RETVAL = SDLK_COLON;
	OUTPUT:
		RETVAL

int
sdl_key_SEMICOLON ()
	CODE:
		RETVAL = SDLK_SEMICOLON;
	OUTPUT:
		RETVAL

int
sdl_key_LESS ()
	CODE:
		RETVAL = SDLK_LESS;
	OUTPUT:
		RETVAL

int
sdl_key_EQUALS ()
	CODE:
		RETVAL = SDLK_EQUALS;
	OUTPUT:
		RETVAL

int
sdl_key_GREATER ()
	CODE:
		RETVAL = SDLK_GREATER;
	OUTPUT:
		RETVAL

int
sdl_key_QUESTION ()
	CODE:
		RETVAL = SDLK_QUESTION;
	OUTPUT:
		RETVAL

int
sdl_key_AT ()
	CODE:
		RETVAL = SDLK_AT;
	OUTPUT:
		RETVAL

int
sdl_key_LEFTBRACKET ()
	CODE:
		RETVAL = SDLK_LEFTBRACKET;
	OUTPUT:
		RETVAL

int
sdl_key_BACKSLASH ()
	CODE:
		RETVAL = SDLK_BACKSLASH;
	OUTPUT:
		RETVAL

int
sdl_key_RIGHTBRACKET ()
	CODE:
		RETVAL = SDLK_RIGHTBRACKET;
	OUTPUT:
		RETVAL

int
sdl_key_CARET ()
	CODE:
		RETVAL = SDLK_CARET;
	OUTPUT:
		RETVAL

int
sdl_key_UNDERSCORE ()
	CODE:
		RETVAL = SDLK_UNDERSCORE;
	OUTPUT:
		RETVAL

int
sdl_key_BACKQUOTE ()
	CODE:
		RETVAL = SDLK_BACKQUOTE;
	OUTPUT:
		RETVAL

int
sdl_key_a ()
	CODE:
		RETVAL = SDLK_a;
	OUTPUT:
		RETVAL

int
sdl_key_b ()
	CODE:
		RETVAL = SDLK_b;
	OUTPUT:
		RETVAL

int
sdl_key_c ()
	CODE:
		RETVAL = SDLK_c;
	OUTPUT:
		RETVAL

int
sdl_key_d ()
	CODE:
		RETVAL = SDLK_d;
	OUTPUT:
		RETVAL

int
sdl_key_e ()
	CODE:
		RETVAL = SDLK_e;
	OUTPUT:
		RETVAL

int
sdl_key_f ()
	CODE:
		RETVAL = SDLK_f;
	OUTPUT:
		RETVAL

int
sdl_key_g ()
	CODE:
		RETVAL = SDLK_g;
	OUTPUT:
		RETVAL

int
sdl_key_h ()
	CODE:
		RETVAL = SDLK_h;
	OUTPUT:
		RETVAL

int
sdl_key_i ()
	CODE:
		RETVAL = SDLK_i;
	OUTPUT:
		RETVAL

int
sdl_key_j ()
	CODE:
		RETVAL = SDLK_j;
	OUTPUT:
		RETVAL

int
sdl_key_k ()
	CODE:
		RETVAL = SDLK_k;
	OUTPUT:
		RETVAL

int
sdl_key_l ()
	CODE:
		RETVAL = SDLK_l;
	OUTPUT:
		RETVAL

int
sdl_key_m ()
	CODE:
		RETVAL = SDLK_m;
	OUTPUT:
		RETVAL

int
sdl_key_n ()
	CODE:
		RETVAL = SDLK_n;
	OUTPUT:
		RETVAL

int
sdl_key_o ()
	CODE:
		RETVAL = SDLK_o;
	OUTPUT:
		RETVAL

int
sdl_key_p ()
	CODE:
		RETVAL = SDLK_p;
	OUTPUT:
		RETVAL

int
sdl_key_q ()
	CODE:
		RETVAL = SDLK_q;
	OUTPUT:
		RETVAL

int
sdl_key_r ()
	CODE:
		RETVAL = SDLK_r;
	OUTPUT:
		RETVAL

int
sdl_key_s ()
	CODE:
		RETVAL = SDLK_s;
	OUTPUT:
		RETVAL

int
sdl_key_t ()
	CODE:
		RETVAL = SDLK_t;
	OUTPUT:
		RETVAL

int
sdl_key_u ()
	CODE:
		RETVAL = SDLK_u;
	OUTPUT:
		RETVAL

int
sdl_key_v ()
	CODE:
		RETVAL = SDLK_v;
	OUTPUT:
		RETVAL

int
sdl_key_w ()
	CODE:
		RETVAL = SDLK_w;
	OUTPUT:
		RETVAL

int
sdl_key_x ()
	CODE:
		RETVAL = SDLK_x;
	OUTPUT:
		RETVAL

int
sdl_key_y ()
	CODE:
		RETVAL = SDLK_y;
	OUTPUT:
		RETVAL

int
sdl_key_z ()
	CODE:
		RETVAL = SDLK_z;
	OUTPUT:
		RETVAL

int
sdl_key_DELETE ()
	CODE:
		RETVAL = SDLK_DELETE;
	OUTPUT:
		RETVAL

int
sdl_key_KP0 ()
	CODE:
		RETVAL = SDLK_KP0;
	OUTPUT:
		RETVAL

int
sdl_key_KP1 ()
	CODE:
		RETVAL = SDLK_KP1;
	OUTPUT:
		RETVAL

int
sdl_key_KP2 ()
	CODE:
		RETVAL = SDLK_KP2;
	OUTPUT:
		RETVAL

int
sdl_key_KP3 ()
	CODE:
		RETVAL = SDLK_KP3;
	OUTPUT:
		RETVAL

int
sdl_key_KP4 ()
	CODE:
		RETVAL = SDLK_KP4;
	OUTPUT:
		RETVAL

int
sdl_key_KP5 ()
	CODE:
		RETVAL = SDLK_KP5;
	OUTPUT:
		RETVAL

int
sdl_key_KP6 ()
	CODE:
		RETVAL = SDLK_KP6;
	OUTPUT:
		RETVAL

int
sdl_key_KP7 ()
	CODE:
		RETVAL = SDLK_KP7;
	OUTPUT:
		RETVAL

int
sdl_key_KP8 ()
	CODE:
		RETVAL = SDLK_KP8;
	OUTPUT:
		RETVAL

int
sdl_key_KP9 ()
	CODE:
		RETVAL = SDLK_KP9;
	OUTPUT:
		RETVAL

int
sdl_key_KP_PERIOD ()
	CODE:
		RETVAL = SDLK_KP_PERIOD;
	OUTPUT:
		RETVAL

int
sdl_key_KP_DIVIDE ()
	CODE:
		RETVAL = SDLK_KP_DIVIDE;
	OUTPUT:
		RETVAL

int
sdl_key_KP_MULTIPLY ()
	CODE:
		RETVAL = SDLK_KP_MULTIPLY;
	OUTPUT:
		RETVAL

int
sdl_key_KP_MINUS ()
	CODE:
		RETVAL = SDLK_KP_MINUS;
	OUTPUT:
		RETVAL

int
sdl_key_KP_PLUS ()
	CODE:
		RETVAL = SDLK_KP_PLUS;
	OUTPUT:
		RETVAL

int
sdl_key_KP_ENTER ()
	CODE:
		RETVAL = SDLK_KP_ENTER;
	OUTPUT:
		RETVAL

int
sdl_key_KP_EQUALS ()
	CODE:
		RETVAL = SDLK_KP_EQUALS;
	OUTPUT:
		RETVAL

int
sdl_key_UP ()
	CODE:
		RETVAL = SDLK_UP;
	OUTPUT:
		RETVAL

int
sdl_key_DOWN ()
	CODE:
		RETVAL = SDLK_DOWN;
	OUTPUT:
		RETVAL

int
sdl_key_RIGHT ()
	CODE:
		RETVAL = SDLK_RIGHT;
	OUTPUT:
		RETVAL

int
sdl_key_LEFT ()
	CODE:
		RETVAL = SDLK_LEFT;
	OUTPUT:
		RETVAL

int
sdl_key_INSERT ()
	CODE:
		RETVAL = SDLK_INSERT;
	OUTPUT:
		RETVAL

int
sdl_key_HOME ()
	CODE:
		RETVAL = SDLK_HOME;
	OUTPUT:
		RETVAL

int
sdl_key_END ()
	CODE:
		RETVAL = SDLK_END;
	OUTPUT:
		RETVAL

int
sdl_key_PAGEUP ()
	CODE:
		RETVAL = SDLK_PAGEUP;
	OUTPUT:
		RETVAL

int
sdl_key_PAGEDOWN ()
	CODE:
		RETVAL = SDLK_PAGEDOWN;
	OUTPUT:
		RETVAL

int
sdl_key_F1 ()
	CODE:
		RETVAL = SDLK_F1;
	OUTPUT:
		RETVAL

int
sdl_key_F2 ()
	CODE:
		RETVAL = SDLK_F2;
	OUTPUT:
		RETVAL

int
sdl_key_F3 ()
	CODE:
		RETVAL = SDLK_F3;
	OUTPUT:
		RETVAL

int
sdl_key_F4 ()
	CODE:
		RETVAL = SDLK_F4;
	OUTPUT:
		RETVAL

int
sdl_key_F5 ()
	CODE:
		RETVAL = SDLK_F5;
	OUTPUT:
		RETVAL

int
sdl_key_F6 ()
	CODE:
		RETVAL = SDLK_F6;
	OUTPUT:
		RETVAL

int
sdl_key_F7 ()
	CODE:
		RETVAL = SDLK_F7;
	OUTPUT:
		RETVAL

int
sdl_key_F8 ()
	CODE:
		RETVAL = SDLK_F8;
	OUTPUT:
		RETVAL

int
sdl_key_F9 ()
	CODE:
		RETVAL = SDLK_F9;
	OUTPUT:
		RETVAL

int
sdl_key_F10 ()
	CODE:
		RETVAL = SDLK_F10;
	OUTPUT:
		RETVAL

int
sdl_key_F11 ()
	CODE:
		RETVAL = SDLK_F11;
	OUTPUT:
		RETVAL

int
sdl_key_F12 ()
	CODE:
		RETVAL = SDLK_F12;
	OUTPUT:
		RETVAL

int
sdl_key_F13 ()
	CODE:
		RETVAL = SDLK_F13;
	OUTPUT:
		RETVAL

int
sdl_key_F14 ()
	CODE:
		RETVAL = SDLK_F14;
	OUTPUT:
		RETVAL

int
sdl_key_F15 ()
	CODE:
		RETVAL = SDLK_F15;
	OUTPUT:
		RETVAL

int
sdl_key_NUMLOCK ()
	CODE:
		RETVAL = SDLK_NUMLOCK;
	OUTPUT:
		RETVAL

int
sdl_key_CAPSLOCK ()
	CODE:
		RETVAL = SDLK_CAPSLOCK;
	OUTPUT:
		RETVAL

int
sdl_key_SCROLLOCK ()
	CODE:
		RETVAL = SDLK_SCROLLOCK;
	OUTPUT:
		RETVAL

int
sdl_key_RSHIFT ()
	CODE:
		RETVAL = SDLK_RSHIFT;
	OUTPUT:
		RETVAL

int
sdl_key_LSHIFT ()
	CODE:
		RETVAL = SDLK_LSHIFT;
	OUTPUT:
		RETVAL

int
sdl_key_RCTRL ()
	CODE:
		RETVAL = SDLK_RCTRL;
	OUTPUT:
		RETVAL

int
sdl_key_LCTRL ()
	CODE:
		RETVAL = SDLK_LCTRL;
	OUTPUT:
		RETVAL

int
sdl_key_RALT ()
	CODE:
		RETVAL = SDLK_RALT;
	OUTPUT:
		RETVAL

int
sdl_key_LALT ()
	CODE:
		RETVAL = SDLK_LALT;
	OUTPUT:
		RETVAL

int
sdl_key_RMETA ()
	CODE:
		RETVAL = SDLK_RMETA;
	OUTPUT:
		RETVAL

int
sdl_key_LMETA ()
	CODE:
		RETVAL = SDLK_LMETA;
	OUTPUT:
		RETVAL

int
sdl_key_LSUPER ()
	CODE:
		RETVAL = SDLK_LSUPER;
	OUTPUT:
		RETVAL

int
sdl_key_RSUPER ()
	CODE:
		RETVAL = SDLK_RSUPER;
	OUTPUT:
		RETVAL

int
sdl_key_MODE ()
	CODE:
		RETVAL = SDLK_MODE;
	OUTPUT:
		RETVAL

int
sdl_key_HELP ()
	CODE:
		RETVAL = SDLK_HELP;
	OUTPUT:
		RETVAL

int
sdl_key_PRINT ()
	CODE:
		RETVAL = SDLK_PRINT;
	OUTPUT:
		RETVAL

int
sdl_key_SYSREQ ()
	CODE:
		RETVAL = SDLK_SYSREQ;
	OUTPUT:
		RETVAL

int
sdl_key_BREAK ()
	CODE:
		RETVAL = SDLK_BREAK;
	OUTPUT:
		RETVAL

int
sdl_key_MENU ()
	CODE:
		RETVAL = SDLK_MENU;
	OUTPUT:
		RETVAL

int
sdl_key_POWER ()
	CODE:
		RETVAL = SDLK_POWER;
	OUTPUT:
		RETVAL

int
sdl_key_EURO ()
	CODE:
		RETVAL = SDLK_EURO;
	OUTPUT:
		RETVAL


int
sdl_mod_NONE ()
	CODE:
		RETVAL = KMOD_NONE;
	OUTPUT:
		RETVAL

int
sdl_mod_NUM ()
	CODE:
		RETVAL = KMOD_NUM;
	OUTPUT:
		RETVAL

int
sdl_mod_CAPS ()
	CODE:
		RETVAL = KMOD_CAPS;
	OUTPUT:
		RETVAL

int
sdl_mod_LCTRL ()
	CODE:
		RETVAL = KMOD_LCTRL;
	OUTPUT:
		RETVAL

int
sdl_mod_RCTRL ()
	CODE:
		RETVAL = KMOD_RCTRL;
	OUTPUT:
		RETVAL

int
sdl_mod_RSHIFT ()
	CODE:
		RETVAL = KMOD_RSHIFT;
	OUTPUT:
		RETVAL

int
sdl_mod_LSHIFT ()
	CODE:
		RETVAL = KMOD_LSHIFT;
	OUTPUT:
		RETVAL

int
sdl_mod_RALT ()
	CODE:
		RETVAL = KMOD_RALT;
	OUTPUT:
		RETVAL

int
sdl_mod_LALT ()
	CODE:
		RETVAL = KMOD_LALT;
	OUTPUT:
		RETVAL

int
sdl_mod_CTRL ()
	CODE:
		RETVAL = KMOD_CTRL;
	OUTPUT:
		RETVAL

int
sdl_mod_SHIFT ()
	CODE:
		RETVAL = KMOD_SHIFT;
	OUTPUT:
		RETVAL

int
sdl_mod_ALT ()
	CODE:
		RETVAL = KMOD_ALT;
	OUTPUT:
		RETVAL

int
sdl_key_event_sym ( e )
	SDL_Event *e
	CODE:
		RETVAL = e->key.keysym.sym;
	OUTPUT:
		RETVAL

int 
sdl_key_event_mod ( e )
	SDL_Event *e
	CODE:
		RETVAL = e->key.keysym.mod;
	OUTPUT:
		RETVAL

Uint16
sdl_key_event_unicode ( e )
	SDL_Event *e
	CODE:
		RETVAL = e->key.keysym.unicode;
	OUTPUT:
		RETVAL

Uint8
sdl_key_event_scancode ( e )
	SDL_Event *e
	CODE:
		RETVAL = e->key.keysym.scancode;
	OUTPUT:
		RETVAL

void
sdl_prep_key_state ()
	CODE:
		keystates = SDL_GetKeyState(NULL);

Uint8
sdl_key_state ( k )
	SDLKey k
	CODE:
		RETVAL = keystates[k];
	OUTPUT:
		RETVAL



Uint8
sdl_mouse_motion_state ( e )
	SDL_Event *e
	CODE:
		RETVAL = e->motion.state;
	OUTPUT:	
		RETVAL

Uint16
sdl_mouse_motion_x ( e )
	SDL_Event *e
	CODE:
		RETVAL = e->motion.x;
	OUTPUT:
		RETVAL

Uint16
sdl_mouse_motion_y ( e )
	SDL_Event *e
	CODE:
		RETVAL = e->motion.y;
	OUTPUT:
		RETVAL

Sint16
sdl_mouse_motion_xrel ( e )
	SDL_Event *e
	CODE:
		RETVAL = e->motion.xrel;
	OUTPUT:
		RETVAL

Sint16
sdl_mouse_motion_yrel ( e )
	SDL_Event *e
	CODE:
		RETVAL = e->motion.yrel;
	OUTPUT:
		RETVAL

Uint8
sdl_mouse_button_state ( e )
	SDL_Event *e
	CODE:
		RETVAL = e->button.state;
	OUTPUT:
		RETVAL

Uint8
sdl_mouse_button_button ( e )
	SDL_Event *e
	CODE:
		RETVAL = e->button.button;
	OUTPUT:
		RETVAL

Uint16
sdl_mouse_button_x ( e )
	SDL_Event *e
	CODE:
		RETVAL = e->button.x;
	OUTPUT:
		RETVAL

Uint16
sdl_mouse_button_y ( e )
	SDL_Event *e
	CODE:
		RETVAL = e->button.y;
	OUTPUT:
		RETVAL

Uint16
sdl_resize_width ( e )
	SDL_Event *e
	CODE:
		RETVAL = e->resize.w;
	OUTPUT:
		RETVAL

Uint16
sdl_resize_height ( e )
	SDL_Event *e
	CODE:
		RETVAL = e->resize.h;
	OUTPUT:
		RETVAL



SDL_SysWMmsg *
sdl_sys_wm_event_msg ( e )
	SDL_Event *e
	CODE:
		RETVAL = e->syswm.msg;
	OUTPUT:
		RETVAL


int
sdl_enable_unicode ( enable )
	int enable
	CODE:
		RETVAL = SDL_EnableUNICODE(enable);
	OUTPUT:
		RETVAL

void
sdl_enable_key_repeat ( delay, interval )
	int delay
	int interval
	CODE:
		SDL_EnableKeyRepeat(delay,interval);

char *
sdl_get_key_name ( sym )
	int sym
	CODE:
		RETVAL = SDL_GetKeyName(sym);
	OUTPUT:
		RETVAL

Uint8
sdl_pressed ()
	CODE:
		RETVAL = SDL_PRESSED;
	OUTPUT:
		RETVAL

Uint8
sdl_released ()
	CODE:
		RETVAL = SDL_RELEASED;
	OUTPUT:
		RETVAL

SDL_Surface *
sdl_new_surface (name, flags, width, height, depth, Rmask, Gmask, Bmask, Amask )
	char *name
	Uint32 flags
	int width
	int height
	int depth
	Uint32 Rmask
	Uint32 Gmask
	Uint32 Bmask
	Uint32 Amask
	CODE:
		if ( ! strcmp ("",name)) {
			RETVAL = SDL_CreateRGBSurface ( flags, width, height,
				depth, Rmask, Gmask, Bmask, Amask );
		}
		else {
			RETVAL = IMG_Load(name);
		}
	OUTPUT:	
		RETVAL


SDL_Surface *
sdl_new_surface_from (pixels, width, height, depth, pitch, Rmask, Gmask, Bmask, Amask )
	void *pixels
	int width
	int height
	int depth
	int pitch
	Uint32 Rmask
	Uint32 Gmask
	Uint32 Bmask
	Uint32 Amask
	CODE:
		RETVAL = SDL_CreateRGBSurfaceFrom ( pixels, width, height,
				depth, pitch, Rmask, Gmask, Bmask, Amask );
	OUTPUT:	
		RETVAL


void
sdl_free_surface ( surface )
	SDL_Surface *surface
	CODE:
		SDL_FreeSurface(surface);
	
Uint32
sdl_surface_flags ( surface )
	SDL_Surface *surface
	CODE:
		RETVAL = surface->flags;
	OUTPUT:
		RETVAL

SDL_Palette *
sdl_surface_palette ( surface )
	SDL_Surface *surface
	CODE:
		RETVAL = surface->format->palette;
	OUTPUT:
		RETVAL

Uint8
sdl_surface_bits_per_pixel ( surface )
	SDL_Surface *surface
	CODE:
		RETVAL = surface->format->BitsPerPixel;
	OUTPUT:
		RETVAL

Uint8
sdl_surface_bytes_per_pixel ( surface )
	SDL_Surface *surface
	CODE:	
		RETVAL = surface->format->BytesPerPixel;
	OUTPUT:
		RETVAL

Uint8
sdl_surface_rshift ( surface )
	SDL_Surface *surface
	CODE:
		RETVAL = surface->format->Rshift;
	OUTPUT:
		RETVAL

Uint8
sdl_surface_gshift ( surface )
	SDL_Surface *surface
	CODE:
		RETVAL = surface->format->Gshift;
	OUTPUT:
		RETVAL

Uint8
sdl_surface_bshift ( surface )
	SDL_Surface *surface
	CODE:
		RETVAL = surface->format->Bshift;
	OUTPUT:
		RETVAL

Uint8
sdl_surface_ashift ( surface )
	SDL_Surface *surface
	CODE:
		RETVAL = surface->format->Ashift;
	OUTPUT:
		RETVAL

Uint32
sdl_surface_rmask ( surface )
	SDL_Surface *surface
	CODE:
		RETVAL = surface->format->Rmask;
	OUTPUT:
		RETVAL

Uint32
sdl_surface_gmask ( surface )
	SDL_Surface *surface
	CODE:
		RETVAL = surface->format->Gmask;
	OUTPUT:
		RETVAL

Uint32
sdl_surface_bmask ( surface )
	SDL_Surface *surface
	CODE:
		RETVAL = surface->format->Bmask;
	OUTPUT:
		RETVAL

Uint32
sdl_surface_amask ( surface )
	SDL_Surface *surface
	CODE:
		RETVAL = surface->format->Amask;
	OUTPUT:
		RETVAL

Uint32
sdl_surface_colorkey ( surface )
	SDL_Surface *surface
	CODE:
		RETVAL = surface->format->colorkey;
	OUTPUT:
		RETVAL

Uint32
sdl_surface_alpha ( surface )
	SDL_Surface *surface
	CODE:
		RETVAL = surface->format->alpha;
	OUTPUT:
		RETVAL

int
sdl_surface_w ( surface )
	SDL_Surface *surface
	CODE:	
		RETVAL = surface->w;
	OUTPUT:
		RETVAL

int
sdl_surface_h ( surface )
	SDL_Surface *surface
	CODE:	
		RETVAL = surface->h;
	OUTPUT:
		RETVAL

int
sdl_surface_clip_minx ( surface )
	SDL_Surface *surface
	CODE:	
		RETVAL = surface->clip_minx;
	OUTPUT:
		RETVAL

int
sdl_surface_clip_miny ( surface )
	SDL_Surface *surface
	CODE:	
		RETVAL = surface->clip_miny;
	OUTPUT:
		RETVAL

int
sdl_surface_clip_maxx ( surface )
	SDL_Surface *surface
	CODE:	
		RETVAL = surface->clip_maxx;
	OUTPUT:
		RETVAL

int
sdl_surface_clip_maxy ( surface )
	SDL_Surface *surface
	CODE:	
		RETVAL = surface->clip_maxy;
	OUTPUT:
		RETVAL

Uint16
sdl_surface_pitch ( surface )
	SDL_Surface *surface
	CODE:	
		RETVAL = surface->pitch;
	OUTPUT:
		RETVAL

void *
sdl_surface_pixels ( surface )
	SDL_Surface *surface
	CODE:	
		RETVAL = surface->pixels;
	OUTPUT:
		RETVAL

Uint32
sdl_surface_pixel ( surface, x, y, ... )
	SDL_Surface *surface
	Sint32 x
	Sint32 y
	CODE:
		Uint32 pixel;
		Uint8 *bitbucket, bpp;

		bpp = surface->format->BytesPerPixel;
		bitbucket = ((Uint8 *)surface->pixels)+y*surface->pitch+x*bpp;
		if ( items > 3 ) {
			pixel = SvIV(ST(3));
			switch(bpp) {
				case 1:
					*((Uint8 *)(bitbucket)) = (Uint8)pixel;
					break;
				case 2:
					*((Uint16 *)(bitbucket)) = 
						(Uint16)pixel;					
					break;
				case 3: {
					Uint8 r,g,b;
					r = 
					(pixel>>surface->format->Rshift)*0xff;
					g = 
					(pixel>>surface->format->Gshift)*0xff;
					b = 
					(pixel>>surface->format->Bshift)*0xff;
					*((bitbucket)+
						surface->format->Rshift/8) = r;
					*((bitbucket)+
						surface->format->Gshift/8) = g;
					*((bitbucket)+
						surface->format->Bshift/8) = b;
					}
					break;
				case 4:
					*((Uint32 *)(bitbucket)) = 
						(Uint32)pixel;
					break;
			}
		}
		switch ( bpp ) {
			case 1:
				RETVAL = (Uint32)*((Uint8 *)(bitbucket));
				break;
			case 2:
				RETVAL = (Uint32)*((Uint16 *)(bitbucket));
				break;
			case 3:
				{ Uint8 r,g,b;
					r = *((bitbucket) + 
						surface->format->Rshift/8);
					g = *((bitbucket) + 
						surface->format->Gshift/8);
					b = *((bitbucket) + 
						surface->format->Bshift/8);
					RETVAL = (Uint32)
						 (r<<surface->format->Rshift) +
						 (g<<surface->format->Gshift) +
						 (b<<surface->format->Bshift);
				} break;
			case 4:
				RETVAL = (Uint32)*((Uint32 *)(bitbucket));
				break;
		}
	OUTPUT:
		RETVAL

int
sdl_surface_must_lock ( surface )
	SDL_Surface *surface
	CODE:
		RETVAL = SDL_MUSTLOCK(surface);
	OUTPUT:
		RETVAL		

int
sdl_surface_lock ( surface )
	SDL_Surface *surface
	CODE:
		RETVAL = SDL_LockSurface(surface);
	OUTPUT:
		RETVAL

void
sdl_surface_unlock ( surface )
	SDL_Surface *surface
	CODE:
		SDL_UnlockSurface(surface);

SDL_Surface *
sdl_get_video_surface ()
	CODE:
		RETVAL = SDL_GetVideoSurface();
	OUTPUT:
		RETVAL


HV *
sdl_video_info ()
	CODE:
		HV *hv;
		SDL_VideoInfo *info;
		info = (SDL_VideoInfo *) safemalloc ( sizeof(SDL_VideoInfo));
		memcpy(info,SDL_GetVideoInfo(),sizeof(SDL_VideoInfo));
		
		hv = newHV();
		hv_store(hv,"hw_available",strlen("hw_available"),
			newSViv(info->hw_available),0);
		hv_store(hv,"wm_available",strlen("wm_available"),
			newSViv(info->wm_available),0);
		hv_store(hv,"blit_hw",strlen("blit_hw"),
			newSViv(info->blit_hw),0);
		hv_store(hv,"blit_hw_CC",strlen("blit_hw_CC"),
			newSViv(info->blit_hw_CC),0);
		hv_store(hv,"blit_hw_A",strlen("blit_hw_A"),
			newSViv(info->blit_hw_A),0);
		hv_store(hv,"blit_sw",strlen("blit_sw"),
			newSViv(info->blit_sw),0);
		hv_store(hv,"blit_sw_CC",strlen("blit_sw_CC"),
			newSViv(info->blit_sw_CC),0);
		hv_store(hv,"blit_sw_A",strlen("blit_sw_A"),
			newSViv(info->blit_sw_A),0);
		hv_store(hv,"blit_fill",strlen("blit_fill"),
			newSViv(info->blit_fill),0);
		hv_store(hv,"video_mem",strlen("video_mem"),
			newSViv(info->video_mem),0);
		RETVAL = hv;
	OUTPUT:
		RETVAL

SDL_Rect *
sdl_new_rect ( x, y, w, h )
	Sint16 x
	Sint16 y
	Uint16 w
	Uint16 h
	CODE:
		RETVAL = (SDL_Rect *) safemalloc (sizeof(SDL_Rect));
		RETVAL->x = x;
		RETVAL->y = y;
		RETVAL->w = w;
		RETVAL->h = h;
	OUTPUT:
		RETVAL

void
sdl_free_rect ( rect )
	SDL_Rect *rect
	CODE:
		safefree(rect);

Sint16
sdl_rect_x ( rect, ... )
	SDL_Rect *rect
	CODE:
		if (items > 1 ) rect->x = SvIV(ST(1)); 
		RETVAL = rect->x;
	OUTPUT:
		RETVAL

Sint16
sdl_rect_y ( rect, ... )
	SDL_Rect *rect
	CODE:
		if (items > 1 ) rect->y = SvIV(ST(1)); 
		RETVAL = rect->y;
	OUTPUT:
		RETVAL

Uint16
sdl_rect_w ( rect, ... )
	SDL_Rect *rect
	CODE:
		if (items > 1 ) rect->w = SvIV(ST(1)); 
		RETVAL = rect->w;
	OUTPUT:
		RETVAL

Uint16
sdl_rect_h ( rect, ... )
	SDL_Rect *rect
	CODE:
		if (items > 1 ) rect->h = SvIV(ST(1)); 
		RETVAL = rect->h;
	OUTPUT:
		RETVAL

SDL_Color *
sdl_new_color ( r, g, b )
	Uint8 r
	Uint8 g
	Uint8 b
	CODE:
		RETVAL = (SDL_Color *) safemalloc(sizeof(SDL_Color));
		RETVAL->r = r;
		RETVAL->g = g;
		RETVAL->b = b;
	OUTPUT:
		RETVAL

Uint8
sdl_color_r ( color, ... )
	SDL_Color *color
	CODE:
		if (items > 1 ) color->r = SvIV(ST(1)); 
		RETVAL = color->r;
	OUTPUT:
		RETVAL

Uint8
sdl_color_g ( color, ... )
	SDL_Color *color
	CODE:
		if (items > 1 ) color->g = SvIV(ST(1)); 
		RETVAL = color->g;
	OUTPUT:
		RETVAL

Uint8
sdl_color_b ( color, ... )
	SDL_Color *color
	CODE:
		if (items > 1 ) color->b = SvIV(ST(1)); 
		RETVAL = color->b;
	OUTPUT:
		RETVAL

void
sdl_free_color ( color )
	SDL_Color *color
	CODE:
		safefree(color);

SDL_Palette *
sdl_new_palette ( number )
	int number
	CODE:
		RETVAL = (SDL_Palette *)safemalloc(sizeof(SDL_Palette));
		RETVAL->colors = (SDL_Color *)safemalloc(number * 
						sizeof(SDL_Color));
		RETVAL->ncolors = number;
	OUTPUT:
		RETVAL

int
sdl_palette_num_colors ( palette, ... )
	SDL_Palette *palette
	CODE:
		if ( items > 1 ) palette->ncolors = SvIV(ST(1));
		RETVAL = palette->ncolors;
	OUTPUT:
		RETVAL

SDL_Color *
sdl_palette_color ( palette, index, ... )
	SDL_Palette *palette
	int index
	CODE:
		if ( items > 2 ) {
			palette->colors[index].r = SvUV(ST(2)); 
			palette->colors[index].g = SvUV(ST(3)); 
			palette->colors[index].b = SvUV(ST(4)); 
		}
		RETVAL = (SDL_Color *)(palette->colors + index);
	OUTPUT:
		RETVAL

Uint32
sdl_swsurface ()
	CODE:
		RETVAL = SDL_SWSURFACE;
	OUTPUT:
		RETVAL

Uint32
sdl_hwsurface ()
	CODE:
		RETVAL = SDL_HWSURFACE;
	OUTPUT:
		RETVAL

Uint32
sdl_anyformat ()
	CODE:
		RETVAL = SDL_ANYFORMAT;
	OUTPUT:
		RETVAL

Uint32
sdl_hwpalette ()
	CODE:
		RETVAL = SDL_HWPALETTE;
	OUTPUT:
		RETVAL

Uint32
sdl_doublebuf ()
	CODE:
		RETVAL = SDL_DOUBLEBUF;
	OUTPUT:
		RETVAL

Uint32
sdl_fullscreen ()
	CODE:
		RETVAL = SDL_FULLSCREEN;
	OUTPUT:
		RETVAL


Uint32
sdl_asyncblit ()
	CODE:
		RETVAL = SDL_ASYNCBLIT;
	OUTPUT:
		RETVAL


Uint32
sdl_opengl ()
	CODE:
		RETVAL = SDL_OPENGL;
	OUTPUT:
		RETVAL

Uint32
sdl_hwaccel ()
	CODE:
		RETVAL = SDL_HWACCEL;
	OUTPUT:
		RETVAL

Uint32
sdl_openglblit ()
	CODE:
		RETVAL = SDL_OPENGLBLIT;
	OUTPUT:
		RETVAL

Uint32
sdl_resizable ()
	CODE:
		RETVAL = SDL_RESIZABLE;
	OUTPUT:
		RETVAL

Uint32
sdl_videoresize ()
	CODE:
		RETVAL = SDL_VIDEORESIZE;
	OUTPUT:
		RETVAL



int
sdl_video_mode_ok ( width, height, bpp, flags )
	int width
	int height
	int bpp
	Uint32 flags
	CODE:
		RETVAL = SDL_VideoModeOK(width,height,bpp,flags);
	OUTPUT:
		RETVAL

SDL_Surface *
sdl_set_video_mode ( width, height, bpp, flags )
	int width
	int height
	int bpp
	Uint32 flags
	CODE:
		RETVAL = SDL_SetVideoMode(width,height,bpp,flags);
	OUTPUT:
		RETVAL

void
sdl_update_rects ( surface, ... )
	SDL_Surface *surface
	CODE:
		SDL_Rect *rects, *temp;
		int num_rects,i;
	
		if ( items < 2 ) return;
		num_rects = items - 1;	
		rects = (SDL_Rect *)safemalloc(sizeof(SDL_Rect)*items);
		for(i=0;i<num_rects;i++) {
			temp = (SDL_Rect *)SvIV(ST(i+1));
			rects[i].x = temp->x;
			rects[i].y = temp->y;
			rects[i].w = temp->w;
			rects[i].h = temp->h;
		} 
		SDL_UpdateRects(surface,num_rects,rects);
		safefree(rects);

int
sdl_flip ( surface )
	SDL_Surface *surface
	CODE:
		RETVAL = SDL_Flip(surface);
	OUTPUT:
		RETVAL

int
sdl_set_colors ( surface, start, ... )
	SDL_Surface *surface
	int start
	CODE:
		SDL_Color *colors,*temp;
		int i, length;

		if ( items < 3 ) { RETVAL = 0;	goto all_done; }
		length = items - 2;
		colors = (SDL_Color *)safemalloc(sizeof(SDL_Color)*(length+1));
		for ( i = 0; i < length ; i++ ) {
			temp = (SDL_Color *)SvIV(ST(i+2));
			colors[i].r = temp->r;
			colors[i].g = temp->g;
			colors[i].b = temp->b;
		}
		RETVAL = SDL_SetColors(surface, colors, start, length );
		safefree(colors);
all_done:
	OUTPUT:	
		RETVAL

Uint32
sdl_map_rgb ( surface, r, g, b )
	SDL_Surface *surface
	Uint8 r
	Uint8 g
	Uint8 b
	CODE:
		RETVAL = SDL_MapRGB(surface->format,r,g,b);
	OUTPUT:
		RETVAL

AV *
sdl_get_rgb ( surface, pixel )
	SDL_Surface *surface
	Uint32 pixel
	CODE:
		Uint8 r,g,b;
		SDL_GetRGB(pixel,surface->format,&r,&g,&b);
		RETVAL = newAV();
		av_push(RETVAL,newSViv(r));
		av_push(RETVAL,newSViv(g));
		av_push(RETVAL,newSViv(b));
	OUTPUT:
		RETVAL

int
sdl_save_bmp ( surface, filename )
	SDL_Surface *surface
	char *filename
	CODE:
		RETVAL = SDL_SaveBMP(surface,filename);
	OUTPUT:
		RETVAL	

int
sdl_set_color_key ( surface, flag, key )
	SDL_Surface *surface
	Uint32 flag
	Uint32 key
	CODE:
		RETVAL = SDL_SetColorKey(surface,flag,key);
	OUTPUT:
		RETVAL

Uint32
sdl_srccolorkey ()
	CODE:
		RETVAL = SDL_SRCCOLORKEY;
	OUTPUT:	
		RETVAL


Uint32
sdl_srcclipping ()
	CODE:
		RETVAL = SDL_SRCCLIPPING;
	OUTPUT:	
		RETVAL

Uint32
sdl_rleaccel ()
	CODE:
		RETVAL = SDL_RLEACCEL;
	OUTPUT:
		RETVAL

Uint32
sdl_rleaccelok ()
	CODE:
		RETVAL = SDL_RLEACCELOK;
	OUTPUT:
		RETVAL

Uint32
sdl_srcalpha ()
	CODE:
		RETVAL = SDL_SRCALPHA;
	OUTPUT:
		RETVAL

int
sdl_set_alpha ( surface, flag, alpha )
	SDL_Surface *surface
	Uint32 flag
	Uint8 alpha
	CODE:
		RETVAL = SDL_SetAlpha(surface,flag,alpha);
	OUTPUT:
		RETVAL

void
sdl_set_clipping ( surface, top, left, bottom, right )
	SDL_Surface *surface
	int top
	int left
	int bottom
	int right
	CODE:
		SDL_SetClipping(surface,top,left,bottom,right);

SDL_Surface *
sdl_display_format( surface )
	SDL_Surface *surface
	CODE:
		RETVAL = SDL_DisplayFormat(surface);
	OUTPUT:
		RETVAL

int
sdl_blit_surface ( src, src_rect, dest, dest_rect )
	SDL_Surface *src
	SDL_Rect *src_rect
	SDL_Surface *dest
	SDL_Rect *dest_rect
	CODE:
		RETVAL = SDL_BlitSurface(src,src_rect,dest,dest_rect);
	OUTPUT:
		RETVAL

int
sdl_fill_rect ( dest, dest_rect, color )
	SDL_Surface *dest
	SDL_Rect *dest_rect
	Uint32 color
	CODE:
		RETVAL = SDL_FillRect(dest,dest_rect,color);
	OUTPUT:
		RETVAL

void
sdl_wm_set_caption ( title, icon )
	char *title
	char *icon
	CODE:
		SDL_WM_SetCaption(title,icon);

AV *
sdl_wm_get_caption ()
	CODE:
		char *title,*icon;
		SDL_WM_GetCaption(&title,&icon);
		RETVAL = newAV();
		av_push(RETVAL,newSVpv(title,0));
		av_push(RETVAL,newSVpv(icon,0));
	OUTPUT:
		RETVAL

void
sdl_wm_set_icon ( icon )
	SDL_Surface *icon
	CODE:
		SDL_WM_SetIcon(icon,NULL);

void
sdl_warp_mouse ( x, y )
	Uint16 x
	Uint16 y
	CODE:
		SDL_WarpMouse(x,y);

void
sdl_wm_toggle_fullscreen ( surface )
	SDL_Surface *surface
	CODE:
		SDL_WM_ToggleFullScreen(surface);

SDL_Cursor *
sdl_new_cursor ( data, mask, x ,y )
	SDL_Surface *data
	SDL_Surface *mask
	int x
	int y
	CODE:
		RETVAL = SDL_CreateCursor((Uint8*)data->pixels,
				(Uint8*)mask->pixels,data->w,data->h,x,y);
	OUTPUT:
		RETVAL

void
sdl_free_cursor ( cursor )
	SDL_Cursor *cursor
	CODE:
		SDL_FreeCursor(cursor);

void
sdl_set_cursor ( cursor )
	SDL_Cursor *cursor
	CODE:
		SDL_SetCursor(cursor);

SDL_Cursor *
sdl_get_cursor ()
	CODE:
		RETVAL = SDL_GetCursor();
	OUTPUT:
		RETVAL

int
sdl_show_cursor ( toggle )
	int toggle
	CODE:
		RETVAL = SDL_ShowCursor(toggle);
	OUTPUT: 
		RETVAL

SDL_AudioSpec *
sdl_new_audio_spec ( freq, format, channels, samples, callback, userdata )
	int freq
	Uint16 format
	Uint8 channels
	Uint16 samples
	void *callback
	void *userdata
	CODE:
		RETVAL = (SDL_AudioSpec *)safemalloc(sizeof(SDL_AudioSpec));
		RETVAL->freq = freq;
		RETVAL->channels = channels;
		RETVAL->samples = samples;
		RETVAL->callback = callback;
		RETVAL->userdata = userdata;
	OUTPUT:
		RETVAL

void
sdl_free_audio_spec ( spec )
	SDL_AudioSpec *spec
	CODE:
		safefree(spec);

Uint16
sdl_audio_U8 ()
	CODE:
		RETVAL = AUDIO_U8;
	OUTPUT: 
		RETVAL

Uint16
sdl_audio_S8 ()
	CODE:
		RETVAL = AUDIO_S8;
	OUTPUT: 
		RETVAL

Uint16
sdl_audio_U16 ()
	CODE:
		RETVAL = AUDIO_U16;
	OUTPUT: 
		RETVAL

Uint16
sdl_audio_S16 ()
	CODE:
		RETVAL = AUDIO_S16;
	OUTPUT: 
		RETVAL

Uint16
sdl_audio_U16MSB ()
	CODE:
		RETVAL = AUDIO_U16MSB;
	OUTPUT: 
		RETVAL

Uint16
sdl_audio_S16MSB ()
	CODE:
		RETVAL = AUDIO_S16MSB;
	OUTPUT: 
		RETVAL

SDL_AudioCVT *
sdl_new_audio_cvt ( src_format, src_channels, src_rate, dst_format, dst_channels, dst_rate)
	Uint16 src_format
	Uint8 src_channels
	int src_rate
	Uint16 dst_format
	Uint8 dst_channels
	int dst_rate
	CODE:
		RETVAL = (SDL_AudioCVT *)safemalloc(sizeof(SDL_AudioCVT));
		if (SDL_BuildAudioCVT(RETVAL,src_format, src_channels, src_rate,
			dst_format, dst_channels, dst_rate)) { 
			safefree(RETVAL); RETVAL = NULL; }
	OUTPUT:
		RETVAL

void
sdl_free_audio_cvt ( cvt )
	SDL_AudioCVT *cvt
	CODE:
		safefree(cvt);

int
sdl_convert_audio_data ( cvt, data, len )
	SDL_AudioCVT *cvt
	Uint8 *data
	int len
	CODE:
		cvt->len = len;
		cvt->buf = (Uint8*) safemalloc(cvt->len*cvt->len_mult);
		memcpy(cvt->buf,data,cvt->len);
		RETVAL = SDL_ConvertAudio(cvt);
	OUTPUT:
		RETVAL			

int
sdl_open_audio ( spec )
	SDL_AudioSpec *spec
	CODE:
		RETVAL = SDL_OpenAudio(spec,NULL);
	OUTPUT:
		RETVAL

void
sdl_pause_audio ( p_on )
	int p_on
	CODE:
		SDL_PauseAudio(p_on);
	
void
sdl_lock_audio ()
	CODE:
		SDL_LockAudio();

void
sdl_unlock_audio ()
	CODE:
		SDL_UnlockAudio();

void
sdl_close_audio ()
	CODE:
		SDL_CloseAudio();

void
sdl_free_wav ( buf )
	Uint8 *buf
	CODE:
		SDL_FreeWAV(buf);

AV *
sdl_load_wav ( filename, spec )
	char *filename
	SDL_AudioSpec *spec
	CODE:
		SDL_AudioSpec *temp;
		Uint8 *buf;
		Uint32 len;

		RETVAL = newAV();
		temp = SDL_LoadWAV(filename,spec,&buf,&len);
		if ( ! temp ) goto error;
		av_push(RETVAL,newSViv((Uint32)temp));
		av_push(RETVAL,newSViv((Uint32)buf));
		av_push(RETVAL,newSViv(len));
error:
	OUTPUT:
		RETVAL

void
sdl_mix_audio ( dst, src, len, volume )
	Uint8 *dst
	Uint8 *src
	Uint32 len
	int volume
	CODE:
		SDL_MixAudio(dst,src,len,volume);
	
int
sdl_mix_max_volume ()
	CODE:
		RETVAL = MIX_MAX_VOLUME;
	OUTPUT:
		RETVAL

int
sdl_mix_default_frequency ()
	CODE:
		RETVAL = MIX_DEFAULT_FREQUENCY;
	OUTPUT:
		RETVAL

Uint16
sdl_mix_default_format ()
	CODE:
		RETVAL = MIX_DEFAULT_FORMAT;
	OUTPUT:	
		RETVAL

int
sdl_mix_default_channels ()
	CODE:
		RETVAL = MIX_DEFAULT_CHANNELS;
	OUTPUT:
		RETVAL

Mix_Fading
sdl_mix_no_fading ()
	CODE:
		RETVAL = MIX_NO_FADING;
	OUTPUT:	
		RETVAL

Mix_Fading
sdl_mix_fading_out ()
	CODE:
		RETVAL = MIX_FADING_OUT;
	OUTPUT:
		RETVAL

Mix_Fading
sdl_mix_fading_in ()
	CODE:
		RETVAL = MIX_FADING_IN;
	OUTPUT:
		RETVAL

int
sdl_mix_open_audio ( frequency, format, channels, chunksize )
	int frequency
	Uint16 format
	int channels
	int chunksize	
	CODE:
		RETVAL = Mix_OpenAudio(frequency, format, channels, chunksize);
	OUTPUT:
		RETVAL

int
sdl_mix_allocate_channels ( number )
	int number
	CODE:
		RETVAL = Mix_AllocateChannels(number);
	OUTPUT:
		RETVAL

AV *
sdl_mix_query_spec ()
	CODE:
		int freq, channels, status;
		Uint16 format;
		status = Mix_QuerySpec(&freq,&format,&channels);
		RETVAL = newAV();
		av_push(RETVAL,newSViv(status));
		av_push(RETVAL,newSViv(freq));
		av_push(RETVAL,newSViv(format));
		av_push(RETVAL,newSViv(channels));
	OUTPUT:
		RETVAL

Mix_Chunk *
sdl_mix_load_wav ( filename )
	char *filename
	CODE:
		RETVAL = Mix_LoadWAV(filename);
	OUTPUT:
		RETVAL

Mix_Music *
sdl_mix_load_music ( filename )
	char *filename
	CODE:
		RETVAL = Mix_LoadMUS(filename);
	OUTPUT:
		RETVAL

Mix_Chunk *
sdl_mix_quick_load_wav ( buf )
	Uint8 *buf
	CODE:
		RETVAL = Mix_QuickLoad_WAV(buf);
	OUTPUT:
		RETVAL

void
sdl_mix_free_chunk ( chunk )
	Mix_Chunk *chunk
	CODE:
		Mix_FreeChunk(chunk);

void
sdl_mix_free_music ( music )
	Mix_Music *music
	CODE:
		Mix_FreeMusic(music);

void
sdl_mix_set_post_mix_callback ( func, arg )
	void *func
	void *arg
	CODE:
		Mix_SetPostMix(func,arg);

void
sdl_mix_set_music_hook ( func, arg )
	void *func
	void *arg
	CODE:
		Mix_HookMusic(func,arg);

void
sdl_mix_set_music_finished_hook ( func )
	void *func
	CODE:
		Mix_HookMusicFinished(func);

void *
sdl_mix_get_music_hook_data ()
	CODE:
		RETVAL = Mix_GetMusicHookData();
	OUTPUT:
		RETVAL

int
sdl_mix_reserve_channels ( number )
	int number
	CODE:
		RETVAL = Mix_ReserveChannels ( number );
	OUTPUT:
		RETVAL

int
sdl_mix_group_channel ( which, tag )
	int which
	int tag
	CODE:
		RETVAL = Mix_GroupChannel(which,tag);
	OUTPUT:
		RETVAL

int
sdl_mix_group_channels ( from, to, tag )
	int from
	int to
	int tag
	CODE:
		RETVAL = Mix_GroupChannels(from,to,tag);
	OUTPUT:
		RETVAL

int
sdl_mix_group_available ( tag )
	int tag
	CODE:
		RETVAL = Mix_GroupAvailable(tag);
	OUTPUT:
		RETVAL

int
sdl_mix_group_count ( tag )
	int tag
	CODE:
		RETVAL = Mix_GroupCount(tag);
	OUTPUT:
		RETVAL

int
sdl_mix_group_oldest ( tag )
	int tag
	CODE:
		RETVAL = Mix_GroupOldest(tag);
	OUTPUT:
		RETVAL

int
sdl_mix_group_newer ( tag )
	int tag
	CODE:
		RETVAL = Mix_GroupNewer(tag);
	OUTPUT:
		RETVAL

int
sdl_mix_play_channel ( channel, chunk, loops )
	int channel
	Mix_Chunk *chunk
	int loops
	CODE:
		RETVAL = Mix_PlayChannel(channel,chunk,loops);
	OUTPUT:
		RETVAL

int
sdl_mix_play_channel_timed ( channel, chunk, loops, ticks )
	int channel
	Mix_Chunk *chunk
	int loops
	int ticks
	CODE:
		RETVAL = Mix_PlayChannelTimed(channel,chunk,loops,ticks);
	OUTPUT:
		RETVAL

int
sdl_mix_play_music ( music, loops )
	Mix_Music *music
	int loops
	CODE:
		RETVAL = Mix_PlayMusic(music,loops);
	OUTPUT:
		RETVAL

int
sdl_mix_fade_in_channel ( channel, chunk, loops, ms )
	int channel
	Mix_Chunk *chunk
	int loops
	int ms
	CODE:
		RETVAL = Mix_FadeInChannel(channel,chunk,loops,ms);
	OUTPUT:
		RETVAL

int
sdl_mix_fade_in_channel_timed ( channel, chunk, loops, ms, ticks )
	int channel
	Mix_Chunk *chunk
	int loops
	int ticks
	int ms
	CODE:
		RETVAL = Mix_FadeInChannelTimed(channel,chunk,loops,ms,ticks);
	OUTPUT:
		RETVAL

int
sdl_mix_fade_in_music ( music, loops, ms )
	Mix_Music *music
	int loops
	int ms
	CODE:
		RETVAL = Mix_FadeInMusic(music,loops,ms);
	OUTPUT:
		RETVAL

int
sdl_mix_volume ( channel, volume )
	int channel
	int volume
	CODE:	
		RETVAL = Mix_Volume(channel,volume);
	OUTPUT:
		RETVAL

int
sdl_mix_chunk_volume ( chunk, volume )
	Mix_Chunk *chunk
	int volume
	CODE:
		RETVAL = Mix_VolumeChunk(chunk,volume);
	OUTPUT:
		RETVAL

int
sdl_mix_volume_music ( volume )
	int volume
	CODE:
		RETVAL = Mix_VolumeMusic(volume);
	OUTPUT:
		RETVAL

int
sdl_mix_halt_channel ( channel )
	int channel
	CODE:
		RETVAL = Mix_HaltChannel(channel);
	OUTPUT:
		RETVAL

int
sdl_mix_halt_group ( tag )
	int tag
	CODE:
		RETVAL = Mix_HaltGroup(tag);
	OUTPUT:
		RETVAL

int
sdl_mix_halt_music ()
	CODE:
		RETVAL = Mix_HaltMusic();
	OUTPUT:
		RETVAL

int
sdl_mix_expire_channel ( channel, ticks )
	int channel
	int ticks
	CODE:
		RETVAL = Mix_ExpireChannel ( channel,ticks);
	OUTPUT:
		RETVAL

int
sdl_mix_fade_out_channel ( which, ms )
	int which
	int ms
	CODE:
		RETVAL = Mix_FadeOutChannel(which,ms);
	OUTPUT:
		RETVAL

int
sdl_mix_fade_out_group ( which, ms )
	int which
	int ms
	CODE:
		RETVAL = Mix_FadeOutGroup(which,ms);
	OUTPUT:
		RETVAL

int
sdl_mix_fade_out_music ( ms )
	int ms
	CODE:
		RETVAL = Mix_FadeOutMusic(ms);
	OUTPUT:
		RETVAL

Mix_Fading
sdl_mix_fading_music_p ()
	CODE:
		RETVAL = Mix_FadingMusic();
	OUTPUT:
		RETVAL

Mix_Fading
sdl_mix_fading_channel_p ( which )
	int which
	CODE:
		RETVAL = Mix_FadingChannel(which);
	OUTPUT:
		RETVAL

void
sdl_mix_pause ( channel )
	int channel
	CODE:
		Mix_Pause(channel);

void
sdl_mix_resume ( channel )
	int channel
	CODE:
		Mix_Resume(channel);

int
sdl_mix_paused ( channel )
	int channel
	CODE:
		RETVAL = Mix_Paused(channel);
	OUTPUT:
		RETVAL

void
sdl_mix_pause_music ()
	CODE:
		Mix_PauseMusic();

void
sdl_mix_resume_music ()
	CODE:
		Mix_ResumeMusic();

void
sdl_mix_rewind_music ()
	CODE:
		Mix_RewindMusic();

int
sdl_mix_paused_music ()
	CODE:
		RETVAL = Mix_PausedMusic();
	OUTPUT:
		RETVAL

int
sdl_mix_playing ( channel )
	int channel	
	CODE:
		RETVAL = Mix_Playing(channel);
	OUTPUT:
		RETVAL

int
sdl_mix_playing_music ()
	CODE:
		RETVAL = Mix_PlayingMusic();
	OUTPUT:
		RETVAL


void
sdl_mix_close_audio ()
	CODE:
		Mix_CloseAudio();

SDL_Surface *
sdl_sfont_new_font ( filename )
	char *filename
	CODE:
		RETVAL = IMG_Load(filename);
		InitFont(RETVAL);
	OUTPUT:
		RETVAL

void
sdl_sfont_use_font ( surface )
	SDL_Surface *surface
	CODE:
		InitFont(surface);

void
sdl_sfont_surface_print ( surface, x, y, text )
	SDL_Surface *surface
	int x
	int y
	char *text
	CODE:
		PutString( surface, x, y, text );

int
sdl_sfont_text_width ( text )
	char *text
	CODE:
		RETVAL = TextWidth(text);
	OUTPUT:
		RETVAL
		

Uint32
sdl_gl_red_size ()
	CODE:
		RETVAL = SDL_GL_RED_SIZE;
	OUTPUT:
		RETVAL

Uint32
sdl_gl_green_size ()
	CODE:
		RETVAL = SDL_GL_GREEN_SIZE;
	OUTPUT:
		RETVAL

Uint32
sdl_gl_blue_size ()
	CODE:
		RETVAL = SDL_GL_BLUE_SIZE;
	OUTPUT:
		RETVAL


Uint32
sdl_gl_alpha_size ()
	CODE:
		RETVAL = SDL_GL_ALPHA_SIZE;
	OUTPUT:
		RETVAL


Uint32
sdl_gl_accum_red_size ()
	CODE:
		RETVAL = SDL_GL_ACCUM_RED_SIZE;
	OUTPUT:
		RETVAL


Uint32
sdl_gl_accum_green_size ()
	CODE:
		RETVAL = SDL_GL_ACCUM_GREEN_SIZE;
	OUTPUT:
		RETVAL

Uint32
sdl_gl_accum_blue_size ()
	CODE:
		RETVAL = SDL_GL_ACCUM_BLUE_SIZE;
	OUTPUT:
		RETVAL


Uint32
sdl_gl_accum_alpha_size ()
	CODE:
		RETVAL = SDL_GL_ACCUM_ALPHA_SIZE;
	OUTPUT:
		RETVAL



Uint32
sdl_gl_buffer_size ()
	CODE:
		RETVAL = SDL_GL_BUFFER_SIZE;
	OUTPUT:
		RETVAL

Uint32
sdl_gl_depth_size ()
	CODE:
		RETVAL = SDL_GL_DEPTH_SIZE;
	OUTPUT:
		RETVAL


Uint32
sdl_gl_stencil_size ()
	CODE:
		RETVAL = SDL_GL_STENCIL_SIZE;
	OUTPUT:
		RETVAL


Uint32
sdl_gl_doublebuffer ()
	CODE:
		RETVAL = SDL_GL_DOUBLEBUFFER;
	OUTPUT:
		RETVAL


int
sdl_gl_set_attribute ( attr,  value )
	int        attr
	int        value
	CODE:
		RETVAL = SDL_GL_SetAttribute(attr, value);
	OUTPUT:
	        RETVAL

int
sdl_gl_get_attribute ( attr,  value )
	int        attr
	int        *value
	CODE:
		RETVAL = SDL_GL_GetAttribute(attr, value);
	OUTPUT:
	        RETVAL


void
sdl_gl_swap_buffers (  )
	CODE:
		SDL_GL_SwapBuffers ();





Uint32
sdl_hat_centered ()
	CODE:
		RETVAL = SDL_HAT_CENTERED;
	OUTPUT:
		RETVAL


Uint32
sdl_hat_up ()
	CODE:
		RETVAL = SDL_HAT_UP;
	OUTPUT:
		RETVAL


Uint32
sdl_hat_right ()
	CODE:
		RETVAL = SDL_HAT_RIGHT;
	OUTPUT:
		RETVAL


Uint32
sdl_hat_down ()
	CODE:
		RETVAL = SDL_HAT_DOWN;
	OUTPUT:
		RETVAL


Uint32
sdl_hat_left ()
	CODE:
		RETVAL = SDL_HAT_LEFT;
	OUTPUT:
		RETVAL


Uint32
sdl_hat_rightup ()
	CODE:
		RETVAL = SDL_HAT_RIGHTUP;
	OUTPUT:
		RETVAL


Uint32
sdl_hat_rightdown ()
	CODE:
		RETVAL = SDL_HAT_RIGHTDOWN;
	OUTPUT:
		RETVAL


Uint32
sdl_hat_leftup ()
	CODE:
		RETVAL = SDL_HAT_LEFTUP;
	OUTPUT:
		RETVAL


Uint32
sdl_hat_leftdown ()
	CODE:
		RETVAL = SDL_HAT_LEFTDOWN;
	OUTPUT:
		RETVAL



int 
sdl_num_joysticks  ( )
	CODE:
		RETVAL = SDL_NumJoysticks( );

	OUTPUT:
		RETVAL

const char *
sdl_joystick_name  ( index )
	int    index;
	CODE:
		RETVAL = SDL_JoystickName( index );

	OUTPUT:
		RETVAL

SDL_Joystick *
sdl_joystick_open  ( index )
	int    index;
	CODE:
		RETVAL = SDL_JoystickOpen( index );

	OUTPUT:
		RETVAL

int 
sdl_joystick_opened  ( index )
	int    index;
	CODE:
		RETVAL = SDL_JoystickOpened( index );

	OUTPUT:
		RETVAL

int 
sdl_joystick_index  ( joystick )
	SDL_Joystick *   joystick;
	CODE:
		RETVAL = SDL_JoystickIndex( joystick );

	OUTPUT:
		RETVAL

int 
sdl_joystick_num_axes  ( joystick )
	SDL_Joystick *   joystick;
	CODE:
		RETVAL = SDL_JoystickNumAxes( joystick );

	OUTPUT:
		RETVAL

int 
sdl_joystick_num_balls  ( joystick )
	SDL_Joystick *   joystick;
	CODE:
		RETVAL = SDL_JoystickNumBalls( joystick );

	OUTPUT:
		RETVAL

int 
sdl_joystick_num_hats  ( joystick )
	SDL_Joystick *   joystick;
	CODE:
		RETVAL = SDL_JoystickNumHats( joystick );

	OUTPUT:
		RETVAL

int 
sdl_joystick_num_buttons  ( joystick )
	SDL_Joystick *   joystick;
	CODE:
		RETVAL = SDL_JoystickNumButtons( joystick );

	OUTPUT:
		RETVAL

void 
sdl_joystick_update  ( )
	CODE:
		SDL_JoystickUpdate( );




int 
sdl_joystick_event_state  ( state )
	int    state;
	CODE:
		RETVAL = SDL_JoystickEventState( state );

	OUTPUT:
		RETVAL

Sint16 
sdl_joystick_get_axis  ( joystick, axis )
	SDL_Joystick *   joystick;
	int    axis;
	CODE:
		RETVAL = SDL_JoystickGetAxis( joystick, axis );

	OUTPUT:
		RETVAL

Uint8 
sdl_joystick_get_hat  ( joystick, hat )
	SDL_Joystick *   joystick;
	int    hat;
	CODE:
		RETVAL = SDL_JoystickGetHat( joystick, hat );

	OUTPUT:
		RETVAL

int 
sdl_joystick_get_ball  ( joystick, ball, dx, dy )
	SDL_Joystick *   joystick;
	int    ball;
	int *   dx;
	int *   dy;
	CODE:
		RETVAL = SDL_JoystickGetBall( joystick, ball, dx, dy );

	OUTPUT:
		RETVAL

Uint8 
sdl_joystick_get_button  ( joystick, button )
	SDL_Joystick *   joystick;
	int    button;
	CODE:
		RETVAL = SDL_JoystickGetButton( joystick, button );

	OUTPUT:
		RETVAL

void 
sdl_joystick_close  ( joystick )
	SDL_Joystick *   joystick;
	CODE:
		SDL_JoystickClose( joystick );




