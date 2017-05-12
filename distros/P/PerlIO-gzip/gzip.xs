/* -*- c -*- */
/*    gzip.xs
 *
 *    Copyright (C) 2001, 2002, Nicholas Clark
 *
 *    You may distribute this work under the terms of either the GNU General
 *    Public License or the Artistic License, as specified in perl's README
 *    file.
 *
 */
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <zlib.h>
#include "perliol.h"

/* auto|gzip|none
   lazy
   csum
   name=
   extra=
   comment=
*/
/* stick a buffer on layer below
   turn of crlf
   zalloc in the zs struct being non-NULL is sign that we need to tidy up
*/

#define GZIP_HEADERSIZE		10
#define GZIP_TEXTFLAG		0x01
#define GZIP_HAS_HEADERCRC	0x02
#define GZIP_HAS_EXTRAFIELD	0x04
#define GZIP_HAS_ORIGNAME	0x08
#define GZIP_HAS_COMMENT	0x10
/* 0x20 is encrypted, which we'll treat as if its unknown.  */
#define GZIP_KNOWNFLAGS		0x1F

#define LAYERGZIP_STATUS_NORMAL		0
#define LAYERGZIP_STATUS_INPUT_EOF	1
#define LAYERGZIP_STATUS_ZSTREAM_END	2
#define LAYERGZIP_STATUS_CONFUSED	3
#define LAYERGZIP_STATUS_1ST_DO_HEADER	4

#define LAYERGZIP_FLAG_GZIPHEADER	0x00
#define LAYERGZIP_FLAG_NOGZIPHEADER	0x01 /* No gzip file header */
#define LAYERGZIP_FLAG_MAYBEGZIPHEADER	0x02 /* Look for magic number */
#define LAYERGZIP_FLAG_AUTOPOP		0x03
#define LAYERGZIP_FLAG_READMODEMASK	0x03

#define LAYERGZIP_FLAG_LAZY		0x04 /* defer header check */
#define LAYERGZIP_FLAG_OURBUFFERBELOW	0x08 /* We own the buffer below us */
#define LAYERGZIP_FLAG_INFL_INIT_DONE	0x10 /* Done inflate init */
#define LAYERGZIP_FLAG_DO_CRC_AT_END	0x20 /* Check CRC at Z_STREAM_END */
#define LAYERGZIP_FLAG_DEFL_INIT_DONE	0x40 /* Done deflate init */
#define LAYERGZIP_FLAG_NO_TIMESTAMP	0x80
#define LAYERGZIP_FLAG_CLOSING_FILE	0x100

#define LAYERGZIP_GZIPHEADER_GOOD	0
#define LAYERGZIP_GZIPHEADER_ERROR	1
#define LAYERGZIP_GZIPHEADER_BADMAGIC	2
#define LAYERGZIP_GZIPHEADER_BADMETHOD	3
#define LAYERGZIP_GZIPHEADER_NOTGZIP	4    /* BEWARE. If you get this your
						buf pointer is now invalid  */


#ifndef LAYERGZIP_DEFAULT_OS_TYPE
#define LAYERGZIP_DEFAULT_OS_TYPE	255  /* "Unknown" - see rfc1952 */
#endif

#define OUTSIZE 4096
#define LAYERGZIP_DEF_MEM_LEVEL 8

typedef struct {
  PerlIOBuf	base;
  z_stream	zs;		/* zlib's struct.  */
  int		status;		/* state of the inflater */
  int		flags;		/* bitmap */
  unsigned long	crc;		/* ongoing CRC of data */
  long		time;		/* timestamp to write to the header	*/
  Bytef		*outbuf;	/* Our malloc'd output buffer		*/
  int		level;		/* compression level for deflate	*/
  unsigned char os_type;	/* OS type flag for the header		*/
} PerlIOGzip;

/*****************************************************************************
 *
 * Reading stuff
 *
 *****************************************************************************/

/* Logic of the header passer:
   buffer is where we're reading from. It may point into the fast_gets buffer
   of the layer below, or into our private SV.
   We start, if possible in the fast_gets buffer. When we exhaust it (or if
   we can't use it) we allocate a private SV and store everything that we've
   read into it. */

static SSize_t
get_more (PerlIO *below, SSize_t wanted, SV **sv, unsigned char **buffer) {
  dTHX;       /* fetch context */
  SSize_t get, done, read;
  unsigned char *read_here;

#if DEBUG_LAYERGZIP
  PerlIO_debug("PerlIOGzip get_more f=%p wanted=%08"UVxf" sv=%p buffer=%p\n",
	       below, wanted, *sv, *buffer);
#endif

  if (!*sv) {
    /* We know there were not enough bytes available in the layer below's
       buffer.  We know that we started at the beginning of it, so we can
       calculate how many bytes we've passed over (but not consumed, as we
       didn't alter the pointer and count).  */
    done = *buffer - (unsigned char*) PerlIO_get_ptr(below);
    get = done + wanted; /* Need to read the lot into our SV.   */
    *sv = newSVpvn("", 0);
    if (!*sv)
      return -1;
    read_here = (unsigned char *) SvGROW(*sv, get);
    *buffer = read_here + done;
  } else {
    done = SvCUR(*sv);
    read_here = *buffer = (unsigned char *) SvGROW(*sv, done + wanted) + done;
    get = wanted; /* Only need to read the next section  */
  }

#if DEBUG_LAYERGZIP
  PerlIO_debug("PerlIOGzip get_more sv=%p buffer=%p done=%08"UVxf" read_here=%p get=%08"UVxf" \n", *sv, *buffer, done, read_here, get);
#endif

  read = PerlIO_read (below, read_here, wanted);
#if DEBUG_LAYERGZIP
  PerlIO_debug("PerlIOGzip get_more read=%08"UVxf"\n", read);
#endif
  if (read == -1) {
    /* Read error. Messy. Don't know what state our buffer is, and whether we
       should unread it.  Probably not.  */
    SvREFCNT_dec(*sv);
    *sv = NULL;
    return read;
  }
  if (read_here == *buffer) {
    /* We were appending.  */
    SvCUR(*sv) += read;
    return read;
  }
  /* We were reading into the whole buffer.  */
  SvCUR_set(*sv, read);
  return read - done;
}


