#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "perliol.h"

#ifndef PERL_UNUSED_ARG
# define PERL_UNUSED_ARG(x) PERL_UNUSED_VAR(x)
#endif /* !PERL_UNUSED_ARG */

#ifndef Newx
# define Newx(v,n,t) New(0,v,n,t)
#endif /* !Newx */

/*
 * Precomputed translation tables for sub-octet bit swaps.  Each table,
 * for a complete set of sub-octet swaps, is generated when a layer
 * requiring it is established, and retained forever.  (Most likely only
 * one, at most, of the eight possible arrangements will be used by each
 * program.)  The null swap doesn't get a table, in the expectation that
 * that's quicker to implement by bypassing the table logic.
 */

static U8 *bitswap_table[7];

static U8 *lookup_bitswap_table(U32 swaps)
{
	swaps &= 7;
	if(!swaps) return NULL;
	if(!bitswap_table[swaps-1]) {
		U8 *tbl;
		U16 i;
		Newx(tbl, 256, U8);
		for(i = 256; i--; ) {
			U8 o = i;
			if(swaps & 1)
				o = ((o & 0xaa) >> 1) | ((o & 0x55) << 1);
			if(swaps & 2)
				o = ((o & 0xcc) >> 2) | ((o & 0x33) << 2);
			if(swaps & 4)
				o = ((o & 0xf0) >> 4) | ((o & 0x0f) << 4);
			tbl[i] = o;
		}
		bitswap_table[swaps-1] = tbl;
	}
	return bitswap_table[swaps-1];
}

/*
 * bitswap layer
 *
 * This layer makes itself as thin as possible.  Sub-octet bit swaps
 * are handled by translating the octets during read and write.  If no
 * super-octet swaps are required, then this layer is always fully
 * synchronised with the layer below.
 *
 * Where super-octet swaps are required, operations are governed by
 * the size of the largest unit within which swaps are performed,
 * the block size.  It is only possible to be fully synchronised with
 * the lower layer when the data read or written so far is an integral
 * number of blocks.  This implementation always performs I/O with the
 * lower layer in units of complete blocks.  (If the lower layer splits a
 * block in a way that can't be adequately recovered, this layer declares
 * an I/O error.)  The higher layer, however, is permitted to perform
 * partial-block reads and writes, provided that the full sequence
 * of contiguous reads/writes (unbroken by writes/reads or seeking)
 * consists of an integral number of blocks.  Furthermore, seeks are
 * required to be to block boundaries.
 *
 * To support partial-block operations, a single-block buffer is used.
 * The buffer always stores data in the format of the higher layer.
 * All swaps are performed at the time of I/O with the lower layer.
 */

struct PerlIObitswap {
	struct _PerlIO base;
	U8 *bitswap_table;
	U32 octetswaps;
	Size_t blocksize;
	U8 *buffer;
	Size_t bufpos;
	U32 bufflags;
};

#define BUFFLAG_READING 0x1
#define BUFFLAG_WRITING 0x2

static IV PerlIObitswap_pushed(pTHX_ PerlIO *f, char const *mode, SV *arg,
	PerlIO_funcs *funcs)
{
	struct PerlIObitswap *bs = PerlIOSelf(f, struct PerlIObitswap);
	U32 swaps;
	{
		IV result = PerlIOBase_pushed(aTHX_ f, mode, NULL, funcs);
		if(result != 0) return result;
	}
	{
		char *p, *e;
		int radix;
		STRLEN alen;
		if(!SvOK(arg)) {
			einval:
			errno = EINVAL;
			return -1;
		}
		p = SvPV(arg, alen);
		e = p + alen;
		if(p[0] == '0') {
			if(p[1] == 'x' || p[1] == 'X') {
				radix = 16;
				p += 2;
			} else if(p[1] == 'b' || p[1] == 'B') {
				radix = 2;
				p += 2;
			} else {
				radix = 8;
			}
		} else {
			radix = 10;
		}
		if(p == e) goto einval;
		swaps = 0;
		do {
			char c = *p;
			int v;
			if(c >= '0' && c <= '9') {
				v = c - '0';
			} else if(c >= 'A' && c <= 'F') {
				v = 10 + c - 'A';
			} else if(c >= 'a' && c <= 'f') {
				v = 10 + c - 'a';
			} else {
				goto einval;
			}
			if(v >= radix) goto einval;
			swaps = swaps * radix + v;
		} while(++p != e);
	}
	bs->bitswap_table = lookup_bitswap_table(swaps);
	{
		U32 octetswaps = swaps >> 3;
		Size_t blocksize;
		for(blocksize = 1; blocksize <= octetswaps; )
			blocksize <<= 1;
		bs->octetswaps = octetswaps;
		bs->blocksize = blocksize;
	}
	bs->buffer = NULL;
	bs->bufpos = 0;
	bs->bufflags = 0;
	return 0;
}

