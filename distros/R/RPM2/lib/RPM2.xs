#include <stdio.h>
#include <string.h>
#include <rpm/rpmcli.h>

#define RPM_VERSION(major,minor) (major*1000+minor)

#include <rpm/rpmts.h>
#include <rpm/rpmte.h>
#include <rpm/rpmdb.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Chip, this is somewhat stripped down from the default callback used by
   the rpmcli.  It has to be here to insure that we open the pkg again. 
   If we don't do this we get segfaults.  I also, kept the updating of some
   of the rpmcli static vars, but I may not have needed to do this.

   Also, we probably want to give a nice interface such that we could allow
   users of RPM2 to do their own callback, but that will have to come later.
*/
void * _null_callback(
	const void * arg, 
	const rpmCallbackType what,
	const rpm_loff_t amount,
	const rpm_loff_t total,
	fnpyKey key, 
	rpmCallbackData data)
{
	Header h = (Header) arg;
	int flags = (int) ((long)data);
	void * rc = NULL;
	const char * filename = (const char *)key;
	static FD_t fd = NULL;
	int xx;

	/* Code stolen from rpminstall.c and modified */
	switch(what) {
		case RPMCALLBACK_INST_OPEN_FILE:
	 		if (filename == NULL || filename[0] == '\0')
			     return NULL;
			fd = Fopen(filename, "r.ufdio");
			/* FIX: still necessary? */
			if (fd == NULL || Ferror(fd)) {
				fprintf(stderr, "open of %s failed!\n", filename);
				if (fd != NULL) {
					xx = Fclose(fd);
					fd = NULL;
				}
			} else
#if RPM2_API < RPM_VERSION(4,9)
				fd = fdLink(fd, "persist (showProgress)");
#else
				fd = fdLink(fd);
#endif
			return (void *)fd;
	 		break;

	case RPMCALLBACK_INST_CLOSE_FILE:
		/* FIX: still necessary? */
#if RPM2_API < RPM_VERSION(4,9)
				fd = fdFree(fd, "persist (showProgress)");
#else
				fd = fdFree(fd);
#endif
		if (fd != NULL) {
			xx = Fclose(fd);
			fd = NULL;
		}
		break;

	case RPMCALLBACK_INST_START:
		break;

	case RPMCALLBACK_TRANS_PROGRESS:
	case RPMCALLBACK_INST_PROGRESS:
		break;

	case RPMCALLBACK_TRANS_START:
		break;

	case RPMCALLBACK_TRANS_STOP:
		break;

	case RPMCALLBACK_REPACKAGE_START:
		break;

	case RPMCALLBACK_REPACKAGE_PROGRESS:
		break;

	case RPMCALLBACK_REPACKAGE_STOP:
		break;

	case RPMCALLBACK_UNINST_PROGRESS:
		break;
	case RPMCALLBACK_UNINST_START:
		break;
	case RPMCALLBACK_UNINST_STOP:
		break;
	case RPMCALLBACK_UNPACK_ERROR:
		break;
	case RPMCALLBACK_CPIO_ERROR:
		break;
	case RPMCALLBACK_UNKNOWN:
		break;
	default:
		break;
	}
	
	return rc;	
}

void
_populate_header_tags(HV *href)
{
    rpmtd names;
    const char *name;

    names = rpmtdNew();
    rpmTagGetNames(names, 1);
    while ((name = rpmtdNextString(names)) != NULL) {
        (void)hv_store(href, name, strlen(name),
            newSViv(rpmTagGetValue(name + strlen("RPMTAG_"))), 0);
    }
}

void
_populate_constant(HV *href, char *name, int val)
{
    (void)hv_store(href, name, strlen(name), newSViv(val), 0);
}

#define REGISTER_CONSTANT(name) _populate_constant(constants, #name, name)

MODULE = RPM2		PACKAGE = RPM2

