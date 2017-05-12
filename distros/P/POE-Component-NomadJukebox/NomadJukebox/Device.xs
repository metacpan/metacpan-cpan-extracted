#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <sys/types.h>
#include <stdlib.h>
#include <unistd.h>
#include <limits.h>
#include <libnjb.h>

extern int njb_error;

static njb_t njbs[NJB_MAX_DEVICES];
static SV* progress_func;
static AV* track_hash;

// NJB_Replace_Track_Tag
// NJB_Update_Playlist
// NJB_Set_Bitmap
// NJB_Get_Time
// NJB_Set_Time
// NJB_Refresh_EAX
// NJB_Get_EAX
// NJB_Get_Extended_Tags
// NJB_Ping
// NJB_Elapsed_Time

//static AV *njb_Discover	( void );
static AV *Discover			( void );
static SV *Open				( SV* device );
static AV *TrackList		( SV* device, int extended );
static AV *PlayList			( SV* device );
static AV *FileList			( SV* device );
static SV *DeletePlayList	( SV* device, int plid );
static SV *GetTrack			( SV* device, SV* hash, char* fname );
static SV *SendTrack		( SV* device, SV* arglist);
static SV *SendFile			( SV* device, SV* arglist);
static SV *GetFile			( SV* device, SV* hash, char* fname );
static SV *PlayTrack		( SV* device, int trackid );
static SV *QueueTrack		( SV* device, int trackid );
static SV *DeleteTrack		( SV* device, int trackid );
static SV *DeleteFile		( SV* device, int fileid );
static SV *StopPlay			( SV* device );
static SV *PausePlay		( SV* device );
static SV *ResumePlay		( SV* device );
static SV *SeekTrack		( SV* device, int position );
static SV *AdjustSound		( SV* device, int effect, int value );
static SV *GetOwner			( SV* device );
static SV *SetOwner			( SV* device, SV* owner );
static SV *GetTmpDir		( SV* device );
static SV *SetTmpDir		( SV* device, SV* dir );
static AV *DiskUsage		( SV* device );
void Close					( SV* device );
static SV *Progress			( SV* prog );
static int progress			(u_int64_t sent, u_int64_t total, const char* buf, unsigned len, void *data);


/* Old code that I'm not using
static AV*
njb_Discover ( void ) {
	AV*    devlist;
	int    n, i;

	devlist = newAV();
	
	if (NJB_Discover(njbs, 0, &n) == -1) {
		printf ("No Nomad Jukebox devices found, are they on?\n");
	}
	
	for (i=0; i<n; i++) {
		av_push(devlist, newSViv((IV) &(njbs[i])));
	}

	return devlist;
}
*/

/*
 * Return a handle to an Nomad Jukebox device.  This handle is
 * needed for almost every function.
*/

static SV*
Open ( SV* device ) {
	njb_t *njb = (njb_t*) SvIV (device);
	AV*    devlist;
	SV**   test;
	HV*    stash;
   	SV*    blessed_device;
/*
	if (!njb) {
		devlist = njb_Discover();

		if (av_len(devlist) == -1) {
			return &PL_sv_undef;
		}

		test = av_fetch( devlist, 0, 0 );
		if (!test) {
			printf ("Can't get device list\n");
			return &PL_sv_undef;
		}

		njb = (njb_t*) SvIV( *test );
		av_undef( devlist );
	}
*/
	if (!njb) {
		return &PL_sv_undef;
//		return (newSViv( 0 ));
	}

	if ( NJB_Open(njb) == -1 ) {
		return &PL_sv_undef;
	}

	if ( NJB_Capture(njb) == -1 ) {
		return &PL_sv_undef;
	}

	blessed_device = newSViv( (IV) njb );

	blessed_device = sv_bless(newRV_noinc(blessed_device),
		gv_stashpv("POE::Component::NomadJukebox::Device", FALSE));

	return blessed_device;
}


/*
 * Retrieve track <trackid> from the device, and save it
 * to file <fname>
*/

