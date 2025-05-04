#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#if __linux__
#include <sys/ioctl.h>
#include <linux/fs.h>
#endif

#include <sys/types.h>
#include <tdb.h>

#define XXH_STATIC_LINKING_ONLY
#define XXH_IMPLEMENTATION
#define XXH_INLINE_ALL
#include "xxHash/xxhash.h"

static void
set_nocow (const char *path, int flags, int mode)
{
  #if __linux__ && FS_NOCOW_FL && O_CLOEXEC
    int fd = open (path, flags, mode | O_CLOEXEC);

    if (fd >= 0)
      {
        int flags;
        if (!ioctl (fd, FS_IOC_GETFLAGS, &flags))
          {
            flags |= FS_NOCOW_FL;
            ioctl (fd, FS_IOC_SETFLAGS, &flags);
          }
    
        close (fd);
      }
  #endif
}

static void
log_func_cb (TDB_CONTEXT *tdb, enum tdb_debug_level level, const char *fmt, ...)
{
  va_list ap;
  bool xfalse = FALSE;
  SV *cb = (SV *)tdb_get_logging_private (tdb);
  
  if (!cb)
    return;

  dSP;
  dXSTARG;

  ENTER;
  SAVETMPS;

  va_start (ap, fmt);

  SV *sv = sv_newmortal ();
  sv_vsetpvfn (sv, fmt, strlen (fmt), &ap, NULL, 0, &xfalse);

  va_end (ap);

  PUSHMARK (SP);
  XPUSHi (level);
  XPUSHs (sv);

  PUTBACK;
  call_sv (cb, G_VOID | G_DISCARD);

  FREETMPS;
  LEAVE;
}

static int
traverse_cb (TDB_CONTEXT *tdb, TDB_DATA key, TDB_DATA data, void *private_data)
{
  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK (SP);
  XPUSHs (sv_2mortal (newSVpv (key .dptr, key .dsize)));
  XPUSHs (sv_2mortal (newSVpv (data.dptr, data.dsize)));
  PUTBACK;

  int count = call_sv ((SV *)private_data, G_SCALAR);

  SPAGAIN;

  if (count != 1)
    croak ("tdb_traverse callback returned %d args\n", count);

  SV *retval = POPs;
  int ret = !SvTRUE (retval);

  PUTBACK;
  FREETMPS;
  LEAVE;

  return ret;
}

static int
check_cb (TDB_DATA key, TDB_DATA data, void *private_data)
{
  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK (SP);
  XPUSHs (sv_2mortal (newSVpv (key .dptr, key .dsize)));
  XPUSHs (sv_2mortal (newSVpv (data.dptr, data.dsize)));

  PUTBACK;
  int count = call_sv ((SV *)private_data, G_SCALAR);
  SPAGAIN;

  if (count != 1)
    croak ("tdb_check callback returned %d args\n", count);

  SV *retval = POPs;
  int ret = SvTRUE (retval) ? 0 : -1;

  PUTBACK;
  FREETMPS;
  LEAVE;

  return ret;
}

static void
rescue_cb (TDB_DATA key, TDB_DATA data, void *private_data)
{
  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK (SP);
  XPUSHs (sv_2mortal (newSVpv (key .dptr, key .dsize)));
  XPUSHs (sv_2mortal (newSVpv (data.dptr, data.dsize)));

  PUTBACK;
  call_sv ((SV *)private_data, G_VOID | G_DISCARD);

  FREETMPS;
  LEAVE;
}

// https://en.wikipedia.org/wiki/Fowler%E2%80%93Noll%E2%80%93Vo_hash_function
// https://github.com/skeeto/hash-prospector/issues/19
static unsigned int
fnv1ax_hash (TDB_DATA *key)
{
  unsigned int x = sizeof (unsigned int) < 8 ? 0x811c9dc5U : 0xcbf29ce484222325U;

  for (size_t i = 0; i < key->dsize; ++i)
    x = (x ^ key->dptr[i]) * (sizeof (unsigned int) < 8 ? 0x01000193U : 0x00000100000001b3U);

  x ^= x >> 16; x *= 0x21f0aaadU;
  x ^= x >> 15; x *= 0x735a2d97U;
  x ^= x >> 15;

  return x;
}

