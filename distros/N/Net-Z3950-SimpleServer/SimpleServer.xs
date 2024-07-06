/* This file is part of simpleserver.
 * Copyright (C) 2000-2017 Index Data.
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Index Data nor the names of its contributors
 *       may be used to endorse or promote products derived from this
 *       software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE REGENTS AND CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

// This pragma inhibits 436 vacuous warnings
// See https://blogs.perl.org/users/tom_wyant/2022/03/xs-versus-clang-infinite-warnings.html
#if defined(__clang__) && defined(__clang_major__) && __clang_major__ > 11
#pragma clang diagnostic ignored "-Wcompound-token-split-by-macro"
#endif

#include "EXTERN.h"
#include "perl.h"
#include "proto.h"
#include "embed.h"
#include "XSUB.h"
#include <assert.h>
#include <yaz/backend.h>
#include <yaz/facet.h>
#include <yaz/log.h>
#include <yaz/wrbuf.h>
#include <yaz/pquery.h>
#include <yaz/querytowrbuf.h>
#include <stdio.h>
#include <yaz/mutex.h>
#include <yaz/oid_db.h>
#include <yaz/yaz-version.h>
#ifdef WIN32
#else
#include <unistd.h>
#endif
#include <stdlib.h>
#include <ctype.h>
#define GRS_MAX_FIELDS 500
#ifdef ASN_COMPILED
#include <yaz/ill.h>
#endif
#ifndef sv_undef		/* To fix the problem with Perl 5.6.0 */
#define sv_undef PL_sv_undef
#endif

YAZ_MUTEX simpleserver_mutex;

typedef struct {
	SV *ghandle;	/* Global handle specified at creation */
	SV *handle;	/* Per-connection handle set at Init */
	NMEM nmem;
	int stop_flag;  /* is used to stop server prematurely .. */
} Zfront_handle;

#define ENABLE_STOP_SERVER 0

SV *_global_ghandle = NULL; /* To be copied into zhandle then ignored */
SV *init_ref = NULL;
SV *close_ref = NULL;
SV *sort_ref = NULL;
SV *search_ref = NULL;
SV *fetch_ref = NULL;
SV *present_ref = NULL;
SV *esrequest_ref = NULL;
SV *delete_ref = NULL;
SV *scan_ref = NULL;
SV *explain_ref = NULL;
SV *start_ref = NULL;
PerlInterpreter *root_perl_context;

#define GRS_BUF_SIZE 8192


/*
 * Inspects the SV indicated by svp, and returns a null pointer if
 * it's an undefined value, or a string allocation from `stream'
 * otherwise.  Using this when filling in addinfo avoids those
 * irritating "Use of uninitialized value in subroutine entry"
 * warnings from Perl.
 */
char *string_or_undef(SV **svp, ODR stream) {
	STRLEN len;
	char *ptr;

	if (!SvOK(*svp))
		return 0;

	ptr = SvPV(*svp, len);
	return odr_strdupn(stream, ptr, len);
}


CV * simpleserver_sv2cv(SV *handler) {
    STRLEN len;
    char *buf;

    if (SvPOK(handler)) {
	CV *ret;
	buf = SvPV( handler, len);
	if ( !( ret = perl_get_cv(buf, FALSE ) ) ) {
	    fprintf( stderr, "simpleserver_sv2cv: No such handler '%s'\n\n", buf );
	    exit(1);
	}

	return ret;
    } else {
	return (CV *) handler;
    }
}

/* debugging routine to check for destruction of Perl interpreters */
#ifdef USE_ITHREADS
void tst_clones(void)
{
    int i;
    PerlInterpreter *parent = PERL_GET_CONTEXT;
    for (i = 0; i<5000; i++)
    {
        PerlInterpreter *perl_interp;

	PERL_SET_CONTEXT(parent);
	PL_perl_destruct_level = 2;
        perl_interp = perl_clone(parent, CLONEf_CLONE_HOST);
	PL_perl_destruct_level = 2;
	PERL_SET_CONTEXT(perl_interp);
        perl_destruct(perl_interp);
        perl_free(perl_interp);
    }
    exit (0);
}
#endif

int simpleserver_clone(void) {
#ifdef USE_ITHREADS
     yaz_mutex_enter(simpleserver_mutex);
     if (1)
     {
         PerlInterpreter *current = PERL_GET_CONTEXT;

	 /* if current is unset, then we're in a new thread with
	  * no Perl interpreter for it. So we must create one .
	  * This will only happen when threaded is used..
	  */
         if (!current) {
             PerlInterpreter *perl_interp;
             PERL_SET_CONTEXT( root_perl_context );
             perl_interp = perl_clone(root_perl_context, CLONEf_CLONE_HOST);
             PERL_SET_CONTEXT( perl_interp );
         }
     }
     yaz_mutex_leave(simpleserver_mutex);
#endif
     return 0;
}


void simpleserver_free(void) {
    yaz_mutex_enter(simpleserver_mutex);
    if (1)
    {
        PerlInterpreter *current_interp = PERL_GET_CONTEXT;

	/* If current Perl Interp is different from root interp, then
	 * we're in threaded mode and we must destroy..
	 */
	if (current_interp != root_perl_context) {
       	    PL_perl_destruct_level = 2;
            PERL_SET_CONTEXT(current_interp);
            perl_destruct(current_interp);
            perl_free(current_interp);
	}
    }
    yaz_mutex_leave(simpleserver_mutex);
}


Z_GenericRecord *read_grs1(char *str, ODR o)
{
	int type, ivalue;
	char line[GRS_BUF_SIZE+1], *buf, *ptr, *original;
	char value[GRS_BUF_SIZE+1];
 	Z_GenericRecord *r = 0;

	original = str;
	r = (Z_GenericRecord *)odr_malloc(o, sizeof(*r));
	r->elements = (Z_TaggedElement **)
		odr_malloc(o, sizeof(Z_TaggedElement*) * GRS_MAX_FIELDS);
	r->num_elements = 0;

	for (;;)
	{
		Z_TaggedElement *t;
		Z_ElementData *c;
		int len;

		ptr = strchr(str, '\n');
		if (!ptr) {
			return r;
		}
		len = ptr - str;
		if (len > GRS_BUF_SIZE) {
		    yaz_log(YLOG_WARN, "GRS string too long - truncating (%d > %d)", len, GRS_BUF_SIZE);
		    len = GRS_BUF_SIZE;
		}
		strncpy(line, str, len);
		line[len] = 0;
		buf = line;
		str = ptr + 1;
		while (*buf && isspace(*buf))
			buf++;
		if (*buf == '}') {
			memmove(original, str, strlen(str));
			return r;
		}
		if (sscanf(buf, "(%d,%[^)])", &type, value) != 2)
		{
			yaz_log(YLOG_WARN, "Bad data in '%s'", buf);
			return r;
		}
		if (!type && *value == '0')
			return r;
		if (!(buf = strchr(buf, ')')))
			return r;
		buf++;
		while (*buf && isspace(*buf))
			buf++;
		if (r->num_elements >= GRS_MAX_FIELDS)
		{
			yaz_log(YLOG_WARN, "Max number of GRS-1 elements exceeded [GRS_MAX_FIELDS=%d]", GRS_MAX_FIELDS);
			exit(0);
		}
		r->elements[r->num_elements] = t = (Z_TaggedElement *)
			odr_malloc(o, sizeof(Z_TaggedElement));
		t->tagType = odr_intdup(o, type);
		t->tagValue = (Z_StringOrNumeric *)
			odr_malloc(o, sizeof(Z_StringOrNumeric));
		if ((ivalue = atoi(value)))
		{
			t->tagValue->which = Z_StringOrNumeric_numeric;
			t->tagValue->u.numeric = odr_intdup(o, ivalue);
		}
		else
		{
			t->tagValue->which = Z_StringOrNumeric_string;
			t->tagValue->u.string = odr_strdup(o, value);
		}
		t->tagOccurrence = 0;
		t->metaData = 0;
		t->appliedVariant = 0;
		t->content = c = (Z_ElementData *)
			odr_malloc(o, sizeof(Z_ElementData));
		if (*buf == '{')
		{
			c->which = Z_ElementData_subtree;
			c->u.subtree = read_grs1(str, o);
		}
		else
		{
			c->which = Z_ElementData_string;
			c->u.string = odr_strdup(o, buf);
		}
		r->num_elements++;
	}
}



static void oid2str(Odr_oid *o, WRBUF buf)
{
    for (; *o >= 0; o++) {
	char ibuf[16];
	sprintf(ibuf, "%d", *o);
	wrbuf_puts(buf, ibuf);
	if (o[1] > 0)
	    wrbuf_putc(buf, '.');
    }
}

WRBUF oid2dotted(Odr_oid *oid)
{
    WRBUF buf = wrbuf_alloc();
    oid2str(oid, buf);
    return buf;
}