PROTOTYPES: ENABLE
BOOT:
    {
	HV *header_tags, *constants;
	rpmReadConfigFiles(NULL, NULL);

	header_tags = perl_get_hv("RPM2::header_tag_map", TRUE);
	_populate_header_tags(header_tags);

	constants = perl_get_hv("RPM2::constants", TRUE);

	/* not the 'standard' way of doing perl constants, but a lot easier to maintain */
	REGISTER_CONSTANT(RPMVSF_DEFAULT);
	REGISTER_CONSTANT(RPMVSF_NOHDRCHK);
	REGISTER_CONSTANT(RPMVSF_NEEDPAYLOAD);
	REGISTER_CONSTANT(RPMVSF_NOSHA1HEADER);
	REGISTER_CONSTANT(RPMVSF_NOMD5HEADER);
	REGISTER_CONSTANT(RPMVSF_NODSAHEADER);
	REGISTER_CONSTANT(RPMVSF_NORSAHEADER);
	REGISTER_CONSTANT(RPMVSF_NOSHA1);
	REGISTER_CONSTANT(RPMVSF_NOMD5);
	REGISTER_CONSTANT(RPMVSF_NODSA);
	REGISTER_CONSTANT(RPMVSF_NORSA);
	REGISTER_CONSTANT(_RPMVSF_NODIGESTS);
	REGISTER_CONSTANT(_RPMVSF_NOSIGNATURES);
	REGISTER_CONSTANT(_RPMVSF_NOHEADER);
	REGISTER_CONSTANT(_RPMVSF_NOPAYLOAD);
	REGISTER_CONSTANT(TR_ADDED);
	REGISTER_CONSTANT(TR_REMOVED);
    }

double
rpm_api_version(pkg)
	char * pkg
    CODE:
	(void)pkg; /* Not used */
	int major = RPM2_API / 1000;
	double minor = (int)RPM2_API % 1000;
	while (minor >= 1) { minor /= 10; }
	RETVAL = major + minor;
    OUTPUT:
	RETVAL


void
add_macro(pkg, name, val)
	char * pkg
	char * name
	char * val
    CODE:
	(void)pkg; /* Not used */
	addMacro(NULL, name, NULL, val, RMIL_DEFAULT);

void
delete_macro(pkg, name)
	char * pkg
	char * name
    CODE:
	(void)pkg; /* Not used */
	delMacro(NULL, name);

void
expand_macro(pkg, str)
	char * pkg
	char * str
    PREINIT:
	char *ret;
    PPCODE:
	(void)pkg; /* Not used */
	ret = rpmExpand(str, NULL);
	PUSHs(sv_2mortal(newSVpv(ret, 0)));
	free(ret);

int
rpmvercmp(one, two)
	char* one
	char* two

void
_read_package_info(fp, vsflags)
	FILE *fp
	int vsflags
    PREINIT:
	rpmts ts;
	Header ret;
	rpmRC rc;
	FD_t fd;
    PPCODE:
	ts = rpmtsCreate();

        /* XXX Determine type of signature verification when reading
	vsflags |= _RPMTS_VSF_NOLEGACY;
	vsflags |= _RPMTS_VSF_NODIGESTS;
	vsflags |= _RPMTS_VSF_NOSIGNATURES;
	xx = rpmtsSetVerifySigFlags(ts, vsflags);
        */ 

	fd = fdDup(fileno(fp));
	rpmtsSetVSFlags(ts, vsflags);
	rc = rpmReadPackageFile(ts, fd, "filename or other identifier", &ret);

	Fclose(fd);

	if (rc == RPMRC_OK) {
	    SV *h_sv;

	    EXTEND(SP, 1);

	    h_sv = sv_newmortal();
            sv_setref_pv(h_sv, "RPM2::C::Header", (void *)ret);

	    PUSHs(h_sv);
	}
	else {
	    croak("error reading package");
	}
	ts = rpmtsFree(ts);

void
_create_transaction(vsflags)
	int vsflags
    PREINIT:
	rpmts ret;
	SV *h_sv;
    PPCODE:
	/* Looking at librpm, it does not look like this ever
	   returns error (though maybe it should).
	*/
	ret = rpmtsCreate();

	/* Should I save the old vsflags aside? */
	rpmtsSetVSFlags(ret, vsflags);

	/* Convert and throw the results on the stack */	
	EXTEND(SP, 1);

	h_sv = sv_newmortal();
	sv_setref_pv(h_sv, "RPM2::C::Transaction", (void *)ret);

	PUSHs(h_sv);

void
_read_from_file(fp)
	FILE *fp
PREINIT:
	SV *h_sv;
	FD_t fd;
	Header h;
PPCODE:
	fd = fdDup(fileno(fp));
	h = headerRead(fd, HEADER_MAGIC_YES);

	if (h) {
	    EXTEND(SP, 1);

	    h_sv = sv_newmortal();
	    sv_setref_pv(h_sv, "RPM2::C::Header", (void *)h);

	    PUSHs(h_sv);
	}
	Fclose(fd);