static unsigned int
xxh3_hash (TDB_DATA *key)
{
  return XXH3_64bits (key->dptr, key->dsize);
}

static unsigned int
custom_hash (TDB_DATA *key, SV *cb)
{
  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK (SP);
  XPUSHs (sv_2mortal (newSVpv (key->dptr, key->dsize)));

  PUTBACK;
  int count = call_sv (cb, G_SCALAR);
  SPAGAIN;

  if (count != 1)
    croak ("hash callback returned %d vaslues, expecte4d exactly 1", count);

  unsigned int hash = POPu;

  PUTBACK;
  FREETMPS;
  LEAVE;

  return hash;
}

static void
croak_on_error_slowpath (TDB_CONTEXT *tdb)
{
  errno = tdb_error (tdb);
  croak_sv (sv_2mortal (newSVpv (tdb_errorstr (tdb), 0)));
}

#define croak_on_error(res) do { if ((res) < 0) croak_on_error_slowpath (tdb); } while (0)

#define NUM_HASH_FUNC 4

static SV *custom_hash_cb[NUM_HASH_FUNC];

static unsigned int custom_hash_1 (TDB_DATA *key) { return custom_hash (key, custom_hash_cb[0]); }
static unsigned int custom_hash_2 (TDB_DATA *key) { return custom_hash (key, custom_hash_cb[1]); }
static unsigned int custom_hash_3 (TDB_DATA *key) { return custom_hash (key, custom_hash_cb[2]); }
static unsigned int custom_hash_4 (TDB_DATA *key) { return custom_hash (key, custom_hash_cb[3]); }

static int
fetch_parser (TDB_DATA key, TDB_DATA data, void *private_data)
{
  SV **svp = (SV **)private_data;
  *svp = newSVpvn (data.dptr, data.dsize);
  return 0;
}

typedef int mone_on_fail;

MODULE = TDB_FileX		PACKAGE = TDB_FileX		PREFIX = tdb_

PROTOTYPES: DISABLE

BOOT:
{
	HV *stash = gv_stashpv ("TDB_FileX", 1);

	static const struct {
	  const char *name;
	  IV iv;
	} *civ, const_iv[] = {
#         define const_iv(name) { # name, (IV) TDB_ ## name },
	  const_iv (ALLOW_NESTING)
	  const_iv (BIGENDIAN)
	  const_iv (CLEAR_IF_FIRST)
	  const_iv (CONVERT)
	  const_iv (DEFAULT)
	  const_iv (DISALLOW_NESTING)
	  const_iv (INCOMPATIBLE_HASH)
	  const_iv (INSERT)
	  const_iv (INTERNAL)
	  const_iv (MODIFY)
	  const_iv (MUTEX_LOCKING)
	  const_iv (NOLOCK)
	  const_iv (NOMMAP)
	  const_iv (NOSYNC)
	  const_iv (REPLACE)
	  const_iv (SEQNUM)
	  const_iv (VOLATILE)

          const_iv (ERR_CORRUPT)
          const_iv (ERR_IO)
          const_iv (ERR_LOCK)
          const_iv (ERR_OOM)
          const_iv (ERR_EXISTS)
          const_iv (ERR_NOLOCK)
          const_iv (ERR_LOCK_TIMEOUT)
          const_iv (ERR_NOEXIST)
          const_iv (ERR_EINVAL)
          const_iv (ERR_RDONLY)
          const_iv (SUCCESS)

          const_iv (DEBUG_FATAL)
          const_iv (DEBUG_ERROR)
          const_iv (DEBUG_WARNING)
          const_iv (DEBUG_TRACE)
	};
	
	for (civ = const_iv + sizeof (const_iv) / sizeof (const_iv [0]); civ > const_iv; civ--)
	  newCONSTSUB (stash, (char *)civ[-1].name, newSViv (civ[-1].iv));
	
	tdb_runtime_check_for_robust_mutexes ();
}