WRBUF zquery2pquery(Z_Query *q)
{
    WRBUF buf = wrbuf_alloc();

    if (q->which != Z_Query_type_1 && q->which != Z_Query_type_101)
	return 0;
    yaz_rpnquery_to_wrbuf(buf, q->u.type_1);
    return buf;
}


/* Lifted verbatim from Net::Z3950 yazwrap/util.c */
#include <stdarg.h>
void fatal(char *fmt, ...)
{
    va_list ap;

    fprintf(stderr, "FATAL (SimpleServer): ");
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);
    fprintf(stderr, "\n");
    abort();
}


/* Lifted verbatim from Net::Z3950 yazwrap/receive.c */
/*
 * Creates a new Perl object of type `class'; the newly-created scalar
 * that is a reference to the blessed thingy `referent' is returned.
 */
static SV *newObject(char *class, SV *referent)
{
    HV *stash;
    SV *sv;

    sv = newRV_noinc((SV*) referent);
    stash = gv_stashpv(class, 0);
    if (stash == 0)
	fatal("attempt to create object of undefined class '%s'", class);
    /*assert(stash != 0);*/
    sv_bless(sv, stash);
    return sv;
}


/* Lifted verbatim from Net::Z3950 yazwrap/receive.c */
static void setMember(HV *hv, char *name, SV *val)
{
    /* We don't increment `val's reference count -- I think this is
     * right because it's created with a refcount of 1, and in fact
     * the reference via this hash is the only reference to it in
     * general.
     */
    if (!hv_store(hv, name, (U32) strlen(name), val, (U32) 0))
	fatal("couldn't store member in hash");
}


/* Lifted verbatim from Net::Z3950 yazwrap/receive.c */
static SV *translateOID(Odr_oid *x)
{
    /* Yaz represents an OID by an int array terminated by a negative
     * value, typically -1; we represent it as a reference to a
     * blessed scalar string of "."-separated elements.
     */
    char buf[1000];
    int i;

    *buf = '\0';
    for (i = 0; x[i] >= 0; i++) {
	sprintf(buf + strlen(buf), "%d", (int) x[i]);
	if (x[i+1] >- 0)
	    strcat(buf, ".");
    }

    /*
     * ### We'd like to return a blessed scalar (string) here, but of
     *	course you can't do that in Perl: only references can be
     *	blessed, so we'd have to return a _reference_ to a string, and
     *	bless _that_.  Better to do without the blessing, I think.
     */
    if (1) {
	return newSVpv(buf, 0);
    } else {
	return newObject("Net::Z3950::APDU::OID", newSVpv(buf, 0));
    }
}

static SV *attributes2perl(Z_AttributeList *list)
{
    AV *av;
	int i;
	SV *attrs = newObject("Net::Z3950::RPN::Attributes",
			      (SV*) (av = newAV()));
	for (i = 0; i < list->num_attributes; i++) {
	    Z_AttributeElement *elem = list->attributes[i];
	    HV *hv2;
	    SV *tmp = newObject("Net::Z3950::RPN::Attribute",
				(SV*) (hv2 = newHV()));
	    if (elem->attributeSet)
		setMember(hv2, "attributeSet",
			  translateOID(elem->attributeSet));
	    setMember(hv2, "attributeType",
		      newSViv(*elem->attributeType));
	    if (elem->which == Z_AttributeValue_numeric) {
		setMember(hv2, "attributeValue",
			  newSViv(*elem->value.numeric));
	    } else {
		Z_ComplexAttribute *c;
		Z_StringOrNumeric *son;
		assert(elem->which == Z_AttributeValue_complex);
		c = elem->value.complex;
		/* We ignore semantic actions and multiple values */
		assert(c->num_list > 0);
		son = c->list[0];
		if (son->which == Z_StringOrNumeric_numeric) {
		    setMember(hv2, "attributeValue",
			      newSViv(*son->u.numeric));
		} else { /*Z_StringOrNumeric_string*/
		    setMember(hv2, "attributeValue",
			      newSVpv(son->u.string, 0));
		}
	    }
	    av_push(av, tmp);
	}
	return attrs;
}

static SV *f_Term_to_SV(Z_Term *term, Z_AttributeList *attributes)
{
	HV *hv;
	SV *sv = newObject("Net::Z3950::RPN::Term", (SV*) (hv = newHV()));

	if (term->which != Z_Term_general)
		fatal("can't handle RPN terms other than general");

        setMember(hv, "term", newSVpv((char*) term->u.general->buf,
				  term->u.general->len));

	if (attributes) {
		setMember(hv, "attributes", attributes2perl(attributes));
	}
	return sv;
}

static SV *rpn2perl(Z_RPNStructure *s)
{
    SV *sv;
    HV *hv;
    AV *av;
    Z_Operand *o;

    switch (s->which) {
    case Z_RPNStructure_simple:
	o = s->u.simple;
	switch (o->which) {
	case Z_Operand_resultSetId: {
	    /* This code causes a SIGBUS on my machine, and I have no
	       idea why.  It seems as clear as day to me */
	    SV *sv2;
	    char *rsid = (char*) o->u.resultSetId;
	    /*printf("Encoding resultSetId '%s'\n", rsid);*/
	    sv = newObject("Net::Z3950::RPN::RSID", (SV*) (hv = newHV()));
	    /*printf("Made sv=0x%lx, hv=0x%lx\n", (unsigned long) sv ,(unsigned long) hv);*/
	    sv2 = newSVpv(rsid, strlen(rsid));
	    setMember(hv, "id", sv2);
	    /*printf("Set hv{id} to 0x%lx\n", (unsigned long) sv2);*/
	    return sv;
	}

	case  Z_Operand_APT:
	    return f_Term_to_SV(o->u.attributesPlusTerm->term,
			o->u.attributesPlusTerm->attributes);
	default:
	    fatal("unknown RPN simple type %d", (int) o->which);
	}

    case Z_RPNStructure_complex: {
	SV *tmp;
	Z_Complex *c = s->u.complex;
	char *type = 0;		/* vacuous assignment satisfies gcc -Wall */
	switch (c->roperator->which) {
	case Z_Operator_and:     type = "Net::Z3950::RPN::And";    break;
	case Z_Operator_or:      type = "Net::Z3950::RPN::Or";     break;
	case Z_Operator_and_not: type = "Net::Z3950::RPN::AndNot"; break;
	case Z_Operator_prox:    type = "Net::Z3950::RPN::Prox"; break;
	default: fatal("unknown RPN operator %d", (int) c->roperator->which);
	}
	sv = newObject(type, (SV*) (av = newAV()));
	if ((tmp = rpn2perl(c->s1)) == 0)
	    return 0;
	av_push(av, tmp);
	if ((tmp = rpn2perl(c->s2)) == 0)
	    return 0;
	av_push(av, tmp);
	if (c->roperator->which == Z_Operator_prox) {
		Z_ProximityOperator prox = *c->roperator->u.prox;
		HV *hv;
		tmp = newObject("Net::Z3950::RPN::Prox::Attributes", (SV*) (hv = newHV()));
		setMember(hv, "exclusion", newSViv(*prox.exclusion));
		setMember(hv, "distance", newSViv(*prox.distance));
		setMember(hv, "ordered", newSViv(*prox.ordered));
		setMember(hv, "relationType", newSViv(*prox.relationType));
		if (prox.which == Z_ProximityOperator_known) {
			setMember(hv, "known", newSViv(*prox.u.known));
		} else {
			setMember(hv, "zprivate", newSViv(*prox.u.zprivate));
		}
		av_push(av, tmp);
	}
	return sv;
    }

    default:
	fatal("unknown RPN node type %d", (int) s->which);
    }

    return 0;
}


/* Decode the Z_SortAttributes struct and store the whole thing into the
 * hash by reference
 */
int simpleserver_ExpandSortAttributes (HV *sort_spec, Z_SortAttributes *sattr)
{
    WRBUF attrset_wr = wrbuf_alloc();
    AV *list = newAV();
    Z_AttributeList *attr_list = sattr->list;
    int i;

    oid2str(sattr->id, attrset_wr);
    hv_store(sort_spec, "ATTRSET", 7,
             newSVpv(attrset_wr->buf, attrset_wr->pos), 0);
    wrbuf_destroy(attrset_wr);

    hv_store(sort_spec, "SORT_ATTR", 9, newRV( sv_2mortal( (SV*) list ) ), 0);

    for (i = 0; i < attr_list->num_attributes; i++)
    {
        Z_AttributeElement *attr = *attr_list->attributes++;
        HV *attr_spec = newHV();

        av_push(list, newRV( sv_2mortal( (SV*) attr_spec ) ));
        hv_store(attr_spec, "ATTR_TYPE", 9, newSViv(*attr->attributeType), 0);

        if (attr->which == Z_AttributeValue_numeric)
        {
            hv_store(attr_spec, "ATTR_VALUE", 10,
                     newSViv(*attr->value.numeric), 0);
        } else {
            return 0;
        }
    }

    return 1;
}