rpmts
_open_rpm_db(for_write)
	int   for_write
    PREINIT:
	 rpmts ts;
    CODE:
	ts = rpmtsCreate();
	if (rpmtsOpenDB(ts, for_write ? O_RDWR : O_RDONLY)) {
		croak("rpmtsOpenDB failed");
		RETVAL = NULL;
	}
	RETVAL = ts;
    OUTPUT:
	RETVAL

MODULE = RPM2		PACKAGE = RPM2::C::DB

void
DESTROY(ts)
	rpmts ts
    CODE:
	rpmtsCloseDB(ts);
	rpmtsFree(ts);

void
_close_rpm_db(self)
	rpmts self
    CODE:
	rpmtsCloseDB(self);
	rpmtsFree(self);

rpmdbMatchIterator
_init_iterator(ts, rpmtag, key, len)
	rpmts ts
	int rpmtag
	char *key
	size_t len
    CODE:
    /* See rpmtsInitIterator() code for explanation of this */
	if (rpmtag == RPMDBI_PACKAGES) {
		len = strlen (key);
	}

	RETVAL = rpmtsInitIterator(ts, rpmtag, len ? key : NULL, len);
    OUTPUT:
	RETVAL

MODULE = RPM2		PACKAGE = RPM2::C::PackageIterator
Header
_iterator_next(i)
	rpmdbMatchIterator i
    PREINIT:
	Header       ret;
        SV *         h_sv;
	unsigned int offset;
    PPCODE:
	ret = rpmdbNextIterator(i);
	if (ret)
		headerLink(ret);
	if(ret != NULL) 
		offset = rpmdbGetIteratorOffset(i);
	else
		offset = 0;
	
	EXTEND(SP, 2);
	h_sv = sv_newmortal();
	sv_setref_pv(h_sv, "RPM2::C::Header", (void *)ret);
	PUSHs(h_sv);
	PUSHs(sv_2mortal(newSViv(offset)));
        RETVAL = ret;

void
DESTROY(i)
	rpmdbMatchIterator i
    CODE:
	rpmdbFreeIterator(i);


MODULE = RPM2		PACKAGE = RPM2::C::Header

void
DESTROY(h)
	Header h
    CODE:
	headerFree(h);

void
tag_by_id(h, tag)
	Header h
	int tag
    PREINIT:
	rpmtd tagdata;
	int ok;
    PPCODE:
	tagdata = rpmtdNew();
	if (tagdata == NULL) {
		croak("Out of memory");
	}
	ok = headerGet(h, tag, tagdata, HEADERGET_DEFAULT);

	if (!ok) {
		/* nop, empty stack */
	}
	else {
		switch(tagdata->type)
		{
		case RPM_STRING_ARRAY_TYPE:
			{
			int i;
			char **s;

			EXTEND(SP, tagdata->count);
			s = (char **)tagdata->data;

			for (i = 0; i < tagdata->count; i++) {
				PUSHs(sv_2mortal(newSVpv(s[i], 0)));
			}
			}
			break;
		case RPM_STRING_TYPE:
			PUSHs(sv_2mortal(newSVpv((char *)tagdata->data, 0)));
			break;
		case RPM_CHAR_TYPE:
			{
			int i;
			char *r;

			EXTEND(SP, tagdata->count);
			r = (char *)tagdata->data;

			for (i = 0; i < tagdata->count; i++) {
				PUSHs(sv_2mortal(newSViv(r[i])));
			}
			}
			break;
		case RPM_INT8_TYPE:
			{
			int i;
			uint8_t *r;

			EXTEND(SP, tagdata->count);
			r = (uint8_t *)tagdata->data;

			for (i = 0; i < tagdata->count; i++) {
				PUSHs(sv_2mortal(newSViv(r[i])));
			}
			}
			break;
		case RPM_INT16_TYPE:
			{
			int i;
			uint16_t *r;

			EXTEND(SP, tagdata->count);
			r = (uint16_t *)tagdata->data;

			for (i = 0; i < tagdata->count; i++) {
				PUSHs(sv_2mortal(newSViv(r[i])));
			}
			}
			break;
		case RPM_INT32_TYPE:
			{
			int i;
			uint32_t *r;

			EXTEND(SP, tagdata->count);
			r = (uint32_t *)tagdata->data;

			for (i = 0; i < tagdata->count; i++) {
				PUSHs(sv_2mortal(newSViv(r[i])));
			}
			}
			break;
		default:
			croak("unknown rpm tag type %d", tagdata->type);
		}
	}
	rpmtdFreeData(tagdata);

