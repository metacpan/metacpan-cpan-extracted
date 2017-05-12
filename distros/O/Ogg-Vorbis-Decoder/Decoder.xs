/* $Id: Decoder.xs 348 2005-07-14 02:32:46Z dsully $ */

#ifdef __cplusplus
"C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <errno.h>
#include <stdlib.h>

#ifdef _MSC_VER
# define alloca            _alloca
#endif

#include <vorbis/codec.h>
#include <vorbis/vorbisfile.h>

/* strlen the length automatically */
#define my_hv_store(a,b,c)   (void)hv_store(a,b,strlen(b),c,0)
#define my_hv_fetch(a,b)     hv_fetch(a,b,strlen(b),0)

#ifdef WORDS_BIGENDIAN
#define host_is_big_endian() TRUE
#else
#define host_is_big_endian() FALSE
#endif

int endian = host_is_big_endian();

static size_t ovcb_read(void *ptr, size_t size, size_t nmemb, void *datasource);
static int    ovcb_seek(void *datasource, ogg_int64_t offset, int whence);
static int    ovcb_close(void *datasource);
static long   ovcb_tell(void *datasource);

/* http://www.xiph.org/ogg/vorbis/doc/vorbisfile/ov_callbacks.html */
ov_callbacks vorbis_callbacks = {
	ovcb_read,
	ovcb_seek,
	ovcb_close,
	ovcb_tell
};

/* Allow multiple instances of the decoder object. Stuff each filehandle into (void*)stream */
typedef struct {
	int is_streaming;
	int bytes_streamed;
	int last_bitstream;
	PerlIO *stream;

} ocvb_datasource;

/* useful items from XMMS */
static size_t ovcb_read(void *ptr, size_t size, size_t nmemb, void *vdatasource) {

	size_t read_bytes = 0;

	ocvb_datasource *datasource = vdatasource;

	read_bytes = PerlIO_read(datasource->stream, ptr, size * nmemb);

	datasource->bytes_streamed += read_bytes;

	return read_bytes;
}

static int ovcb_seek(void *vdatasource, ogg_int64_t offset, int whence) {

	ocvb_datasource *datasource = vdatasource;

	if (datasource->is_streaming) {
		return -1;
	}

	/* For some reason PerlIO_seek fails miserably here. < 5.8.1 works */
	/* return PerlIO_seek(datasource->stream, offset, whence); */

	return fseek(PerlIO_findFILE(datasource->stream), offset, whence);
}

static int ovcb_close(void *vdatasource) {

	ocvb_datasource *datasource = vdatasource;

	return PerlIO_close(datasource->stream);
}

static long ovcb_tell(void *vdatasource) {

	ocvb_datasource *datasource = vdatasource;

	if (datasource->is_streaming) {
		return datasource->bytes_streamed;
	}

	return PerlIO_tell(datasource->stream);
}

/* Loads the commments from the stream and fills the object's hash */
void __read_comments(HV *self, OggVorbis_File *vf) {

	int i;
	char *half;

	/* XXX - rename these */
	HV *comments = newHV();
	SV *ts;
	AV *ta;

	vorbis_comment *vc = ov_comment(vf, -1);

	/* return early if there are no comments */
	if (!vc) return;

	for (i = 0; i < vc->comments; ++i) {

		half = strchr(vc->user_comments[i], '=');

		if (half == NULL) {
			warn("Comment \"%s\" missing \'=\', skipping...\n", vc->user_comments[i]);
			continue;
		}

		if (!hv_exists(comments, vc->user_comments[i], half - vc->user_comments[i])) {

			ta = newAV();
			ts = newRV_noinc((SV*) ta);

			(void)hv_store(comments, vc->user_comments[i], half - vc->user_comments[i], ts, 0);

		} else {

			ta = (AV*) SvRV(*(hv_fetch(comments, vc->user_comments[i], half - vc->user_comments[i], 0)));
		}

		av_push(ta, newSVpv(half + 1, 0));
	}

	my_hv_store(self, "COMMENTS", newRV_noinc((SV*) comments));
}