/* Decode the Z_SortKeySpec struct and store the whole thing in a perl hash */
int simpleserver_SortKeySpecToHash (HV *sort_spec, Z_SortKeySpec *spec)
{
    Z_SortElement *element = spec->sortElement;

    hv_store(sort_spec, "RELATION", 8, newSViv(*spec->sortRelation), 0);
    hv_store(sort_spec, "CASE", 4, newSViv(*spec->caseSensitivity), 0);
    hv_store(sort_spec, "MISSING", 7, newSViv(spec->which), 0);

    if (element->which == Z_SortElement_generic)
    {
        Z_SortKey *key = element->u.generic;

        if (key->which == Z_SortKey_sortField)
        {
            hv_store(sort_spec, "SORTFIELD", 9,
                     newSVpv((char *) key->u.sortField, 0), 0);
        }
        else if (key->which == Z_SortKey_elementSpec)
        {
            Z_Specification *zspec = key->u.elementSpec;

            hv_store(sort_spec, "ELEMENTSPEC_TYPE", 16,
                     newSViv(zspec->which), 0);

            if (zspec->which == Z_Schema_oid)
            {
                WRBUF elementSpec = wrbuf_alloc();

                oid2str(zspec->schema.oid, elementSpec);
                hv_store(sort_spec, "ELEMENTSPEC_VALUE", 17,
                         newSVpv(elementSpec->buf, elementSpec->pos), 0);
                wrbuf_destroy(elementSpec);
            }
            else if (zspec->which == Z_Schema_uri)
            {
                hv_store(sort_spec, "ELEMENTSPEC_VALUE", 17,
                         newSVpv((char *) zspec->schema.uri, 0), 0);
            }
        }
        else if (key->which == Z_SortKey_sortAttributes)
        {
            return simpleserver_ExpandSortAttributes(sort_spec,
                                                     key->u.sortAttributes);
        }
        else
        {
            return 0;
        }
    }
    else
    {
        return 0;
    }

    return 1;
}


static SV *zquery2perl(Z_Query *q)
{
    SV *sv;
    HV *hv;

    if (q->which != Z_Query_type_1 && q->which != Z_Query_type_101)
	return 0;
    sv = newObject("Net::Z3950::APDU::Query", (SV*) (hv = newHV()));
    if (q->u.type_1->attributeSetId)
	setMember(hv, "attributeSet",
		  translateOID(q->u.type_1->attributeSetId));
    setMember(hv, "query", rpn2perl(q->u.type_1->RPNStructure));
    return sv;
}


int bend_sort(void *handle, bend_sort_rr *rr)
{
	HV *href;
	AV *aref;
        AV *sort_seq;
	SV **temp;
	SV *err_code;
	SV *err_str;
	SV *status;
        SV *point;
	STRLEN len;
	char *ptr;
	char **input_setnames;
	Zfront_handle *zhandle = (Zfront_handle *)handle;
        Z_SortKeySpecList *sort_spec = rr->sort_sequence;
	int i;

	dSP;
	ENTER;
	SAVETMPS;

	aref = newAV();
	input_setnames = rr->input_setnames;
	for (i = 0; i < rr->num_input_setnames; i++)
	{
            av_push(aref, newSVpv(*input_setnames++, 0));
	}

        sort_seq = newAV();
        for (i = 0; i < sort_spec->num_specs; i++)
        {
            Z_SortKeySpec *spec = *sort_spec->specs++;
            HV *sort_spec = newHV();

            if ( simpleserver_SortKeySpecToHash(sort_spec, spec) )
                av_push(sort_seq, newRV( sv_2mortal( (SV*) sort_spec ) ));
            else
            {
                rr->errcode = 207;
                return 0;
            }
        }

	href = newHV();
	hv_store(href, "INPUT", 5, newRV( (SV*) aref), 0);
	hv_store(href, "OUTPUT", 6, newSVpv(rr->output_setname, 0), 0);
        hv_store(href, "SEQUENCE", 8, newRV( (SV*) sort_seq), 0);
	hv_store(href, "GHANDLE", 7, newSVsv(zhandle->ghandle), 0);
	hv_store(href, "HANDLE", 6, zhandle->handle, 0);
	hv_store(href, "STATUS", 6, newSViv(0), 0);
        hv_store(href, "ERR_CODE", 8, newSViv(0), 0);
        hv_store(href, "ERR_STR", 7, newSVpv("", 0), 0);

	PUSHMARK(sp);

	XPUSHs(sv_2mortal(newRV( (SV*) href)));

	PUTBACK;

	perl_call_sv(sort_ref, G_SCALAR | G_DISCARD);

	SPAGAIN;

	temp = hv_fetch(href, "ERR_CODE", 8, 1);
	err_code = newSVsv(*temp);

	temp = hv_fetch(href, "ERR_STR", 7, 1);
	err_str = newSVsv(*temp);

	temp = hv_fetch(href, "STATUS", 6, 1);
	status = newSVsv(*temp);

        temp = hv_fetch(href, "HANDLE", 6, 1);
        point = newSVsv(*temp);

	hv_undef(href);
	av_undef(aref);
        av_undef(sort_seq);

	sv_free( (SV*) aref);
	sv_free( (SV*) href);
	sv_free( (SV*) sort_seq);

	rr->errcode = SvIV(err_code);
	rr->sort_status = SvIV(status);

	ptr = SvPV(err_str, len);
	rr->errstring = odr_strdupn(rr->stream, ptr, len);
        zhandle->handle = point;

	sv_free(err_code);
	sv_free(err_str);
	sv_free(status);

        PUTBACK;
	FREETMPS;
	LEAVE;

	return 0;
}

static SV *f_FacetField_to_SV(Z_FacetField *facet_field)
{
	HV *hv;
	AV *av;
	SV *terms;
	int i;
	SV *sv = newObject("Net::Z3950::FacetField", (SV *) (hv = newHV()));
	if (facet_field->attributes) {
                setMember(hv, "attributes",
                     attributes2perl(facet_field->attributes));
        }
	terms = newObject("Net::Z3950::FacetTerms", (SV *) (av = newAV()));

	for (i = 0; i < facet_field->num_terms; i++) {
	    Z_Term *z_term = facet_field->terms[i]->term;
            HV *hv;
	    SV *sv_count = newSViv(*facet_field->terms[i]->count);
	    SV *sv_term = 0;
	    SV *tmp;
	    if (z_term->which == Z_Term_general) {
	        sv_term = newSVpv((char*) z_term->u.general->buf,
	                           z_term->u.general->len);
            } else if (z_term->which == Z_Term_characterString) {
                sv_term = newSVpv(z_term->u.characterString,
		                  strlen(z_term->u.characterString));
            }
	    tmp = newObject("Net::Z3950::FacetTerm", (SV *) (hv = newHV()));

	    setMember(hv, "count", sv_count);
	    if (sv_term) {
	        setMember(hv, "term", sv_term);
	    }
	    av_push(av, tmp);
	}
	setMember(hv, "terms", terms);
	return sv;
}

static SV *f_FacetList_to_SV(Z_FacetList *facet_list)
{
	SV *sv = 0;
	if (facet_list) {
		AV *av;
		int i;
		sv = newObject("Net::Z3950::FacetList", (SV *) (av = newAV()));

		for (i = 0; i < facet_list->num; i++) {
		       SV *sv = f_FacetField_to_SV(facet_list->elements[i]);
		       av_push(av, sv);
		}
	}
	return sv;
}


