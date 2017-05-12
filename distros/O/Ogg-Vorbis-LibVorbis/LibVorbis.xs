#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <errno.h>
#include <stdlib.h>

#include <ogg/ogg.h>
#include <vorbis/codec.h>
#include <vorbis/vorbisenc.h>
#include <vorbis/vorbisfile.h>

#include "const-c.inc"

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

typedef PerlIO *        OutputStream;
typedef PerlIO *        InputStream;

static int _arr_rows;
static int _arr_cols;

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

static void * get_mortalspace ( size_t nbytes ) {
  SV * mortal;
  mortal = sv_2mortal( NEWSV(0, nbytes ) );
  return (void *) SvPVX( mortal );
}

/* Handler for unpacking (float **) */
float ** XS_unpack_floatPtrPtr(SV * arg ) { 
  AV * avref;
  AV * avref_2; 
  float ** array;
  SV ** data; 
  int len, len_2; 
  SV ** elem; 
  int i, j; 

  avref = (AV*)SvRV(arg); 
  len = av_len( avref ) + 1; 
  /* First allocate some memory for the pointers and a NULL for delimiter */ 
  array = (float **)get_mortalspace( (len+1) * sizeof( *array ));   
  /* Loop over each element copying pointers to the array */ 
  for (i=0; i<len; i++) { 
    /* now elem points to the 2nd array in 2D float array */
    elem = av_fetch( avref, i, 0); 
    /* get the pointer to inner array */
    avref_2 = (AV*)SvRV((SV *)*elem);
    /* get the length of the inner array */
    len_2 = av_len(avref_2) + 1;
    /* create mortal space for the 2D array (+1 for NULL delimiter) */
    array[i] = (float *)get_mortalspace( (len_2+1) * sizeof(float));
    for (j=0; j<len_2; j++) {
      /* get the element */   
      data = av_fetch(avref_2, j, 0);
      /* fill the ARRAY */
      array[i][j] = SvNV(*data); 
    }
  } 

  /* hard code the row and col length */
  _arr_rows = i;
  _arr_cols = j;		/* all arrays are of same size */

  return array; 
} 

/* Handler for packing (float **) */
void XS_pack_floatPtrPtr( SV * arg, float ** array) { 
  int i, j; 
  AV *avref, *avref_2; 
  /* create an array_ref */
  avref  = (AV*)sv_2mortal((SV*)newAV()); 
  for (i=0; i<_arr_rows; i++) { 
    /* ref to inner array */
    avref_2  = (AV*)sv_2mortal((SV*)newAV()); 
    /* populate inner array */
    for (j=0; j<_arr_cols; j++) {
      av_push(avref_2, newSVnv(array[i][j]));
    }
    /* create a reference to array (inner) */
    av_push(avref, newRV((SV*)avref_2));
  } 

  /* pack the data in 'arg' and put it back in 'arg' */
  SvSetSV( arg, newRV((SV*)avref)); 
} 



MODULE = Ogg::Vorbis::LibVorbis		PACKAGE = Ogg::Vorbis::LibVorbis	PREFIX = LibVorbis_

INCLUDE: const-xs.inc

PROTOTYPES: DISABLE

=head1 Functions (malloc)

L<http://www.xiph.org/vorbis/doc/vorbisfile/datastructures.html>

=cut

=head2 make_oggvorbis_file

Creates a memory allocation for OggVorbis_File datastructure

-Input:
  Void

-Output:
  Memory Pointer

=cut
OggVorbis_File *
LibVorbis_make_oggvorbis_file()
  PREINIT:
    OggVorbis_File *memory;
  CODE:
    New(0, memory, 1, OggVorbis_File);
    RETVAL = memory;
  OUTPUT:
    RETVAL  


=head1 make_vorbis_info

Creates a memory allocation for vorbis_info

-Input:
  void

-Output:
  Memory Pointer to vorbis_info

=cut

vorbis_info *
LibVorbis_make_vorbis_info()
  PREINIT:
    vorbis_info *	memory;
  CODE:
    New(0, memory, 1, vorbis_info);
    RETVAL = memory;
  OUTPUT:
    RETVAL 


=head1 make_vorbis_comment

Creates a memory allocation for vorbis_comment

-Input:
  void

-Output:
  Memory Pointer to vorbis_comment

=cut

vorbis_comment *
LibVorbis_make_vorbis_comment()
  PREINIT:
    vorbis_comment *	memory;
  CODE:
    New(0, memory, 1, vorbis_comment);
    RETVAL = memory;
  OUTPUT:
    RETVAL

=head1 make_vorbis_block

Creates a memory allocation for vorbis_block

-Input:
  void

-Output:
  Memory Pointer to vorbis_block

=cut

vorbis_block *
LibVorbis_make_vorbis_block()
  PREINIT:
    vorbis_block *	memory;
  CODE:
    New(0, memory, 1, vorbis_block);
    RETVAL = memory;
  OUTPUT:
    RETVAL


=head1 make_vorbis_dsp_state

Creates a memory allocation for vorbis_dsp_state

-Input:
  void

-Output:
  Memory Pointer to vorbis_dsp_state

=cut

vorbis_dsp_state *
LibVorbis_make_vorbis_dsp_state()
  PREINIT:
    vorbis_dsp_state *	memory;
  CODE:
    New(0, memory, 1, vorbis_dsp_state);
    RETVAL = memory;
  OUTPUT:
    RETVAL 


=head1 Functions (vorbisfile)

L<http://www.xiph.org/vorbis/doc/vorbisfile/reference.html>

=cut

=head2 ov_open

ov_open is one of three initialization functions used to initialize an OggVorbis_File 
structure and prepare a bitstream for playback. 
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_open.html>

