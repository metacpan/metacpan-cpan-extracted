/*
   :reverse - Reads lines backward
 */
#include "perlioutil.h"

#define IOR(f) (PerlIOSelf(f, PerlIOReverse))


#define REV_BUFSIZ 4096

#define SEGSV_BUFSIZ 512
#define BUFSV_BUFSIZ (REV_BUFSIZ+SEGSV_BUFSIZ)


typedef struct{
	struct _PerlIO base;

	STDCHAR buffer[ REV_BUFSIZ ]; /* first buffer */

	SV* segsv; /* broken segment */

	SV* bufsv; /* reversed buffer */
	STDCHAR* ptr;
	STDCHAR* end;
} PerlIOReverse;

static PerlIO*
PerlIOReverse_open(pTHX_ PerlIO_funcs* const self, PerlIO_list_t* const layers, IV const n,
		  const char* const mode, int const fd, int const imode, int const perm,
		  PerlIO* f, int const narg, SV** const args){
	PerlIO_funcs* tab;

	assert(layers->cur > 0);
	tab = LayerFetch(layers, 0); /* :unix or :scalar */

	if(!(tab && tab->Open) || PerlIOUnix_oflags(mode) & (O_WRONLY | O_RDWR) ){
		SETERRNO(EINVAL, LIB_INVARG);
		return NULL;
	}

	f = tab->Open(aTHX_ tab, layers, (IV)1, mode, fd, imode, perm, f, narg, args);

	if(f){
		if(!PerlIO_push(aTHX_ f, self, mode, PerlIOArg)){
			PerlIO_close(f);
			return NULL;
		}
	}
	return f;
}

static IV
PerlIOReverse_pushed(pTHX_ PerlIO* const f, const char* const mode, SV* const arg, PerlIO_funcs* const tab){
	PerlIOReverse* ior;
	PerlIO* nx;
	Off_t pos;
	PerlIO* p;

	if(!(PerlIOValid(f) && (nx = PerlIONext(f)) && PerlIOValid(nx))){
		SETERRNO(EBADF, SS_IVCHAN);
		return -1;
	}

	if(!IOLflag(nx, PERLIO_F_CANREAD)){
		SETERRNO(EINVAL, LIB_INVARG);
		return -1;
	}

	for(p = nx; PerlIOValid(p); p = PerlIONext(p)){
		if(!(PerlIOBase(p)->tab->kind & PERLIO_K_RAW)
			|| (PerlIOBase(p)->flags & PERLIO_F_CRLF)){

			PerlIOUtil_warnif(aTHX_ packWARN(WARN_LAYER),
					":%s is not a raw layer",
					PerlIOBase(p)->tab->name);
			SETERRNO(EINVAL, LIB_INVARG);
			return -1;
		}
	}

	pos = PerlIO_tell(nx);
	if(pos <= 0){
		if(pos < 0 || PerlIO_seek(nx, (Off_t)0, SEEK_END) < 0){
			return -1;
		}
	}

	ior = IOR(f);
	ior->segsv = newSV(SEGSV_BUFSIZ);
	ior->bufsv = newSV(BUFSV_BUFSIZ);

	assert( ior->bufsv );
	assert( ior->segsv );

	sv_setpvn(ior->bufsv, "", 0);
	sv_setpvn(ior->segsv, "", 0);

	return PerlIOBase_pushed(aTHX_ f, mode, arg, tab);
}
static IV
PerlIOReverse_popped(pTHX_ PerlIO* const f){
	PerlIOReverse* const ior = IOR(f);

	PerlIO_debug("PerlIOReverse_popped:"
			" bufsv=%ld, segsv=%ld\n",
			(long)(ior->bufsv ? SvLEN(ior->bufsv) : 0),
			(long)(ior->segsv ? SvLEN(ior->segsv) : 0));

	SvREFCNT_dec(ior->bufsv);
	SvREFCNT_dec(ior->segsv);

	return PerlIOBase_popped(aTHX_ f);
}

#if defined(IOR_DEBUGGING)

#define write_buf(s, l, m)   PerlIOReverse_debug_write_buf(aTHX_ s, l, m)
#define write_bufsv(sv, msg) PerlIOReverse_debug_write_buf(aTHX_ SvPVX(sv), SvCUR(sv), msg)

/* to pass -Wmissing-prototypes -Wunused-function */
void
PerlIOReverse_debug_write_buf(pTHX_ register const STDCHAR*, const Size_t count, const STDCHAR* msg);