static SSize_t
eat_nul (PerlIO *below, SV **sv, unsigned char **buffer) {
  dTHX;       /* fetch context */
  SSize_t munch_size = 256; /* Pick a size to read in. Should this double
			       each loop?  */

#if DEBUG_LAYERGZIP
  PerlIO_debug("PerlIOGzip eat_nul f=%p sv=%p buffer=%p\n",
		 below, *sv, *buffer);
#endif

  if (!*sv) {
    /* Buffer below supposed fast_gets.  */
    unsigned char *end
      = (unsigned char *) PerlIO_get_base(below) + PerlIO_get_bufsiz(below);
    unsigned char *here = *buffer;

#if DEBUG_LAYERGZIP
    PerlIO_debug("PerlIOGzip eat_nul here=%p end=%p\n", here, end);
#endif

    while (here < end) {
      if (*here++)
	continue;

      *buffer = here;
#if DEBUG_LAYERGZIP
      PerlIO_debug("PerlIOGzip eat_nul found it! here=%p end=%p, returning %08"
		   UVxf"\n", here, end, (UV) (end-here));
#endif
      return end-here;
    }

    *buffer = here;
#if DEBUG_LAYERGZIP
    PerlIO_debug("PerlIOGzip eat_nul no joy here=%p end=%p\n", here, end);
#endif
  }

#if DEBUG_LAYERGZIP
  PerlIO_debug("PerlIOGzip eat_nul about to loop\n");
#endif

  while (1) {
    unsigned char *end, *here;
    SSize_t avail = get_more (below, munch_size, sv, buffer);
#if DEBUG_LAYERGZIP
    PerlIO_debug("PerlIOGzip eat_nul sv=%p buffer=%p wanted=%08"UVxf" avail=%08"UVxf"\n",
		 *sv, *buffer, munch_size, (UV)avail);
#endif
    if (avail == -1 || avail == 0)
      return -1;

    end = (unsigned char *)SvEND(*sv);
    here = *buffer;

#if DEBUG_LAYERGZIP
    PerlIO_debug("PerlIOGzip eat_nul here=%p end=%p\n", here, end);
#endif

    while (here < end) {
      if (*here++)
	continue;
      
      *buffer = here;
#if DEBUG_LAYERGZIP
      PerlIO_debug("PerlIOGzip eat_nul found it! here=%p end=%p, returning %08"
		   UVxf"\n", here, end, (UV) (end-here));
#endif
      return end-here;
    }
    /* as *sv is not NULL, get_more doesn't use the input value of *buffer,
       so don't waste time setting it.  We've eaten the whole SV - that's
       all get_more cares about.  So loop and munch some more.  */
  }
}

/* gzip header is
   Magic number		0,1
   Compression type	  2
   Flags		  3
   Time			4-7
   XFlags		  8
   OS Code		  9
   */