-Input:
  FILE *, File pointer to an already opened file or pipe,
  OggVorbis_File, A pointer to the OggVorbis_File structure,
  char *, Typically set to NULL,
  int, Typically set to 0.

-Output:
  0 indicates succes,
  less than zero for failure:

    OV_EREAD - A read from media returned an error.
    OV_ENOTVORBIS - Bitstream is not Vorbis data.
    OV_EVERSION - Vorbis version mismatch.
    OV_EBADHEADER - Invalid Vorbis bitstream header.
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.

=cut

int
LibVorbis_ov_open(f, vf, initial, ibytes)
    InputStream	     f
    OggVorbis_File * vf
    char *	     initial
    int		     ibytes
  PREINIT:
    FILE *fp = PerlIO_findFILE(f);
  CODE:
    /* check whether it is a valid file handler */
    if (fp == (FILE*) 0 || fileno(fp) <= 0) {   
      Perl_croak(aTHX_ "Expected Open FILE HANDLER");
    }
    /* open the vorbis file */
    RETVAL = ov_open(fp, vf, initial, ibytes);
  OUTPUT:
    RETVAL

=head2 ov_fopen

This is the simplest function used to open and initialize an OggVorbis_File structure.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_fopen.html>

-Input:
  char *, (null terminated string containing a file path suitable for passing to fopen())
  OggVorbis_File

-Output:
  0 indicates success
  less than zero for failure:

    OV_EREAD - A read from media returned an error.
    OV_ENOTVORBIS - Bitstream does not contain any Vorbis data.
    OV_EVERSION - Vorbis version mismatch.
    OV_EBADHEADER - Invalid Vorbis bitstream header.
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.

=cut

int
LibVorbis_ov_fopen(path, vf)
    char *		 path
    OggVorbis_File *	 vf
  CODE:
    RETVAL = ov_fopen(path, vf);
  OUTPUT:
    RETVAL


=head2 ov_open_callbacks

an alternative function used to open and initialize an OggVorbis_File structure when using a data source 
other than a file, when its necessary to modify default file access behavior.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_open.html>

B<Please read the official ov_open_callbacks doc before you use this.> The perl version uses
a different approach and uses vorbis_callbacks with custom functions to read, seek tell and close.

B<this module can accept file name, network socket or a file pointer.>

-Input:
  void *, (data source)
  OggVorbis_File, A pointer to the OggVorbis_File structure,
  char *, Typically set to NULL,
  int, Typically set to 0.

-Output:
  0 indicates succes,
  less than zero for failure:

    OV_EREAD - A read from media returned an error.
    OV_ENOTVORBIS - Bitstream is not Vorbis data.
    OV_EVERSION - Vorbis version mismatch.
    OV_EBADHEADER - Invalid Vorbis bitstream header.
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.

=cut

int
LibVorbis_ov_open_callbacks(path, vf, initial, ibytes)
    SV *       	     path  
    OggVorbis_File * vf
    char *	     initial
    int		     ibytes
  PREINIT:
    FILE *fp;
  CODE:
    int ret = 10;

    /* our stash for streams */
    ocvb_datasource *datasource = (ocvb_datasource *) safemalloc(sizeof(ocvb_datasource));
    memset(datasource, 0, sizeof(ocvb_datasource));

    /* check and see if a pathname was passed in, otherwise it might be a
     * IO::Socket subclass, or even a *FH Glob */
    if (SvOK(path) && (SvTYPE(SvRV(path)) != SVt_PVGV)) {

      if ((datasource->stream = PerlIO_open((char*)SvPV_nolen(path), "r")) == NULL) {
        safefree(vf);
        fprintf(stderr, "failed on open: [%d] - [%s]\n", errno, strerror(errno));
        XSRETURN_UNDEF;
      }

      datasource->is_streaming = 0;

    } else if (SvOK(path)) {

      /* Did we get a Glob, or a IO::Socket subclass? */		
      if (sv_isobject(path) && sv_derived_from(path, "IO::Socket")) {
        datasource->is_streaming = 1;
      } else {

        datasource->is_streaming = 0;
      }

      /* dereference and get the SV* that contains the Magic & FH,
       * then pull the fd from the PerlIO object */
      datasource->stream = IoIFP(GvIOp(SvRV(path)));

    } else {

      fp = PerlIO_findFILE((PerlIO *)IoIFP(sv_2io(path)));
      /* check whether it is a valid file handler */
      if (fp == (FILE*) 0 || fileno(fp) <= 0) {   
         XSRETURN_UNDEF;
      }
      datasource->stream = (PerlIO *)IoIFP(sv_2io(path));
    }

    if ((ret = ov_open_callbacks((void*)datasource, vf, NULL, 0, vorbis_callbacks)) < 0) {
      warn("Failed on registering callbacks: [%d]\n", ret);
      printf("failed on open: [%d] - [%s]\n", errno, strerror(errno));
      ov_clear(vf);

      XSRETURN_UNDEF;
    }

    datasource->bytes_streamed = 0;
    datasource->last_bitstream = -1;

    RETVAL = ret;

  OUTPUT:
    RETVAL


=head2 ov_test

This partially opens a vorbis file to test for Vorbis-ness.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_test.html>

-Input:
  FILE *, File pointer to an already opened file or pipe,
  OggVorbis_File, A pointer to the OggVorbis_File structure,
  char *, Typically set to NULL,
  int, Typically set to 0.

-Output:
  0 indicates succes,
  less than zero for failure:

    OV_EREAD - A read from media returned an error.
    OV_ENOTVORBIS - Bitstream is not Vorbis data.
    OV_EVERSION - Vorbis version mismatch.
    OV_EBADHEADER - Invalid Vorbis bitstream header.
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.

=cut