static SV*
GetTrack (SV* device, SV* hash, char* fname) {
	songid_t*  tag;
	njb_t*     njb;
	int        size=0;
	int        trackid;
	HV*        HV_track_info;
	SV**       ref;

	if (SvROK( device )) {
		device = SvRV( device );
	}

	njb = (njb_t*) SvIV( device );

	if (SvROK( hash )) {
		HV_track_info = (HV*) SvRV( hash );
	}

	ref = hv_fetch( HV_track_info, "TAG", 3, 0);

	if ( ref ) {
		tag = (songid_t*) SvIV( *ref );
		trackid = tag->trid;
		size = songid_size( tag );
	} else {
		trackid = SvIV(* hv_fetch( HV_track_info, "ID", 2, 0) );
		if  ( trackid ) {
			NJB_Reset_Get_Track_Tag(njb);
			while ( (tag = NJB_Get_Track_Tag(njb)) ) {
				if ( tag->trid == trackid ) {
					size = songid_size( tag );
				}
				songid_destroy(tag);
			}
			if ( size == 0 ) {
				printf("failed to find track %d\n",trackid);
				return &PL_sv_undef;
			}
		} else {
			printf( "Not a proper hash reference, must have TAG or ID in it!\n" );
			return &PL_sv_undef;
		}
	}

	if ( NJB_Get_Track (njb, trackid, size, fname, progress, NULL) == -1 ) {
		njb_error_dump( stderr );
		return &PL_sv_undef;
	}

	return newSViv( (IV) 1 );
}

static SV*
SendTrack (SV* device, SV* arglist) {
	SV**       scratch;
	SV*        result;
	SV*        argref;
	njb_t*     njb;
	int        trackid, track;
	char *path, *partist, *ptitle, *pgenre, *pcodec, *palbum, *pnum;
	u_int32_t length, size;
	

	if (SvROK( device )) {
		device = SvRV( device );
	}

	if (SvROK(arglist)) {
		argref = SvRV(arglist);
	}	

	njb = (njb_t*) SvIV( device );

	if (scratch = hv_fetch( (HV*) argref , "FILE", 4, 0))
		path = SvPV( *scratch, PL_na);

	if (scratch = hv_fetch( (HV*) argref , "CODEC", 5, 0))
		pcodec  = SvPV( *scratch, PL_na);

	if (scratch = hv_fetch( (HV*) argref , "TITLE", 5, 0))
		ptitle = SvPV( *scratch, PL_na);

	if (scratch = hv_fetch( (HV*) argref , "ALBUM", 5, 0))
		palbum = SvPV( *scratch, PL_na);

	if (scratch = hv_fetch( (HV*) argref , "GENRE", 5, 0))
		pgenre = SvPV( *scratch, PL_na);

	if (scratch = hv_fetch( (HV*) argref , "ARTIST", 6, 0))
		partist = SvPV( *scratch, PL_na);

	if (scratch = hv_fetch( (HV*) argref , "LENGTH", 6, 0))
		length = SvIV ( *scratch );

	if (scratch = hv_fetch( (HV*) argref , "TRACK", 5, 0))
		track = SvIV ( *scratch );

	if ( NJB_Send_Track(njb, path, pcodec, ptitle, palbum, pgenre,
		partist, length, track, NULL, 0, progress,
		NULL, &trackid) == -1 ) {

		njb_error_dump(stderr);
		result = &PL_sv_undef;
	} else {
		result = newSViv( (IV) trackid );
	}
	
	return result;
}

static SV*
SendFile (SV* device, SV* arglist) {
	SV**       scratch;
	SV*        result;
	SV*        argref;
	njb_t*     njb;
	int        fileid;
	char *path, *name;
	

	if (SvROK( device )) {
		device = SvRV( device );
	}

	if (SvROK(arglist)) {
		argref = SvRV(arglist);
	}	

	njb = (njb_t*) SvIV( device );

	if (scratch = hv_fetch( (HV*) argref , "FILE", 4, 0))
		path = SvPV( *scratch, PL_na);

	if (scratch = hv_fetch( (HV*) argref , "NAME", 4, 0))
		name = SvPV( *scratch, PL_na);

	if ( NJB_Send_File(njb, path, name, progress, NULL,
		&fileid) == -1 ) {

		njb_error_dump(stderr);
		result = &PL_sv_undef;
	} else {
		result = newSViv( (IV) fileid );
	}
	
	return result;
}

/*
 * Retrieve file <fileid> from the device, and save it
 * to file <fname>
*/