void
PerlIOReverse_debug_write_buf(pTHX_ register const STDCHAR* src, const Size_t count, const STDCHAR* msg){
	char* buf;
	char* end;
	register char* ptr;

	Newx(buf, count, char);

	ptr = buf;
	end = buf + count;
	/* write the buffer */

	while(ptr < end){
		*ptr = (*src == '\0' ? '@' : *src);
		ptr++;
		src++;
	}
	if(msg){
		PerlIO_write(PerlIO_stderr(), msg, strlen(msg));
	}
	PerlIO_write(PerlIO_stderr(), "[", 1);
	PerlIO_write(PerlIO_stderr(), buf, count);
	Perl_warn(aTHX_ "]");
	//PerlIO_write(PerlIO_stderr(), "]\n", 2);

	Safefree(buf);
}
#endif /* IOR_DEBUGGING */

static IV
PerlIOReverse_flush(pTHX_ PerlIO* const f){
	if(IOLflag(f, PERLIO_F_RDBUF)){
		PerlIOReverse* ior = IOR(f);
		Off_t offset = (ior->end - ior->ptr) + SvCUR(ior->segsv);
		SvCUR(ior->bufsv) = SvCUR(ior->segsv) = 0;
		ior->end = ior->ptr = SvPVX(ior->bufsv);

		IOLflag_off(f, PERLIO_F_RDBUF);
		PerlIO_seek(PerlIONext(f), offset , SEEK_CUR);
	}
	return PerlIO_flush(PerlIONext(f));
}

static SSize_t
reverse_read(pTHX_ PerlIO* const f, STDCHAR* const vbuf, SSize_t count){
	PerlIO* const nx = PerlIONext(f);
	SSize_t avail = 0;
	Off_t const pos = PerlIO_tell(nx);

	assert( pos == (SSize_t)pos ); /* XXX: What should I do? */

	if(pos <= 0){
		IOLflag_on(f, pos < 0 ? PERLIO_F_ERROR : PERLIO_F_EOF);

		return (SSize_t)pos;
	}

	if(pos < count){
		count = (SSize_t)pos;
	}

	if(PerlIO_seek(nx, (Off_t)-count, SEEK_CUR) < 0){
		IOLflag_on(f, PERLIO_F_ERROR);
		return -1;
	}

	while(avail < count){
		SSize_t s = PerlIO_read(nx, vbuf+avail, (Size_t)(count - avail));
		if(s > 0){
			avail += s;
		}
		else{
			break;
		}
	}

	if(PerlIO_seek(nx, (Off_t)-avail, SEEK_CUR) < 0){
		IOLflag_on(f, PERLIO_F_ERROR);

		return -1;
	}
	return avail;
}



static IV
PerlIOReverse_fill(pTHX_ PerlIO* const f){
	PerlIOReverse* const ior = IOR(f);
	SSize_t avail;

	SV* const bufsv = ior->bufsv;
	SV* const segsv = ior->segsv;
	STDCHAR* rbuf;

	STDCHAR* const buf = ior->buffer;
	STDCHAR* ptr;
	const STDCHAR* end;
	const STDCHAR* start;

	SvCUR(bufsv) = 0;

	retry:
	avail = reverse_read(aTHX_ f, buf, REV_BUFSIZ);

	if(avail < 0){
		return -1;
	}

	start = ptr = buf;
	end = buf + avail;

	if(avail == REV_BUFSIZ){ /* not EOF */
		while(ptr < end){
			if(*(ptr++) == '\n') break;
		}

		/* available buffer has no newlines */
		if(ptr == end){
			/* fill segment simply */
			sv_insert(segsv, 0, 0, buf, (Size_t)avail);

			goto retry;
		}
	}

	/* solve previous segment */
	if(SvCUR(segsv) > 0){
		const STDCHAR* p = end;
		while(p >= ptr){
			if(*(--p) == '\n') break;
		}
		p++;
		/* buf[oo\nbar\nba]
		       ^   ^    ^
		    start ptr   p

		   seg[z\n]
		*/

		sv_grow(bufsv, (end - ptr) + SvCUR(segsv));

		sv_setpvn(bufsv, p, (Size_t)(end - p));
		sv_catsv( bufsv, segsv);
		end = p;
	}
	/*write_buf(start, (Size_t)(ptr - start), "");*/

	sv_setpvn(segsv, start, (Size_t)(ptr - start));
	start = ptr;

	rbuf = SvPVX(bufsv) + SvCUR(bufsv);
	SvCUR(bufsv) += end - start;

	assert(SvCUR(bufsv) <= SvLEN(bufsv));

	while(ptr < end){
		if(*(ptr++) == '\n'){
			/* line length: ptr - start */
			/* write pos:   end - ptr   */

			Copy( start,
			      rbuf + (end - ptr),
			      ptr - start, STDCHAR);

			start = ptr;
		}
	}
	if(start != end){
		Copy( start, rbuf + (end - ptr), ptr - start, STDCHAR);
	}


/*
	write_bufsv(segsv, "segm");
	write_buf(start, end - start, "buf");
	write_bufsv(segsv, "rbuf");
// */
	ior->ptr = SvPVX(bufsv);
	ior->end = SvPVX(bufsv) + SvCUR(bufsv);

	if( SvCUR(bufsv) == 0 ){
		return -1;
	}

	IOLflag_on(f, PERLIO_F_RDBUF);

	return 0;
}