int
LibVorbis_ov_test(f, vf, initial, ibytes)
    InputStream	     f
    OggVorbis_File * vf
    char *	     initial
    long 	     ibytes
  PREINIT:
    FILE *fp = PerlIO_findFILE(f);
  CODE:
    if (fp == (FILE*) 0 || fileno(fp) <= 0) {   
       XSRETURN_UNDEF;
    }    
    /* open the vorbis file */
    RETVAL = ov_test(fp, vf, initial, ibytes);
  OUTPUT:
    RETVAL


=head2 ov_test_open

Finish opening a file partially opened with ov_test() or ov_test_callbacks(). 
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_test_open.html>

-Input:
  OggVorbis_File

-Output:
  0 indicates succes,
  less than zero for failure:

    OV_EREAD - A read from media returned an error.
    OV_ENOTVORBIS - Bitstream is not Vorbis data.
    OV_EVERSION - Vorbis version mismatch.
    OV_EBADHEADER - Invalid Vorbis bitstream header.
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.

=cut

int
LibVorbis_ov_test_open(vf)
    OggVorbis_File *	vf
  CODE:
    RETVAL = ov_test_open(vf);
  OUTPUT:
    RETVAL


=head2 ov_test_callbacks

an alternative function used to open and test an OggVorbis_File structure when using a data source
other than a file, when its necessary to modify default file access behavior.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_test_callbacks.html>

B<Please read the official ov_test_callbacks doc before you use this.> The perl version uses
a different approach and uses vorbis_callbacks with custom functions to read, seek tell and close.

B<this module can accept file name, network socket or a file pointer.>

-Input:
  void *, (data source)
  OggVorbis_File, A pointer to the OggVorbis_File structure,
  char *, Typically set to NULL,
  int, Typically set to 0.

-Output:
  0 indicates succes,
  less than zero for failure:

    OV_EREAD - A read from media returned an error.
    OV_ENOTVORBIS - Bitstream is not Vorbis data.
    OV_EVERSION - Vorbis version mismatch.
    OV_EBADHEADER - Invalid Vorbis bitstream header.
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.

=cut

int
LibVorbis_ov_test_callbacks(path, vf, initial, ibytes)
    SV *       	     path  
    OggVorbis_File * vf
    char *	     initial
    int		     ibytes
  PREINIT:
    FILE *fp;
  CODE:
    int ret = 10;

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

      /* Did we get a Glob, or a IO::Socket subclass? */		
      if (sv_isobject(path) && sv_derived_from(path, "IO::Socket")) {
        datasource->is_streaming = 1;
      } else {

        datasource->is_streaming = 0;
      }

      /* dereference and get the SV* that contains the Magic & FH,
       * then pull the fd from the PerlIO object */
      datasource->stream = IoIFP(GvIOp(SvRV(path)));

    } else {

      fp = PerlIO_findFILE((PerlIO *)IoIFP(sv_2io(path)));
      /* check whether it is a valid file handler */
      if (fp == (FILE*) 0 || fileno(fp) <= 0) {   
         XSRETURN_UNDEF;
      }
      datasource->stream = (PerlIO *)IoIFP(sv_2io(path));
    }

    if ((ret = ov_test_callbacks((void*)datasource, vf, NULL, 0, vorbis_callbacks)) < 0) {
      warn("Failed on registering callbacks: [%d]\n", ret);
      printf("failed on open: [%d] - [%s]\n", errno, strerror(errno));
      ov_clear(vf);

      XSRETURN_UNDEF;
    }

    datasource->bytes_streamed = 0;
    datasource->last_bitstream = -1;

    RETVAL = ret;

  OUTPUT:
    RETVAL



=head2 ov_clear

ov_clear() to clear the decoder's buffers and close the file
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_clear.html>

-Input:
  OggVorbis_File

-Output:
  0 for success

=cut

int
LibVorbis_ov_clear(vf)
    OggVorbis_File *	vf
  CODE:
    RETVAL = ov_clear(vf);
  OUTPUT:
    RETVAL


=head2 ov_seekable

This indicates whether or not the bitstream is seekable. 
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_seekable.html>

-Input:
  OggVorbis_File

-Output:
  0 indicates that the file is not seekable.
  nonzero indicates that the file is seekable.

=cut

int
LibVorbis_ov_seekable(vf)
    OggVorbis_File *	vf
  CODE:
    RETVAL = ov_seekable(vf);
  OUTPUT:
    RETVAL


=head2 ov_time_total

Returns the total time in seconds of the physical bitstream or a specified logical bitstream. 
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_time_total.html>

-Input:
  OggVorbis_File,
  int (link to the desired logical bitstream)

-Output:
  OV_EINVAL means that the argument was invalid. In this case, the requested bitstream did not exist or the bitstream is nonseekable.
  n total length in seconds of content if i=-1.
  n length in seconds of logical bitstream if i=0 to n.

=cut

double
LibVorbis_ov_time_total(vf, i)
    OggVorbis_File *	    vf
    int		   	    i
  CODE:
    RETVAL = ov_time_total(vf, i);
  OUTPUT:
    RETVAL


=head2 ov_time_seek

For seekable streams, this seeks to the given time.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_time_seek.html>

-Input:
  OggVorbis_File,
  double (location to seek in seconds)

-Output:
  0 for success
  nonzero indicates failure, described by several error codes:

    OV_ENOSEEK - Bitstream is not seekable.
    OV_EINVAL - Invalid argument value; possibly called with an OggVorbis_File structure that isn't open.
    OV_EREAD - A read from media returned an error.
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.
    OV_EBADLINK - Invalid stream section supplied to libvorbisfile, or the requested link is corrupt.

=cut

int
LibVorbis_ov_time_seek(vf, s)
    OggVorbis_File *	   vf
    double	   	   s
  CODE:
    RETVAL = ov_time_seek(vf, s);
  OUTPUT:
    RETVAL  


