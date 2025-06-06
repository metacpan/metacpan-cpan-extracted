#ifndef _pdlmagic_H_
#define _pdlmagic_H_

#define PDL_ISMAGIC(it) ((it)->magic != 0)

/* Magic stuff */

struct pdl_magic;

/* If no copy, not copied with the pdl */
typedef struct pdl_magic_vtable {
	void *(*cast)(struct pdl_magic *); /* Cast the spell */
	struct pdl_magic *(*copy)(struct pdl_magic *);
/*	void *(*cast_tr)(struct pdl_magic *,XXX);
 *	int  (*nth_tr)(struct pdl_magic *,XXX);
 */
} pdl_magic_vtable;

#define PDL_MAGIC_MARKCHANGED     (1 << 0)
#define PDL_MAGIC_THREADING       (1 << 2)
#define PDL_MAGIC_DELETEDATA      (1 << 3)

#define PDL_MAGIC_UNDESTROYABLE   (1 << 14) /* Someone is referring to this */
				/* when magic removed, call pdl_destroy */
#define PDL_MAGIC_DELAYED         (1 << 15)

#define PDL_MAGICSTART \
		int what; /* when is this magic to be called */ \
		pdl_magic_vtable *vtable; \
		struct pdl_magic *next; \
		pdl *pdl

#define PDL_TRMAGICSTART \
		int what; /* when is this magic to be called */ \
		pdl_magic_vtable *vtable; \
		struct pdl_magic *next; \
		pdl_trans *tr

typedef struct pdl_magic {
	PDL_MAGICSTART;
} pdl_magic;

typedef struct pdl_magic_perlfunc {
	PDL_MAGICSTART;
	SV *sv;         	/* sub{} or subname (perl_call_sv) */
} pdl_magic_perlfunc;

typedef struct pdl_magic_changetrans {
	PDL_MAGICSTART;
	pdl_trans *tr;
} pdl_magic_changetrans;

typedef struct pdl_magic_deletedata {
	PDL_MAGICSTART;
	void (*func)(pdl *p, Size_t param);
	Size_t param;
} pdl_magic_deletedata;

#ifdef PDL_PTHREAD

/* This is a workaround to a perl CORE "feature" where they define a
 * macro PTHREAD_CREATE_JOINABLE with the same name as POSIX threads
 * which works as long as the implementation of POSIX threads also
 * uses macros.  As is, the use of the same name space breaks for
 * win32 pthreads where the identifiers are enums and not #defines
 */
#ifdef PTHREAD_CREATE_JOINABLE
#undef  PTHREAD_CREATE_JOINABLE
#endif

#include <pthread.h>

typedef struct pdl_magic_pthread {
	PDL_MAGICSTART;
	PDL_Indx nthdim;
	PDL_Indx nthreads;
	pthread_key_t key;
} pdl_magic_pthread;
#endif

/* - tr magics */

typedef struct pdl_trmagic {
	PDL_TRMAGICSTART;
} pdl_trmagic;

typedef struct pdl_trmagic_family {
	PDL_TRMAGICSTART;
	pdl *fprog,*tprog;
	pdl *fmut,*tmut;
} pdl_trmagic_family;

/* __ = Don't call from outside pdl if you don't know what you're doing */

void pdl__magic_add(pdl *,pdl_magic *);
pdl_error pdl__magic_rm(pdl *,pdl_magic *);
void pdl__magic_free(pdl *);

int pdl__magic_isundestroyable(pdl *);

void *pdl__call_magic(pdl *,int which);
int pdl__ismagic(pdl *);

pdl_magic *pdl__print_magic(pdl *it);

pdl_magic *pdl_add_svmagic(pdl *,SV *);

/* A kind of "dowhenidle" system */

void pdl_add_delayed_magic(pdl_magic *);
void pdl_run_delayed_magic(void);

/* Threading magic */

/* Deferred barfing and warning when pthreading  */
char pdl_pthread_main_thread(void);
int pdl_pthread_barf_or_warn(const char* pat, int iswarn, va_list *args);
void pdl_pthread_realloc_vsnprintf(char **p, size_t *len, size_t extralen, const char *pat, va_list *args, char add_newline);
void pdl_pthread_free(void *p);

pdl_error pdl_add_threading_magic(pdl *,PDL_Indx nthdim, PDL_Indx nthreads);

int pdl_magic_thread_nthreads(pdl *,PDL_Indx *nthdim);
int pdl_magic_get_thread(pdl *);

pdl_error pdl_magic_thread_cast(pdl *,pdl_error (*func)(pdl_trans *),pdl_trans *t, pdl_broadcast *broadcast);
int pdl_pthreads_enabled(void);

/* Delete data magic */
pdl_error pdl_add_deletedata_magic(pdl *it,void (*func)(pdl *, Size_t param), Size_t param);

#endif /* _pdlmagic_H_  */