static IV PerlIObitswap_popped(pTHX_ PerlIO *f)
{
	struct PerlIObitswap *bs = PerlIOSelf(f, struct PerlIObitswap);
	Safefree(bs->buffer);
	return 0;
}

static SV *PerlIObitswap_getarg(pTHX_ PerlIO *f, CLONE_PARAMS *param, int flags)
{
	struct PerlIObitswap *bs = PerlIOSelf(f, struct PerlIObitswap);
	PERL_UNUSED_ARG(param);
	PERL_UNUSED_ARG(flags);
	U32 swaps = bs->octetswaps << 3;
	if(bs->bitswap_table) {
		U8 s = bs->bitswap_table[1];
		if(s & 0xf0) swaps |= 4;
		if(s & 0xcc) swaps |= 2;
		if(s & 0xaa) swaps |= 1;
	}
	return newSVuv((UV)swaps);
}

static void swap_blocks(struct PerlIObitswap *bs, U8 *buffer, Size_t buflen)
{
	U8 *bitswap_table;
	U32 octetswaps;
	if((bitswap_table = bs->bitswap_table)) {
		U8 *p = buffer + buflen;
		while(p-- != buffer)
			*p = bitswap_table[*p];
	}
	if((octetswaps = bs->octetswaps)) {
		Size_t blocksize = bs->blocksize;
		Size_t halfblocksize = blocksize >> 1;
		U8 *p = buffer + buflen;
		while(p != buffer) {
			Size_t i;
			p -= blocksize;
			for(i = halfblocksize; i--; ) {
				U8 a = p[i];
				U8 b = p[i ^ octetswaps];
				p[i] = b;
				p[i ^ octetswaps] = a;
			}
		}
	}
}

static SSize_t PerlIObitswap_read(pTHX_ PerlIO *f, void *vbuf, Size_t count)
{
	struct PerlIObitswap *bs = PerlIOSelf(f, struct PerlIObitswap);
	U8 *cbuf = vbuf;
	Size_t blocksize = bs->blocksize;
	Size_t blockbits = blocksize - 1;
	Size_t ndone = 0;
	if(bs->bufflags & BUFFLAG_WRITING) {
		eio:
		errno = EIO;
		return -1;
	}
	if(bs->bufflags & BUFFLAG_READING) {
		Size_t bufpos = bs->bufpos;
		Size_t bufavail = blocksize - bufpos;
		if(count < bufavail) {
			Copy(bs->buffer + bufpos, cbuf, count, U8);
			bs->bufpos = bufpos + count;
			return count;
		}
		Copy(bs->buffer + bufpos, cbuf, bufavail, U8);
		ndone = bufavail;
		cbuf += bufavail;
		count -= bufavail;
		bs->bufflags &= ~BUFFLAG_READING;
	}
	if(count & ~blockbits) {
		Size_t dctcount = count & ~blockbits;
		SSize_t dctdone = PerlIO_read(PerlIONext(f), cbuf, dctcount);
		if(dctdone < 0)
			return dctdone;
		if(dctdone & blockbits) goto eio;
		swap_blocks(bs, cbuf, dctdone);
		ndone += dctdone;
		if((Size_t)dctdone != dctcount)
			return ndone;
		cbuf += dctdone;
		count -= dctdone;
	}
	if(count) {
		SSize_t bufdone;
		if(!bs->buffer)
			Newx(bs->buffer, blocksize, U8);
		bufdone = PerlIO_read(PerlIONext(f), bs->buffer, blocksize);
		if(bufdone < 0)
			return bufdone;
		if(bufdone == 0)
			return ndone;
		if((Size_t)bufdone != blocksize) goto eio;
		swap_blocks(bs, bs->buffer, blocksize);
		bs->bufflags |= BUFFLAG_READING;
		bs->bufpos = count;
		Copy(bs->buffer, cbuf, count, U8);
		ndone += count;
	}
	return ndone;
}