static void f_SV_to_FacetField(HV *facet_field_hv, Z_FacetField **fl, ODR odr)
{
	int i;
	int num_terms, num_attributes;
        SV **temp;
	Z_AttributeList *attributes = odr_malloc(odr, sizeof(*attributes));

        AV *sv_terms, *sv_attributes;

	temp = hv_fetch(facet_field_hv, "attributes", 10, 1);
	sv_attributes = (AV *) SvRV(*temp);
	num_attributes = av_len(sv_attributes) + 1;
	attributes->num_attributes = num_attributes;
	attributes->attributes = (Z_AttributeElement **)
	     odr_malloc(odr, sizeof(*attributes->attributes) * num_attributes);

	for (i = 0; i < num_attributes; i++) {
            HV *hv_elem = (HV*) SvRV(sv_2mortal(av_shift(sv_attributes)));
            Z_AttributeElement *elem;
	    elem = (Z_AttributeElement *) odr_malloc(odr, sizeof(*elem));
	    attributes->attributes[i] = elem;

	    elem->attributeSet = 0;

  	    temp = hv_fetch(hv_elem, "attributeType", 13, 1);
   	    elem->attributeType = odr_intdup(odr, SvIV(*temp));

  	    temp = hv_fetch(hv_elem, "attributeValue", 14, 1);

	    if (SvIOK(*temp)) {
	    	    elem->which = Z_AttributeValue_numeric;
	            elem->value.numeric = odr_intdup(odr, SvIV(*temp));
            } else {
                    STRLEN s_len;
	            char *s_buf = SvPV(*temp, s_len);
	            Z_ComplexAttribute *c = odr_malloc(odr, sizeof *c);
	    	    elem->which = Z_AttributeValue_complex;
		    elem->value.complex = c;

		    c->num_list = 1;
		    c->list = (Z_StringOrNumeric **) odr_malloc(odr,
		          sizeof(*c->list));
	            c->list[0] = (Z_StringOrNumeric *) odr_malloc(odr,
                          sizeof(**c->list));
	            c->list[0]->which = Z_StringOrNumeric_string;
		    c->list[0]->u.string = odr_strdupn(odr, s_buf, s_len);
		    c->num_semanticAction = 0;
		    c->semanticAction = 0;
            }
	    hv_undef(hv_elem);
        }

	temp = hv_fetch(facet_field_hv, "terms", 5, 0);
	if (!temp) {
	  num_terms = 0;
	} else {
	  sv_terms = (AV *) SvRV(*temp);
	  if (SvTYPE(sv_terms) == SVt_PVAV) {
  	    num_terms = av_len(sv_terms) + 1;
	  } else {
            num_terms = 0;
	  }
	}
	*fl = facet_field_create(odr, attributes, num_terms);
	for (i = 0; i < num_terms; i++) {
	    STRLEN s_len;
            char *s_buf;
            HV *hv_elem = (HV*) SvRV(sv_2mortal(av_shift(sv_terms)));

	    Z_FacetTerm *facet_term =
	     (Z_FacetTerm *) odr_malloc(odr, sizeof(*facet_term));
	    (*fl)->terms[i] = facet_term;

  	    temp = hv_fetch(hv_elem, "count", 5, 1);
	    facet_term->count = odr_intdup(odr, SvIV(*temp));

  	    temp = hv_fetch(hv_elem, "term", 4, 1);

            s_buf = SvPV(*temp, s_len);
	    facet_term->term = z_Term_create(odr, Z_Term_general, s_buf, s_len);
	    hv_undef(hv_elem);
	}
}

static void f_SV_to_FacetList(SV *sv, Z_OtherInformation **oip, ODR odr)
{
	AV *entries = (AV *) SvRV(sv);
	int num_facets;
	if (entries && SvTYPE(entries) == SVt_PVAV &&
       		(num_facets = av_len(entries) + 1) > 0)
 	{
            Z_OtherInformation *oi;
            Z_OtherInformationUnit *oiu;
	    Z_FacetList *facet_list = facet_list_create(odr, num_facets);
	    int i;
	    for (i = 0; i < num_facets; i++) {
	        HV *facet_field = (HV*) SvRV(sv_2mortal(av_shift(entries)));
	    	f_SV_to_FacetField(facet_field, &facet_list->elements[i], odr);
		hv_undef(facet_field);
	    }
            oi = odr_malloc(odr, sizeof(*oi));
            oiu = odr_malloc(odr, sizeof(*oiu));
            oi->num_elements = 1;
            oi->list = odr_malloc(odr, oi->num_elements * sizeof(*oi->list));
            oiu->category = 0;
            oiu->which = Z_OtherInfo_externallyDefinedInfo;
            oiu->information.externallyDefinedInfo = odr_malloc(odr, sizeof(*oiu->information.externallyDefinedInfo));
            oiu->information.externallyDefinedInfo->direct_reference = odr_oiddup(odr, yaz_oid_userinfo_facet_1);
            oiu->information.externallyDefinedInfo->descriptor = 0;
            oiu->information.externallyDefinedInfo->indirect_reference = 0;
            oiu->information.externallyDefinedInfo->which = Z_External_userFacets;
            oiu->information.externallyDefinedInfo->u.facetList = facet_list;
            oi->list[0] = oiu;
            *oip = oi;
	}
}

static HV *parse_extra_args(Z_SRW_extra_arg *args)
{
	HV *href = newHV();

	for (; args; args = args->next)
	{
		hv_store(href, args->name, strlen(args->name),
			newSVpv(args->value, 0), 0);
	}
	return href;
}

int bend_search(void *handle, bend_search_rr *rr)
{
	HV *href;
	AV *aref;
	SV **temp;
	int i;
	char **basenames;
	WRBUF query;
	SV *point;
	Zfront_handle *zhandle = (Zfront_handle *)handle;
	CV* handler_cv = 0;
	SV *rpnSV;
	SV *facetSV;
	char *ptr;
	STRLEN len;

	dSP;
	ENTER;
	SAVETMPS;

	aref = newAV();
	basenames = rr->basenames;
	for (i = 0; i < rr->num_bases; i++)
	{
		av_push(aref, newSVpv(*basenames++, 0));
	}
#if ENABLE_STOP_SERVER
	if (rr->num_bases == 1 && !strcmp(rr->basenames[0], "XXstop"))
	{
		zhandle->stop_flag = 1;
	}
#endif
	href = newHV();

	hv_store(href, "SETNAME", 7, newSVpv(rr->setname, 0), 0);
	if (rr->srw_sortKeys && *rr->srw_sortKeys)
	    hv_store(href, "SRW_SORTKEYS", 12, newSVpv(rr->srw_sortKeys, 0), 0);
	hv_store(href, "REPL_SET", 8, newSViv(rr->replace_set), 0);
	hv_store(href, "ERR_CODE", 8, newSViv(0), 0);
	hv_store(href, "ERR_STR", 7, newSVpv("", 0), 0);
	hv_store(href, "HITS", 4, newSViv(0), 0);
	hv_store(href, "DATABASES", 9, newRV( (SV*) aref), 0);
	hv_store(href, "GHANDLE", 7, newSVsv(zhandle->ghandle), 0);
	hv_store(href, "HANDLE", 6, zhandle->handle, 0);
	hv_store(href, "PID", 3, newSViv(getpid()), 0);
	hv_store(href, "PRESENT_NUMBER", 14, newSViv(rr->present_number), 0);
	hv_store(href, "EXTRA_ARGS", 10,
		newRV( (SV*) parse_extra_args(rr->extra_args)), 0);
	if ((rpnSV = zquery2perl(rr->query)) != 0) {
	    hv_store(href, "RPN", 3, rpnSV, 0);
	}
	facetSV = f_FacetList_to_SV(yaz_oi_get_facetlist(&rr->search_input));
	if (facetSV) {
	    hv_store(href, "INPUTFACETS", 11, facetSV, 0);
	}

	query = zquery2pquery(rr->query);
	if (query)
	{
		hv_store(href, "QUERY", 5, newSVpv((char *)query->buf, query->pos), 0);
	}
	else if (rr->query->which == Z_Query_type_104 &&
		 rr->query->u.type_104->which == Z_External_CQL) {
	    hv_store(href, "CQL", 3,
		     newSVpv(rr->query->u.type_104->u.cql, 0), 0);
	}
	else
	{
		rr->errcode = 108;
		return 0;
	}
	PUSHMARK(sp);

	XPUSHs(sv_2mortal(newRV( (SV*) href)));

	PUTBACK;

	handler_cv = simpleserver_sv2cv( search_ref );
	perl_call_sv( (SV *) handler_cv, G_SCALAR | G_DISCARD);

	SPAGAIN;

	temp = hv_fetch(href, "HITS", 4, 1);
	rr->hits = SvIV(*temp);

	temp = hv_fetch(href, "ERR_CODE", 8, 1);
	rr->errcode = SvIV(*temp);

	temp = hv_fetch(href, "ERR_STR", 7, 1);
	rr->errstring = string_or_undef(temp, rr->stream);

	temp = hv_fetch(href, "HANDLE", 6, 1);
	point = newSVsv(*temp);

	temp = hv_fetch(href, "OUTPUTFACETS", 12, 1);
        if (SvTYPE(*temp) != SVt_NULL)
	    f_SV_to_FacetList(*temp, &rr->search_info, rr->stream);

	temp = hv_fetch(href, "EXTRA_RESPONSE_DATA", 19, 0);
	if (temp)
	{
		ptr = SvPV(*temp, len);
		rr->extra_response_data = odr_strdupn(rr->stream, ptr, len);
	}

	temp = hv_fetch(href, "ESTIMATED" "_HIT_" "COUNT", 19, 0);
	if (temp)
	{
		rr->estimated_hit_count = SvIV(*temp);
	}
	hv_undef(href);
	av_undef(aref);

	zhandle->handle = point;
	sv_free( (SV*) aref);
	sv_free( (SV*) href);
	if (query)
	    wrbuf_destroy(query);
	PUTBACK;
	FREETMPS;
	LEAVE;
	return 0;
}