static SV*
GetFile (SV* device, SV* hash, char* fname) {
	datafile_t*  df;
	njb_t*     njb;
	u_int64_t  size=0;
	u_int32_t  fileid;
	HV*        HV_track_info;
	SV**       ref;

	if (SvROK( device )) {
		device = SvRV( device );
	}

	njb = (njb_t*) SvIV( device );

	if (SvROK( hash )) {
		HV_track_info = (HV*) SvRV( hash );
	}

	ref = hv_fetch( HV_track_info, "TAG", 3, 0);

	if ( ref ) {
		df = (datafile_t*) SvIV( *ref );
		fileid = df->dfid;
		size = datafile_size( df );
	} else {
		fileid = SvIV(* hv_fetch( HV_track_info, "ID", 2, 0) );
		if  ( fileid ) {
			NJB_Reset_Get_Datafile_Tag(njb);
			while ( (df = NJB_Get_Datafile_Tag(njb)) ) {
				if ( df->dfid == fileid ) {
					size = datafile_size( df );
				}
				datafile_destroy(df);
			}
			if ( size == 0 ) {
				printf("failed to find file %d\n",fileid);
				return &PL_sv_undef;
			}
		} else {
			printf( "Not a proper hash reference, must have TAG or ID in it!\n" );
			return &PL_sv_undef;
		}
	}

	if ( NJB_Get_File (njb, fileid, (u_int32_t) size, fname, progress, NULL) == -1 ) {
		njb_error_dump( stderr );
		return &PL_sv_undef;
	}

	return newSViv( (IV) 1 );
}

static SV*
ProgressFunc (SV* prog) {
	if (prog) {
		progress_func = newSVsv(prog);
		return newSViv( (IV) 1);
	}

	return &PL_sv_undef;
}


static int
progress (u_int64_t sent, u_int64_t total, const char* buf,
		unsigned len, void *data) {
	if (progress_func) {
		dSP;

		ENTER;
		SAVETMPS;

		PUSHMARK( SP );
		XPUSHs ( sv_2mortal( newSViv( sent )));
		XPUSHs ( sv_2mortal( newSViv( total )));
		PUTBACK;

		call_sv( progress_func, G_DISCARD );

		FREETMPS;
		LEAVE;
	}

	return 0;
}

/*
 * Play
*/

static SV*
PlayTrack ( SV* device, int trackid ) {
	njb_t*     njb;

	if (SvROK( device )) {
		device = SvRV( device );
	}

	njb = (njb_t*) SvIV( device );

	if (njb) {
		int status;

		status = NJB_Play_Track( njb, trackid );
		return newSViv( (IV) status );
	}

	return &PL_sv_undef;
}

/*
 * Queue
*/

static SV*
QueueTrack ( SV* device, int trackid ) {
	njb_t*     njb;

	if (SvROK( device )) {
		device = SvRV( device );
	}

	njb = (njb_t*) SvIV( device );

	if (njb) {
		int status;

		status = NJB_Queue_Track( njb, trackid );
		return newSViv( (IV) status );
	}

	return &PL_sv_undef;
}

/*
 * Delete
*/

static SV*
DeleteTrack ( SV* device, int trackid ) {
	njb_t*     njb;

	if (SvROK( device )) {
		device = SvRV( device );
	}

	njb = (njb_t*) SvIV( device );

	if (njb) {
		int status;

		status = NJB_Delete_Track( njb, trackid );
		return newSViv( (IV) status );
	}

	return &PL_sv_undef;
}

/*
 * Delete File
*/

static SV*
DeleteFile ( SV* device, int fileid ) {
	njb_t*     njb;

	if (SvROK( device )) {
		device = SvRV( device );
	}

	njb = (njb_t*) SvIV( device );

	if (njb) {
		int status;

		status = NJB_Delete_Datafile( njb, fileid );
		return newSViv( (IV) status );
	}

	return &PL_sv_undef;
}

/*
 * Stop
*/

static SV*
StopPlay ( SV* device ) {
	njb_t*     njb;

	if (SvROK( device )) {
		device = SvRV( device );
	}

	njb = (njb_t*) SvIV( device );

	if (njb) {
		int status;

		status = NJB_Stop_Play( njb );
		return newSViv( (IV) status );
	}

	return &PL_sv_undef;
}

/*
 * Pause
*/