void __read_info(HV *self, OggVorbis_File *vf) {

	HV *info = newHV();

	vorbis_info *vi = ov_info(vf, -1);

	if (!vi) return;

	my_hv_store(info, "version", newSViv(vi->version));
	my_hv_store(info, "channels", newSViv(vi->channels));
	my_hv_store(info, "rate", newSViv(vi->rate));
	my_hv_store(info, "bitrate_upper", newSViv(vi->bitrate_upper));
	my_hv_store(info, "bitrate_nominal", newSViv(vi->bitrate_nominal));
	my_hv_store(info, "bitrate_lower", newSViv(vi->bitrate_lower));
	my_hv_store(info, "bitrate_window", newSViv(vi->bitrate_window));
	my_hv_store(info, "length", newSVnv(ov_time_total(vf, -1)));

	my_hv_store(self, "INFO", newRV_noinc((SV*) info));
}

MODULE = Ogg::Vorbis::Decoder PACKAGE = Ogg::Vorbis::Decoder

SV*
open(class, path)
	char *class;
	SV   *path;

	CODE:
	int ret;

	/* Create our new self and a ref to it - all of these are cleaned up
	 * in DESTROY by ov_clear() and safefree() */

	HV *self = newHV();
	SV *obj_ref = newRV_noinc((SV*) self);

	/* holder for the VF itself */
	OggVorbis_File *vf = (OggVorbis_File *) safemalloc(sizeof(OggVorbis_File));

	/* our stash for streams */
	ocvb_datasource *datasource = (ocvb_datasource *) safemalloc(sizeof(ocvb_datasource));
	memset(datasource, 0, sizeof(ocvb_datasource));

	/* check and see if a pathname was passed in, otherwise it might be a
	 * IO::Socket subclass, or even a *FH Glob */
	if (SvOK(path) && (SvTYPE(SvRV(path)) != SVt_PVGV)) {

		if ((datasource->stream = PerlIO_open((char*)SvPV_nolen(path), "r")) == NULL) {
			safefree(vf);
			printf("failed on open: [%d] - [%s]\n", errno, strerror(errno));
			XSRETURN_UNDEF;
		}

		datasource->is_streaming = 0;

	} else if (SvOK(path)) {

		/* Did we get a Glob, or a IO::Socket subclass?
		 *
		 * XXX This should really be a class method so the caller
		 * can tell us if it's streaming or not. But how to do this on
		 * a per object basis without changing open()s arugments. That
		 * may be the easiest/only way. XXX
		 *
		 */

		if (sv_isobject(path) && sv_derived_from(path, "IO::Socket")) {
			datasource->is_streaming = 1;
		} else {
			datasource->is_streaming = 0;
		}

		/* dereference and get the SV* that contains the Magic & FH,
		 * then pull the fd from the PerlIO object */
		datasource->stream = IoIFP(GvIOp(SvRV(path)));

	} else {

		XSRETURN_UNDEF;
	}

	if ((ret = ov_open_callbacks((void*)datasource, vf, NULL, 0, vorbis_callbacks)) < 0) {

		warn("Failed on registering callbacks: [%d]\n", ret);
		printf("failed on open: [%d] - [%s]\n", errno, strerror(errno));
		ov_clear(vf);
		XSRETURN_UNDEF;
        }

	datasource->bytes_streamed = 0;
	datasource->last_bitstream = -1;

	/* initalize bitrate, channels, etc */
	__read_info(self, vf);

	/* Values stored at base level */
	my_hv_store(self, "PATH", newSVsv(path));
	my_hv_store(self, "VFILE", newSViv((IV) vf));
	my_hv_store(self, "BSTREAM", newSViv(0));
	my_hv_store(self, "READCOMMENTS", newSViv(1));

	/* Bless the hashref to create a class object */
	sv_bless(obj_ref, gv_stashpv(class, FALSE));

	RETVAL = obj_ref;

	OUTPUT:
	RETVAL