int
register_hash_function (SV *cb)
	PROTOTYPE: $
	CODE:
{
	int idx;

        for (idx = 0; ; ++idx)
          {
            if (idx >= NUM_HASH_FUNC)
              croak ("register_hash_function: no free slot left");

            if (!custom_hash_cb[idx])
              {
                custom_hash_cb[idx] = newSVsv (cb);
                RETVAL = idx + 1;
                break;
              }
          }
}
	OUTPUT: RETVAL

void
unregister_hash_function (int idx)
	CODE:
        --idx;
        if (idx <= 0 || idx > NUM_HASH_FUNC || !custom_hash_cb[idx])
          croak ("unregister_hash_function: illegal hash function id");
        SvREFCNT_dec_NN (custom_hash_cb[idx]);
        custom_hash_cb[idx] = 0;

void
DESTROY (TDB_CONTEXT *tdb)
	CODE:
        if (tdb)
          {
            SvREFCNT_dec ((SV *)tdb_get_logging_private (tdb));
            tdb_close (tdb);
          }

NO_OUTPUT int
tdb_delete (TDB_CONTEXT *tdb, TDB_DATA key)
	ALIAS:
	   DELETE = 0
        POSTCALL:
        croak_on_error (RETVAL);

NO_OUTPUT int
tdb_wipe_all (TDB_CONTEXT *tdb)
	ALIAS:
           CLEAR = 0
	CODE:
        tdb_wipe_all (tdb);
        POSTCALL:
        croak_on_error (RETVAL);

void
tdb_dump_all (TDB_CONTEXT *tdb)

enum TDB_ERROR
tdb_error (TDB_CONTEXT *tdb)

const char *
tdb_errorstr (TDB_CONTEXT *tdb)

SV *
tdb_exists (TDB_CONTEXT *tdb, TDB_DATA key)
	ALIAS:
	   EXISTS = 0
        CODE:
        RETVAL = tdb_exists (tdb, key) ? &PL_sv_yes : &PL_sv_no;
        OUTPUT: RETVAL

SV *
tdb_fetch (TDB_CONTEXT *tdb, TDB_DATA key)
	ALIAS:
	   FETCH  = 0
        CODE:
        /* tdb_parse_record is faster than tdb_fetch, due to one copy saved */
        /* should use tdb_fetch with perlmulticore */
        RETVAL = 0;
        int res = tdb_parse_record (tdb, key, fetch_parser, &RETVAL);
        if (res < 0)
	  {
            SvREFCNT_dec (RETVAL);
            if (tdb_error (tdb) == TDB_ERR_NOEXIST)
              XSRETURN_UNDEF;
	    croak_on_error (res);
          }
        OUTPUT: RETVAL

NO_OUTPUT int
tdb_store (TDB_CONTEXT *tdb, TDB_DATA key, TDB_DATA dbuf, int flag = TDB_REPLACE)
	ALIAS:
	   STORE = 0
        POSTCALL:
        croak_on_error (RETVAL);

NO_OUTPUT int
tdb_append (TDB_CONTEXT *tdb, TDB_DATA key, TDB_DATA dbuf)
        POSTCALL:
        croak_on_error (RETVAL);

TDB_DATA
tdb_firstkey (TDB_CONTEXT *tdb)
	ALIAS:
	   FIRSTKEY = 0