static SSize_t PerlIObitswap_write(pTHX_ PerlIO *f, void const *vbuf,
	Size_t count)
{
	struct PerlIObitswap *bs = PerlIOSelf(f, struct PerlIObitswap);
	U8 const *cbuf = vbuf;
	Size_t blocksize = bs->blocksize;
	Size_t blockbits = blocksize - 1;
	Size_t ndone = 0;
	if(bs->bufflags & BUFFLAG_READING) {
		eio:
		errno = EIO;
		return -1;
	}
	if(bs->bufflags & BUFFLAG_WRITING) {
		Size_t bufpos = bs->bufpos;
		Size_t bufavail = blocksize - bufpos;
		SSize_t bufdone;
		if(count < bufavail) {
			Copy(cbuf, bs->buffer + bufpos, count, U8);
			bs->bufpos = bufpos + count;
			return count;
		}
		Copy(cbuf, bs->buffer + bufpos, bufavail, U8);
		swap_blocks(bs, bs->buffer, blocksize);
		bufdone = PerlIO_write(PerlIONext(f), bs->buffer, blocksize);
		if(bufdone < 0)
			return bufdone;
		if((Size_t)bufdone != blocksize) goto eio;
		ndone = bufavail;
		cbuf += bufavail;
		count -= bufavail;
		bs->bufflags &= ~BUFFLAG_WRITING;
	}
	if(count & ~blockbits) {
		Size_t dctcount = count & ~blockbits;
		SSize_t dctdone;
		U8 *sbuf;
		Newx(sbuf, dctcount, U8);
		Copy(cbuf, sbuf, dctcount, U8);
		swap_blocks(bs, sbuf, dctcount);
		dctdone = PerlIO_write(PerlIONext(f), sbuf, dctcount);
		Safefree(sbuf);
		if(dctdone < 0)
			return dctdone;
		if(dctdone & blockbits) goto eio;
		ndone += dctdone;
		if((Size_t)dctdone != dctcount)
			return ndone;
		cbuf += dctdone;
		count -= dctdone;
	}
	if(count) {
		if(!bs->buffer)
			Newx(bs->buffer, blocksize, U8);
		Copy(cbuf, bs->buffer, count, U8);
		bs->bufflags |= BUFFLAG_WRITING;
		bs->bufpos = count;
		ndone += count;
	}
	return ndone;
}

static IV PerlIObitswap_seek(pTHX_ PerlIO *f, Off_t off, int whence)
{
	struct PerlIObitswap *bs = PerlIOSelf(f, struct PerlIObitswap);
	if((bs->bufflags & (BUFFLAG_READING|BUFFLAG_WRITING)) ||
			(off & (bs->blocksize-1))) {
		errno = EIO;
		return -1;
	}
	return PerlIO_seek(PerlIONext(f), off, whence);
}

static Off_t PerlIObitswap_tell(pTHX_ PerlIO *f)
{
	struct PerlIObitswap *bs = PerlIOSelf(f, struct PerlIObitswap);
	Off_t off = PerlIO_tell(PerlIONext(f));
	if(off < 0) return off;
	if(bs->bufflags & (BUFFLAG_READING|BUFFLAG_WRITING)) {
		if(bs->bufflags & BUFFLAG_READING)
			off -= bs->blocksize;
		off += bs->bufpos;
	}
	return off;
}

static IV PerlIObitswap_close(pTHX_ PerlIO *f)
{
	struct PerlIObitswap *bs = PerlIOSelf(f, struct PerlIObitswap);
	bool eio = !!(bs->bufflags & BUFFLAG_WRITING);
	IV result = PerlIOBase_close(aTHX_ f);
	if(result == 0 && eio) {
		errno = EIO;
		result = -1;
	}
	return result;
}

static PerlIO_funcs PerlIObitswap_funcs = {
	sizeof(PerlIO_funcs),
	"bitswap",
	sizeof(struct PerlIObitswap),
	0,
	PerlIObitswap_pushed,
	PerlIObitswap_popped,
	NULL /*open*/,
	NULL /*binmode*/,
	PerlIObitswap_getarg,
	NULL /*fileno*/,
	NULL /*dup*/,
	PerlIObitswap_read,
	NULL /*unread*/,
	PerlIObitswap_write,
	PerlIObitswap_seek,
	PerlIObitswap_tell,
	PerlIObitswap_close,
	NULL /*flush*/,
	NULL /*fill*/,
	NULL /*eof*/,
	NULL /*error*/,
	NULL /*clearerr*/,
	NULL /*setlinebuf*/,
	NULL /*get_base*/,
	NULL /*get_bufsiz*/,
	NULL /*get_ptr*/,
	NULL /*get_cnt*/,
	NULL /*set_ptrcnt*/,
};

MODULE = PerlIO::bitswap PACKAGE = PerlIO::bitswap

PROTOTYPES: DISABLE

BOOT:
	PerlIO_define_layer(aTHX_ &PerlIObitswap_funcs);
