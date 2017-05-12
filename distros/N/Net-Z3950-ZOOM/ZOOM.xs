#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <yaz/zoom.h>
#include <yaz/diagsrw.h>
#include <yaz/xmalloc.h>
#include <yaz/log.h>
#include <yaz/yaz-version.h>

/* Used by the *_setl() functions */
typedef char opaquechar;

/* Used as the return value of the *_getl() functions */
struct datachunk {
	char *data;
	int len;
};

/* Used to package Perl function-pointer and user-data together */
struct callback_block {
	SV *function;
	SV *handle;
};

/* The callback function used for ZOOM_options_set_callback().  I do
 * not claim to fully understand all the stack-hacking magic, and less
 * still the reference-counting/mortality stuff.  Accordingly, the
 * memory management here is best characterised as What I Could Get To
 * Work, More Or Less.
 */
const char *__ZOOM_option_callback (void *handle, const char *name)
{
	struct callback_block *cb = (struct callback_block*) handle;
	int count;
	SV *ret;
	char *s;
	char *res;

	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	XPUSHs(cb->handle);
	XPUSHs(sv_2mortal(newSVpv(name, 0)));
	PUTBACK;
	/* Perl_sv_dump(0, cb->function); */

	count = call_sv(cb->function, G_SCALAR);

	SPAGAIN;

	if (count != 1)
		croak("callback function for ZOOM_options_get() returned %d values: should have returned exactly one", count);

	ret = POPs;
	if (SvPOK(ret)) {
		s = SvPV_nolen(ret);
		/* ### `res' never gets freed!  I think it is
		 * impossible to solve this problem "correctly"
		 * because the ZOOM-C option callback interface is
		 * inadequate. */
		res = xstrdup(s);
	} else {
		res = 0;
	}

	PUTBACK;
	FREETMPS;
	LEAVE;

	return res;
}


MODULE = Net::Z3950::ZOOM		PACKAGE = Net::Z3950::ZOOM		PREFIX=ZOOM_

PROTOTYPES: ENABLE


ZOOM_connection
ZOOM_connection_new(host, portnum)
	const char* host
	int portnum

ZOOM_connection
ZOOM_connection_create(options)
	ZOOM_options options

void
ZOOM_connection_connect(c, host, portnum)
	ZOOM_connection	c
	const char* host
	int portnum

void
ZOOM_connection_destroy(c)
	ZOOM_connection	c

const char *
ZOOM_connection_option_get(c, key)
	ZOOM_connection	c
	const char *key

struct datachunk
ZOOM_connection_option_getl(c, key, len)
	ZOOM_connection	c
	const char* key
	int &len
	CODE:
		RETVAL.data = (char*) ZOOM_connection_option_getl(c, key, &len);
		RETVAL.len = len;
	OUTPUT:
		RETVAL
		len

void
ZOOM_connection_option_set(c, key, val)
	ZOOM_connection	c
	const char *key
	const char *val

# In ZOOM-C, the `val' parameter is const char*.  However, our typemap
# treats this as T_PV, i.e. it's "known" that it points to a
# NUL-terminated string.  Instead, then, I here use opaquechar*, which
# is an opaque pointer.  The underlying C function can then use this
# along with `len' to Do The Right Thing.
#
void
ZOOM_connection_option_setl(c, key, val, len)
	ZOOM_connection	c
	const char* key
	opaquechar* val
	int len

# The reference parameters, `cp' and `addinfo', need to already have
# values when this function is called, otherwise an "uninitialised
# value" warning is generated.  As far as I can see, there is no way
# around this: no way to specify in a prototype that an argument is
# allowed to be undefined, for example.  Since these function will
# never be called directly by well-behaved client code, but only by
# our own wrapper classes, I think we can live with that.
#
# The poxing about with cpp and caddinfo is due to Perl XS's lack of
# support for const char**, but who can blame it?  If you ask me, the
# whole "const" thing was well-intentioned by ghastly mistake.
#
int
ZOOM_connection_error(c, cp, addinfo)
	ZOOM_connection	c
	char* &cp
	char* &addinfo
	CODE:
		{
		const char *ccp, *caddinfo;
		RETVAL = ZOOM_connection_error(c, &ccp, &caddinfo);
		cp = (char*) ccp;
		addinfo = (char*) caddinfo;
		}
	OUTPUT:
		RETVAL
		cp
		addinfo