static SV*
PausePlay ( SV* device ) {
	njb_t*     njb;

	if (SvROK( device )) {
		device = SvRV( device );
	}

	njb = (njb_t*) SvIV( device );

	if (njb) {
		int status;

		status = NJB_Pause_Play( njb );
		return newSViv( (IV) status );
	}

	return &PL_sv_undef;
}

/*
 * Resume
*/

static SV*
ResumePlay ( SV* device ) {
	njb_t*     njb;

	if (SvROK( device )) {
		device = SvRV( device );
	}

	njb = (njb_t*) SvIV( device );

	if (njb) {
		int status;

		status = NJB_Resume_Play( njb );
		return newSViv( (IV) status );
	}

	return &PL_sv_undef;
}


/*
 * Seek
*/

static SV*
SeekTrack ( SV* device, int position ) {
	njb_t*     njb;

	if (SvROK( device )) {
		device = SvRV( device );
	}

	njb = (njb_t*) SvIV( device );

	if (njb) {
		int status;

		status = NJB_Seek_Track( njb, position );
		return newSViv( (IV) status );
	}

	return &PL_sv_undef;
}

/*
 * Adjust Sound
*/

static SV*
AdjustSound ( SV* device, int effect, int value ) {
	njb_t*     njb;

	if (SvROK( device )) {
		device = SvRV( device );
	}

	njb = (njb_t*) SvIV( device );

	if (njb) {
		int status;

		status = NJB_Adjust_Sound( njb, effect, value );
		return newSViv( (IV) status );
	}

	return &PL_sv_undef;
}

/*
 * Get the owner string
*/

SV*
GetOwner( SV* device ) {
	njb_t*     njb;

	if (SvROK( device )) {
		device = SvRV( device );
	}

	njb = (njb_t*) SvIV( device );

	if (!njb) {
		return &PL_sv_undef;
	}

	return newSVpv (NJB_Get_Owner_String (njb), 0);
}

/*
 * Set the owner
*/

SV*
SetOwner( SV* device, SV* owner ) {
	SV*     result;
	STRLEN  len;
	char    owner_string[256];
	njb_t*  njb;

	if (SvROK( device )) {
		device = SvRV( device );
	}

	njb = (njb_t*) SvIV( device );

	if (!njb) {
		return &PL_sv_undef;
	}

	strncpy( owner_string, SvPV( owner, len ), 255 );
	owner_string[len] = 0;

	return newSViv( (IV) NJB_Set_Owner_String( njb, owner_string ));
}


/*
 * Close the device
*/

void
Close ( SV* device ) {
	njb_t*     njb;

	if (SvROK( device )) {
		device = SvRV( device );
	}

	njb = (njb_t*) SvIV( device );
	if (njb) {
		NJB_Release(njb);
		NJB_Close(njb);
	}
}

/*
 * Get the temp dir
*/

SV*
GetTmpDir( SV* device ) {
	njb_t*     njb;

	if (SvROK( device )) {
		device = SvRV( device );
	}

	njb = (njb_t*) SvIV( device );

	if (!njb) {
		return &PL_sv_undef;
	}

	return newSVpv (NJB_Get_TmpDir(njb), 0);
}

/*
 * Set the temp dir
*/

SV*
SetTmpDir( SV* device, SV* dir ) {
	SV*     result;
	STRLEN  len;
	char    dir_string[256];
	njb_t*  njb;

	if (SvROK( device )) {
		device = SvRV( device );
	}

	njb = (njb_t*) SvIV( device );

	if (!njb) {
		return &PL_sv_undef;
	}

	strncpy( dir_string, SvPV( dir, len ), 255 );
	dir_string[len] = 0;

	return newSViv( (IV) NJB_Set_TmpDir( njb, dir_string ));
}

/*
 * Delete Playlist
*/

static SV*
DeletePlayList ( SV* device, int plid ) {
	njb_t*     njb;

	if (SvROK( device )) {
		device = SvRV( device );
	}

	njb = (njb_t*) SvIV( device );

	if (njb) {
		int status;

		status = NJB_Delete_Playlist( njb, plid );
		return newSViv( (IV) status );
	}

	return &PL_sv_undef;
}

/**************** Perl Stubs ****************/

MODULE = POE::Component::NomadJukebox::Device		PACKAGE = POE::Component::NomadJukebox::Device		

AV*
Discover ()
	PPCODE:
	HV*    devlist;
	SV*    devid;