static int
check_gzip_header (PerlIO *f) {
  dTHX;       /* fetch context */
  PerlIO *below = PerlIONext(f);
  int code = LAYERGZIP_GZIPHEADER_GOOD;
  SSize_t avail;
  SV *temp = NULL;
  unsigned char *header;
  
#if DEBUG_LAYERGZIP
  PerlIO_debug("PerlIOGzip check_gzip_header f=%p below=%p fast_gets=%d\n",
	       f, below, PerlIO_fast_gets(below));
#endif

  if (PerlIO_fast_gets(below)) {
    avail = PerlIO_get_cnt(below);
    if (avail <= 0) {
      avail = PerlIO_fill(below);
      if (avail == 0)
	avail = PerlIO_get_cnt(below);
      else
	avail = 0;
    }
  } else
    avail = 0;

#if DEBUG_LAYERGZIP
  PerlIO_debug("PerlIOGzip check_gzip_header avail=%08"UVxf"\n", (UV)avail);
#endif

  if (avail >= GZIP_HEADERSIZE)
    header = (unsigned char *) PerlIO_get_ptr(below);
  else {
    temp = newSVpvn("", 0);
    if (!temp)
      return LAYERGZIP_GZIPHEADER_ERROR;
    header = (unsigned char *) SvGROW(temp, GZIP_HEADERSIZE);
#if DEBUG_LAYERGZIP
    PerlIO_debug("PerlIOGzip check_gzip_header below=%p header=%p size %d\n",
		 below, header, GZIP_HEADERSIZE);
#endif
    avail = PerlIO_read(below,header,GZIP_HEADERSIZE);
#if DEBUG_LAYERGZIP
    PerlIO_debug("PerlIOGzip check_gzip_header read=%08"UVxf"\n", (UV)avail);
#endif
    SvCUR_set(temp, avail);

    if (avail < 0) {
      code = LAYERGZIP_GZIPHEADER_ERROR;
      goto bad;
    } else if (avail < 2 ) {
      code = LAYERGZIP_GZIPHEADER_BADMAGIC;
      goto bad;
    } else if (avail < GZIP_HEADERSIZE) {
      /* Too short, but if magic number isn't there, it's not a gzip file  */
      if (header[0] == 0x1f && header[1] == 0x8b) {
	/* It's trying to be a gzip file.  */
	code = LAYERGZIP_GZIPHEADER_ERROR;
      } else
	code = LAYERGZIP_GZIPHEADER_BADMAGIC;
      goto bad;
    }
  }

#if DEBUG_LAYERGZIP
    PerlIO_debug("PerlIOGzip check_gzip_header header=%p\n", header);
#endif

  avail -= GZIP_HEADERSIZE;
  if (header[0] != 0x1f || header[1] != 0x8b)
    code = LAYERGZIP_GZIPHEADER_BADMAGIC;
  else if (header[2] != Z_DEFLATED)
    code = LAYERGZIP_GZIPHEADER_BADMETHOD;
  else if (header[3] & !GZIP_KNOWNFLAGS)
    code = LAYERGZIP_GZIPHEADER_ERROR;
  else { /* Check the header, and skip any extra fields */
    int flags = header[3];

#if DEBUG_LAYERGZIP
    PerlIO_debug("PerlIOGzip check_gzip_header flags=%02X\n", flags);
#endif

    header += GZIP_HEADERSIZE;
    if (flags & GZIP_HAS_EXTRAFIELD) {
      Size_t len;

      if (avail < 2) {
	/* Need some more */
	avail = get_more (below, 2, &temp, &header);
	if (avail < 2) {
	  code = LAYERGZIP_GZIPHEADER_ERROR;
	  goto bad;
	}
      }

      /* 2 byte little endian quantity, which we now know is in the buffer.  */
      len = header[0] | (header[1] << 8);
      header += 2;
      avail -= 2;

#if DEBUG_LAYERGZIP
      PerlIO_debug("PerlIOGzip check_gzip_header header=%p avail=%08"UVxf
		   " extra len=%d\n", header, (UV)avail, (int)len);
#endif

      if (avail < len) {
	/* Need some more */
	avail = get_more (below, len, &temp, &header);
	if (avail < len) {
	  code = LAYERGZIP_GZIPHEADER_ERROR;
	  goto bad;
	}
      }
      header += len;
      avail -= len;
    }

    if (flags & GZIP_HAS_ORIGNAME) {
#if DEBUG_LAYERGZIP
      PerlIO_debug("PerlIOGzip check_gzip_header header=%p avail=%08"UVxf
		   " has origname\n", header, (UV)avail);
#endif

      avail = eat_nul (below, &temp, &header);
      if (avail < 0) {
	code = LAYERGZIP_GZIPHEADER_ERROR;
	goto bad;
      }
    }
    if (flags & GZIP_HAS_COMMENT) {
#if DEBUG_LAYERGZIP
      PerlIO_debug("PerlIOGzip check_gzip_header header=%p avail=%08"UVxf
		   " has comment\n", header, (UV)avail);
#endif

      avail = eat_nul (below, &temp, &header);
      if (avail < 0) {
	code = LAYERGZIP_GZIPHEADER_ERROR;
	goto bad;
      }
    }
  
    if (flags & GZIP_HAS_HEADERCRC) {
#if DEBUG_LAYERGZIP
      PerlIO_debug("PerlIOGzip check_gzip_header header=%p avail=%08"UVxf
" has header CRC\n", header, (UV)avail);
#endif
      if (avail < 2) {
	/* Need some more */
	avail = get_more (below, 2, &temp, &header);
	if (avail < 2) {
	  code = LAYERGZIP_GZIPHEADER_ERROR;
	  goto bad;
	}
      }
      header += 2;
      avail -= 2;
    }
  }

  if (code == LAYERGZIP_GZIPHEADER_GOOD) {
    /* Adjust the pointer here. or free the SV */
    if (temp) {
      SSize_t unread;
#if DEBUG_LAYERGZIP
      PerlIO_debug("PerlIOGzip check_gzip_header finished. unreading header=%p "
		   "avail=%08"UVxf"\n", header, (UV)avail);
#endif
      if (avail) {
	if (!(PerlIOBase(below)->flags & PERLIO_F_FASTGETS)) {
#if DEBUG_LAYERGZIP
	  PerlIO_debug("check_gzip_header HACK around core PerlIO bug\n");
#endif
	  if (!PerlIO_push(aTHX_ below,&PerlIO_perlio,"r",&PL_sv_undef)) {
#if DEBUG_LAYERGZIP
	    PerlIO_debug("check_gzip_header failed to push new layer\n");
#endif
	    code = LAYERGZIP_GZIPHEADER_ERROR;
	    goto bad;
	  }
	  PerlIOSelf(f,PerlIOGzip)->flags |= LAYERGZIP_FLAG_OURBUFFERBELOW;
	  below = PerlIONext(f);
	}

	unread = PerlIO_unread (below, header, avail);
	if (unread != avail) {
#if DEBUG_LAYERGZIP
	  PerlIO_debug("PerlIOGzip check_gzip_header finished. only unread %08"UVxf"\n", unread);
#endif
	  code = LAYERGZIP_GZIPHEADER_ERROR;
	}
      }
      SvREFCNT_dec(temp);
    } else {
      PerlIO_debug("PerlIOGzip check_gzip_header finished. setting ptrcnt "
		   "header=%p avail=%08"UVxf"\n", header, (UV)avail);
      PerlIO_set_ptrcnt(below, (STDCHAR *) header, avail);
    }
  } else {
    /* Unread the whole the SV.  Maybe I should try to seek first. */
  bad:
    if (temp) {
      STRLEN len;
      STDCHAR *ptr = SvPV(temp, len);
      PerlIOGzip *g = PerlIOSelf(f,PerlIOGzip);

#if DEBUG_LAYERGZIP
      PerlIO_debug("PerlIOGzip check_gzip_header failed. unreading ptr=%p len=%08"UVxf"\n", ptr, (UV)len);
#endif

      if (((g->flags & LAYERGZIP_FLAG_READMODEMASK)
	   == LAYERGZIP_FLAG_MAYBEGZIPHEADER)
	  && !(PerlIOBase(below)->flags & PERLIO_F_FASTGETS)) {
#if DEBUG_LAYERGZIP
	PerlIO_debug("check_gzip_header HACK around core PerlIO bug\n");
#endif
	if (PerlIO_push(aTHX_ below,&PerlIO_perlio,"r",&PL_sv_undef)) {
	  g->flags |= LAYERGZIP_FLAG_OURBUFFERBELOW;
	  below = PerlIONext(f);
	} else {
#if DEBUG_LAYERGZIP
	  PerlIO_debug("check_gzip_header failed to push new layer\n");
#endif
	}
      }
      PerlIO_unread (below, ptr, len);
      SvREFCNT_dec(temp);
    }
    if (code != LAYERGZIP_GZIPHEADER_BADMAGIC)
      PerlIOBase(f)->flags |= PERLIO_F_ERROR;
  }
  return code;
}

