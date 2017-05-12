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
// David J. Goehrig Copyright (C) 2000
//
// This software is under the GNU Library General Public License (LGPL)
// see the file COPYING for terms of use

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <SDL.h>
#include <SDL_image.h>
#include <SDL_mixer.h>

MODULE = SDL::sdlpl		PACKAGE = SDL::sdlpl
PROTOTYPES : DISABLE

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