//	SV*    type;
	int    n, i;

	devlist = newHV();

	if (NJB_Discover(njbs, 0, &n) == -1) {
		XSRETURN( 0 );
	}

	for (i=0; i<n; i++) {
		XPUSHs( newRV_noinc( (SV*) devlist ));
		devid = newSViv ( (IV) &(njbs[i]) );
//		type = newSViv ( (IV) njbs[i]->device_type);
		hv_store (devlist, "DEVID", 5, devid, 0);
// doesn't work
//		hv_store (devlist, "TYPE", 4, type, 0);
	}

	XSRETURN( i );

SV*
Open ( device )
	SV * device
	OUTPUT:
		RETVAL

void
TrackList ( device, extended )
	SV * device
	int extended
	PPCODE:
	njb_t*     njb;
	int        n, count=0;
	songid_t*  songtag;

	if (SvROK( device )) {
		device = SvRV( device );
	}

	njb = (njb_t*) SvIV( device );
	if ( !njb ) {
	    XSRETURN(0);
	}

	if ( extended == 1 ) {
		// 20 times slower because it gets more tags
		NJB_Get_Extended_Tags(njb, 1);
	}

	NJB_Reset_Get_Track_Tag(njb);
	while ( songtag = NJB_Get_Track_Tag(njb) ) {
		HV*    HV_track_info;
		SV*    data;
		SV*    tag;
		songid_frame_t*  songinfo;
		int    i, j;

		HV_track_info = newHV();
		XPUSHs( newRV_noinc( (SV*) HV_track_info));
		count++;
		tag = newSViv ( (IV) songtag );
		data = newSViv ( (IV) songtag->trid);
		hv_store (HV_track_info, "ID", 2, data, 0);
		hv_store (HV_track_info, "TAG", 3, tag, 0);
// this is set below
//		hv_store (HV_track_info, "SIZE", 4, newSViv( songid_size( songtag )), 0 );
		songinfo = songtag->first;

		for (i=0; i<songtag->nframes; i++) {
			char newdata[256];

 			switch (songinfo->type) {
				case 1:		snprintf ((char *) newdata, 256, "%lu",
							songid_frame_data32(songinfo));
							break;

				case 0:		memcpy(newdata,
							songinfo->data,
							songinfo->datasz);
							break;

				default:	strcpy (newdata, "UNDEF");
			}

			data = newSVpv ( newdata, strlen (newdata) );
  			for (j=0; j<songinfo->labelsz; j++) {
				if ( ((char*) songinfo->label)[j] < 22)
					break;
			}
			hv_store (HV_track_info,
				  (char*) songinfo->label,
				  j,
				  data,
				  0);
			songinfo = songinfo->next;
		}

	}

	// turn it off
	if ( extended == 1 ) {
		NJB_Get_Extended_Tags(njb, 0);
	}
	XSRETURN(count);

void
PlayList ( device )
	SV * device
	PPCODE:
	njb_t*     njb;
//	njbid_t    njbid;
	int        n, count=0;
	playlist_t*  pl;

	if (SvROK( device )) {
		device = SvRV( device );
	}

	njb = (njb_t*) SvIV( device );
	if ( !njb ) {
	    XSRETURN(0);
	}

	NJB_Reset_Get_Playlist(njb);
	while ( pl = NJB_Get_Playlist(njb) ) {
		HV*    HV_playlist_info;
		AV*    AV_tracklist;
		playlist_track_t*  trackinfo;
		int    i;

		AV_tracklist = newAV();
		HV_playlist_info = newHV();
		XPUSHs( newRV_noinc( (SV*) HV_playlist_info));
		count++;
		hv_store (HV_playlist_info, "ID", 2, newSViv( (IV) pl->plid ), 0);
		hv_store (HV_playlist_info, "NAME", 4, newSVpv( pl->name, strlen(pl->name) ), 0);
		hv_store (HV_playlist_info, "TAG", 3, newSViv( (IV) pl ), 0);
		hv_store (HV_playlist_info, "STATE", 5, newSViv( (IV) pl->_state), 0);
		trackinfo = pl->first;
		for (i=0; i<pl->ntracks; i++) {
			SV* trackid;
			
			trackid = newSViv ( (IV) trackinfo->trackid );
			av_push(AV_tracklist,trackid);
			trackinfo = trackinfo->next;
		}
		hv_store (HV_playlist_info, "TRACKS", 6, newRV((SV*) AV_tracklist), 0); 
	}
	XSRETURN(count);