long
read(obj, buffer, nbytes = 4096, word = 2, sgned = 1)
	SV* obj;
	SV* buffer;
	int nbytes;
	int word;
	int sgned;

	ALIAS:
	sysread = 1

	CODE:
	{
	int bytes = 0;
	int total_bytes_read = 0;
	int read_comments = 0;
	int old_bitstream, cur_bitstream;

	char *readBuffer = alloca(nbytes);

	/* for replay gain */
	/* not yet.. */
	int use_rg = 0;
	float ***pcm = NULL;

	HV *self = (HV *) SvRV(obj);
	OggVorbis_File *vf = (OggVorbis_File *) SvIV(*(my_hv_fetch(self, "VFILE")));

	if (!vf) XSRETURN_UNDEF;

	if (ix) {
		/* empty */
	}

	/* See http://www.xiph.org/ogg/vorbis/doc/vorbisfile/ov_read.html for
	 * a description of the bitstream parameter. This allows streaming
	 * without a hack like icy-metaint */
	cur_bitstream = (int) SvIV(*(my_hv_fetch(self, "BSTREAM")));
	old_bitstream = cur_bitstream;

	/* When we get a new bitstream, re-read the comment fields */
	read_comments = (int)SvIV(*(my_hv_fetch(self, "READCOMMENTS")));

	/* The nbytes argument to ov_read is only a limit, not a request. So
	 * read until we hit the requested number of bytes */
	while (nbytes > 0) {

		if (use_rg) {

                	bytes = ov_read_float(vf, pcm, nbytes, &cur_bitstream);

                	if (bytes > 0) {
                        	/* bytes = vorbis_process_replaygain(pcm, bytes, channels, readBuffer, rg_scale); */
			}

		} else {

			bytes = ov_read(vf, readBuffer, nbytes, endian, word, sgned, &cur_bitstream);
		}

		if (bytes && read_comments != 0) {
			__read_comments(self, vf);
			read_comments = 0;
		}

		if (bytes == 0) {
			/* eof */
			break;

		} else if (bytes == OV_HOLE || bytes == OV_EBADLINK) {
			/* error in stream, but we don't care, move along */

		} else if (bytes < 0 && errno == EINTR) {
			/* try to re-read, same as above */

		} else if (bytes < 0) {
			/* error */
			break;

		} else {

			total_bytes_read += bytes;
			readBuffer += bytes;
			nbytes  -= bytes;

			/* did we enter a new logical bitstream? */
			if (old_bitstream != cur_bitstream && old_bitstream != -1) {

				__read_info(self, vf);
				read_comments = 1;
				break;
			}
		}
	}

	/* update with our new bitstream */
	sv_setiv(*my_hv_fetch(self, "BSTREAM"), (IV) cur_bitstream);
	sv_setiv(*my_hv_fetch(self, "READCOMMENTS"), (IV)read_comments);

	/* copy the buffer into our passed SV* */
	sv_setpvn(buffer, readBuffer-total_bytes_read, total_bytes_read);

	if (bytes < 0) XSRETURN_UNDEF;

	RETVAL = total_bytes_read;

	}

	OUTPUT:
	RETVAL

void
_read_info (obj)
	SV* obj;

	CODE:
	HV *self = (HV *) SvRV(obj);
	OggVorbis_File *vf = (OggVorbis_File *) SvIV(*(my_hv_fetch(self, "VFILE")));

	__read_info(self, vf);

void
_read_comments (obj)
	SV* obj;

	CODE:
	HV *self = (HV *) SvRV(obj);
	OggVorbis_File *vf = (OggVorbis_File *) SvIV(*(my_hv_fetch(self, "VFILE")));

	__read_comments(self, vf);

void
DESTROY (obj)
	SV* obj;

	CODE:
	HV *self = (HV *) SvRV(obj);
	OggVorbis_File *vf = (OggVorbis_File *) SvIV(*(my_hv_fetch(self, "VFILE")));

	ov_clear(vf);
	safefree(vf);

# For all of the below, see:
# http://www.xiph.org/ogg/vorbis/doc/vorbisfile/fileinfo.html for a
# description of the functions that duplicate the vorbisfile API.

int
raw_seek (obj, pos, whence = 0)
	SV* obj;
	long pos;
	int whence;

	CODE:
	HV *self = (HV *) SvRV(obj);
	OggVorbis_File *vf = (OggVorbis_File *) SvIV(*(my_hv_fetch(self, "VFILE")));

	/* XXX - handle whence */
	RETVAL = ov_raw_seek(vf, pos);

	OUTPUT:
	RETVAL

int
pcm_seek (obj, pos, page = 0)
	SV* obj;
	ogg_int64_t pos;
	int page;

	CODE:
	{

	HV *self = (HV *) SvRV(obj);
	OggVorbis_File *vf = (OggVorbis_File *) SvIV(*(my_hv_fetch(self, "VFILE")));

	if (page == 0) {
		RETVAL = ov_pcm_seek(vf, pos);
	} else {
		RETVAL = ov_pcm_seek_page(vf, pos);
	}

	}

	OUTPUT:
	RETVAL