int
_header_compare(h1, h2)
	Header h1
	Header h2
    CODE:
	RETVAL = rpmVersionCompare(h1, h2);
    OUTPUT:
        RETVAL

int
_header_is_source(h)
	Header h
    CODE:
	RETVAL = headerIsEntry(h, RPMTAG_SOURCEPACKAGE);
    OUTPUT:
	RETVAL

void
_header_sprintf(h, format)
	Header h
	char * format
    PREINIT:
	char * s;
    PPCODE:
	s =  headerFormat(h, format, NULL);
	PUSHs(sv_2mortal(newSVpv((char *)s, 0)));
/* By the way, the #if below is completely useless, free() would work for both */
	free(s);


MODULE = RPM2		PACKAGE = RPM2::C::Transaction

void
DESTROY(t)
	rpmts t
    CODE:
	t = rpmtsFree(t);

# XXX:  Add relocations some day. 
int
_add_install(t, h, fn, upgrade)
	rpmts  t
	Header h
	char * fn
	int    upgrade
    PREINIT:
	rpmRC rc = 0;
    CODE:
	rc = rpmtsAddInstallElement(t, h, (fnpyKey) fn, upgrade, NULL);
	RETVAL = (rc == RPMRC_OK) ? 1 : 0;
    OUTPUT:
	RETVAL	

int
_add_delete(t, h, offset)
	rpmts        t
	Header       h
	unsigned int offset
    PREINIT:
	rpmRC rc = 0;
    CODE:
	rc = rpmtsAddEraseElement(t, h, offset);
	RETVAL = (rc == RPMRC_OK) ? 1 : 0;
    OUTPUT:
	RETVAL	

int
_element_count(t)
	rpmts t
PREINIT:
	int ret;
CODE:
	ret    = rpmtsNElements(t);
	RETVAL = ret;
OUTPUT:
	RETVAL

int
_close_db(t)
	rpmts t
PREINIT:
	int ret;
CODE:
	ret    = rpmtsCloseDB(t);
	RETVAL = (ret == 0) ? 1 : 0;
OUTPUT:
	RETVAL

int
_check(t)
	rpmts t
PREINIT:
	int ret;
CODE:
	ret    = rpmtsCheck(t);
	RETVAL = (ret == 0) ? 1 : 0;
OUTPUT:
	RETVAL

int
_order(t)
	rpmts t
PREINIT:
	int ret;
CODE:
	ret    = rpmtsOrder(t);
	/* XXX:  May want to do something different here.  It actually
	         returns the number of non-ordered elements...maybe we
	         want this?
	*/
	RETVAL = (ret == 0) ? 1 : 0;
OUTPUT:
	RETVAL

void
_elements(t, type)
	rpmts t;
	rpmElementType type;
PREINIT:
	rpmtsi       i;
	rpmte        te;
	const char * NEVR;
PPCODE:
	i = rpmtsiInit(t);
	if(i == NULL) {
		printf("Did not get a thing!\n");
		return;	
	} else {
		while((te = rpmtsiNext(i, type)) != NULL) {
			NEVR = rpmteNEVR(te);
			XPUSHs(sv_2mortal(newSVpv(NEVR,	0)));
		}
		i = rpmtsiFree(i);
	}

int
_run(t, ok_probs, prob_filter)
	rpmts t
	rpmprobFilterFlags prob_filter 
    PREINIT:
	int ret;
    CODE:
	/* Make sure we could run this transactions */
	ret = rpmtsCheck(t);
	if (ret != 0) {
		RETVAL = 0;
		return;
	}
	ret = rpmtsOrder(t);
	if (ret != 0) {
		RETVAL = 0;
		return;
	}

	/* XXX:  Should support callbacks eventually */
	(void) rpmtsSetNotifyCallback(t, _null_callback, (void *) ((long)0));
	ret    = rpmtsRun(t, NULL, prob_filter);
	RETVAL = (ret == 0) ? 1 : 0;
    OUTPUT:
	RETVAL