NO_OUTPUT int
tdb_context_only_and_mone_on_fail (TDB_CONTEXT *tdb)
	INTERFACE:
        tdb_lockall
	tdb_unlockall
	tdb_lockall_read
	tdb_unlockall_read
	tdb_lockall_mark
	tdb_lockall_unmark
	tdb_transaction_start
	tdb_transaction_cancel
	tdb_transaction_commit
	tdb_transaction_prepare_commit
	tdb_repack
        POSTCALL:
        croak_on_error (RETVAL);

bool
tdb_context_only_and_mone_on_fail_nonblock (TDB_CONTEXT *tdb)
	INTERFACE:
        tdb_lockall_nonblock
	tdb_lockall_read_nonblock
	tdb_transaction_start_nonblock
        POSTCALL:
        if (RETVAL < 0)
	  {
            if (tdb_error (tdb) != TDB_ERR_LOCK)
              croak_on_error (RETVAL);

            RETVAL = 0;
          }
	else
          RETVAL = 1;

bool         tdb_transaction_active               (TDB_CONTEXT *tdb)

void         tdb_enable_seqnum                    (TDB_CONTEXT *tdb)

int          tdb_get_seqnum                       (TDB_CONTEXT *tdb)

void         tdb_increment_seqnum_nonblock        (TDB_CONTEXT *tdb)

int          tdb_hash_size                        (TDB_CONTEXT *tdb)

size_t       tdb_map_size                         (TDB_CONTEXT *tdb)

int          tdb_get_flags                        (TDB_CONTEXT *tdb)

void         tdb_add_flags                        (TDB_CONTEXT *tdb, unsigned int flag)

void         tdb_remove_flags                     (TDB_CONTEXT *tdb, unsigned int flag)

void         tdb_set_max_dead                     (TDB_CONTEXT *tdb, int max_dead)

bool         tdb_runtime_check_for_robust_mutexes ()

void
tdb_set_logging_function (TDB_CONTEXT *tdb, SV *cb)
	CODE:
        struct tdb_logging_context ctx;
        ctx.log_fn = log_func_cb;
        ctx.log_private = (SV *)newSVsv (cb);
        SvREFCNT_dec ((SV *)tdb_get_logging_private (tdb));
	tdb_set_logging_function (tdb, &ctx);

TDB_DATA
tdb_nextkey (TDB_CONTEXT *tdb, TDB_DATA key)
	ALIAS:
	   NEXTKEY = 0

TDB_CONTEXT *
tdb_open (char *class, char *path, ...)
	ALIAS:
	   TIEHASH = 0
	CODE:
	tdb_hash_func hash_func = 0;
        struct tdb_logging_context ctx = { 0 };
        int tdb_flags = TDB_DEFAULT;
        int open_flags = O_RDWR | O_CREAT;
        mode_t mode = S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH;
        int hash_size = 0;
        int nocow = 0;

        for (int i = 2; i < items - 1; i += 2)
          {
            const char *k = SvPVbyte_nolen (ST (i));
            SV         *v = ST (i + 1);

            if      (strEQ (k, "tdb_flags" )) tdb_flags  = SvIV (v);
            else if (strEQ (k, "open_flags")) open_flags = SvIV (v);
            else if (strEQ (k, "mode"      )) mode       = SvUV (v);
            else if (strEQ (k, "hash_size" )) hash_size  = SvIV (v);
            else if (strEQ (k, "log_cb"))
              {
                SvREFCNT_dec (ctx.log_private);
                ctx.log_fn = 0;
                ctx.log_private = 0;

                if (SvOK (v))
                  {
                    ctx.log_fn = log_func_cb;
                    ctx.log_private = (void *)newSVsv (v);
                  }
              }
            else if (strEQ (k, "hash"))
              {
                const char *f = SvPVbyte_nolen (v);

                if      (!SvOK (v)           ) hash_func = 0;
                else if (strEQ (f, "default")) hash_func = 0;
                else if (strEQ (f, "jenkins")) hash_func = tdb_jenkins_hash;
                else if (strEQ (f, "fnv1ax" )) hash_func = fnv1ax_hash;
                else if (strEQ (f, "xxh3"   )) hash_func = xxh3_hash;
                else if (strEQ (f, "1"      )) hash_func = custom_hash_1;
                else if (strEQ (f, "2"      )) hash_func = custom_hash_2;
                else if (strEQ (f, "3"      )) hash_func = custom_hash_3;
                else if (strEQ (f, "4"      )) hash_func = custom_hash_4;
                else
                  croak ("%s: not a known hash function", f);
              }
            else if (strEQ (k, "mutex"))
              {
                if (SvTRUE (v))
                  {
                    if (tdb_runtime_check_for_robust_mutexes ())
                      tdb_flags |= TDB_MUTEX_LOCKING;
                  }
                else
                  tdb_flags &= ~TDB_MUTEX_LOCKING;
              }
            else if (strEQ (k, "nocow"))
              nocow = SvTRUE (v);
            else
              croak ("%s: not a known parameter name", k);
          }

	if (nocow && (open_flags & O_CREAT) && !(tdb_flags & TDB_INTERNAL))
          set_nocow (path, open_flags, mode);

	RETVAL = tdb_open_ex (path, hash_size, tdb_flags, open_flags, mode, ctx.log_fn ? &ctx : 0, hash_func);

        if (!RETVAL)
          {
            SvREFCNT_dec ((SV *)ctx.log_private);
	    XSRETURN_UNDEF;
          }
	OUTPUT: RETVAL