void
FileList ( device )
	SV * device
	PPCODE:
	njb_t*     njb;
	int        n, count=0;
	datafile_t*  datatag;

	if (SvROK( device )) {
		device = SvRV( device );
	}

	njb = (njb_t*) SvIV( device );
	if ( !njb ) {
	    XSRETURN(0);
	}

	NJB_Reset_Get_Datafile_Tag(njb);
	while ( datatag = NJB_Get_Datafile_Tag(njb) ) {
		HV*    HV_datafile_info;

		HV_datafile_info = newHV();
		XPUSHs( newRV_noinc( (SV*) HV_datafile_info));
		count++;
		
		hv_store (HV_datafile_info, "ID", 2, newSVnv ( (NV) datatag->dfid ), 0);
		hv_store (HV_datafile_info, "FILE", 4, newSVpv ( datatag->filename, strlen(datatag->filename) ), 0);
		hv_store (HV_datafile_info, "SIZE", 4, newSVnv ( (NV) datafile_size(datatag) ), 0);
		hv_store (HV_datafile_info, "TAG", 3, newSViv ( (IV) datatag ), 0);
// doesn't work
//		hv_store (HV_datafile_info, "TIMESTAMP", 9, newSVnv ( (NV) datatag->timestamp ), 0);
	}
	XSRETURN(count);

SV*
GetTrack ( device, hash, fname )
	SV *   device
	SV *   hash
	char * fname;
	OUTPUT:
		RETVAL


SV*
SendTrack ( device, arglist )
	SV* device
	SV* arglist
	OUTPUT:
		RETVAL

SV*
SendFile ( device, arglist )
	SV* device
	SV* arglist
	OUTPUT:
		RETVAL

SV*
GetFile ( device, hash, fname )
	SV *   device
	SV *   hash
	char * fname;
	OUTPUT:
		RETVAL

SV*
ProgressFunc ( func )
	SV* func
	OUTPUT:
		RETVAL


SV*
DeleteTrack ( device, trackid )
	SV*   device
	int   trackid
	OUTPUT:
		RETVAL

SV*
DeletePlayList ( device, plid )
	SV*   device
	int   plid
	OUTPUT:
		RETVAL

SV*
DeleteFile ( device, fileid )
	SV*   device
	int   fileid
	OUTPUT:
		RETVAL

SV*
PlayTrack ( device, trackid )
	SV*   device
	int   trackid
	OUTPUT:
		RETVAL

SV*
QueueTrack ( device, trackid )
	SV*   device
	int   trackid
	OUTPUT:
		RETVAL

SV*
SeekTrack ( device, position )
	SV*   device
	int   position
	OUTPUT:
		RETVAL

SV*
StopPlay ( device )
	SV*   device
	OUTPUT:
		RETVAL

SV*
PausePlay ( device )
	SV*   device
	OUTPUT:
		RETVAL

SV*
ResumePlay ( device )
	SV*   device
	OUTPUT:
		RETVAL

SV*
GetOwner ( device )
	SV * device
	OUTPUT:
		RETVAL

SV*
SetOwner ( device, owner )
	SV * device
	SV * owner
	OUTPUT:
		RETVAL

SV*
GetTmpDir ( device )
	SV * device
	OUTPUT:
		RETVAL

SV*
SetTmpDir ( device, dir )
	SV * device
	SV * dir
	OUTPUT:
		RETVAL

void
Close ( device )
	SV * device

AV*
DiskUsage ( device )
	SV*    device
	PPCODE:
	njb_t*     njb;
	HV*    info;
	u_int64_t   total=0, free=0;

	if (SvROK( device )) {
		device = SvRV( device );
	}

	njb = (njb_t*) SvIV( device );
	if ( !njb ) {
	    XSRETURN(0);
	}
	if (NJB_Get_Disk_Usage(njbs, &total, &free) == -1) {
		XSRETURN( 0 );
	}

	info = newHV();
	
	XPUSHs( newRV_noinc( (SV*) info ));
	hv_store (info, "TOTAL", 5, newSVnv( (NV) total ), 0);
	hv_store (info, "FREE", 4, newSVnv( (NV) free ), 0);

	XSRETURN( 1 );