/* ### I am not 100% about the memory management in this handler */
int bend_delete(void *handle, bend_delete_rr *rr)
{
	Zfront_handle *zhandle = (Zfront_handle *)handle;
	HV *href;
	CV* handler_cv;
	int i;
	SV **temp;
	SV *point;

	dSP;
	ENTER;
	SAVETMPS;

	href = newHV();
	hv_store(href, "GHANDLE", 7, newSVsv(zhandle->ghandle), 0);
	hv_store(href, "HANDLE", 6, zhandle->handle, 0);
	hv_store(href, "STATUS", 6, newSViv(0), 0);

	PUSHMARK(sp);
	XPUSHs(sv_2mortal(newRV( (SV*) href)));
	PUTBACK;

	handler_cv = simpleserver_sv2cv(delete_ref);

	if (rr->function == 1) {
	    /* Delete all result sets in the session */
	    perl_call_sv( (SV *) handler_cv, G_SCALAR | G_DISCARD);
	    temp = hv_fetch(href, "STATUS", 6, 1);
	    rr->delete_status = SvIV(*temp);
	} else {
	    rr->delete_status = 0;
	    /*
	     * For some reason, deleting two or more result-sets in
	     * one operation goes horribly wrong, and ### I don't have
	     * time to debug it right now.
	     */
	    if (rr->num_setnames > 1) {
		rr->delete_status = 3; /* "System problem at target" */
		/* There's no way to sent delete-msg using the GFS */
		return 0;
	    }

	    for (i = 0; i < rr->num_setnames; i++) {
		hv_store(href, "SETNAME", 7, newSVpv(rr->setnames[i], 0), 0);
		perl_call_sv( (SV *) handler_cv, G_SCALAR | G_DISCARD);
		temp = hv_fetch(href, "STATUS", 6, 1);
		rr->statuses[i] = SvIV(*temp);
		if (rr->statuses[i] != 0)
		    rr->delete_status = rr->statuses[i];
	    }
	}

	SPAGAIN;

	temp = hv_fetch(href, "HANDLE", 6, 1);
	point = newSVsv(*temp);

	hv_undef(href);

	zhandle->handle = point;

	sv_free( (SV*) href);

	PUTBACK;
	FREETMPS;
	LEAVE;

	return 0;
}

static int comp(HV *href, Z_RecordComposition *composition)
{
	if (composition->which == Z_RecordComp_simple) {
		Z_ElementSetNames *simple = composition->u.simple;
		if (simple->which == Z_ElementSetNames_generic) {
			hv_store(href, "COMP", 4, newSVpv(simple->u.generic, 0), 0);
		} else {
			return 26;
		}
	} else if (composition->which == Z_RecordComp_complex) {
		Z_CompSpec *c = composition->u.complex;
		if (c && c->generic && c->generic->elementSpec &&
		    c->generic->elementSpec->which ==
		    Z_ElementSpec_elementSetName) {
			hv_store(href, "COMP", 4,
				 newSVpv(c->generic->elementSpec->u.elementSetName, 0), 0);
		}
		if (c->generic->which ==  Z_Schema_oid &&
		    c->generic->schema.oid) {
			WRBUF w = oid2dotted(c->generic->schema.oid);
			hv_store(href,
				 "SCHEMA_OID", 10,
				 newSVpv(wrbuf_buf(w), wrbuf_len(w)), 0);
			wrbuf_destroy(w);
		}
	} else {
		return 26;
	}
	return 0;
}

int bend_fetch(void *handle, bend_fetch_rr *rr)
{
	HV *href;
	SV **temp;
	SV *basename;
	SV *last;
	SV *err_code;
	SV *err_string;
	SV *sur_flag;
	SV *point;
	SV *rep_form;
	SV *schema = 0;
	char *ptr;
	WRBUF oid_dotted;
	Zfront_handle *zhandle = (Zfront_handle *)handle;
	CV* handler_cv = 0;

	STRLEN length;

	dSP;
	ENTER;
	SAVETMPS;

	rr->errcode = 0;
	href = newHV();
	hv_store(href, "SETNAME", 7, newSVpv(rr->setname, 0), 0);
	if (rr->schema)
		hv_store(href, "SCHEMA", 6, newSVpv(rr->schema, 0), 0);
        else
                hv_store(href, "SCHEMA", 6, newSVpv("", 0), 0);

	temp = hv_store(href, "OFFSET", 6, newSViv(rr->number), 0);
	if (rr->request_format != 0) {
	    oid_dotted = oid2dotted(rr->request_format);
	} else {
	    /* Probably an SRU request: assume XML is required */
	    oid_dotted = wrbuf_alloc();
	    wrbuf_puts(oid_dotted, "1.2.840.10003.5.109.10");
	}
	hv_store(href, "REQ_FORM", 8, newSVpv((char *)oid_dotted->buf, oid_dotted->pos), 0);
	hv_store(href, "REP_FORM", 8, newSVpv((char *)oid_dotted->buf, oid_dotted->pos), 0);
	hv_store(href, "BASENAME", 8, newSVpv("", 0), 0);
	hv_store(href, "LAST", 4, newSViv(0), 0);
	hv_store(href, "ERR_CODE", 8, newSViv(0), 0);
	hv_store(href, "ERR_STR", 7, newSVpv("", 0), 0);
	hv_store(href, "SUR_FLAG", 8, newSViv(0), 0);
	hv_store(href, "GHANDLE", 7, newSVsv(zhandle->ghandle), 0);
	hv_store(href, "HANDLE", 6, zhandle->handle, 0);
	hv_store(href, "PID", 3, newSViv(getpid()), 0);

	if (rr->comp) {
		rr->errcode = comp(href, rr->comp);
		if (rr->errcode) {
			rr->errstring = "unhandled compspec";
			return 0;
		}
	}

	PUSHMARK(sp);

	XPUSHs(sv_2mortal(newRV( (SV*) href)));

	PUTBACK;

	handler_cv = simpleserver_sv2cv( fetch_ref );
	perl_call_sv( (SV *) handler_cv, G_SCALAR | G_DISCARD);

	SPAGAIN;

	temp = hv_fetch(href, "BASENAME", 8, 1);
	basename = newSVsv(*temp);


	temp = hv_fetch(href, "LAST", 4, 1);
	last = newSVsv(*temp);

	temp = hv_fetch(href, "ERR_CODE", 8, 1);
	err_code = newSVsv(*temp);

	temp = hv_fetch(href, "ERR_STR", 7, 1),
	err_string = newSVsv(*temp);

	temp = hv_fetch(href, "SUR_FLAG", 8, 1);
	sur_flag = newSVsv(*temp);

	temp = hv_fetch(href, "REP_FORM", 8, 1);
	rep_form = newSVsv(*temp);

	temp = hv_fetch(href, "SCHEMA", 6, 0);
	if (temp != 0)
	{
		schema = newSVsv(*temp);
		ptr = SvPV(schema, length);
		if (length > 0)
			rr->schema = odr_strdupn(rr->stream, ptr, length);
	}

	temp = hv_fetch(href, "HANDLE", 6, 1);
	point = newSVsv(*temp);

	ptr = SvPV(basename, length);
	rr->basename = odr_strdupn(rr->stream, ptr, length);

	ptr = SvPV(rep_form, length);

	rr->output_format = yaz_string_to_oid_odr(yaz_oid_std(),
					CLASS_RECSYN, ptr, rr->stream);
	if (!rr->output_format)
	{
		printf("Net::Z3950::SimpleServer: WARNING: Bad OID %s\n", ptr);
		rr->output_format =
			odr_oiddup(rr->stream, yaz_oid_recsyn_sutrs);
	}
	temp = hv_fetch(href, "RECORD", 6, 0);
	if (temp)
	{
		SV *record = newSVsv(*temp);
		ptr = SvPV(record, length);
        	/* Treat GRS-1 records separately */
		if (!oid_oidcmp(rr->output_format, yaz_oid_recsyn_grs_1))
		{
			rr->record = (char *) read_grs1(ptr, rr->stream);
			rr->len = -1;
		}
		else
		{
			rr->record = odr_strdupn(rr->stream, ptr, length);
			rr->len = length;
		}
		sv_free(record);
	}
	hv_undef(href);

	zhandle->handle = point;
	handle = zhandle;
	rr->last_in_set = SvIV(last);

	if (!(rr->errcode))
	{
		rr->errcode = SvIV(err_code);
		ptr = SvPV(err_string, length);
		rr->errstring = odr_strdupn(rr->stream, ptr, length);
	}
	rr->surrogate_flag = SvIV(sur_flag);

	wrbuf_destroy(oid_dotted);
	sv_free((SV*) href);
	sv_free(basename);
	sv_free(last);
	sv_free(err_string);
	sv_free(err_code),
	sv_free(sur_flag);
	sv_free(rep_form);

	if (schema)
		sv_free(schema);

	PUTBACK;
	FREETMPS;
	LEAVE;

	return 0;
}