# See comments for ZOOM_connection_error() above
int
ZOOM_connection_error_x(c, cp, addinfo, diagset)
	ZOOM_connection	c
	const char * &cp
	const char * &addinfo
	const char * &diagset
	CODE:
		{
		const char *ccp, *caddinfo, *cdset;
		RETVAL = ZOOM_connection_error_x(c, &ccp, &caddinfo, &cdset);
		cp = (char*) ccp;
		addinfo = (char*) caddinfo;
		diagset = (char*) cdset;
		}
	OUTPUT:
		RETVAL
		cp
		addinfo
		diagset

int
ZOOM_connection_errcode(c)
	ZOOM_connection	c

const char *
ZOOM_connection_errmsg(c)
	ZOOM_connection	c

const char *
ZOOM_connection_addinfo(c)
	ZOOM_connection	c

const char *
ZOOM_connection_diagset(c)
	ZOOM_connection	c

const char *
ZOOM_diag_str(error)
	int error

const char *
ZOOM_diag_srw_str(error)
	int error
	CODE:
		RETVAL = yaz_diag_srw_str(error);
	OUTPUT:
		RETVAL

ZOOM_resultset
ZOOM_connection_search(arg0, q)
	ZOOM_connection	arg0
	ZOOM_query q

ZOOM_resultset
ZOOM_connection_search_pqf(c, q)
	ZOOM_connection c
	const char *q

void
ZOOM_resultset_destroy(r)
	ZOOM_resultset r

const char *
ZOOM_resultset_option_get(r, key)
	ZOOM_resultset r
	const char* key

void
ZOOM_resultset_option_set(r, key, val)
	ZOOM_resultset r
	const char* key
	const char* val

size_t
ZOOM_resultset_size(r)
	ZOOM_resultset r

SV *
ZOOM_resultset_records(r, start, count, return_records)
	ZOOM_resultset r
	size_t start
	size_t count
	int return_records
	CODE:
		{
		ZOOM_record *recs = 0;
		if (return_records)
			recs = (ZOOM_record*) xmalloc(count * sizeof *recs);
		ZOOM_resultset_records(r, recs, start, count);
		if (return_records) {
			AV *av = newAV();
			int i;
			for (i = 0; i < count; i++) {
				SV *tmp = newSV(0);
				sv_setref_pv(tmp, "ZOOM_record", (void*) recs[i]);
				av_push(av, tmp);
			}
			RETVAL = newRV((SV*) av);
		} else {
			RETVAL = &PL_sv_undef;
		}
		}
	OUTPUT:
		RETVAL

ZOOM_record
ZOOM_resultset_record(s, pos)
	ZOOM_resultset s
	size_t pos

ZOOM_record
ZOOM_resultset_record_immediate(s, pos)
	ZOOM_resultset s
	size_t pos

void
ZOOM_resultset_cache_reset(r)
	ZOOM_resultset r

# TESTED (but deprecated)
void
ZOOM_resultset_sort(r, sort_type, sort_spec)
	ZOOM_resultset r
	const char* sort_type
	const char* sort_spec

int
ZOOM_resultset_sort1(r, sort_type, sort_spec)
	ZOOM_resultset r
	const char* sort_type
	const char* sort_spec

# See comments for ZOOM_connection_error() above
int
ZOOM_record_error(rec, cp, addinfo, diagset)
	ZOOM_record rec
	const char* &cp
	const char* &addinfo
	const char* &diagset
	CODE:
		{
		const char *ccp = "", *caddinfo = "", *cdset = "";
		RETVAL = ZOOM_record_error(rec, &ccp, &caddinfo, &cdset);
		cp = (char*) ccp;
		addinfo = (char*) caddinfo;
		diagset = (char*) cdset;
		}
	OUTPUT:
		RETVAL
		cp
		addinfo
		diagset

# See "typemap" for discussion of the "const char *" return-type.
const char *
ZOOM_record_get_string(rec, type)
	ZOOM_record rec
	const char* type
	INIT:
		int len;
	CODE:
		RETVAL = ZOOM_record_get(rec, type, &len);
	OUTPUT:
		RETVAL

struct datachunk
ZOOM_record_get_binary(rec, type)
	ZOOM_record rec
	const char* type
	CODE:
		RETVAL.data = (char*) ZOOM_record_get(rec, type, &RETVAL.len);
	OUTPUT:
		RETVAL

void
ZOOM_record_destroy(rec)
	ZOOM_record rec

ZOOM_record
ZOOM_record_clone(srec)
	ZOOM_record srec

