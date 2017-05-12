#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/types.h>
#include <tdb.h>

#include "const-c.inc"

/* for debugging.. */
#if defined (__GNUC__) && defined (__i386__)
# define stop() __asm__("int    $0x03\n")
#endif

#ifndef TDB_HAS_HASH_FUNC
typedef u32 (*tdb_hash_func)(TDB_DATA *key);
#endif

static int
delete_key_cb(TDB_CONTEXT *tdb, TDB_DATA key, TDB_DATA data, void *state)
{
	return tdb_delete(tdb, key);
}

static HV *log_func_map = Nullhv;
static SV *log_func_sv = Nullsv;
static void
log_func_cb(TDB_CONTEXT *tdb, int level, const char *fmt, ...)
{
	va_list	ap;
	int	count;
	bool	false = FALSE;
	SV **	callback_p;
	SV *	sv;
	dSP;
	dXSTARG;

	if (log_func_sv)
		callback_p = &log_func_sv;
	else if (log_func_map) {
		callback_p = hv_fetch(log_func_map, (char*)&tdb, sizeof(tdb), FALSE);
		if (callback_p == (SV**)NULL)
			croak("TDB_File internal error: log callback not found in map\n");
	}
	else
		croak("TDB_File internal error: log callback called with no map\n");


	ENTER;
	SAVETMPS;

	va_start(ap, fmt);

	sv = NEWSV(777, 0);
	sv_vsetpvfn(sv, fmt, strlen(fmt), &ap, NULL, 0, &false);

	va_end(ap);

	PUSHMARK(SP);
	XPUSHi(level);
	XPUSHs(sv_2mortal(sv));
	PUTBACK;

	count = call_sv(*callback_p, G_VOID|G_DISCARD);

	if (count != 0)
		croak("log_func_cb: expected 0 values from callback %p, got %d\n",
		      *callback_p, count);

	FREETMPS;
	LEAVE;
}

static SV *hash_func_cb_sv = Nullsv;
static u32
hash_func_cb(TDB_DATA *key)
{
	int	count;
	u32	ret;
	dSP;

	if (!SvOK(hash_func_cb_sv)) return 0;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newSVpv(key->dptr, key->dsize)));
	PUTBACK;

	count = call_sv(hash_func_cb_sv, G_SCALAR);

	SPAGAIN;

	if (count != 1)
		croak("hash_func_cb: expected 1 value from callback %p, got %d\n",
		      hash_func_cb_sv, count);

	ret = POPu;

	PUTBACK;
	FREETMPS;
	LEAVE;

	return ret;
}

static int
traverse_cb(TDB_CONTEXT *tdb, TDB_DATA key, TDB_DATA data, void *status)
{
	dSP;
	SV *	coderef = status;
	SV *	retval;
	int	count;
	int	ret;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newSVpv(key.dptr, key.dsize)));
	XPUSHs(sv_2mortal(newSVpv(data.dptr, data.dsize)));
	PUTBACK;

	count = call_sv(coderef, G_SCALAR);

	SPAGAIN;

	if (count != 1)
		croak("tdb_traverse callback returned %d args\n", count);

	retval = POPs;
	ret = !SvTRUE(retval);

	PUTBACK;
	FREETMPS;
	LEAVE;

	return ret;
}

typedef int mone_on_fail;


MODULE = TDB_File		PACKAGE = TDB_File		PREFIX = tdb_

INCLUDE: const-xs.inc

mone_on_fail
tdb_chainlock(tdb, key)
	TDB_CONTEXT *	tdb
	TDB_DATA	key

void
tdb_chainunlock(tdb, key)
	TDB_CONTEXT *	tdb
	TDB_DATA	key

void
tdb_DESTROY(tdb)
	TDB_CONTEXT *	tdb
    CODE:
	if (tdb) {
		hv_delete(log_func_map, (char*)&tdb, sizeof(tdb), G_DISCARD);
		tdb_close(tdb);
		/* ignores tdb_close() failure (which probably leaks) */
	}

mone_on_fail
tdb_delete(tdb, key)
	TDB_CONTEXT *	tdb
	TDB_DATA	key
    ALIAS:
	DELETE = 1

void
tdb_CLEAR(tdb)
	TDB_CONTEXT *	tdb
    CODE:
	tdb_traverse(tdb, delete_key_cb, NULL);

void
tdb_dump_all(tdb)
	TDB_CONTEXT *	tdb

enum TDB_ERROR
tdb_error(tdb)
	TDB_CONTEXT *	tdb

const char *
tdb_errorstr(tdb)
	TDB_CONTEXT *	tdb

int
tdb_exists(tdb, key)
	TDB_CONTEXT *	tdb
	TDB_DATA	key
    ALIAS:
	EXISTS = 1

TDB_DATA
tdb_fetch(tdb, key)
	TDB_CONTEXT *	tdb
	TDB_DATA	key
    ALIAS:
	FETCH = 1

TDB_DATA
tdb_firstkey(tdb)
	TDB_CONTEXT *	tdb
    ALIAS:
	FIRSTKEY = 1

mone_on_fail
tdb_lockall(tdb)
	TDB_CONTEXT *	tdb