int bend_present(void *handle, bend_present_rr *rr)
{
	HV *href;
	SV **temp;
	SV *err_code;
	SV *err_string;
	SV *point;
	STRLEN len;
	char *ptr;
	Zfront_handle *zhandle = (Zfront_handle *)handle;
	CV* handler_cv = 0;

	dSP;
	ENTER;
	SAVETMPS;

	href = newHV();
	hv_store(href, "GHANDLE", 7, newSVsv(zhandle->ghandle), 0);
        hv_store(href, "HANDLE", 6, zhandle->handle, 0);
	hv_store(href, "ERR_CODE", 8, newSViv(0), 0);
	hv_store(href, "ERR_STR", 7, newSVpv("", 0), 0);
	hv_store(href, "START", 5, newSViv(rr->start), 0);
	hv_store(href, "SETNAME", 7, newSVpv(rr->setname, 0), 0);
	hv_store(href, "NUMBER", 6, newSViv(rr->number), 0);
	hv_store(href, "PID", 3, newSViv(getpid()), 0);
	if (rr->comp) {
		rr->errcode = comp(href, rr->comp);
		if (rr->errcode) {
			rr->errstring = "unhandled compspec";
			return 0;
		}
	}

	PUSHMARK(sp);

	XPUSHs(sv_2mortal(newRV( (SV*) href)));

	PUTBACK;

	handler_cv = simpleserver_sv2cv( present_ref );
	perl_call_sv( (SV *) handler_cv, G_SCALAR | G_DISCARD);

	SPAGAIN;

	temp = hv_fetch(href, "ERR_CODE", 8, 1);
	err_code = newSVsv(*temp);

	temp = hv_fetch(href, "ERR_STR", 7, 1);
	err_string = newSVsv(*temp);

	temp = hv_fetch(href, "HANDLE", 6, 1);
	point = newSVsv(*temp);

	PUTBACK;
	FREETMPS;
	LEAVE;

	hv_undef(href);
	rr->errcode = SvIV(err_code);

	ptr = SvPV(err_string, len);
	rr->errstring = odr_strdupn(rr->stream, ptr, len);
/*	wrbuf_free(oid_dotted, 1);*/
	zhandle->handle = point;
	handle = zhandle;
	sv_free(err_code);
	sv_free(err_string);
	sv_free( (SV*) href);

	return 0;
}


static Z_IOOriginPartToKeep *decodeItemOrderRequest(HV *href, Z_ItemOrder *it)
{
	if (it->which == Z_IOItemOrder_esRequest) {
		Z_IORequest *ir = it->u.esRequest;
		Z_IOOriginPartToKeep *k = ir->toKeep;
		Z_IOOriginPartNotToKeep *n = ir->notToKeep;

		if (n->itemRequest) {
			Z_External *r = n->itemRequest;
			if (r->direct_reference
			    && !oid_oidcmp(r->direct_reference, yaz_oid_recsyn_xml)
			    && r->which == Z_External_octet)
				hv_store(href, "XML_ILL", 7,
					 newSVpvn(r->u.octet_aligned->buf,
						  r->u.octet_aligned->len), 0);
		}
		return k;
	} else {
		return 0;
	}
}

static Z_TaskPackage *createItemOrderTaskPackage(HV *href,
						 Z_IOOriginPartToKeep *k,
						 bend_esrequest_rr *rr)
{
	SV **temp;
	ODR stream = rr->stream;
	Z_TaskPackage *tp = (Z_TaskPackage *) odr_malloc(stream, sizeof(*tp));
	Z_External *ext = (Z_External *)
		odr_malloc(stream, sizeof(*ext));
	Z_IUOriginPartToKeep *keep = (Z_IUOriginPartToKeep *)
		odr_malloc(stream, sizeof(*keep));
	Z_IOTargetPart *targetPart = (Z_IOTargetPart *)
		odr_malloc(stream, sizeof(*targetPart));

	tp->packageType =
		odr_oiddup(stream, rr->esr->packageType);
	tp->packageName = 0;
	tp->userId = 0;
	tp->retentionTime = 0;
	tp->permissions = 0;
	tp->description = 0;
	tp->targetReference = 0;
	tp->creationDateTime = 0;
	tp->taskStatus = odr_intdup(stream, 0);
	tp->packageDiagnostics = 0;
	tp->taskSpecificParameters = ext;
	ext->direct_reference =
		odr_oiddup(stream, rr->esr->packageType);
	ext->indirect_reference = 0;
	ext->descriptor = 0;
	ext->which = Z_External_itemOrder;
	ext->u.itemOrder = (Z_ItemOrder *)
		odr_malloc(stream, sizeof(*ext->u.update));
	ext->u.itemOrder->which = Z_IOItemOrder_taskPackage;
	ext->u.itemOrder->u.taskPackage =  (Z_IOTaskPackage *)
		odr_malloc(stream, sizeof(Z_IOTaskPackage));
	ext->u.itemOrder->u.taskPackage->originPart = k;
	ext->u.itemOrder->u.taskPackage->targetPart = targetPart;

	temp = hv_fetch(href, "XML_ILL", 7, 1);
	if (temp) {
		SV *err_str = newSVsv(*temp);
		STRLEN len;
		char *ptr;
		ptr = SvPV(err_str, len);
		targetPart->itemRequest = z_ext_record_xml(stream, ptr, len);
	} else {
		targetPart->itemRequest = 0;
	}
	targetPart->statusOrErrorReport = 0;
	targetPart->auxiliaryStatus = 0;
	return tp;
}

int bend_esrequest(void *handle, bend_esrequest_rr *rr)
{
	Z_IOOriginPartToKeep *k = 0;
	HV *href;
	Zfront_handle *zhandle = (Zfront_handle *)handle;
	SV **temp;
	Z_ExtendedServicesRequest *esr = rr->esr;
	Z_External *ext = esr->taskSpecificParameters;

	dSP;
	ENTER;
	SAVETMPS;

	href = newHV();
	hv_store(href, "GHANDLE", 7, newSVsv(zhandle->ghandle), 0);
        hv_store(href, "HANDLE", 6, zhandle->handle, 0);
        hv_store(href, "ERR_CODE", 8, newSViv(0), 0);
        hv_store(href, "ERR_STR", 7, newSVpv("", 0), 0);
	if (esr->function) {
		hv_store(href, "FUNCTION", 8,
			 newSViv(*esr->function), 0);
	}
	if (esr->packageType) {
		hv_store(href, "PACKAGE_TYPE", 12,
			 translateOID(esr->packageType), 0);
	}
	if (esr->packageName) {
		hv_store(href, "PACKAGE_NAME", 12,
			 newSVpv(esr->packageName, 0), 0);
	}
	if (esr->userId) {
		hv_store(href, "USER_ID", 7,
			 newSVpv(esr->userId, 0), 0);
	}
	if (esr->waitAction) {
		hv_store(href, "WAIT_ACTION", 11,
			 newSViv(*esr->waitAction), 0);
	}
	if (esr->elements) {
		hv_store(href, "ELEMENTS", 8,
			 newSVpv(esr->elements, 0), 0);
	}

	if (ext && ext->which == Z_External_itemOrder) {
		k = decodeItemOrderRequest(href, ext->u.itemOrder);
	}
	if (ext && !oid_oidcmp(yaz_oid_extserv_xml_es, esr->packageType)
	    && ext->which ==  Z_External_octet) {
	  hv_store(href, "XML_ILL", 7,
		   newSVpvn(ext->u.octet_aligned->buf,
			    ext->u.octet_aligned->len), 0);
	}
	PUSHMARK(SP);

	XPUSHs(sv_2mortal(newRV( (SV*) href)));

	PUTBACK;

	perl_call_sv(esrequest_ref, G_SCALAR | G_DISCARD);

	SPAGAIN;

	temp = hv_fetch(href, "ERR_CODE", 8, 1);
	if (temp) {
		SV *err_code = newSVsv(*temp);
		rr->errcode = SvIV(err_code);
	}

	temp = hv_fetch(href, "ERR_STR", 7, 1);
	if (temp) {
		SV *err_str = newSVsv(*temp);
		STRLEN len;
		char *ptr;
		ptr = SvPV(err_str, len);
		rr->errstring = odr_strdupn(rr->stream, ptr, len);
	}
	if (rr->errcode == 0 && k) {
		rr->taskPackage = createItemOrderTaskPackage(href, k, rr);
	}
        temp = hv_fetch(href, "XML_ILL", 7, 1);
	if (rr->errcode == 0 &&
	    ext && !oid_oidcmp(yaz_oid_extserv_xml_es, esr->packageType)
	    && temp) {
	    SV *err_str = newSVsv(*temp);
	    STRLEN len;
	    char *ptr;
	    Z_External *ext = (Z_External *)
	      odr_malloc(rr->stream, sizeof(*ext));
	    rr->taskPackageExt = ext;
	    ext->direct_reference = esr->packageType;
	    ext->descriptor = 0;
	    ext->indirect_reference = 0;
	    ext->which = Z_External_octet;
	    ptr = SvPV(err_str, len);
	    ext->u.octet_aligned = odr_create_Odr_oct(rr->stream, ptr, len);
	}
	PUTBACK;
	FREETMPS;
	LEAVE;
	return 0;
}