ZOOM_query
ZOOM_query_create()

void
ZOOM_query_destroy(s)
	ZOOM_query s

int
ZOOM_query_cql(s, str)
	ZOOM_query s
	const char* str

int
ZOOM_query_cql2rpn(s, str, conn)
	ZOOM_query s
	const char* str
	ZOOM_connection conn

int
ZOOM_query_ccl2rpn(s, query_str, config, errcode, errstr, errpos)
	ZOOM_query s
	const char* query_str
	const char* config
	int &errcode
	const char* &errstr
	int &errpos
	OUTPUT:
		RETVAL
		errcode
		errstr
		errpos

int
ZOOM_query_prefix(s, str)
	ZOOM_query s
	const char* str

int
ZOOM_query_sortby(s, criteria)
	ZOOM_query	s
	const char *	criteria
	
int
ZOOM_query_sortby2(s, strategy, criteria)
	ZOOM_query	s
	const char *	strategy
	const char *	criteria

ZOOM_scanset
ZOOM_connection_scan(c, startterm)
	ZOOM_connection c
	const char* startterm

ZOOM_scanset
ZOOM_connection_scan1(c, startterm)
	ZOOM_connection c
	ZOOM_query startterm

const char *
ZOOM_scanset_term(scan, pos, occ, len)
	ZOOM_scanset scan
	size_t pos
	size_t& occ
	size_t& len
	OUTPUT:
		RETVAL
		occ
		len

const char *
ZOOM_scanset_display_term(scan, pos, occ, len)
	ZOOM_scanset scan
	size_t pos
	size_t& occ
	size_t& len
	OUTPUT:
		RETVAL
		occ
		len

size_t
ZOOM_scanset_size(scan)
	ZOOM_scanset scan

void
ZOOM_scanset_destroy(scan)
	ZOOM_scanset scan

const char *
ZOOM_scanset_option_get(scan, key)
	ZOOM_scanset	scan
	const char *	key

void
ZOOM_scanset_option_set(scan, key, val)
	ZOOM_scanset	scan
	const char *	key
	const char *	val

# We ignore the return value of ZOOM_options_set_callback(), since it
# is always just the address of the __ZOOM_option_callback() function.
# The information that we actually want -- the address of the Perl
# function in the callback_block -- is unavailable to us, as the
# underlying C function doesn't give the block back.
#
void
ZOOM_options_set_callback(opt, function, handle)
	ZOOM_options opt
	SV* function;
	SV* handle;
	CODE:
		{
		/* The tiny amount of memory allocated here is never
	         * released, as options_destroy() doesn't do anything
	         * to the callback information.  Not a big deal.
		 * Also, I have no idea how to drive the Perl "mortal"
		 * reference-counting stuff, so I am just allocating
		 * copies which also never get released.  Don't sue!
		 */
		struct callback_block *block = (struct callback_block*)
			xmalloc(sizeof *block);
		block->function = function;
		block->handle = handle;
		SvREFCNT(block->function);
		SvREFCNT(block->handle);
		ZOOM_options_set_callback(opt, __ZOOM_option_callback,
					  (void*) block);
		}

ZOOM_options
ZOOM_options_create()

ZOOM_options
ZOOM_options_create_with_parent(parent)
	ZOOM_options parent

ZOOM_options
ZOOM_options_create_with_parent2(parent1, parent2)
	ZOOM_options parent1
	ZOOM_options parent2

const char *
ZOOM_options_get(opt, name)
	ZOOM_options opt
	const char* name

struct datachunk
ZOOM_options_getl(opt, name, len)
	ZOOM_options opt
	const char* name
	int &len
	CODE:
		RETVAL.data = (char*) ZOOM_options_getl(opt, name, &len);
		RETVAL.len = len;
	OUTPUT:
		RETVAL
		len

void
ZOOM_options_set(opt, name, v)
	ZOOM_options opt
	const char* name
	const char* v

void
ZOOM_options_setl(opt, name, value, len)
	ZOOM_options opt
	const char* name
	opaquechar* value
	int len

void
ZOOM_options_destroy(opt)
	ZOOM_options opt

int
ZOOM_options_get_bool(opt, name, defa)
	ZOOM_options opt
	const char* name
	int defa

int
ZOOM_options_get_int(opt, name, defa)
	ZOOM_options opt
	const char* name
	int defa

void
ZOOM_options_set_int(opt, name, value)
	ZOOM_options opt
	const char* name
	int value