=head2 ov_raw_seek

For seekable streams, this seeks to the given offset in compressed raw bytes.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_raw_seek.html>

-Input:
  OggVorbis_File,
  long (location to seek in compressed raw bytes)

-Output:
  0 for success
  nonzero indicates failure, described by several error codes:

    OV_ENOSEEK - Bitstream is not seekable.
    OV_EINVAL - Invalid argument value; possibly called with an OggVorbis_File structure that isn't open.
    OV_EREAD - A read from media returned an error.
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.
    OV_EBADLINK - Invalid stream section supplied to libvorbisfile, or the requested link is corrupt.

=cut

int
LibVorbis_ov_raw_seek(vf, s)
    OggVorbis_File *	   vf
    long	   	   s
  CODE:
    RETVAL = ov_raw_seek(vf, s);
  OUTPUT:
    RETVAL


=head2 ov_pcm_seek

Seeks to the offset specified (in pcm samples) within the physical bitstream.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_pcm_seek.html>

-Input:
  OggVorbis_File,
  ogg_int64_t, (location to seek in pcm samples)

-Output:
  0 for success
  nonzero indicates failure, described by several error codes:

    OV_ENOSEEK - Bitstream is not seekable.
    OV_EINVAL - Invalid argument value; possibly called with an OggVorbis_File structure that isn't open.
    OV_EREAD - A read from media returned an error.
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.
    OV_EBADLINK - Invalid stream section supplied to libvorbisfile, or the requested link is corrupt.

=cut

int
LibVorbis_ov_pcm_seek(vf, s)
    OggVorbis_File *	   vf
    ogg_int64_t	   	   s
  CODE:
    RETVAL = ov_pcm_seek(vf, s);
  OUTPUT:
    RETVAL


=head2 ov_pcm_seek_page

Seeks to the closest page preceding the specified location (in pcm samples).
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_pcm_seek_page.html>

-Input:
  OggVorbis_File,
  ogg_int64_t (position in pcm samples to seek to in the bitstream)

-Output:
  0 for success
  nonzero indicates failure, described by several error codes:

    OV_ENOSEEK - Bitstream is not seekable.
    OV_EINVAL - Invalid argument value; possibly called with an OggVorbis_File structure that isn't open.
    OV_EREAD - A read from media returned an error.
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.
    OV_EBADLINK - Invalid stream section supplied to libvorbisfile, or the requested link is corrupt.

=cut

int
LibVorbis_ov_pcm_seek_page(vf, pos)
    OggVorbis_File *	   vf
    ogg_int64_t	   	   pos
  CODE:
    RETVAL = ov_pcm_seek_page(vf, pos);
  OUTPUT:
    RETVAL


=head2 ov_time_seek_page

For seekable streams, this seeks to closest full page preceding the given time.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_time_seek_page.html>

-Input:
  OggVorbis_File,
  double (Location to seek to within the file, specified in seconds)

-Output:
  0 for success
  nonzero indicates failure, described by several error codes:

    OV_ENOSEEK - Bitstream is not seekable.
    OV_EINVAL - Invalid argument value; possibly called with an OggVorbis_File structure that isn't open.
    OV_EREAD - A read from media returned an error.
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.
    OV_EBADLINK - Invalid stream section supplied to libvorbisfile, or the requested link is corrupt.

=cut

int
LibVorbis_ov_time_seek_page(vf, pos)
    OggVorbis_File *	   vf
    double	   	   pos
  CODE:
    RETVAL = ov_time_seek_page(vf, pos);
  OUTPUT:
    RETVAL


=head2 ov_raw_seek_lap

Seeks to the offset specified (in compressed raw bytes) within the physical bitstream.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_raw_seek_lap.html>

-Input:
  OggVorbis_File,
  ogg_int64_t (Location to seek to within the file, specified in compressed raw bytes)

-Output:
  0 for success
  nonzero indicates failure, described by several error codes:

    OV_ENOSEEK - Bitstream is not seekable.
    OV_EINVAL - Invalid argument value; possibly called with an OggVorbis_File structure that isn't open.
    OV_EREAD - A read from media returned an error.
    OV_EOF - Indicates stream is at end of file immediately after a seek
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.
    OV_EBADLINK - Invalid stream section supplied to libvorbisfile, or the requested link is corrupt.

=cut

int
LibVorbis_ov_raw_seek_lap(vf, pos)
    OggVorbis_File *	   vf
    ogg_int64_t	   	   pos
  CODE:
    RETVAL = ov_raw_seek_lap(vf, pos);
  OUTPUT:
    RETVAL


=head2 ov_pcm_seek_lap

Seeks to the offset specified (in pcm samples) within the physical bitstream.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_pcm_seek_lap.html>

-Input:
  OggVorbis_File,
  long (Location to seek to within the file, specified in pcm samples)

-Output:
  0 for success
  nonzero indicates failure, described by several error codes:

    OV_ENOSEEK - Bitstream is not seekable.
    OV_EINVAL - Invalid argument value; possibly called with an OggVorbis_File structure that isn't open.
    OV_EREAD - A read from media returned an error.
    OV_EOF - Indicates stream is at end of file immediately after a seek
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.
    OV_EBADLINK - Invalid stream section supplied to libvorbisfile, or the requested link is corrupt.

=cut

int
LibVorbis_ov_pcm_seek_lap(vf, pos)
    OggVorbis_File *	   vf
    long	   	   pos
  CODE:
    RETVAL = ov_pcm_seek_lap(vf, pos);
  OUTPUT:
    RETVAL


=head2 ov_time_seek_lap

Seeks to the offset specified (in seconds) within the physical bitstream.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_time_seek_lap.html>