int bend_scan(void *handle, bend_scan_rr *rr)
{
        HV *href;
	AV *aref;
	AV *list;
	AV *entries;
	HV *scan_item;
	struct scan_entry *buffer;
	int *step_size = rr->step_size;
	int i;
	char **basenames;
	SV **temp;
	SV *err_code = sv_newmortal();
	SV *err_str = sv_newmortal();
	SV *point = sv_newmortal();
	SV *status = sv_newmortal();
	SV *number = sv_newmortal();
	char *ptr;
	STRLEN len;
	SV *entries_ref;
	Zfront_handle *zhandle = (Zfront_handle *)handle;
	CV* handler_cv = 0;
	SV *rpnSV;

	dSP;
	ENTER;
	SAVETMPS;
	href = newHV();
	list = newAV();

	/* RPN is better than TERM since it includes attributes */
	if ((rpnSV = f_Term_to_SV(rr->term->term, rr->term->attributes)) != 0) {
	    setMember(href, "RPN", rpnSV);
	}

	if (rr->term->term->which == Z_Term_general)
	{
		Odr_oct *oterm = rr->term->term->u.general;
		hv_store(href, "TERM", 4, newSVpv((char*) oterm->buf,
			oterm->len), 0);
	} else {
		rr->errcode = 229;	/* Unsupported term type */
		return 0;
	}
	if (rr->attributeset)
		setMember(href, "attributeSet",
			  translateOID(rr->attributeset));

	hv_store(href, "STEP", 4, newSViv(*step_size), 0);
	hv_store(href, "NUMBER", 6, newSViv(rr->num_entries), 0);
	hv_store(href, "POS", 3, newSViv(rr->term_position), 0);
	hv_store(href, "ERR_CODE", 8, newSViv(0), 0);
	hv_store(href, "ERR_STR", 7, newSVpv("", 0), 0);
	hv_store(href, "GHANDLE", 7, newSVsv(zhandle->ghandle), 0);
	hv_store(href, "HANDLE", 6, zhandle->handle, 0);
	hv_store(href, "STATUS", 6, newSViv(BEND_SCAN_SUCCESS), 0);
	hv_store(href, "ENTRIES", 7, newRV((SV *) list), 0);
	hv_store(href, "EXTRA_ARGS", 10,
		newRV( (SV*) parse_extra_args(rr->extra_args)), 0);
        aref = newAV();
        basenames = rr->basenames;
        for (i = 0; i < rr->num_bases; i++)
        {
                av_push(aref, newSVpv(*basenames++, 0));
        }
	hv_store(href, "DATABASES", 9, newRV( (SV*) aref), 0);

	PUSHMARK(sp);

	XPUSHs(sv_2mortal(newRV( (SV*) href)));

	PUTBACK;

	handler_cv = simpleserver_sv2cv( scan_ref );
	perl_call_sv( (SV *) handler_cv, G_SCALAR | G_DISCARD);

	SPAGAIN;

	temp = hv_fetch(href, "ERR_CODE", 8, 1);
	err_code = newSVsv(*temp);

	temp = hv_fetch(href, "ERR_STR", 7, 1);
	err_str = newSVsv(*temp);

	temp = hv_fetch(href, "HANDLE", 6, 1);
	point = newSVsv(*temp);

	temp = hv_fetch(href, "STATUS", 6, 1);
	status = newSVsv(*temp);

	temp = hv_fetch(href, "NUMBER", 6, 1);
	number = newSVsv(*temp);

	temp = hv_fetch(href, "ENTRIES", 7, 1);
	entries_ref = newSVsv(*temp);

	temp = hv_fetch(href, "EXTRA_RESPONSE_DATA", 19, 0);
	if (temp)
	{
		ptr = SvPV(*temp, len);
		rr->extra_response_data = odr_strdupn(rr->stream, ptr, len);
	}

	PUTBACK;
	FREETMPS;
	LEAVE;

	ptr = SvPV(err_str, len);
	rr->errstring = odr_strdupn(rr->stream, ptr, len);
	rr->errcode = SvIV(err_code);
	rr->num_entries = SvIV(number);
	rr->status = SvIV(status);
	buffer = rr->entries;
	entries = (AV *)SvRV(entries_ref);
	if (rr->errcode == 0) for (i = 0; i < rr->num_entries; i++)
	{
		scan_item = (HV *)SvRV(sv_2mortal(av_shift(entries)));
		temp = hv_fetch(scan_item, "TERM", 4, 1);
		ptr = SvPV(*temp, len);
		buffer->term = odr_strdupn(rr->stream, ptr, len);
		temp = hv_fetch(scan_item, "OCCURRENCE", 10, 1);
		buffer->occurrences = SvIV(*temp);
		temp = hv_fetch(scan_item, "DISPLAY_TERM", 12, 0);
		if (temp)
		{
			ptr = SvPV(*temp, len);
			buffer->display_term = odr_strdupn(rr->stream, ptr,len);
		}
		buffer++;
		hv_undef(scan_item);
	}

	zhandle->handle = point;
	handle = zhandle;
	sv_free(err_code);
	sv_free(err_str);
	sv_free(status);
	sv_free(number);
	hv_undef(href);
	sv_free((SV *)href);
	av_undef(aref);
	sv_free((SV *)aref);
	av_undef(list);
	sv_free((SV *)list);
	av_undef(entries);
	/*sv_free((SV *)entries);*/
	sv_free(entries_ref);

        return 0;
}

int bend_explain(void *handle, bend_explain_rr *q)
{
	HV *href;
	CV *handler_cv = 0;
	SV **temp;
	char *explain;
	SV *explainsv;
	STRLEN len;
	Zfront_handle *zhandle = (Zfront_handle *)handle;

	dSP;
	ENTER;
	SAVETMPS;

	href = newHV();
	hv_store(href, "EXPLAIN", 7, newSVpv("", 0), 0);
	hv_store(href, "DATABASE", 8, newSVpv(q->database, 0), 0);
	hv_store(href, "GHANDLE", 7, newSVsv(zhandle->ghandle), 0);
	hv_store(href, "HANDLE", 6, zhandle->handle, 0);

	PUSHMARK(sp);
	XPUSHs(sv_2mortal(newRV((SV*) href)));
	PUTBACK;

	handler_cv = simpleserver_sv2cv(explain_ref);
	perl_call_sv((SV*) handler_cv, G_SCALAR | G_DISCARD);

	SPAGAIN;

	temp = hv_fetch(href, "EXPLAIN", 7, 1);
	explainsv = newSVsv(*temp);

	PUTBACK;
	FREETMPS;
	LEAVE;

	explain = SvPV(explainsv, len);
	q->explain_buf = odr_strdupn(q->stream, explain, len);

        return 0;
}


/*
 * You'll laugh when I tell you this ...  Astonishingly, it turns out
 * that ActivePerl (which is widely used on Windows) has, in the
 * header file Perl\lib\CORE\XSUB.h, the following heinous crime:
 *	    #    define open		PerlLIO_open
 * This of course screws up the use of the "open" member of the
 * Z_IdAuthentication structure below, so we have to undo this
 * brain-damage.
 */
#ifdef open
#undef open
#endif