static int
check_gzip_header_and_init (PerlIO *f) {
  dTHX;       /* fetch context */
  PerlIOGzip *g = PerlIOSelf(f,PerlIOGzip);
  int code;
  z_stream *z = &g->zs;
  PerlIO *below = PerlIONext(f);

#if DEBUG_LAYERGZIP
  PerlIO_debug("PerlIOGzip check_gzip_header_and_init f=%p below=%p flags=%02X\n",
	       f, below, g->flags);
#endif

  if ((g->flags & LAYERGZIP_FLAG_READMODEMASK) != LAYERGZIP_FLAG_NOGZIPHEADER) {
    g->flags |= LAYERGZIP_FLAG_DO_CRC_AT_END;
    code = check_gzip_header (f);
    if (code != LAYERGZIP_GZIPHEADER_GOOD) {
#if DEBUG_LAYERGZIP
      PerlIO_debug("PerlIOGzip check_gzip_header_and_init code=%d\n", code);
#endif
      if (code != LAYERGZIP_GZIPHEADER_BADMAGIC)
	return code;
      else {
	int mode = g->flags & LAYERGZIP_FLAG_READMODEMASK;
	if (mode == LAYERGZIP_FLAG_MAYBEGZIPHEADER) {
	  /* There wasn't a magic number.  But flags say that's OK.
	     And we won't be checking the CRC at the end  */
	  g->flags &= ~LAYERGZIP_FLAG_DO_CRC_AT_END;
	} else if (mode == LAYERGZIP_FLAG_AUTOPOP) {
	  /* There wasn't a magic number.  Muahahaha. Treat it as a normal
	     file by popping ourself.  */
	  return LAYERGZIP_GZIPHEADER_NOTGZIP;
	} else {
	  return code;
	}
      }
    }
  }
  g->status = LAYERGZIP_STATUS_NORMAL;

  /* (any header validated) */
  if (PerlIOBase(below)->flags & PERLIO_F_FASTGETS) {
#if DEBUG_LAYERGZIP
    PerlIO_debug("check_gzip_header_and_init :-). f=%p %s fl=%08X\n",
		 below, PerlIOBase(below)->tab->name,
		 (int)PerlIOBase(below)->flags);
#endif
  } else {
    /* Bah. Layer below us doesn't support FASTGETS. So we need to add a layer
       to provide our input buffer.  */
#if DEBUG_LAYERGZIP
    PerlIO_debug("check_gzip_header_and_init :-(. f=%p %s fl=%08X\n",
		 below, PerlIOBase(below)->tab->name,
		 (int) PerlIOBase(below)->flags);
#endif
    if (!PerlIO_push(aTHX_ below,&PerlIO_perlio,"r",&PL_sv_undef))
      return LAYERGZIP_GZIPHEADER_ERROR;
    g->flags |= LAYERGZIP_FLAG_OURBUFFERBELOW;
    below = PerlIONext(f);
  }
  assert (PerlIO_fast_gets(below));

  z->next_in = (Bytef *) PerlIO_get_base(below);
  z->avail_in = z->avail_out = 0;
  z->zalloc = (alloc_func) 0;
  z->zfree = (free_func) 0;
  z->opaque = 0;

  /* zlib docs say that next_out and avail_out are unchanged by init.
     Implication is that they don't yet need to be initialised.  */

  if (inflateInit2(z, -MAX_WBITS) != Z_OK) {
#if DEBUG_LAYERGZIP
    PerlIO_debug("check_gzip_header_and_init failed to inflateInit2");
#endif
    if (g->flags & LAYERGZIP_FLAG_OURBUFFERBELOW) {
      g->flags &= ~LAYERGZIP_FLAG_OURBUFFERBELOW;
      PerlIO_pop(aTHX_ below);
    }
    return LAYERGZIP_GZIPHEADER_ERROR;
  }

  g->flags |= LAYERGZIP_FLAG_INFL_INIT_DONE;

  if (g->flags & LAYERGZIP_FLAG_DO_CRC_AT_END)
    g->crc = crc32(0L, Z_NULL, 0);

  return LAYERGZIP_GZIPHEADER_GOOD;
}

/*****************************************************************************
 *
 * Writing stuff
 *
 *****************************************************************************/

static int
write_gzip_header (PerlIO *f) {
  dTHX;       /* fetch context */
  PerlIOGzip *g = PerlIOSelf(f,PerlIOGzip);
  char header[10];
  unsigned long timestamp = 0;

#if DEBUG_LAYERGZIP
  PerlIO_debug("PerlIOGzip write_gzip_header f=%p flags=%02X\n", f, g->flags);
#endif

  header[0] = 0x1f; header[1] = 0x8b;
  header[2] = Z_DEFLATED;
  header[3] = 0; /* TEXT, CRC, EXTRA, NAME, COMMENT */

  if (!(g->flags & LAYERGZIP_FLAG_NO_TIMESTAMP)) {
    timestamp = g->time;
    if (timestamp == 0) {
      /* time_t is signed, I want unsigned for my shifting below */
      time_t now = time(NULL);
      timestamp = (now == -1) ? 0 : now;
    }
  }
  /* All quantities are little endian.  */
  header[4] = timestamp & 0xFF;
  header[5] = (timestamp >>  8) & 0xFF;
  header[6] = (timestamp >> 16) & 0xFF;
  header[7] = (timestamp >> 24) & 0xFF;
  
  header[8] = 0; /* XFlags can be zero.  */
  header[9] = g->os_type;

  if (PerlIO_write(PerlIONext(f), header, sizeof(header)) != sizeof(header))
    return -1;

  return 0;
}

static int
write_gzip_header_and_init (PerlIO *f) {
  dTHX;       /* fetch context */
  PerlIOGzip *g = PerlIOSelf(f,PerlIOGzip);
  int code;
  z_stream *z = &g->zs;

#if DEBUG_LAYERGZIP
  PerlIO *below = PerlIONext(f);
  PerlIO_debug("PerlIOGzip write_gzip_header_and_init f=%p below=%p flags=%02X\n",
	       f, below, g->flags);
#endif

  if ((g->flags & LAYERGZIP_FLAG_READMODEMASK) != LAYERGZIP_FLAG_NOGZIPHEADER) {
    g->flags |= LAYERGZIP_FLAG_DO_CRC_AT_END;
    code = write_gzip_header (f);
    if (code) {
#if DEBUG_LAYERGZIP
      PerlIO_debug("PerlIOGzip write_gzip_header_and_init code=%d\n", code);
#endif
      return code;
    }
  }
  g->status = LAYERGZIP_STATUS_NORMAL;
  Renew(g->outbuf, OUTSIZE, Bytef);

  z->next_in = (Bytef *) NULL;
  z->avail_in = 0;
  z->next_out = (Bytef *) g->outbuf;
  z->avail_out = OUTSIZE;
  z->zalloc = (alloc_func) 0;
  z->zfree = (free_func) 0;
  z->opaque = 0;

  /* zlib docs say that next_out and avail_out are unchanged by init.
     Implication is that they don't yet need to be initialised.  */

  if (deflateInit2(z, g->level, Z_DEFLATED, -MAX_WBITS,
		   LAYERGZIP_DEF_MEM_LEVEL, Z_DEFAULT_STRATEGY) != Z_OK) {
#if DEBUG_LAYERGZIP
    PerlIO_debug("write_gzip_header_and_init failed to deflateInit2");
#endif
    return LAYERGZIP_GZIPHEADER_ERROR;
  }

  g->flags |= LAYERGZIP_FLAG_DEFL_INIT_DONE;

  if (g->flags & LAYERGZIP_FLAG_DO_CRC_AT_END)
    g->crc = crc32(0L, Z_NULL, 0);

  return LAYERGZIP_GZIPHEADER_GOOD;
}



/*****************************************************************************
 *
 * Methods
 *
 *****************************************************************************/

