/*
	PerlIO::dir
*/


#include "perlioutil.h"

#define Dirp(f)   (PerlIOSelf(f, PerlIODir)->dirp)

#define DirBuf(f)    (PerlIOSelf(f, PerlIODir)->buf)
#define DirBufPtr(f) (PerlIOSelf(f, PerlIODir)->ptr)
#define DirBufEnd(f) (PerlIOSelf(f, PerlIODir)->end)

#if defined(FILENAME_MAX)
#	define DIR_BUFSIZ (FILENAME_MAX+1)
#else
#	define DIR_BUFSIZ 512
#endif
/*
	BUF: foobar\n@@@@@@@@@@@@@
	      ^      ^            ^
	     ptr    end        BUFSIZ
*/
typedef struct{
	struct _PerlIO base;

	DIR* dirp;

	STDCHAR buf[DIR_BUFSIZ];
	STDCHAR* ptr;
	STDCHAR* end;
} PerlIODir;

static PerlIO*
PerlIODir_open(pTHX_ PerlIO_funcs* self, PerlIO_list_t* layers, IV n,
		  const char* mode, int fd, int imode, int perm,
		  PerlIO* f, int narg, SV** args){
	PERL_UNUSED_ARG(layers);
	PERL_UNUSED_ARG(n);
	PERL_UNUSED_ARG(fd);
	PERL_UNUSED_ARG(imode);
	PERL_UNUSED_ARG(perm);
	PERL_UNUSED_ARG(narg);

#ifndef EACCES
#define EACCES EPERM
#endif

	if(!imode){
		imode = PerlIOUnix_oflags(mode);
	}
	if( imode & (O_WRONLY | O_RDWR) ){
		SETERRNO(EACCES, RMS_PRV);
		return NULL;
	}
	if(PerlIOValid(f)){ /* reopen */
		PerlIO_close(f);
	}
	else{
		f = PerlIO_allocate(aTHX);
	}

	return PerlIO_push(aTHX_ f, self, mode, args[0]);
}

static IV
PerlIODir_pushed(pTHX_ PerlIO* f, const char* mode, SV* arg, PerlIO_funcs* tab){
	if(!SvOK(arg)){
		SETERRNO(EINVAL, LIB_INVARG);
		return -1;
	}

	Dirp(f) = PerlDir_open(SvPV_nolen_const(arg));
	if(!Dirp(f)){
		return -1;
	}

	DirBufPtr(f) = DirBufEnd(f) = DirBuf(f);

	PerlIOBase(f)->flags |= (PERLIO_F_NOTREG | PERLIO_F_OPEN);

	return PerlIOBase_pushed(aTHX_ f, mode, arg, tab);
}

static IV
PerlIODir_popped(pTHX_ PerlIO* f){
	if(Dirp(f)){
#ifdef VOID_CLOSEDIR
		PerlDir_close(Dirp(f));
#else
		if(PerlDir_close(Dirp(f)) < 0){
			Dirp(f) = NULL;
			return -1;
		}
#endif
		Dirp(f) = NULL;
	}
	return PerlIOBase_popped(aTHX_ f);
}

static IV
PerlIODir_fill(pTHX_ PerlIO* f){

#if !defined(I_DIRENT) && !defined(VMS)
	Direntry_t *readdir (DIR *);
#endif
	const Direntry_t* de = PerlDir_read(Dirp(f));

	if(de){
#ifdef DIRNAMLEN
		STRLEN len = de->d_namlen;
#else
		STRLEN len = strlen(de->d_name);
#endif

		assert(DIR_BUFSIZ > len);

		Copy(de->d_name, DirBuf(f), len, STDCHAR);

		/* add "\n" */
		DirBuf(f)[len] = '\n';

		DirBufPtr(f) = DirBuf(f);
		DirBufEnd(f) = DirBuf(f) + (len+1);

		IOLflag_on(f, PERLIO_F_RDBUF);

		return 0;
	}
	else{
		IOLflag_off(f, PERLIO_F_RDBUF);
		IOLflag_on(f,  PERLIO_F_EOF);

		DirBufPtr(f) = DirBufEnd(f) = DirBuf(f);
		return -1;
	}
}

static STDCHAR *
PerlIODir_get_base(pTHX_ PerlIO * f){
	PERL_UNUSED_CONTEXT;

	return DirBuf(f);
}

static STDCHAR *
PerlIODir_get_ptr(pTHX_ PerlIO * f){
	PERL_UNUSED_CONTEXT;

	return DirBufPtr(f);
}

static SSize_t
PerlIODir_get_cnt(pTHX_ PerlIO * f){
	PERL_UNUSED_CONTEXT;

	return DirBufEnd(f) - DirBufPtr(f);
}

static Size_t
PerlIODir_bufsiz(pTHX_ PerlIO * f){
	PERL_UNUSED_CONTEXT;
	PERL_UNUSED_ARG(f);

	return DirBufEnd(f) - DirBuf(f);
}

static void
PerlIODir_set_ptrcnt(pTHX_ PerlIO * f, STDCHAR * ptr, SSize_t cnt){
	PERL_UNUSED_CONTEXT;
	PERL_UNUSED_ARG(cnt);

	DirBufPtr(f) = ptr;
}
#if 0
static IV
PerlIODir_seek(pTHX_ PerlIO* f, Off_t offset, int whence){
	switch(whence){
	case SEEK_SET:
		PerlDir_seek(Dirp(f), offset);
		break;

	case SEEK_CUR:
		if(offset != 0){
			goto einval;
		}
		break;

	case SEEK_END:
		if(offset != 0){
			goto einval;
		}
		while(PerlDir_read(Dirp(f)) != NULL){
			NOOP;
		}
		break;

	default:
		einval: SETERRNO(EINVAL, LIB_INVARG);
		return -1;
	}

	DirBufPtr(f) = DirBufEnd(f) = DirBuf(f);

	IOLflag_off(f, PERLIO_F_EOF | PERLIO_F_RDBUF);
	return 0;
}

static Off_t
PerlIODir_tell(pTHX_ PerlIO* f){
	return PerlDir_tell( Dirp(f) );
}

#else


static IV
PerlIODir_seek(pTHX_ PerlIO* f, Off_t offset, int whence){
	switch(whence){
	case SEEK_SET:
		if(offset == 0){
			PerlDir_rewind(Dirp(f));
			return 0;
		}
	case SEEK_CUR:
	case SEEK_END:
	default:
		SETERRNO(EINVAL, LIB_INVARG);
		return -1;
	}
}


#define PerlIODir_tell NULL
#endif


PERLIO_FUNCS_DECL(PerlIO_dir) = {
    sizeof(PerlIO_funcs),
    "dir",
    sizeof(PerlIODir),
    PERLIO_K_BUFFERED | PERLIO_K_RAW | PERLIO_K_DESTRUCT,
    PerlIODir_pushed,
    PerlIODir_popped,
    PerlIODir_open,
    PerlIOBase_binmode,
    NULL, /* getarg */
    NULL, /* fileno */
    NULL, /* dup */
    NULL, /* read */
    NULL, /* unread */
    NULL, /* write */
    PerlIODir_seek,
    PerlIODir_tell,
    NULL, /* close */
    NULL, /* flush */
    PerlIODir_fill,
    NULL, /* eof */
    NULL, /* error */
    NULL, /* clearerror */
    NULL, /* setlinebuf */
    PerlIODir_get_base,
    PerlIODir_bufsiz,
    PerlIODir_get_ptr,
    PerlIODir_get_cnt,
    PerlIODir_set_ptrcnt
};