ZOOM_package
ZOOM_connection_package(c, options)
	ZOOM_connection	c
	ZOOM_options	options

void
ZOOM_package_destroy(p)
	ZOOM_package	p

void
ZOOM_package_send(p, type)
	ZOOM_package	p
	const char *	type

const char *
ZOOM_package_option_get(p, key)
	ZOOM_package	p
	const char *	key

void
ZOOM_package_option_set(p, key, val)
	ZOOM_package	p
	const char *	key
	const char *	val

# This has to be called with a single argument which is a _reference_
# to an array -- rather than directly with an array, which is of
# course identical to passing arbitrarily many arguments.  This is
# because there doesn't seem to be a way to do varargs in an XS
# function.
#
int
ZOOM_event(conns)
	SV* conns
	INIT:
		SV *realconns;
		I32 n, i;
		ZOOM_connection *cs;
	CODE:
		/*printf("* in ZOOM_event(%p)\n", conns);*/
		if (!SvROK(conns)) {
			/*printf("* argument is not a reference\n");*/
			XSRETURN_IV(-1);
		}
		realconns = SvRV(conns);
		/*printf("* realconns = %p\n", realconns);*/
		if (SvTYPE(realconns) != SVt_PVAV) {
			/*printf("* reference is not to an array\n");*/
			XSRETURN_IV(-2);
		}
		n = av_len((AV*) realconns);
		n++; /* The av_len() return-value is zero-based */
		if (n == 0) {
			/*printf("* No connections in referenced array\n");*/
			XSRETURN_IV(-3);
		}

		/*printf("* n = %d\n", n);*/
		if ((cs = (ZOOM_connection*) malloc(n * sizeof *cs)) == 0) {
			/*printf("* Too many connections (%d)\n", (int) n);*/
			XSRETURN_IV(-4);
		}

		for (i = 0; i < n; i++) {
		    SV **connp = av_fetch((AV*) realconns, i, (I32) 0);
		    SV *conn, *sv;
		    /*printf("* %d of %d: connp = %p\n", (int) i, (int) n,connp);*/
		    assert(connp != 0);
		    conn = *connp;
		    /*printf("* conn = %p\n", conn);*/
		    /*
		     * From here on, the tests and assertions seem to
		     * be ignored: if I pass in a reference to
		     * something other than a ZOOM_connection, or even
		     * if I pass a non-reference, the assertions still
		     * pass and everything seems to work until the
		     * segmentation fault bites.
		     */
		    assert(sv_derived_from(conn, "ZOOM_connection"));
		    /*printf("* passed assert(isa(ZOOM_connection))\n");*/
		    assert(SvROK(conn));
		    /*printf("* passed assert SvROK()\n");*/
		    sv = (SV*) SvRV(conn);
		    /*printf("* sv = %p\n", sv);*/
		    cs[i] = INT2PTR(ZOOM_connection, SvIV(sv));
		    /*printf("got cs[%d] of %d = %p\n", (int) i, (int) n, cs[i]);*/
		}
		RETVAL = ZOOM_event((int) n, cs);
		free(cs);
	OUTPUT:
		RETVAL

int
ZOOM_connection_last_event(cs)
	ZOOM_connection	cs

int
ZOOM_connection_is_idle(cs)
	ZOOM_connection	cs

int
ZOOM_connection_peek_event(cs)
	ZOOM_connection	cs


# ----------------------------------------------------------------------------
# What follows is the YAZ logging API.  This is not strictly part of
# ZOOM, but it's so useful that it would be silly to omit.

int
yaz_log_mask_str(str)
	const char *str

int
yaz_log_module_level(name)
	const char *name

void
yaz_log_init(level, prefix, name)
	int level
	const char *prefix
	const char *name

void
yaz_log_init_file(fname)
	const char *fname

void
yaz_log_init_level(level)
	int level

void
yaz_log_init_prefix(prefix)
	const char *prefix

void
yaz_log_time_format(fmt)
	const char *fmt

void
yaz_log_init_max_size(mx)
	int mx

# <stdarg.h> interfaces are horrible to code for a Perl-C interface
# layer.  Instead, we expect Perl applications to construct the
# message themselves, and pass it in as an opaque lump.
void
yaz_log(level, str)
	int level
	const char *str
	CODE:
		yaz_log(level, "%s", str);

# This is also not strictly part of ZOOM
unsigned long
yaz_version(version_str, sys_str)
	char *version_str
	char *sys_str
	OUTPUT:
		RETVAL
		version_str
		sys_str