-Input:
  OggVorbis_File,
  double (Location to seek to within the file, specified in seconds)

-Output:
  0 for success
  nonzero indicates failure, described by several error codes:

    OV_ENOSEEK - Bitstream is not seekable.
    OV_EINVAL - Invalid argument value; possibly called with an OggVorbis_File structure that isn't open.
    OV_EREAD - A read from media returned an error.
    OV_EOF - Indicates stream is at end of file immediately after a seek
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.
    OV_EBADLINK - Invalid stream section supplied to libvorbisfile, or the requested link is corrupt.

=cut

int
LibVorbis_ov_time_seek_lap(vf, pos)
    OggVorbis_File *	   vf
    double	   	   pos
  CODE:
    RETVAL = ov_time_seek_lap(vf, pos);
  OUTPUT:
    RETVAL


=head2 ov_time_page_seek_lap

For seekable streams, ov_time_seek_page_lap seeks to the closest full page preceeding the given time.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_time_seek_page_lap.html>

-Input:
  OggVorbis_File,
  double (Location to seek to within the file, specified in seconds)

-Output:
  0 for success
  nonzero indicates failure, described by several error codes:

    OV_ENOSEEK - Bitstream is not seekable.
    OV_EINVAL - Invalid argument value; possibly called with an OggVorbis_File structure that isn't open.
    OV_EREAD - A read from media returned an error.
    OV_EOF - Indicates stream is at end of file immediately after a seek
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.
    OV_EBADLINK - Invalid stream section supplied to libvorbisfile, or the requested link is corrupt.

=cut

int
LibVorbis_ov_time_seek_page_lap(vf, pos)
    OggVorbis_File *	   vf
    double	   	   pos
  CODE:
    RETVAL = ov_time_seek_page_lap(vf, pos);
  OUTPUT:
    RETVAL


=head2 ov_pcm_page_seek_lap

Seeks to the closest page preceding the specified location (in pcm samples) within the physical bitstream.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_pcm_seek_page_lap.html>

-Input:
  OggVorbis_File,
  ogg_int64_t (Location to seek to within the file, specified in pcm samples)

-Output:
  0 for success
  nonzero indicates failure, described by several error codes:

    OV_ENOSEEK - Bitstream is not seekable.
    OV_EINVAL - Invalid argument value; possibly called with an OggVorbis_File structure that isn't open.
    OV_EREAD - A read from media returned an error.
    OV_EOF - Indicates stream is at end of file immediately after a seek
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.
    OV_EBADLINK - Invalid stream section supplied to libvorbisfile, or the requested link is corrupt.

=cut

int
LibVorbis_ov_pcm_seek_page_lap(vf, pos)
    OggVorbis_File *	   vf
    ogg_int64_t	   	   pos
  CODE:
    RETVAL = ov_pcm_seek_page_lap(vf, pos);
  OUTPUT:
    RETVAL


=head2 ov_streams

Returns the number of logical bitstreams within our physical bitstream. 
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_streams.html>

-Input:
  OggVorbis_File

-Output:
  1 indicates a single logical bitstream or an unseekable file,
  n indicates the number of logical bitstreams.

=cut

long
LibVorbis_ov_streams(vf)
    OggVorbis_File *	vf
  CODE:
    RETVAL = ov_streams(vf);
  OUTPUT:
    RETVAL


=head2 ov_info

Returns the vorbis_info struct for the specified bitstream.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_info.html>

-Input:
  OggVorbis_File,
  int (link to desired logical bitstream)

-Output:
  Returns the vorbis_info struct for the specified bitstream,
  NULL if the specified bitstream does not exist or the file has been initialized improperly.

=cut

vorbis_info *
LibVorbis_ov_info(vf, link)
    OggVorbis_File *  vf
    int		      link
  CODE:
    RETVAL = ov_info(vf, link);
  OUTPUT:
    RETVAL

=head2 ov_bitrate

Function returns the average bitrate for the specified logical bitstream. 
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_bitrate.html>

-Input:
  OggVorbis_File,
  int (desired logical bitstream)

-Output:
    OV_EINVAL indicates that an invalid argument value or that the stream represented by vf is not open,
    OV_FALSE means the call returned a 'false' status, 
    n indicates the bitrate for the given logical bitstream or the entire physical bitstream.

=cut

long
LibVorbis_ov_bitrate(vf, i)
    OggVorbis_File *	vf
    int		   	i
  CODE:
    RETVAL = ov_bitrate(vf, i);
  OUTPUT:
    RETVAL

=head2 ov_bitrate_instant

Function returns the average bitrate for the specified logical bitstream. 
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_bitrate_instant.html>

-Input:
  OggVorbis_File.

-Output:
    0 indicates the beginning of the file or unchanged bitrate info.
    OV_EINVAL indicates that an invalid argument value or that the stream represented by vf is not open,
    OV_FALSE means the call returned a 'false' status, 
    n indicates the actual bitrate since the last call.

=cut

long
LibVorbis_ov_bitrate_instant(vf)
    OggVorbis_File *	vf
  CODE:
    RETVAL = ov_bitrate_instant(vf);
  OUTPUT:
    RETVAL


=head2 ov_serialnumber

serialnumber of the specified logical bitstream link number within the overall physical bitstream.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_serialnumber.html>

-Input:
  OggVorbis_File,
  int (desired logical bitstream)

-Output:
  -1 if the specified logical bitstream i does not exist,
  serial number of the logical bitstream i or the serial number of the current bitstream.

=cut

long
LibVorbis_ov_serialnumber(vf, i)
    OggVorbis_File *	vf
    int		   	i
  CODE:
    RETVAL = ov_serialnumber(vf, i);
  OUTPUT:
    RETVAL