static SV *
PerlIOGzip_getarg(pTHX_ PerlIO *f, CLONE_PARAMS *param, int flags)
{
  PerlIOGzip *g = PerlIOSelf(f,PerlIOGzip);
  SV *sv;
  register const char *mode;

  switch (g->flags & LAYERGZIP_FLAG_READMODEMASK) {
  case LAYERGZIP_FLAG_GZIPHEADER:
    if (!(g->flags & LAYERGZIP_FLAG_AUTOPOP)) {
      /* Default */
      sv = newSVpvn("",0);
      return sv ? sv : &PL_sv_undef;
    }
    mode = "gzip";
    break;
  case LAYERGZIP_FLAG_NOGZIPHEADER:
    mode = "none";
    break;
  case LAYERGZIP_FLAG_MAYBEGZIPHEADER:
    mode = "auto";
    break;
  case LAYERGZIP_FLAG_LAZY:
    mode = "lazy";
    break;
  }

  sv = newSVpv (mode, 4);
  if (!sv)
    return &PL_sv_undef;

  if (g->flags & LAYERGZIP_FLAG_AUTOPOP)
    sv_catpv (sv, ",autopop");

  return sv;
}

PerlIO_funcs PerlIO_gzip;

static IV
PerlIOGzip_pushed(pTHX_ PerlIO *f, const char *mode, SV *arg, PerlIO_funcs *tab)
{
  PerlIOGzip *g = PerlIOSelf(f,PerlIOGzip);
  IV code = 0;
  STRLEN len;
  const char *argstr;

  if (arg && SvOK(arg))
    argstr = SvPV(arg, len);
  else {
    argstr = NULL;
    len = 0;
  }
  
#if DEBUG_LAYERGZIP
  PerlIO_debug("PerlIOGzip_pushed f=%p %s %s fl=%08"UVxf" g=%p\n",
	       f,PerlIOBase(f)->tab->name,(mode) ? mode : "(Null)",
	       PerlIOBase(f)->flags, g);
  if (argstr)
    PerlIO_debug("  len=%d argstr=%.*s\n", (int)len, (int)len, argstr);
#endif

  code = PerlIOBuf_pushed(aTHX_ f,mode,&PL_sv_undef,&PerlIO_gzip);
  if (code)
    return code;

  g->flags = LAYERGZIP_FLAG_GZIPHEADER;
  g->status = LAYERGZIP_STATUS_1ST_DO_HEADER;
  g->outbuf = NULL;
  g->level = Z_DEFAULT_COMPRESSION;
  g->os_type = LAYERGZIP_DEFAULT_OS_TYPE;

  if (len) {
    const char *end = argstr + len;
    while (1) {
      int arg_bad = 0;
      const char *comma = memchr (argstr, ',', end - argstr);
      STRLEN this_len = comma ? (comma - argstr) : (end - argstr);

#if DEBUG_LAYERGZIP
      PerlIO_debug("  processing len=%d argstr=%.*s\n",
		   (int)this_len, (int)this_len, argstr);
#endif

      if (this_len == 4) {
	if (memEQ (argstr, "none", 4)) {
	  g->flags &= ~LAYERGZIP_FLAG_READMODEMASK;
	  g->flags |= LAYERGZIP_FLAG_NOGZIPHEADER;
	} else if (memEQ (argstr, "auto", 4)) {
	  g->flags &= ~LAYERGZIP_FLAG_READMODEMASK;
	  g->flags |= LAYERGZIP_FLAG_MAYBEGZIPHEADER;
        } else if (memEQ (argstr, "lazy", 4)) {
	  g->flags &= ~LAYERGZIP_FLAG_READMODEMASK;
	  g->flags |= LAYERGZIP_FLAG_LAZY;
	} else if (memEQ (argstr, "gzip", 4)) {
	  g->flags &= ~LAYERGZIP_FLAG_READMODEMASK;
	  g->flags |= LAYERGZIP_FLAG_GZIPHEADER;
	} else
	  arg_bad = 1;
      } else if (this_len == 7) {
	if (memEQ (argstr, "autopop", 7)) {
	  g->flags &= ~LAYERGZIP_FLAG_READMODEMASK;
	  g->flags |= LAYERGZIP_FLAG_AUTOPOP;
	} else
	  arg_bad = 1;
      }

      if (arg_bad) {
	dTHX;       /* fetch context */
        /* XXX This will mangle UTF8 in error messages  */
	Perl_warn(aTHX_ "perlio: layer :gzip, unrecognised argument \"%.*s\"",
		  (int)this_len, argstr);
      }

      if (!comma)
	break;
      argstr = comma + 1;
    }
  }
  

  if (PerlIOBase(f)->flags & PERLIO_F_CANWRITE) {
#if DEBUG_LAYERGZIP
    PerlIO_debug("PerlIOGzip_pushed f=%p fl=%08"UVxf" including write (%X)\n",
		 f, PerlIOBase(f)->flags, PERLIO_F_CANWRITE);
#endif
    /* autopop trumps writing.  */
    if ((g->flags & LAYERGZIP_FLAG_READMODEMASK) == LAYERGZIP_FLAG_AUTOPOP) {
	PerlIO_pop(aTHX_ f);
	return 0;
    } else if ((g->flags & LAYERGZIP_FLAG_READMODEMASK) ==
	       LAYERGZIP_FLAG_MAYBEGZIPHEADER) {
      /* This makes no sense for writing.  */
      return -1;
    }
    if (PerlIOBase(f)->flags & PERLIO_F_CANREAD)
      return -1;

    if (!(g->flags & LAYERGZIP_FLAG_LAZY) ||
	((g->flags & LAYERGZIP_FLAG_READMODEMASK) ==
	 LAYERGZIP_FLAG_NOGZIPHEADER)) {
      code = write_gzip_header_and_init (f);
      if (code != LAYERGZIP_GZIPHEADER_GOOD)
	return -1;
    }

  } else if (PerlIOBase(f)->flags & PERLIO_F_CANREAD) {

    /* autopop trumps lazy. (basically, it's going to confuse upstream far too
       much if on the first read we pop our buffered layer off to reveal an
       unbuffered layer below us)  */
    if (!(g->flags & LAYERGZIP_FLAG_LAZY) ||
	((g->flags & LAYERGZIP_FLAG_READMODEMASK) == LAYERGZIP_FLAG_AUTOPOP)) {
      code = check_gzip_header_and_init (f);
      if (code != LAYERGZIP_GZIPHEADER_GOOD) {
	if (code == LAYERGZIP_GZIPHEADER_NOTGZIP) {
	  PerlIO_pop(aTHX_ f);
#if DEBUG_LAYERGZIP
	  PerlIO_debug("PerlIOGzip_pushed just popped f=%p\n", f);
#endif
	  return 0;
	}
	return -1;
      }
    }
  } else {
#if DEBUG_LAYERGZIP
    PerlIO_debug("PerlIOGzip_pushed f=%p fl=%08"UVxf
		 " neither read nor write\n", f, PerlIOBase(f)->flags);
#endif
    return -1;
  }

  if (g->flags & LAYERGZIP_FLAG_DO_CRC_AT_END)
    g->crc = crc32(0L, Z_NULL, 0);
#if DEBUG_LAYERGZIP
  PerlIO_debug("PerlIOGzip_pushed f=%p g->status=%d g->flags=%02X\n",
	       f, g->status, g->flags);
#endif
  return 0;
}