int
time_seek (obj, pos, page = 0)
	SV* obj;
	double pos;
	int page;

	CODE:
	{

	HV *self = (HV *) SvRV(obj);
	OggVorbis_File *vf = (OggVorbis_File *) SvIV(*(my_hv_fetch(self, "VFILE")));

	if (page == 0) {
		RETVAL = ov_time_seek(vf, pos);
	} else {
		RETVAL = ov_time_seek_page(vf, pos);
	}

	}

	OUTPUT:
	RETVAL

long
bitrate (obj, i = -1)
	SV* obj;
	int i;

	CODE:
	{

	HV *self = (HV *) SvRV(obj);
	OggVorbis_File *vf = (OggVorbis_File *) SvIV(*(my_hv_fetch(self, "VFILE")));

	RETVAL = ov_bitrate(vf, i);

	}

	OUTPUT:
	RETVAL

long
bitrate_instant (obj)
	SV* obj;

	CODE:
	HV *self = (HV *) SvRV(obj);
	OggVorbis_File *vf = (OggVorbis_File *) SvIV(*(my_hv_fetch(self, "VFILE")));

	RETVAL = ov_bitrate_instant(vf);

	OUTPUT:
	RETVAL

long
streams (obj)
	SV* obj;

	CODE:
	HV *self = (HV *) SvRV(obj);
	OggVorbis_File *vf = (OggVorbis_File *) SvIV(*(my_hv_fetch(self, "VFILE")));

	RETVAL = ov_streams(vf);

	OUTPUT:
	RETVAL

long
seekable (obj)
	SV* obj;

	CODE:
	HV *self = (HV *) SvRV(obj);
	OggVorbis_File *vf = (OggVorbis_File *) SvIV(*(my_hv_fetch(self, "VFILE")));

	RETVAL = ov_seekable(vf);

	OUTPUT:
	RETVAL

long
serialnumber (obj, i = -1)
	SV* obj;
	int i;

	CODE:
	{

	HV *self = (HV *) SvRV(obj);
	OggVorbis_File *vf = (OggVorbis_File *) SvIV(*(my_hv_fetch(self, "VFILE")));

	RETVAL = ov_serialnumber(vf, i);
	}

	OUTPUT:
	RETVAL

IV
raw_total (obj, i = -1)
	SV* obj;
	int i;

	CODE:
	{

	HV *self = (HV *) SvRV(obj);
	OggVorbis_File *vf = (OggVorbis_File *) SvIV(*(my_hv_fetch(self, "VFILE")));

	RETVAL = ov_raw_total(vf, i);

	}

	OUTPUT:
	RETVAL

IV
pcm_total (obj, i = -1)
	SV* obj;
	int i;

	CODE:
	{

	HV *self = (HV *) SvRV(obj);
	OggVorbis_File *vf = (OggVorbis_File *) SvIV(*(my_hv_fetch(self, "VFILE")));

	RETVAL = ov_pcm_total(vf, i);

	}

	OUTPUT:
	RETVAL

double
time_total (obj, i = -1)
	SV* obj;
	int i;

	CODE:
	{

	HV *self = (HV *) SvRV(obj);
	OggVorbis_File *vf = (OggVorbis_File *) SvIV(*(my_hv_fetch(self, "VFILE")));

	RETVAL = ov_time_total(vf, i);

	}

	OUTPUT:
	RETVAL

IV
raw_tell (obj)
	SV* obj;

	CODE:
	HV *self = (HV *) SvRV(obj);
	OggVorbis_File *vf = (OggVorbis_File *) SvIV(*(my_hv_fetch(self, "VFILE")));

	RETVAL = ov_raw_tell(vf);

	OUTPUT:
	RETVAL

IV
pcm_tell (obj)
	SV* obj;

	CODE:
	HV *self = (HV *) SvRV(obj);
	OggVorbis_File *vf = (OggVorbis_File *) SvIV(*(my_hv_fetch(self, "VFILE")));

	RETVAL = ov_pcm_tell(vf);

	OUTPUT:
	RETVAL

double
time_tell (obj)
	SV* obj;

	CODE:
	HV *self = (HV *) SvRV(obj);
	OggVorbis_File *vf = (OggVorbis_File *) SvIV(*(my_hv_fetch(self, "VFILE")));

	RETVAL = ov_time_tell(vf);

	OUTPUT:
	RETVAL