bend_initresult *bend_init(bend_initrequest *q)
{
	int dummy = simpleserver_clone();
	bend_initresult *r = (bend_initresult *)
		odr_malloc (q->stream, sizeof(*r));
	char *ptr;
	CV* handler_cv = 0;
	dSP;
	STRLEN len;
	NMEM nmem = nmem_create();
	Zfront_handle *zhandle = (Zfront_handle *)
		nmem_malloc(nmem, sizeof(*zhandle));
	SV *handle;
	HV *href;
	SV **temp;

	ENTER;
	SAVETMPS;

	zhandle->ghandle = _global_ghandle;
	zhandle->nmem = nmem;
	zhandle->stop_flag = 0;

        if (sort_ref)
        {
		q->bend_sort = bend_sort;
        }
	if (search_ref)
	{
		q->bend_search = bend_search;
	}
	if (present_ref)
	{
		q->bend_present = bend_present;
	}
	if (esrequest_ref)
	{
		q->bend_esrequest = bend_esrequest;
	}
	if (delete_ref)
	{
		q->bend_delete = bend_delete;
	}
	if (fetch_ref)
	{
		q->bend_fetch = bend_fetch;
	}
	if (scan_ref)
	{
		q->bend_scan = bend_scan;
	}
	if (explain_ref)
	{
		q->bend_explain = bend_explain;
	}

       	href = newHV();

	/* ### These should be given initial values from the client */
	hv_store(href, "IMP_ID", 6, newSVpv("", 0), 0);
	hv_store(href, "IMP_NAME", 8, newSVpv("", 0), 0);
	hv_store(href, "IMP_VER", 7, newSVpv("", 0), 0);

	hv_store(href, "ERR_CODE", 8, newSViv(0), 0);
	hv_store(href, "ERR_STR", 7, newSViv(0), 0);
	hv_store(href, "PEER_NAME", 9, newSVpv(q->peer_name, 0), 0);
	hv_store(href, "GHANDLE", 7, newSVsv(zhandle->ghandle), 0);
	hv_store(href, "HANDLE", 6, newSVsv(&sv_undef), 0);
	hv_store(href, "PID", 3, newSViv(getpid()), 0);
	if (q->auth) {
	    char *user = NULL;
	    char *passwd = NULL;
	    char *group = NULL;
	    if (q->auth->which == Z_IdAuthentication_open) {
                char *cp;
		user = nmem_strdup (odr_getmem (q->stream), q->auth->u.open);
		cp = strchr (user, '/');
		if (cp) {
                    /* password after / given */
		    *cp = '\0';
		    passwd = cp+1;
		    cp = strchr(passwd, '/');
		    if (cp) {
			/* user/group/passwd */
			*cp = '\0';
			group = passwd;
			passwd = cp+1;
		    }
		}
	    } else if (q->auth->which == Z_IdAuthentication_idPass) {
		user = q->auth->u.idPass->userId;
		passwd = q->auth->u.idPass->password;
		group = q->auth->u.idPass->groupId;
	    }
	    /* ### some code paths have user/password unassigned here */
            if (user)
	        hv_store(href, "USER", 4, newSVpv(user, 0), 0);
            if (passwd)
	        hv_store(href, "PASS", 4, newSVpv(passwd, 0), 0);
            if (group)
	        hv_store(href, "GROUP", 5, newSVpv(group, 0), 0);
	}

	PUSHMARK(sp);

	XPUSHs(sv_2mortal(newRV((SV*) href)));

	PUTBACK;

	if (init_ref != NULL)
	{
	     handler_cv = simpleserver_sv2cv( init_ref );
	     perl_call_sv( (SV *) handler_cv, G_SCALAR | G_DISCARD);
	}

	SPAGAIN;

	temp = hv_fetch(href, "IMP_ID", 6, 1);
	ptr = SvPV(*temp, len);
	q->implementation_id = nmem_strdup(nmem, ptr);

	temp = hv_fetch(href, "IMP_NAME", 8, 1);
	ptr = SvPV(*temp, len);
	q->implementation_name = nmem_strdup(nmem, ptr);

	temp = hv_fetch(href, "IMP_VER", 7, 1);
	ptr = SvPV(*temp, len);
	q->implementation_version = nmem_strdup(nmem, ptr);

	temp = hv_fetch(href, "ERR_CODE", 8, 1);
	r->errcode = SvIV(*temp);

	temp = hv_fetch(href, "ERR_STR", 7, 1);
	ptr = SvPV(*temp, len);
	r->errstring = odr_strdupn(q->stream, ptr, len);

	temp = hv_fetch(href, "HANDLE", 6, 1);
	handle= newSVsv(*temp);
	zhandle->handle = handle;

	r->handle = zhandle;

	hv_undef(href);
	sv_free((SV*) href);

	PUTBACK;
	FREETMPS;
	LEAVE;

	return r;
}

void bend_close(void *handle)
{
	HV *href;
	Zfront_handle *zhandle = (Zfront_handle *)handle;
	CV* handler_cv = 0;
	int stop_flag = 0;
	dSP;
	ENTER;
	SAVETMPS;

	if (close_ref)
	{
		href = newHV();
		hv_store(href, "GHANDLE", 7, newSVsv(zhandle->ghandle), 0);
		hv_store(href, "HANDLE", 6, zhandle->handle, 0);

		PUSHMARK(sp);

		XPUSHs(sv_2mortal(newRV((SV *)href)));

		PUTBACK;

		handler_cv = simpleserver_sv2cv( close_ref );
		perl_call_sv( (SV *) handler_cv, G_SCALAR | G_DISCARD);

		SPAGAIN;

		sv_free((SV*) href);
	}
	else
		sv_free(zhandle->handle);
	PUTBACK;
	FREETMPS;
	LEAVE;
	stop_flag = zhandle->stop_flag;
	nmem_destroy(zhandle->nmem);
	simpleserver_free();

	if (stop_flag)
		exit(0);
	return;
}

static void start_stop(struct statserv_options_block *sob, SV *handler_ref)
{
	HV *href;
	dSP;
	ENTER;
	SAVETMPS;

	href = newHV();
	hv_store(href, "CONFIG", 6, newSVpv(sob->configname, 0), 0);

	PUSHMARK(sp);

	XPUSHs(sv_2mortal(newRV((SV*) href)));

	PUTBACK;

	if (handler_ref != NULL)
	{
		CV* handler_cv = simpleserver_sv2cv( handler_ref );
		perl_call_sv( (SV *) handler_cv, G_SCALAR | G_DISCARD);
	}

	SPAGAIN;

	PUTBACK;
	FREETMPS;
	LEAVE;


}

void bend_start(struct statserv_options_block *sob)
{
	start_stop(sob, start_ref);
}

MODULE = Net::Z3950::SimpleServer	PACKAGE = Net::Z3950::SimpleServer

PROTOTYPES: DISABLE


void
set_ghandle(arg)
		SV *arg
	CODE:
		_global_ghandle = newSVsv(arg);


void
set_init_handler(arg)
		SV *arg
	CODE:
		init_ref = newSVsv(arg);


void
set_close_handler(arg)
		SV *arg
	CODE:
		close_ref = newSVsv(arg);


void
set_sort_handler(arg)
		SV *arg
	CODE:
		sort_ref = newSVsv(arg);

void
set_search_handler(arg)
		SV *arg
	CODE:
		search_ref = newSVsv(arg);


void
set_fetch_handler(arg)
		SV *arg
	CODE:
		fetch_ref = newSVsv(arg);


void
set_present_handler(arg)
		SV *arg
	CODE:
		present_ref = newSVsv(arg);


void
set_esrequest_handler(arg)
		SV *arg
	CODE:
		esrequest_ref = newSVsv(arg);


void
set_delete_handler(arg)
		SV *arg
	CODE:
		delete_ref = newSVsv(arg);


void
set_scan_handler(arg)
		SV *arg
	CODE:
		scan_ref = newSVsv(arg);

void
set_explain_handler(arg)
		SV *arg
	CODE:
		explain_ref = newSVsv(arg);

void
set_start_handler(arg)
		SV *arg
	CODE:
		start_ref = newSVsv(arg);

int
start_server(...)
	PREINIT:
		char **argv;
		char **argv_buf;
		char *ptr;
		int i;
		STRLEN len;
		struct statserv_options_block *sob;
	CODE:
		argv_buf = (char **)xmalloc((items + 1) * sizeof(char *));
		argv = argv_buf;
		for (i = 0; i < items; i++)
		{
			ptr = SvPV(ST(i), len);
			*argv_buf = (char *)xmalloc(len + 1);
			strcpy(*argv_buf++, ptr);
		}
		*argv_buf = NULL;

		sob = statserv_getcontrol();
		sob->bend_start = bend_start;
		statserv_setcontrol(sob);

		root_perl_context = PERL_GET_CONTEXT;
		yaz_mutex_create(&simpleserver_mutex);
#if 0
		/* only for debugging perl_clone .. */
		tst_clones();
#endif

		RETVAL = statserv_main(items, argv, bend_init, bend_close);
	OUTPUT:
		RETVAL


int
ScanSuccess()
	CODE:
		RETVAL = BEND_SCAN_SUCCESS;
	OUTPUT:
		RETVAL

int
ScanPartial()
	CODE:
		RETVAL = BEND_SCAN_PARTIAL;
	OUTPUT:
		RETVAL


void
yazlog(arg)
		SV *arg
	CODE:
    		STRLEN len;
		char *ptr;
		ptr = SvPV(arg, len);
		yaz_log(YLOG_LOG, "%.*s", (int) len, ptr);

int
yaz_diag_srw_to_bib1(srw_code)
	int srw_code

int
yaz_diag_bib1_to_srw(bib1_code)
	int bib1_code