static IV
PerlIOGzip_popped(pTHX_ PerlIO *f)
{
  PerlIOGzip *g = PerlIOSelf(f,PerlIOGzip);
  IV code = 0;

#if DEBUG_LAYERGZIP
  PerlIO_debug("PerlIOGzip_popped f=%p %s flags=%02X\n",
	       f,PerlIOBase(f)->tab->name, g->flags);
#endif

  if (g->flags & LAYERGZIP_FLAG_INFL_INIT_DONE) {
    g->flags &= ~LAYERGZIP_FLAG_INFL_INIT_DONE;
    code = inflateEnd (&(g->zs)) == Z_OK ? 0 : -1;
  }
  if (g->flags & LAYERGZIP_FLAG_DEFL_INIT_DONE) {
    g->flags &= ~LAYERGZIP_FLAG_DEFL_INIT_DONE;
    code = deflateEnd (&(g->zs));
    PerlIO_debug("PerlIOGzip_popped code=%"IVdf"\n", code);
    code = (code == Z_OK) ? 0 : -1;
  }

#if DEBUG_LAYERGZIP
  PerlIO_debug("PerlIOGzip_popped code=%d\n", code);
#endif

  Safefree (g->outbuf);
  g->outbuf = NULL;

  if (g->flags & LAYERGZIP_FLAG_OURBUFFERBELOW) {
    PerlIO *below = PerlIONext(f);
    assert (below); /* This must be a layer, or our flags a screwed, or someone
		       else has been screwing with our buffer.  */
    PerlIO_pop(aTHX_ below);
    g->flags &= ~LAYERGZIP_FLAG_OURBUFFERBELOW;
  }

#if DEBUG_LAYERGZIP
  PerlIO_debug("PerlIOGzip_popped f=%p %s %d\n",
	       f,PerlIOBase(f)->tab->name, (int)code);
#endif

  return code;
}

static IV
PerlIOGzip_close(pTHX_ PerlIO *f)
{
  IV code = 0;
  PerlIOGzip *g = PerlIOSelf(f,PerlIOGzip);

#if DEBUG_LAYERGZIP
  PerlIO_debug("PerlIOGzip_close f=%p %s za=%p g->status=%d\n",
	       f,PerlIOBase(f)->tab->name, g->zs.zalloc, (int) g->status);
#endif

  /* Signal to anything (eg the flush()) that the sky *is* falling down.
     Can't simply move the status to EOF, as status on "1ST_DO_HEADER"
     is used by lazy write to mean "write the gzip header on first write"
     and there's a real chance (certainly in the regression tests :-))
     that we have all the data to compress ready in the buffer with nothing
     actually deflated right now at close time. */
  g->flags |= LAYERGZIP_FLAG_CLOSING_FILE;

  if ((g->flags & LAYERGZIP_FLAG_DEFL_INIT_DONE) ||
      (PerlIOBase(f)->flags & PERLIO_F_WRBUF)) {
    code = PerlIO_flush(f);
  }

  if (g->flags & LAYERGZIP_FLAG_DO_CRC_AT_END) {
    if ((PerlIOBase(f)->flags & PERLIO_F_CANREAD)
	&& (g->status == LAYERGZIP_STATUS_ZSTREAM_END)) {
      unsigned char buffer[8];
      PerlIO *below = PerlIONext(f);
      SSize_t got = PerlIO_read(below,buffer,8);

#if DEBUG_LAYERGZIP
      PerlIO_debug("PerlIOGzip_close g->crc=%08"UVxf" next=%p got=%d\n",
		   g->crc, below, (int)got);
#endif

      if (got != 8)
	code = -1;
      else {
	U32 crc = buffer[0] | (buffer[1] << 8) | (buffer[2] << 16)
	  | (buffer[3] << 24);
#if DEBUG_LAYERGZIP
	PerlIO_debug("PerlIOGzip_close    crc=%08"UVxf"\n", crc);
#endif
	if (crc != (g->crc & 0xFFFFFFFF))
	  code = -1;
	else {
	  U32 len = buffer[4] | (buffer[5] << 8) | (buffer[6] << 16)
	    | (buffer[7] << 24);
#if DEBUG_LAYERGZIP
	  PerlIO_debug("PerlIOGzip_close    len=%08"UVxf" total=%08"UVxf"\n",
		       len, g->zs.total_out);
#endif
	  if (len != (g->zs.total_out & 0xFFFFFFFF))
	    code = -1;
	}
      }
    } else if ((PerlIOBase(f)->flags & PERLIO_F_CANWRITE) && (code == 0)) {
      /* Don't come in here if the flush failed (ie code != 0). */
      unsigned char buffer[8];
      PerlIO *below = PerlIONext(f);

#if DEBUG_LAYERGZIP
	PerlIO_debug("PerlIOGzip_close crc=%08"UVxf" len=%08"UVxf"\n", g->crc,
		     g->zs.total_in);
#endif

      buffer[0] = g->crc & 0xFF;
      buffer[1] = (g->crc >>  8) & 0xFF;
      buffer[2] = (g->crc >> 16) & 0xFF;
      buffer[3] = (g->crc >> 24) & 0xFF;
      buffer[4] = g->zs.total_in & 0xFF;
      buffer[5] = (g->zs.total_in >>  8) & 0xFF;
      buffer[6] = (g->zs.total_in >> 16) & 0xFF;
      buffer[7] = (g->zs.total_in >> 24) & 0xFF;

      code = (PerlIO_write(below,buffer,8) == 8 ? 0 : -1);
    }
  }
  if (g->flags & (LAYERGZIP_FLAG_DEFL_INIT_DONE | LAYERGZIP_FLAG_INFL_INIT_DONE
		  | LAYERGZIP_FLAG_OURBUFFERBELOW))
    code |= PerlIOGzip_popped(aTHX_ f);

#if DEBUG_LAYERGZIP
  PerlIO_debug("PerlIOGzip_close f=%p %d\n", f, (int)code);
#endif

#if PERL_VERSION > 8 || PERL_SUBVERSION > 0
  /* 5.8.1 correctly exports PerlIOBuf_close */
  code |= PerlIOBuf_close(aTHX_ f);	/* Call it whatever.  */
#else
  /* 5.8.0 doesn't, so platforms such as AIX and Windows can't see it.
     Inline it here:  */
  code |= PerlIOBase_close(aTHX_ f);
  {
    PerlIOBuf *b = PerlIOSelf(f, PerlIOBuf);
    if (b->buf && b->buf != (STDCHAR *) & b->oneword) {
      Safefree(b->buf);
    }
    b->buf = NULL;
    b->ptr = b->end = b->buf;
    PerlIOBase(f)->flags &= ~(PERLIO_F_RDBUF | PERLIO_F_WRBUF);
  }
#endif
  return code ? -1 : 0;		/* Only returns 0 if both succeeded */
}