=head2 ov_raw_total

total (compressed) bytes of the physical bitstream or a specified logical bitstream. 
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_raw_total.html>

-Input:
  OggVorbis_File,
  int (desired logical bitstream)

-Output:
  OV_EINVAL means that the argument was invalid
  n total length in compressed bytes of content if i=-1
  n length in compressed bytes of logical bitstream if i=0 to n

=cut

long
LibVorbis_ov_raw_total(vf, i)
    OggVorbis_File *	vf
    int		   	i
  CODE:
    RETVAL = ov_raw_total(vf, i);
  OUTPUT:
    RETVAL

=head2 ov_pcm_total

Returns the total pcm samples of the physical bitstream or a specified logical bitstream.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_pcm_total.html>

-Input:
  OggVorbis_File,
  int (desired logical bitstream)

-Output:
  OV_EINVAL means that the argument was invalid
  n total length in pcm samples of content if i=-1
  n length in pcm samples of logical bitstream if i=0 to n

=cut

ogg_int64_t
LibVorbis_ov_pcm_total(vf, i)
    OggVorbis_File *	vf
    int		   	i
  CODE:
    RETVAL = ov_pcm_total(vf, i);
  OUTPUT:
    RETVAL


=head2 ov_raw_tell

Returns the current offset in raw compressed bytes.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_raw_tell.html>

-Input:
  OggVorbis_File

-Output:
  n indicates the current offset in bytes,
  OV_EINVAL means that the argument was invalid.

=cut

ogg_int64_t
LibVorbis_ov_raw_tell(vf)
    OggVorbis_File *	vf
  CODE:
    RETVAL = ov_raw_tell(vf);
  OUTPUT:
    RETVAL


=head2 ov_pcm_tell

Returns the current offset in samples. 
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_pcm_tell.html>

-Input:
  OggVorbis_File

-Output:
  n indicates the current offset in samples,
  OV_EINVAL means that the argument was invalid.

=cut

ogg_int64_t
LibVorbis_ov_pcm_tell(vf)
    OggVorbis_File *	vf
  CODE:
    RETVAL = ov_pcm_tell(vf);
  OUTPUT:
    RETVAL


=head2 ov_time_tell

Returns the current decoding offset in seconds.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_time_tell.html>

-Input:
  OggVorbis_File

-Output:
  n indicates the current decoding time offset in seconds,
  OV_EINVAL means that the argument was invalid.

=cut

ogg_int64_t
LibVorbis_ov_time_tell(vf)
    OggVorbis_File *	vf
  CODE:
    RETVAL = ov_time_tell(vf);
  OUTPUT:
    RETVAL


=head2 ov_comment

Returns a pointer to the vorbis_comment struct for the specified bitstream.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_comment.html>

-Input:
  OggVorbis_File,
  int (link to desired logical bitstream)

-Output:
  Returns the vorbis_comment struct for the specified bitstream,
  NULL if the specified bitstream does not exist or the file has been initialized improperly.

=cut

vorbis_comment *
LibVorbis_ov_comment(vf, link)
    OggVorbis_File *  vf
    int		      link
  CODE:
    RETVAL = ov_comment(vf, link);
  OUTPUT:
    RETVAL

=head1 Decoding (vorbisfile)

=head2 ov_read

Decode a Vorbis file within a loop. L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_read.html>

-Input:
  OggVorbis_File *vf, 
  char *buffer, 
  int length, 
  int bigendianp, (big or little endian byte packing. 0 for little endian, 1 for b ig endian)
  int word, (word size)
  int sgned, (1 for signed or 0 for unsigned)
  int *bitstream

-Output:
  OV_HOLE, interruption in the data
  OV_EBADLINK, invalid stream section
  OV_EINVAL, initial file headers couldn't be read or are corrupt
  0, EOF
  n, actual number of bytes read

=cut

long
LibVorbis_ov_read(vf, buffer, length, big, word, sgned, bit)
    OggVorbis_File *  vf
    char *	      buffer = NO_INIT
    int  	      length
    int		      big
    int 	      word
    int 	      sgned
    int 	      bit = NO_INIT
  CODE:
    New(0, buffer, length, char);
    RETVAL = ov_read(vf, buffer, length, big, word, sgned, &bit);
    // if you dig deep in the XS, you will see char * is T_PV which is 
    // sv_setpv for OUTPUT and SvPV_nolen for input
    sv_setpvn((SV*)ST(1), buffer, RETVAL); 
    SvSETMAGIC(ST(1));
    XSprePUSH; 
  OUTPUT:
    RETVAL
  CLEANUP:
    Safefree(buffer);

=head2 ov_read_float

B<TODO> Returns samples in native float format instead of in integer formats.

=cut

=head2 ov_read_filter

B<TODO> It passes the decoded floating point PCM data to the filter specified in the function arguments before 
converting the data to integer output samples. (variant of ov_read())

=cut

=head1 Encoding 

=cut

=head2 vorbis_info_init

This function initializes a vorbis_info structure and allocates its internal storage.
L<http://www.xiph.org/vorbis/doc/libvorbis/vorbis_info_init.html>

-Input:
  vi, Pointer to a vorbis_info struct to be initialized.

-Output:
  void

=cut

void
LibVorbis_vorbis_info_init(vi)
    vorbis_info *	vi
  CODE:
    vorbis_info_init(vi);


=head2 vorbis_encode_init_vbr

This is the primary function within libvorbisenc for setting up variable 
bitrate ("quality" based) modes. 

-Input:
  vorbis_info *vi,
  long channels (number of channels to be encoded),
  long rate (sampling rate of the source audio),
  float base_quality (desired quality level, currently from -0.1 to 1.0 [lo to hi])