void
tdb_reopen (TDB_CONTEXT *tdb)
	PROTOTYPE:
	CODE:
        void *logcb = tdb_get_logging_private (tdb);

        int res = tdb_reopen (tdb);

	if (res < 0)
          {
	    /* tdb_reopen frees the TDB_CONTEXT on failure,
	     * so set scalar value to 0 to avoid double free on DESTROY */
	    sv_setiv ((SV*)SvRV (ST (0)), 0);
            SvREFCNT_dec ((SV *)logcb);
            croak ("tdb_reopen failed");
          }

# FIXME: if this fails, we need to undef $tdb or something
# .. which we can't do - cos we don't know where it failed :(
# maybe reimplement this ourselves?
NO_OUTPUT int
tdb_reopen_all (int parent_longlived = 0)
	POSTCALL:
        if (RETVAL < 0)
          croak ("tdb_reopen_all failed");

int
tdb_fd (TDB_CONTEXT *tdb)

const char *
tdb_name (TDB_CONTEXT *tdb)

int
tdb_traverse (TDB_CONTEXT *tdb, SV *fn = &PL_sv_undef)
	ALIAS:
           tdb_traverse_read = 1
	CODE:
	RETVAL = (ix ? tdb_traverse_read : tdb_traverse) (tdb, SvOK (fn) ? traverse_cb: 0, fn);
        croak_on_error (RETVAL);
	OUTPUT: RETVAL

mone_on_fail
tdb_check (TDB_CONTEXT *tdb, SV *fn = &PL_sv_undef)
	CODE:
	RETVAL = tdb_check (tdb, SvOK (fn) ? check_cb : 0, fn);
	OUTPUT: RETVAL

mone_on_fail
tdb_rescue (TDB_CONTEXT *tdb, SV *fn)
	CODE:
	RETVAL = tdb_rescue (tdb, rescue_cb, fn);
	OUTPUT: RETVAL

char *
tdb_summary (TDB_CONTEXT *tdb)
	CLEANUP:
        free (RETVAL);

int
tdb_validate_freelist (TDB_CONTEXT *tdb)
	CODE:
        int ret = tdb_validate_freelist (tdb, &RETVAL);
        croak_on_error (ret);
        OUTPUT: RETVAL

void
tdb_printfreelist (TDB_CONTEXT *tdb)

int
tdb_freelist_size (TDB_CONTEXT *tdb)