static IV
PerlIOGzip_fill(pTHX_ PerlIO *f)
{
  PerlIOGzip *g = PerlIOSelf(f,PerlIOGzip);
  PerlIOBuf *b = PerlIOSelf(f,PerlIOBuf);
  PerlIO *n = PerlIONext(f);
  SSize_t avail;
  int status = Z_OK;

#if DEBUG_LAYERGZIP
  PerlIO_debug("PerlIOGzip_fill f=%p g->status=%d\n", f, g->status);
#endif

  if (g->status == LAYERGZIP_STATUS_CONFUSED ||
      g->status == LAYERGZIP_STATUS_ZSTREAM_END)
    return -1;	/* Error state, or EOF has been seen.  */

  if (g->status == LAYERGZIP_STATUS_1ST_DO_HEADER) {
    if (check_gzip_header_and_init (f) != LAYERGZIP_GZIPHEADER_GOOD) {
      g->status = LAYERGZIP_STATUS_CONFUSED;
      PerlIOBase(f)->flags |= PERLIO_F_ERROR;
      return -1;
    }
  }

  if (!b->buf)
    PerlIO_get_base(f); /* allocate via vtable */

  b->ptr = b->end = b->buf;
  g->zs.next_out = (Bytef *) b->buf;
  g->zs.avail_out = b->bufsiz;

#if DEBUG_LAYERGZIP
  PerlIO_debug("PerlIOGzip_fill next_out=%p avail_out=%08x status=%d\n",
	       g->zs.next_out,g->zs.avail_out, g->status);
#endif

  assert (PerlIO_fast_gets(n));
  /* loop while we see no output.  */
  while (g->zs.next_out == (Bytef *) b->buf) {
    /* If we have run out of input then read some more.  */
    avail = PerlIO_get_cnt(n);
#if DEBUG_LAYERGZIP
    PerlIO_debug("PerlIOGzip_fill avail=%08"UVxf" status=%d\n", (UV)avail,
		 g->status);
#endif
    /* Someone is going to give us compressed input on a tty some day, and
       there we'll only see EOF once, before a read will block again.
       So if we see EOF, remember it.  inflate will stall with an error if
       more input were really needed and this EOF turns out to have been
       premature.  */
    if (avail <= 0 && (g->status != LAYERGZIP_STATUS_INPUT_EOF)) {
      avail = PerlIO_fill(n);
      if (avail == 0) {
	avail = PerlIO_get_cnt(n);
#if DEBUG_LAYERGZIP
	PerlIO_debug("PerlIOGzip_fill refill, avail=%08"UVxf"\n",(UV)avail);
#endif
      } else {
	/* To make this non blocking friendly would we need to change this?  */
	if (PerlIO_error(n)) {
	  /* I'm assuming that the error on the input stream is persistent,
	     and that as there is going to be output space, I'll get
	     Z_BUF_ERROR if no progress is possible because I've used all
	     the input I got before the error.  */
	  avail = 0;
#if DEBUG_LAYERGZIP
	PerlIO_debug("PerlIOGzip_fill error, avail=%08"UVxf"\n",(UV)avail);
#endif
	} else if (PerlIO_eof(n)) {
	  g->status = LAYERGZIP_STATUS_INPUT_EOF;
	  avail = 0;
#if DEBUG_LAYERGZIP
	PerlIO_debug("PerlIOGzip_fill input eof, avail=%08"UVxf"\n",(UV)avail);
#endif
	} else {
	  avail = 0;
#if DEBUG_LAYERGZIP
	  PerlIO_debug("PerlIOGzip_fill how did I get here?, avail=%08"UVxf
		       "\n",(UV)avail);
#endif
	}
      }
    }


    g->zs.avail_in = avail;
    g->zs.next_in = (Bytef *) PerlIO_get_ptr(n);
    /* Z_SYNC_FLUSH to get as much output as possible if there's no input left.
       This may be pointless, but I'm hoping that this is enough to make non-
       blocking work by forcing as much output as possible if the input
       blocked.  */
#if DEBUG_LAYERGZIP
    PerlIO_debug("PerlIOGzip_fill preinf  next_in=%p avail_in=%08x\n",
		 g->zs.next_in,g->zs.avail_in);
#endif
    status = inflate (&(g->zs), avail ? Z_NO_FLUSH : Z_SYNC_FLUSH);
#if DEBUG_LAYERGZIP
    PerlIO_debug("PerlIOGzip_fill postinf next_in=%p avail_in=%08x status=%d\n",
	       g->zs.next_in,g->zs.avail_in, status);
#endif
  
    /* And we trust that zlib gets these two correct  */
    PerlIO_set_ptrcnt(n, (STDCHAR *) g->zs.next_in, g->zs.avail_in);

    if (status != Z_OK) {
      if (status == Z_STREAM_END) {
	g->status = LAYERGZIP_STATUS_ZSTREAM_END;
	PerlIOBase(f)->flags |= PERLIO_F_EOF;
      } else {
	PerlIOBase(f)->flags |= PERLIO_F_ERROR;
      }
      break;
    }

  }  /* loop until we read enough data.
	hopefully not literally forever. Z_BUF_ERROR should be generated if
	there is a buffer problem.  Z_OK will only appear if there is progress
	- ie either input is consumed (it must be available for this) or output
	is generated (there must be space for this).  Hence not consuming any
	input whilst also not generating any more output is an error we will
	spot and barf on.  */

#if DEBUG_LAYERGZIP
  PerlIO_debug("PerlIOGzip_fill leaving next_out=%p avail_out=%08x\n",
	       g->zs.next_out,g->zs.avail_out);
#endif
  
  if (g->zs.next_out != (Bytef *) b->buf) {
    /* Success if we got at least one byte. :-) */
    b->end = (STDCHAR *) g->zs.next_out;
    /* Update the crc */
    if (g->flags & LAYERGZIP_FLAG_DO_CRC_AT_END)
      g->crc = crc32(g->crc, (Bytef *) b->buf, b->end - b->buf);
    PerlIOBase(f)->flags |= PERLIO_F_RDBUF;
    return 0;
  }
  return -1;
}