#if 0			/* functions removed in recent tdb */

mone_on_fail
tdb_lockkeys(tdb, ...)
	TDB_CONTEXT *	tdb
    PREINIT:
	TDB_DATA *	keys;
	int		i;
	int		number;
    CODE:
	number = items - 1;
	New(777, keys, number, TDB_DATA);
	for (i = 0; i < number; i++) {
		STRLEN	len;
		keys[i].dptr = SvPV(ST(i+1), len);
		keys[i].dsize = len;
	}
	RETVAL = tdb_lockkeys(tdb, number, keys);
	Safefree(keys);
    OUTPUT:
	RETVAL

void
tdb_unlockkeys(tdb)
	TDB_CONTEXT *	tdb

#endif

void
tdb_logging_function(tdb, arg1)
	TDB_CONTEXT *	tdb
	SV *		arg1
    CODE:
	if (log_func_map == Nullhv)
		log_func_map = newHV();
	/* save &TDB_CONTEXT -> log callback mapping */
	hv_store(log_func_map, (char*)&tdb, sizeof(tdb), newSVsv(arg1), 0);

	tdb_logging_function(tdb, log_func_cb);

TDB_DATA
tdb_nextkey(tdb, key)
	TDB_CONTEXT *	tdb
	TDB_DATA	key
    ALIAS:
	NEXTKEY = 1

TDB_CONTEXT *
tdb_open(class, name, tdb_flags = TDB_DEFAULT, open_flags = O_RDWR|O_CREAT, mode = S_IRUSR|S_IWUSR|S_IRGRP|S_IWGRP|S_IROTH|S_IWOTH, hash_size = 0, log_fn = Nullsv, hash_fn = Nullsv)
	char *	class
	char *	name
	int	hash_size
	int	tdb_flags
	int	open_flags
	mode_t	mode
	SV *	log_fn
	SV *	hash_fn
    ALIAS:
	TIEHASH = 1
    CODE:
	if (log_fn == Nullsv && hash_fn == Nullsv)
		RETVAL = tdb_open(name, hash_size, tdb_flags, open_flags, mode);
	else {
		tdb_log_func log_func;
		tdb_hash_func hash_func;

		if (hash_fn && SvOK(hash_fn)) {
			if (hash_func_cb_sv == Nullsv)
				hash_func_cb_sv = newSVsv(hash_fn);
			else
				SvSetSV(hash_func_cb_sv, hash_fn);
			hash_func = hash_func_cb;
		}
		else
			hash_func = NULL;

		if (log_fn && SvOK(log_fn)) {
			/* We find log callback via return value from
			 * open() - so the only way to catch open-time
			 * log calls is to special-case it :( */
			log_func_sv = log_fn;
			log_func = log_func_cb;
		}
		else
			log_func = NULL;
#ifdef TDB_HAS_HASH_FUNC
		RETVAL = tdb_open_ex(name, hash_size, tdb_flags,
				     open_flags, mode,
				     log_func, hash_func);
#else
		if (hash_func)
			warn("Your libtdb version doesn't support specifying the hash function - ignored.");
		RETVAL = tdb_open_ex(name, hash_size, tdb_flags,
				     open_flags, mode, log_func);
#endif

		/* undo open-time log hack */
		log_func_sv = NULL;

		if (RETVAL && log_fn && SvOK(log_fn)) {
			if (log_func_map == Nullhv)
				log_func_map = newHV();

			/* save &TDB_CONTEXT -> log callback mapping */
			hv_store(log_func_map, (char*)&RETVAL, sizeof(RETVAL),
				 newSVsv(log_fn), 0);
		}
	}
	if (!RETVAL) XSRETURN_UNDEF;
    OUTPUT:
	RETVAL

void
tdb_printfreelist(tdb)
	TDB_CONTEXT *	tdb

mone_on_fail
tdb_reopen(tdb)
	TDB_CONTEXT *	tdb
    POSTCALL:
	/* tdb_reopen frees the TDB_CONTEXT on failure,
	 * so set scalar value to 0 to avoid double free on DESTROY */
	if (RETVAL == -1)
		sv_setiv((SV*)SvRV(ST(0)), 0);
	/* log_func_map entry will be removed on DESTROY */

# FIXME: if this fails, we need to undef $tdb or something
# .. which we can't do - cos we don't know where it failed :(
# maybe reimplement this ourselves?
mone_on_fail
tdb_reopen_all()

mone_on_fail
tdb_store(tdb, key, dbuf, flag = TDB_REPLACE)
	TDB_CONTEXT *	tdb
	TDB_DATA	key
	TDB_DATA	dbuf
	int		flag
    ALIAS:
	STORE = 1

int
tdb_traverse(tdb, fn = &PL_sv_undef)
	TDB_CONTEXT *	tdb
	SV *		fn
    CODE:
	if (SvOK(fn))
		RETVAL = tdb_traverse(tdb, traverse_cb, fn);
	else
		RETVAL = tdb_traverse(tdb, NULL, NULL);
	if (RETVAL == -1) XSRETURN_UNDEF;
    OUTPUT:
	RETVAL

void
tdb_unlockall(tdb)
	TDB_CONTEXT *	tdb