static STDCHAR*
PerlIOReverse_get_base(pTHX_ PerlIO* const f){
	return SvPVX(IOR(f)->bufsv);
}

static STDCHAR*
PerlIOReverse_get_ptr(pTHX_ PerlIO* const f){
	return IOR(f)->ptr;
}

static SSize_t
PerlIOReverse_get_cnt(pTHX_ PerlIO* const f){
	return IOR(f)->end - IOR(f)->ptr;
}

static Size_t
PerlIOReverse_bufsiz(pTHX_ PerlIO* const f){
	return SvCUR(IOR(f)->bufsv);
}

static void
PerlIOReverse_set_ptrcnt(pTHX_ PerlIO* const f, STDCHAR* const ptr, SSize_t const cnt){
	PERL_UNUSED_ARG(cnt);

	IOR(f)->ptr  = ptr;
}

static IV
PerlIOReverse_seek(pTHX_ PerlIO* const f, Off_t const offset, int whence){
	PerlIO* const nx = PerlIONext(f);

	PerlIOReverse_flush(aTHX_ f);

	switch(whence){
		case SEEK_SET:
			whence = SEEK_END;
			break;
		case SEEK_END:
			whence = SEEK_SET;
			break;
	}
	return PerlIO_seek(nx, -offset, whence);
}
static Off_t
PerlIOReverse_tell(pTHX_ PerlIO* const f){
	PerlIO* const nx = PerlIONext(f);
	Off_t const current = PerlIO_tell(nx);
	Off_t end;

	if(PerlIO_seek(nx, (Off_t)0, SEEK_END) < 0){
		return -1;
	}
	end = PerlIO_tell(nx);
	if(PerlIO_seek(nx, current, SEEK_SET) < 0){
		return -1;
	}

	/*
	warn("(end=%d - pos=%d) - (cnt=%d + segsv=%d) = %d",
		(int)end, (int)current, (int)(IOR(f)->end-IOR(f)->ptr), (int)SvCUR(IOR(f)->segsv),
		(int)((end - current) - ((IOR(f)->end - IOR(f)->ptr) + SvCUR(IOR(f)->segsv))));
	*/
	return (end - current) - ((IOR(f)->end - IOR(f)->ptr) + SvCUR(IOR(f)->segsv));
}

PERLIO_FUNCS_DECL(PerlIO_reverse) = {
	sizeof(PerlIO_funcs),
	"reverse",
	sizeof(PerlIOReverse),
	PERLIO_K_BUFFERED | PERLIO_K_RAW,
	PerlIOReverse_pushed,
	PerlIOReverse_popped,
	PerlIOReverse_open,
	PerlIOBase_binmode,
	NULL, /* getarg */
	NULL, /* fileno */
	NULL, /* dup */
	NULL, /* read */
	NULL, /* unread */
	NULL, /* write */
	PerlIOReverse_seek,
	PerlIOReverse_tell,
	NULL, /* close */
	PerlIOReverse_flush,
	PerlIOReverse_fill,
	NULL, /* eof */
	NULL, /* error */
	NULL, /* clearerr */
	NULL, /* setlinebuf */
	PerlIOReverse_get_base,
	PerlIOReverse_bufsiz,
	PerlIOReverse_get_ptr,
	PerlIOReverse_get_cnt,
	PerlIOReverse_set_ptrcnt
};