IV
PerlIOGzip_flush(pTHX_ PerlIO *f) {
#if DEBUG_LAYERGZIP
  PerlIO_debug("PerlIOGzip_flush f=%p fl=%08"UVxf"\n", f,
	       PerlIOBase(f)->flags);
#endif
  if (PerlIOBase(f)->flags & PERLIO_F_ERROR)
    return -1;


  if (PerlIOBase(f)->flags & PERLIO_F_CANWRITE) {
    /* Must come in here even if there's no buffered data, in case we need
       to finish  */
    PerlIOGzip *g = PerlIOSelf(f,PerlIOGzip);
    PerlIOBuf *b = PerlIOSelf(f,PerlIOBuf);
    z_stream *z = &g->zs;

    if (g->status == LAYERGZIP_STATUS_1ST_DO_HEADER) {
#if DEBUG_LAYERGZIP
      PerlIO_debug("PerlIOGzip_flush 1st do header b->buf=%p b->ptr=%p\n",
		   b->buf, b->ptr);
#endif
      /* OK. In lazy mode.  */
      if (b->ptr == b->buf) {
#if DEBUG_LAYERGZIP
	PerlIO_debug("PerlIOGzip_flush no data, write no header\n");
#endif
	g->status = LAYERGZIP_STATUS_ZSTREAM_END;
	return 0;
      }
      if (write_gzip_header_and_init (f)) {
	g->status = LAYERGZIP_STATUS_CONFUSED;
	PerlIOBase(f)->flags |= PERLIO_F_ERROR;
	return -1;
      }
    }

    z->next_in = (Bytef *) b->buf;
    z->avail_in = b->ptr - b->buf;

    if (g->flags & LAYERGZIP_FLAG_DO_CRC_AT_END)
      g->crc = crc32(g->crc, z->next_in, z->avail_in);

    while (z->avail_in || ((g->flags & LAYERGZIP_FLAG_CLOSING_FILE)
			   && g->status == LAYERGZIP_STATUS_NORMAL)) {
      int status;
#if DEBUG_LAYERGZIP
      PerlIO_debug("PerlIOGzip_flush predef  next_in= %p avail_in= %08x\n"
		   "                         next_out=%p avail_out=%08x"
		   "\n", g->zs.next_in, g->zs.avail_in, g->zs.next_out,
		   g->zs.avail_out);
#endif
      status = deflate (&(g->zs), (g->flags & LAYERGZIP_FLAG_CLOSING_FILE)
			? Z_FINISH : 0);

#if DEBUG_LAYERGZIP
      PerlIO_debug("PerlIOGzip_flush postdef next_in= %p avail_in= %08x\n"
		   "                         next_out=%p avail_out=%08x "
		   "status=%d\n", g->zs.next_in,g->zs.avail_in,
		   g->zs.next_out,g->zs.avail_out, status);
#endif

      if (status == Z_STREAM_END) {
	assert (z->avail_in == 0);
	g->status = LAYERGZIP_STATUS_ZSTREAM_END;
      }

      if (status == Z_OK || status == Z_STREAM_END) {
	if (z->avail_out == 0 || status == Z_STREAM_END) {
	  PerlIO *n = PerlIONext(f);
	  SSize_t avail = OUTSIZE - z->avail_out;
	  STDCHAR *where = (STDCHAR *) g->outbuf;


	  while (avail > 0) {
	    SSize_t count = PerlIO_write(n, where, avail);

	    if (count > 0) {
	      where += count;
	      avail -= count;
	    } else if (count < 0 || PerlIO_error(n)) {
#if DEBUG_LAYERGZIP
	      PerlIO_debug("PerlIOGzip_flush write failed, data lost\n");
#endif
	      PerlIOBase(f)->flags |= PERLIO_F_ERROR;
	      return -1;
#if DEBUG_LAYERGZIP
	    } else {
	      PerlIO_debug("PerlIOGzip_flush wrote 0 - aren't we spinning?\n");
#endif
	    }
	  }
	  z->next_out = (Bytef *) g->outbuf;
	  z->avail_out = OUTSIZE;
	}
      } else {
#if DEBUG_LAYERGZIP
	PerlIO_debug("PerlIOGzip_flush deflate failed %d, data lost\n",
		     status);
#endif
	PerlIOBase(f)->flags |= PERLIO_F_ERROR;
	return -1;
      }
    }

    b->ptr = b->end = b->buf;
    PerlIOBase(f)->flags &= ~(PERLIO_F_WRBUF);

    if (PerlIO_flush(PerlIONext(f)) != 0)
      return -1;
  }
  return 0;
}


/* Hmm. These need to be public?  */

static IV
PerlIOGzip_seek_fail(pTHX_ PerlIO *f, Off_t offset, int whence)
{
  return -1;
}

PerlIO *
PerlIOGzip_dup(pTHX_ PerlIO *f, PerlIO *o, CLONE_PARAMS *param, int flags)
{
  croak ("PerlIO::gzip can't yet clone active layers");
  return NULL;
}

PerlIO_funcs PerlIO_gzip = {
  sizeof(PerlIO_funcs),
  "gzip",
  sizeof(PerlIOGzip),
  PERLIO_K_BUFFERED, /* XXX destruct */
  PerlIOGzip_pushed,
  PerlIOGzip_popped,
  PerlIOBuf_open,
  PerlIOBase_binmode,
  PerlIOGzip_getarg,
  PerlIOBase_fileno,
  PerlIOGzip_dup,
  PerlIOBuf_read,
  PerlIOBuf_unread, /* I am not convinced that this is going to work */
  PerlIOBuf_write,
  PerlIOGzip_seek_fail,	/* PerlIOBuf_seek, */
  PerlIOBuf_tell,
  PerlIOGzip_close,
  PerlIOGzip_flush,	/* PerlIOBuf_flush, Hmm. open() expects to flush :-( */
  PerlIOGzip_fill,
  PerlIOBase_eof,
  PerlIOBase_error,
  PerlIOBase_clearerr,
  PerlIOBase_setlinebuf,
  PerlIOBuf_get_base,
  PerlIOBuf_bufsiz,
  PerlIOBuf_get_ptr,
  PerlIOBuf_get_cnt,
  PerlIOBuf_set_ptrcnt,
};

MODULE = PerlIO::gzip		PACKAGE = PerlIO::gzip		

PROTOTYPES: DISABLE

BOOT:
	PerlIO_define_layer(aTHX_ &PerlIO_gzip);