-Output:
  0 for success
  less than zero for failure:
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.
    OV_EINVAL - Invalid setup request, eg, out of range argument.
    OV_EIMPL - Unimplemented mode; unable to comply with quality level request.

=cut

int
LibVorbis_vorbis_encode_init_vbr(vi, channels, rate, base_quality)
    vorbis_info *	vi
    long		channels
    long		rate
    float		base_quality
  CODE:
    RETVAL = vorbis_encode_init_vbr(vi, channels, rate, base_quality);
  OUTPUT:
    RETVAL


=head2 vorbis_analysis_init

This function allocates and initializes the encoder's analysis state inside a is 
vorbis_dsp_state, based on the configuration in a vorbis_info struct. 
L<http://www.xiph.org/vorbis/doc/libvorbis/vorbis_analysis_init.html>

-Input:
  vorbis_dsp_state *v,
  vorbis_info *vi

-Output:
  0 for SUCCESS

=cut

int
LibVorbis_vorbis_analysis_init(v, vi)
    vorbis_dsp_state *		  v
    vorbis_info *    		  vi
  CODE:
    RETVAL = vorbis_analysis_init(v, vi);
  OUTPUT:
    RETVAL


=head2 vorbis_block_init

This function initializes a vorbis_block structure and allocates its internal storage.
L<http://www.xiph.org/vorbis/doc/libvorbis/vorbis_block_init.html>

-Input:
  vorbis_dsp_state *v,
  vorbis_block *vb

-Output:
  0 (for success)

=cut

int
LibVorbis_vorbis_block_init(v, vb)
    vorbis_dsp_state *	       v
    vorbis_block *   	       vb
  CODE:
    RETVAL = vorbis_block_init(v, vb);
  OUTPUT:
    RETVAL


=head2 vorbis_encode_setup_init

This function performs the last stage of three-step encoding setup, as 
described in the API overview under managed bitrate modes. 
L<http://xiph.org/vorbis/doc/vorbisenc/vorbis_encode_setup_init.html>

-Input:
  vorbis_info *vi

-Output:
  0 for success
  less than zero for failure:
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.
    OV_EINVAL - Attempt to use vorbis_encode_setup_init() without first calling one of vorbis_encode_setup_managed() 
                or vorbis_encode_setup_vbr() to initialize the high-level encoding setup

=cut

int
LibVorbis_vorbis_encode_setup_init(vi)
    vorbis_info *	vi
  CODE:
    RETVAL = vorbis_encode_setup_init(vi);
  OUTPUT:
    RETVAL

=head2 vorbis_comment_init

This function initializes a vorbis_comment structure for use.
L<http://www.xiph.org/vorbis/doc/libvorbis/vorbis_comment_init.html>

-Input:
  vorbis_comment *vc

-Ouput:
  void

=cut

void
LibVorbis_vorbis_comment_init(vc)
    vorbis_comment *	vc
  CODE:
    vorbis_comment_init(vc);


=head2 vorbis_analysis_headerout(v, vc, op, op_comm, op_code)

This function creates and returns the three header packets needed to configure a decoder to 
accept compressed data. L<http://www.xiph.org/vorbis/doc/libvorbis/vorbis_analysis_headerout.html>

-Input:
  vorbis_dsp_state *v,
  vorbis_comment *vc,
  ogg_packet *op,
  ogg_packet *op_comm,
  ogg_packet *op_code

-Output:
  0 for success
  negative values for failure:
    OV_EFAULT - Internal fault; indicates a bug or memory corruption.
    OV_EIMPL - Unimplemented; not supported by this version of the library.

=cut

int
LibVorbis_vorbis_analysis_headerout(v, vc, op, op_comm, op_code)
    vorbis_dsp_state *		v
    vorbis_comment * 		vc
    ogg_packet *   		op
    ogg_packet *		op_comm
    ogg_packet *		op_code
  CODE:
    RETVAL = vorbis_analysis_headerout(v, vc, op, op_comm, op_code);
  OUTPUT:
    RETVAL


=heaqd2 vorbis_analysis_buffer

This fuction requests a buffer array for delivering audio to the encoder for compression.
L<http://www.xiph.org/vorbis/doc/libvorbis/vorbis_analysis_buffer.html>

-Input:
  vorbis_dsp_state *v,
  int vals

-Output:
  ** float (an array of floating point buffers which can accept data)

=cut

float **
LibVorbis_vorbis_analysis_buffer(v, vals)
    vorbis_dsp_state *		v
    int		     		vals
  CODE:
    RETVAL = vorbis_analysis_buffer(v, vals);
  OUTPUT:
    RETVAL


=head2 vorbis_analysis_wrote

This function tells the encoder new data is available for compression. 
L<http://www.xiph.org/vorbis/doc/libvorbis/vorbis_analysis_wrote.html>

-Input:
  vorbis_dsp_state *v,
  int vals

-Output:  
  0 for success
  negative values for failure:
    OV_EINVAL - Invalid request; e.g. vals overflows the allocated space,
    OV_EFAULT - Internal fault; indicates a bug or memory corruption,
    OV_EIMPL - Unimplemented; not supported by this version of the library.

=cut

int
LibVorbis_vorbis_analysis_wrote(v, val)
    vorbis_dsp_state *		v
    int		     		val
  CODE:
    RETVAL = vorbis_analysis_wrote(v, val);
  OUTPUT:
    RETVAL


=head2 vorbis_analysis_blockout

This fuction examines the available uncompressed data and tries to break it into appropriate 
sized blocks. L<http://www.xiph.org/vorbis/doc/libvorbis/vorbis_analysis_blockout.html>

-Input:
  vorbis_dsp_state *,
  vorbis_block *

-Output:
  1 for success when more blocks are available.
  0 for success when this is the last block available from the current input.
  negative values for failure:
    OV_EINVAL - Invalid parameters.
    OV_EFAULT - Internal fault; indicates a bug or memory corruption.
    OV_EIMPL - Unimplemented; not supported by this version of the library.

=cut

int
LibVorbis_vorbis_analysis_blockout(v, vb)
    vorbis_dsp_state *		v
    vorbis_block *   		vb
  CODE:
    RETVAL = vorbis_analysis_blockout(v, vb);
  OUTPUT:
    RETVAL

=head2 vorbis_analysis

Once the uncompressed audio data has been divided into blocks, this function is called on each block. 
It looks up the encoding mode and dispatches the block to the forward transform provided by that mode. 
L<http://www.xiph.org/vorbis/doc/libvorbis/vorbis_analysis.html>

-Input:
  vorbis_block *,
  ogg_packet *

-Output:
   0 for success
   negative values for failure:
     OV_EINVAL - Invalid request; a non-NULL value was passed for op when the encoder is using a bitrate managed mode.
     OV_EFAULT - Internal fault; indicates a bug or memory corruption.
     OV_EIMPL - Unimplemented; not supported by this version of the library.

=cut 

int
LibVorbis_vorbis_analysis(vb, op)
    vorbis_block *	  vb
    ogg_packet * 	  op
  CODE:
    RETVAL = vorbis_analysis(vb, op);
  OUTPUT:
    RETVAL


=head1 Miscellaneous Functions 

These functions are not found in libvorbis*, but is written by the XS author
to simplify few tasks.

=cut

=head2 get_vorbis_info

Returns a HashRef with vorbis_info struct values.
L<http://www.xiph.org/vorbis/doc/libvorbis/vorbis_info.html>

-Input:
  vorbis_info

-Output:
  HashRef

=cut

HV *
LibVorbis_get_vorbis_info(vi)
    vorbis_info *	vi
  PREINIT:
    HV * hash;
  CODE:
    hash = newHV();

    sv_2mortal((SV *)hash);	/* convert the HASH to a mortal */
    hv_store(hash, "version", strlen("version"), newSVnv(vi->version), 0); 
    hv_store(hash, "channels", strlen("channels"), newSViv(vi->channels), 0); 
    hv_store(hash, "rate", strlen("rate"), newSVnv(vi->rate), 0);
    hv_store(hash, "bitrate_upper", strlen("bitrate_upper"), newSVnv(vi->bitrate_upper), 0);
    hv_store(hash, "bitrate_nominal", strlen("bitrate_nominal"), newSVnv(vi->bitrate_nominal), 0);
    hv_store(hash, "bitrate_lower", strlen("bitrate_lower"), newSVnv(vi->bitrate_lower), 0);
    hv_store(hash, "bitrate_window", strlen("bitrate_window"), newSVnv(vi->bitrate_window), 0);
    hv_store(hash, "codec_setup", strlen("codec_setup"), newSViv(PTR2IV(vi->codec_setup)), 0);

    RETVAL = hash;
  OUTPUT:
    RETVAL


=head2 get_vorbis_comment

Returns a HashRef with vorbis_comment struct values.
L<http://www.xiph.org/vorbis/doc/libvorbis/vorbis_comment.html>

-Input:
  vorbis_comment *

-Output:
  HashRef

=cut

HV *
LibVorbis_get_vorbis_comment(vc)
    vorbis_comment *	vc
  PREINIT:
    HV * hash;
    AV * uc;			/* user comments */
    AV * cl;			/* comment lenth */
    int i = 0;
  CODE:
    hash = newHV();
    sv_2mortal((SV *)hash);

    uc = newAV();
    cl = newAV();
    /* get the user comments and put in hash */
    for (i=0; i<vc->comments; i++) {
      av_push(uc, newSVpv(vc->user_comments[i], 0));
      av_push(cl, newSViv(vc->comment_lengths[i]));
    } 

    /* store the user comments */
    hv_store(hash, "user_comments", strlen("user_comments"), newRV_noinc((SV *)uc), 0);      
    /* store the comment length */
    hv_store(hash, "comment_lenghts", strlen("comment_lenghts"), newRV_noinc((SV *)cl), 0);      
    /* get the vendor */
    hv_store(hash, "vendor", strlen("vendor"), newSVpv(vc->vendor, 0), 0);      
    /* number of comments */
    hv_store(hash, "comments", strlen("comments"), newSViv(vc->comments), 0);      

    RETVAL = hash;

  OUTPUT:
    RETVAL


=head2 vorbis_encode_wav_frames

This function encode the given frames. It calls vorbis_analysis_buffer and
vorbis_analysis_wrote internally to give the data to the encode for compression.

-Input:
  vorbis_dsp_state *,
  int (number of samples to provide space for in the returned buffer),
  channels,
  data buffer

-Output:
  same as of vorbis_analysis_wrote

=cut

int
LibVorbis_vorbis_encode_wav_frames(v, vals, channels, buffer)
    vorbis_dsp_state *		v
    int		     		vals
    int				channels
    char *			buffer
  PREINIT:
    float ** vorbis_buffer;
    int i, j;
    int count = 0;
  CODE:
   vorbis_buffer=vorbis_analysis_buffer(v, vals);

   if (vorbis_buffer == NULL)
     fprintf(stderr, "vorbis_analysis_buffer returned NULL, float ** was expected (might crap out soon)\n");

   /* uninterleave samples */
   for(i=0; i<vals; i++){
     for(j=0; j<channels; j++){
       vorbis_buffer[j][i]=((buffer[count+1]<<8)|
			   (0x00ff&(int)buffer[count]))/32768.f;
       count+=2;
     }
   }

   RETVAL = vorbis_analysis_wrote(v, channels);
  OUTPUT:
    RETVAL

