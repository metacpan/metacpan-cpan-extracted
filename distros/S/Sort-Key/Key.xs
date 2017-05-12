/* -*- Mode: C -*- */

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#if (PERL_VERSION < 7)
#include "sort.h"
#endif

static I32
ix_sv_cmp(pTHX_ SV **a, SV **b) {
    return sv_cmp(*a, *b);
}

static I32
ix_rsv_cmp(pTHX_ SV **a, SV **b) {
    return sv_cmp(*b, *a);
}

static I32
ix_lsv_cmp(pTHX_ SV **a, SV **b) {
    return sv_cmp_locale(*a, *b);
}

static I32
ix_rlsv_cmp(pTHX_ SV **a, SV **b) {
    return sv_cmp_locale(*b, *a);
}

static I32
ix_n_cmp(pTHX_ NV *a, NV *b) {
    NV nv1 = *a;
    NV nv2 = *b;
    return nv1 < nv2 ? -1 : nv1 > nv2 ? 1 : 0;
}

static I32
ix_rn_cmp(pTHX_ NV *a, NV *b) {
    NV nv1 = *b;
    NV nv2 = *a;
    return nv1 < nv2 ? -1 : nv1 > nv2 ? 1 : 0;
}

static I32
ix_i_cmp(pTHX_ IV *a, IV *b) {
    IV iv1 = *a;
    IV iv2 = *b;
    return iv1 < iv2 ? -1 : iv1 > iv2 ? 1 : 0;
}

static I32
ix_ri_cmp(pTHX_ IV *a, IV *b) {
    IV iv1 = *b;
    IV iv2 = *a;
    return iv1 < iv2 ? -1 : iv1 > iv2 ? 1 : 0;
}

static I32
ix_u_cmp(pTHX_ UV *a, UV *b) {
    UV uv1 = *a;
    UV uv2 = *b;
    return uv1 < uv2 ? -1 : uv1 > uv2 ? 1 : 0;
}

static I32
ix_ru_cmp(pTHX_ UV *a, UV *b) {
    UV uv1 = *b;
    UV uv2 = *a;
    return uv1 < uv2 ? -1 : uv1 > uv2 ? 1 : 0;
}

static void *v_alloc(pTHX_ IV n, IV lsize) {
    void *r;
    Newxc(r, n<<lsize, char, void);
    SAVEFREEPV(r);
    return r;
}

static void *av_alloc(pTHX_ IV n, IV lsize) {
    AV *av=(AV*)sv_2mortal((SV*)newAV());
    av_fill(av, n-1);
    return AvARRAY(av);
}

static void i_store(pTHX_ SV *v, void *to) {
    *((IV*)to)=SvIV(v);
}

static void u_store(pTHX_ SV *v, void *to) {
    *((UV*)to)=SvUV(v);
}

static void n_store(pTHX_ SV *v, void *to) {
    *((NV*)to)=SvNV(v);
}

static void sv_store(pTHX_ SV *v, void *to) {
    *((SV**)to)=SvREFCNT_inc(v);
}

#define lsizeof(A) (ilog2(sizeof(A)))


static int ilog2(int i) {
    if (i>256) croak("internal error");
    if (i>128) return 8;
    if (i>64) return 7;
    if (i>32) return 6;
    if (i>16) return 5;
    if (i>8) return 4;
    if (i>4) return 3;
    if (i>2) return 2;
    if (i>1) return 1;
    return 0;
}

/* sorting types:

   0 => string
   1 => locale
   2 => number
   3 => integer
   4 => unsigned_integer
   5 => single precission float - not implemented
   
   128 => reverse string
   129 => reverse locale
   130 => reverse number
   131 => reverse integer
   132 => reverse unsigned_integer
   133 => reverse s. p. float - not implemented

*/

typedef I32 (*COMPARE_t)(pTHX_ void*, void*);
typedef void (*STORE_t)(pTHX_ SV*, void*);

static void
_keysort(pTHX_ IV type, SV *keygen, SV **values, I32 offset, I32 ax, IV len) {
    dSP;
    if (len) {
	void *keys;
	void **ixkeys;
	IV i;
	SV **from, **to;

	IV lsize;
	COMPARE_t cmp;
	STORE_t store;

#if (PERL_VERSION < 9)
        int hints = PL_curcop->op_private;
#else
        int hints = CopHINTS_get(PL_curcop);
#endif

        /* fprintf (stderr, "hints=0x%x, int=0x%x, loc=0x%x\n", hints, HINT_INTEGER, HINT_LOCALE );fflush(stderr); */

	switch(type) {
	case 0:
	case 128:
	    if (hints & HINT_LOCALE) type = type | 128;
	    break;
	case 2:
	case 130:
	    if (hints & HINT_INTEGER) type = type | 1;
	    break;
	}

	switch(type) {
	case 0:
	    cmp = (COMPARE_t)&ix_sv_cmp;
	    lsize = lsizeof(SV*);
	    keys = av_alloc(aTHX_ len, lsize);
	    store = &sv_store;
	    break;
	case 1:
	    cmp = (COMPARE_t)&ix_lsv_cmp;
	    lsize = lsizeof(SV*);
	    keys = av_alloc(aTHX_ len, lsize);
	    store = &sv_store;
	    break;
	case 2:
	    cmp = (COMPARE_t)&ix_n_cmp;
	    lsize = lsizeof(NV);
	    keys = v_alloc(aTHX_ len, lsize);
	    store = &n_store;
	    break;
	case 3:
	    cmp = (COMPARE_t)&ix_i_cmp;
	    lsize = lsizeof(IV);
	    keys = v_alloc(aTHX_ len, lsize);
	    store = &i_store;
	    break;
	case 4:
	    cmp = (COMPARE_t)&ix_u_cmp;
	    lsize = lsizeof(UV);
	    keys = v_alloc(aTHX_ len, lsize);
	    store = &u_store;
	    break;
	case 128:
	    cmp = (COMPARE_t)&ix_rsv_cmp;
	    lsize = lsizeof(SV*);
	    keys = av_alloc(aTHX_ len, lsize);
	    store = &sv_store;
	    break;
	case 129:
	    cmp = (COMPARE_t)&ix_rlsv_cmp;
	    lsize = lsizeof(SV*);
	    keys = av_alloc(aTHX_ len, lsize);
	    store = &sv_store;
	    break;
	case 130:
	    cmp = (COMPARE_t)&ix_rn_cmp;
	    lsize = lsizeof(NV);
	    keys = v_alloc(aTHX_ len, lsize);
	    store = &n_store;
	    break;
	case 131:
	    cmp = (COMPARE_t)&ix_ri_cmp;
	    lsize = lsizeof(IV);
	    keys = v_alloc(aTHX_ len, lsize);
	    store = &i_store;
	    break;
	case 132:
	    cmp = (COMPARE_t)&ix_ru_cmp;
	    lsize = lsizeof(UV);
	    keys = v_alloc(aTHX_ len, lsize);
	    store = &u_store;
	    break;
	default:
	    croak("unsupported sort type %d", type);
	}

	Newx(ixkeys, len, void*);
	SAVEFREEPV(ixkeys);
	if (keygen) {
	    for (i=0; i<len; i++) {
		IV count;
		SV *current;
		SV *result;
		void *target;
		/* warn("values=%p SP=%p SP-len=%p, &ST(0)=%p\n", values, SP, SP-len, &ST(0)); */
		ENTER;
		SAVETMPS;
                SAVE_DEFSV;
		current = values ? values[i] : ST(i + offset);
		DEFSV = sv_2mortal(current ? SvREFCNT_inc(current) : newSV(0));
		PUSHMARK(SP);
		PUTBACK;
		count = call_sv(keygen, G_SCALAR);
		SPAGAIN;
		if (count != 1)
		    croak("wrong number of results returned from key generation sub");
		result = POPs;
		/* warn("key: %_\n", result); */
		ixkeys[i] = target = ((char*)keys) + (i << lsize);
		(*store)(aTHX_ result, target);
		FREETMPS;
		LEAVE;
	    }
	}
	else {
	    for (i = 0; i < len; i++) {
		void *target;
		SV *current = values ? values[i] : ST(i + offset);
		ixkeys[i] = target = ((char*)keys) + (i << lsize);

		(*store)(aTHX_
			 current ? current : sv_2mortal(newSV(0)),
			 target);
	    }
	}
	sortsv((SV**)ixkeys, len, (SVCOMPARE_t)cmp);
	if (values) {
	    from = to = values;
	}
	else {
	    from = &ST(offset);
	    to = &ST(0);
	}
	for(i = 0; i < len; i++) {
            IV j = ( ((char*)(ixkeys[i])) - ((char*)keys) )>>lsize;
	    ixkeys[i] = from[j];
	}
	for(i = 0; i < len; i++) {
	    to[i] = (SV*)ixkeys[i];
	}
    }
}

typedef struct multikey {
    COMPARE_t cmp;
    void *data;
    IV lsize;
} MK;


static I32 _multikeycmp(pTHX_ void *a, void *b) {
    MK *keys = (MK*)PL_sortcop;
    IV r = (*(keys->cmp))(aTHX_ a, b);
    if (r) 
	return r;
    else {
	IV ixa = ( ((char*)a) - ((char*)(keys->data)) ) >> keys->lsize;
	IV ixb = ( ((char*)b) - ((char*)(keys->data)) ) >> keys->lsize;
	COMPARE_t cmp;
	while(1) {
	    keys++;
	    cmp=keys->cmp;
	    if (!cmp)
		return 0;
	    a = ((char*)(keys->data))+(ixa<<keys->lsize);
	    b = ((char*)(keys->data))+(ixb<<keys->lsize);
	    r = (*cmp)(aTHX_ a, b);
	    if (r)
		return r;
	}
    }
    return 0; /* dead code just to remove warnings from some
	       * compilers */
}

static I32 _secondkeycmp(pTHX_ void *a, void *b) {
    MK *keys = (MK*)PL_sortcop;
    IV ixa = ( ((char*)a) - ((char*)(keys->data)) ) >> keys->lsize;
    IV ixb = ( ((char*)b) - ((char*)(keys->data)) ) >> keys->lsize;
    COMPARE_t cmp;
    while(1) {
	I32 r;
	keys++;
	cmp=keys->cmp;
	if (!cmp)
	    return 0;
	a = ((char*)(keys->data))+(ixa<<keys->lsize);
	b = ((char*)(keys->data))+(ixb<<keys->lsize);
	r = (*cmp)(aTHX_ a, b);
	if (r)
	    return r;
    }
    return 0; /* dead code just to remove warnings from some
	       * compilers */
}

static I32
ix_sv_mcmp(pTHX_ SV **a, SV **b) {
    I32 r = sv_cmp(*a, *b);
    if (r) return r;
    return _secondkeycmp(aTHX_ a, b);
}

static I32
ix_rsv_mcmp(pTHX_ SV **a, SV **b) {
    I32 r = sv_cmp(*b, *a);
    if (r) return r;
    return _secondkeycmp(aTHX_ a, b);
}

static I32
ix_lsv_mcmp(pTHX_ SV **a, SV **b) {
    I32 r = sv_cmp_locale(*a, *b);
    if (r) return r;
    return _secondkeycmp(aTHX_ a, b);
}

static I32
ix_rlsv_mcmp(pTHX_ SV **a, SV **b) {
    I32 r = sv_cmp_locale(*b, *a);
    if (r) return r;
    return _secondkeycmp(aTHX_ a, b);
}

static I32
ix_n_mcmp(pTHX_ NV *a, NV *b) {
    NV nv1 = *a;
    NV nv2 = *b;
    return nv1 < nv2 ? -1 : nv1 > nv2 ? 1 : _secondkeycmp(aTHX_ a, b);
}

static I32
ix_rn_mcmp(pTHX_ NV *a, NV *b) {
    NV nv1 = *b;
    NV nv2 = *a;
    return nv1 < nv2 ? -1 : nv1 > nv2 ? 1 : _secondkeycmp(aTHX_ a, b);
}

static I32
ix_i_mcmp(pTHX_ IV *a, IV *b) {
    IV iv1 = *a;
    IV iv2 = *b;
    return iv1 < iv2 ? -1 : iv1 > iv2 ? 1 : _secondkeycmp(aTHX_ a, b);
}

static I32
ix_ri_mcmp(pTHX_ IV *a, IV *b) {
    IV iv1 = *b;
    IV iv2 = *a;
    return iv1 < iv2 ? -1 : iv1 > iv2 ? 1 : _secondkeycmp(aTHX_ a, b);
}

static I32
ix_u_mcmp(pTHX_ UV *a, UV *b) {
    UV uv1 = *a;
    UV uv2 = *b;
    return uv1 < uv2 ? -1 : uv1 > uv2 ? 1 : _secondkeycmp(aTHX_ a, b);
}

static I32
ix_ru_mcmp(pTHX_ UV *a, UV *b) {
    UV uv1 = *b;
    UV uv2 = *a;
    return uv1 < uv2 ? -1 : uv1 > uv2 ? 1 : _secondkeycmp(aTHX_ a, b);
}

static void
_multikeysort(pTHX_ SV *keytypes, SV *keygen, SV *post,
	      SV**values, I32 from_offset, I32 ax, I32 len) {
    dSP;
    STRLEN nkeys;
    unsigned char *types=(unsigned char *)SvPV(keytypes, nkeys);

    if (nkeys<1)
	croak("empty multikey type list passed");

    if (len) {
	IV i;
	MK *keys;
	STORE_t *store;
	void **ixkeys;
	SV **from, **to;
	COMPARE_t cmp = (COMPARE_t)&_multikeycmp;

	Newx(keys, nkeys+1, MK);
	SAVEFREEPV(keys);
	Newx(store, nkeys, STORE_t);
	SAVEFREEPV(store);
	
	for(i=0; i<nkeys; i++) {
	    MK *key = keys+i;
	    switch(types[i]) {
	    case 0:
		if (i==0) cmp = (COMPARE_t)&ix_sv_mcmp;
		key->cmp = (COMPARE_t)&ix_sv_cmp;
		key->lsize = lsizeof(SV*);
		key->data = av_alloc(aTHX_ len, key->lsize);
		store[i] = &sv_store;
		break;
	    case 1:
		if (i==0) cmp = (COMPARE_t)&ix_lsv_mcmp;
		key->cmp = (COMPARE_t)&ix_lsv_cmp;
		key->lsize = lsizeof(SV*);
		key->data = av_alloc(aTHX_ len, key->lsize);
		store[i] = &sv_store;
		break;
	    case 2:
		if (i==0) cmp = (COMPARE_t)&ix_n_mcmp;
		key->cmp = (COMPARE_t)&ix_n_cmp;
		key->lsize = lsizeof(NV);
		key->data = v_alloc(aTHX_ len, key->lsize);
		store[i] = &n_store;
		break;
	    case 3:
		if (i==0) cmp = (COMPARE_t)&ix_i_mcmp;
		key->cmp = (COMPARE_t)&ix_i_cmp;
		key->lsize = lsizeof(IV);
		key->data = v_alloc(aTHX_ len, key->lsize);
		store[i] = &i_store;
		break;
	    case 4:
		if (i==0) cmp = (COMPARE_t)&ix_u_mcmp;
		key->cmp = (COMPARE_t)&ix_u_cmp;
		key->lsize = lsizeof(UV);
		key->data = v_alloc(aTHX_ len, key->lsize);
		store[i] = &u_store;
		break;
	    case 128:
		if (i==0) cmp = (COMPARE_t)&ix_rsv_mcmp;
		key->cmp = (COMPARE_t)&ix_rsv_cmp;
		key->lsize = lsizeof(SV*);
		key->data = av_alloc(aTHX_ len, key->lsize);
		store[i] = &sv_store;
		break;
	    case 129:
		if (i==0) cmp = (COMPARE_t)&ix_rlsv_mcmp;
		key->cmp = (COMPARE_t)&ix_rlsv_cmp;
		key->lsize = lsizeof(SV*);
		key->data = av_alloc(aTHX_ len, key->lsize);
		store[i] = &sv_store;
		break;
	    case 130:
		if (i==0) cmp = (COMPARE_t)&ix_rn_mcmp;
		key->cmp = (COMPARE_t)&ix_rn_cmp;
		key->lsize = lsizeof(NV);
		key->data = v_alloc(aTHX_ len, key->lsize);
		store[i] = &n_store;
		break;
	    case 131:
		if (i==0) cmp = (COMPARE_t)&ix_ri_mcmp;
		key->cmp = (COMPARE_t)&ix_ri_cmp;
		key->lsize = lsizeof(IV);
		key->data = v_alloc(aTHX_ len, key->lsize);
		store[i] = &i_store;
                break;
	    case 132:
		if (i==0) cmp = (COMPARE_t)&ix_ru_mcmp;
		key->cmp = (COMPARE_t)&ix_ru_cmp;
		key->lsize = lsizeof(UV);
		key->data = v_alloc(aTHX_ len, key->lsize);
		store[i] = &u_store;
		break;
	    default:
		croak("unsupported sort type %d", types[i]);
	    }
	}

	keys[nkeys].cmp = 0;
	keys[nkeys].data = 0;
	keys[nkeys].lsize = 0;
	    
	Newx(ixkeys, len, void*);
	SAVEFREEPV(ixkeys);
	for (i=0; i<len; i++) {
	    IV count;
	    SV *current;
	    void *target;
	    ENTER;
	    SAVETMPS;
            SAVE_DEFSV;
	    current = values ? values[i] : ST(i+from_offset);
	    DEFSV = sv_2mortal(current ? SvREFCNT_inc(current) : newSV(0));
	    PUSHMARK(SP);
	    PUTBACK;
	    count = call_sv(keygen, G_ARRAY);
	    SPAGAIN;
	    if (post) {
		PUSHMARK(SP-count);
		PUTBACK;
		count = call_sv(post, G_ARRAY);
		SPAGAIN;
	    }
	    if (count != nkeys)
		croak("wrong number of results returned "
		      "from multikey generation sub "
		      "(%d expected, %d returned)",
		      nkeys, count);
	    while(count-- > 0) {
		SV *result = POPs;
		MK *key = keys+count;
		target = ((char*)(key->data)) + (i<<key->lsize);
		(*(store[count]))(aTHX_ result, target);
	    }
	    ixkeys[i] = target;
	    FREETMPS;
	    LEAVE;
	}
	SAVEVPTR(PL_sortcop);
	PL_sortcop = (OP*)keys;
	sortsv((SV**)ixkeys, len, (SVCOMPARE_t)cmp);
	if (values) {
	    from = to = values;
	}
	else {
	    from = &ST(from_offset);
	    to = &ST(0);
	}
	for(i=0; i<len; i++) {
	    IV j = ( ((char*)(ixkeys[i])) - ((char*)(keys->data)) )>>keys->lsize;
	    ixkeys[i] = from[j];
	}
	for(i=0; i<len; i++) {
	    to[i] = (SV*)ixkeys[i];
	}
    }
}

static AV *
_xclosure_defaults(pTHX_ CV *cv) {
    MAGIC *magic = mg_find((SV*)cv, '~');
    if (magic) {
	if ( magic->mg_obj
	     && SvTYPE((SV*)(magic->mg_obj)) == SVt_PVAV )
	    return (AV*)(magic->mg_obj);
	croak("internal error: bad XSUB closure");
    }
    return NULL;
}

static void
_xclosure_make(pTHX_ CV *cv, AV *defaults) {
    sv_magic((SV*)cv, (SV*)defaults, '~', "XCLOSURE", 0);
}

XS(XS_Sort__Key__multikeysort);
XS(XS_Sort__Key__multikeysort)
{
    dXSARGS;
    SV *gen=0;
    SV *post=0;
    SV *types=0;
    IV offset=0;

    AV *defaults = _xclosure_defaults(aTHX_ cv);

    if (defaults) {
	types = *(av_fetch(defaults, 0, 1));
	gen = *(av_fetch(defaults, 1, 1));
	post = *(av_fetch(defaults, 2, 1));
	if (!SvOK(post))
	    post = 0;
    }

    if (!types || !SvOK(types)) {
	if (items--)
	    types = ST(offset++);
	else
	    croak("not enough arguments");

    }
    if (!gen || !SvOK(gen)) {
	if (items--)
	    gen = ST(offset++);
	else
	    croak("not enough arguments");
    }

    _multikeysort(aTHX_ types, gen, post, 0, offset, ax, items);
    SP=&ST(items-1);
    PUTBACK;
    return;
}


XS(XS_Sort__Key__multikeysort_inplace);
XS(XS_Sort__Key__multikeysort_inplace)
{
    dXSARGS;
    SV *gen = 0;
    SV *post = 0;
    SV *types = 0;
    AV *values;

    AV *magic_values=0;
    I32 len;
    I32 offset=0;

    AV *defaults = _xclosure_defaults(aTHX_ cv);

    if (defaults) {
	types = *(av_fetch(defaults, 0, 1));
	gen = *(av_fetch(defaults, 1, 1));
	post = *(av_fetch(defaults, 2, 1));
	if (!SvOK(post))
	    post = 0;
    }

    SP-=items;

    if (!types || !SvOK(types)) {
	if (items--)
	    types = ST(offset++);
	else
	    croak("not enough arguments, packed multikey type descriptor required");
    }
    if (!gen || !SvOK(gen)) {
	if (items--)
	    gen = ST(offset++);
	else
	    croak("not enough arguments, reference to multikey generation subroutine required");
    }

    if(!(SvROK(gen) && SvTYPE(SvRV(gen))==SVt_PVCV))
       croak("wrong argument type, subroutine reference required");

    if (items != 1)
	croak("not enough arguments, array reference required");

    if (SvROK(ST(offset)) && SvTYPE(SvRV(ST(offset)))==SVt_PVAV)
	values = (AV*)SvRV(ST(offset));
    else croak("wrong argument type, array reference required");

    if ((len=av_len(values)+1)) {
	/* warn("ix=%d\n", ix); */
	if (SvMAGICAL(values) || AvREIFY(values)) {
	    int i;
	    magic_values = values;
	    values = (AV*)sv_2mortal((SV*)newAV());
	    av_extend(values, len-1);
	    for (i=0; i<len; i++) {
		SV **currentp = av_fetch(magic_values, i, 0);
		av_store( values, i,
			  ( currentp
			    ? SvREFCNT_inc(*currentp)
			    : newSV(0) ) );
	    }
	}
	
	_multikeysort(aTHX_ types, gen, post, AvARRAY(values), 0, 0, len);
	
	if (magic_values) {
	    int i;
	    SV **values_array = AvARRAY(values);
	    for(i=0; i<len; i++) {
		SV *current = values_array[i];
		if (!current) current = &PL_sv_undef;
		if (!av_store(magic_values, i, SvREFCNT_inc(current)))
		    SvREFCNT_dec(current);
	    }
	}
    }
    PUTBACK;
}


MODULE = Sort::Key		PACKAGE = Sort::Key		
PROTOTYPES: ENABLE

void
keysort(SV *keygen, ...)
PROTOTYPE: &@
ALIAS:
    lkeysort = 1
    nkeysort = 2
    ikeysort = 3
    ukeysort = 4
    rkeysort = 128
    rlkeysort = 129
    rnkeysort = 130
    rikeysort = 131
    rukeysort = 132
PPCODE:
    items--;
    if (items) {
	_keysort(aTHX_ ix, keygen, 0, 1, ax, items);
        SPAGAIN;
	SP = &ST(items-1);
    }


void
keysort_inplace(SV *keygen, AV *values)
PROTOTYPE: &\@
PREINIT:
    AV *magic_values=0;
    int len;
ALIAS:
    lkeysort_inplace = 1
    nkeysort_inplace = 2
    ikeysort_inplace = 3
    ukeysort_inplace = 4
    rkeysort_inplace = 128
    rlkeysort_inplace = 129
    rnkeysort_inplace = 130
    rikeysort_inplace = 131
    rukeysort_inplace = 132
PPCODE:
    if ((len=av_len(values)+1)) {
	/* warn("ix=%d\n", ix); */
	if (SvMAGICAL(values) || AvREIFY(values)) {
	    int i;
	    magic_values = values;
	    values = (AV*)sv_2mortal((SV*)newAV());
	    av_extend(values, len-1);
	    for (i=0; i<len; i++) {
		SV **currentp = av_fetch(magic_values, i, 0);
		av_store( values, i,
			  ( currentp
			    ? SvREFCNT_inc(*currentp)
			    : newSV(0) ) );
	    }
	}
	_keysort(aTHX_ ix, keygen, AvARRAY(values), 0, 0, len);
        SPAGAIN;
	if (magic_values) {
	    int i;
	    SV **values_array = AvARRAY(values);
	    for(i=0; i<len; i++) {
		SV *current = values_array[i];
		if (!current) current = &PL_sv_undef;
		if (!av_store(magic_values, i, SvREFCNT_inc(current)))
		    SvREFCNT_dec(current);
	    }
	}
    }

void
_sort(...)
PROTOTYPE: @
ALIAS:
    lsort = 1
    nsort = 2
    isort = 3
    usort = 4
    rsort = 128
    rlsort = 129
    rnsort = 130
    risort = 131
    rusort = 132
PPCODE:
    if (items) {
	_keysort(aTHX_ ix, 0, 0, 0, ax, items);
        SPAGAIN;
	SP = &ST(items-1);
    }

void
_sort_inplace(AV *values)
PROTOTYPE: \@
PREINIT:
    AV *magic_values=0;
    int len;
ALIAS:
    lsort_inplace = 1
    nsort_inplace = 2
    isort_inplace = 3
    usort_inplace = 4
    rsort_inplace = 128
    rlsort_inplace = 129
    rnsort_inplace = 130
    risort_inplace = 131
    rusort_inplace = 132
PPCODE:
    if ((len=av_len(values)+1)) {
	/* warn("ix=%d\n", ix); */
	if (SvMAGICAL(values) || AvREIFY(values)) {
	    int i;
	    magic_values = values;
	    values = (AV*)sv_2mortal((SV*)newAV());
	    av_extend(values, len-1);
	    for (i=0; i<len; i++) {
		SV **currentp = av_fetch(magic_values, i, 0);
		av_store( values, i,
			  ( currentp
			    ? SvREFCNT_inc(*currentp)
			    : newSV(0) ) );
	    }
	}

	_keysort(aTHX_ ix, 0, AvARRAY(values), 0, 0, len);
        SPAGAIN;
	if (magic_values) {
	    int i;
	    SV **values_array = AvARRAY(values);
	    for(i=0; i<len; i++) {
		SV *current = values_array[i];
		if (!current) current = &PL_sv_undef;
		if (!av_store(magic_values, i, SvREFCNT_inc(current)))
		    SvREFCNT_dec(current);
	    }
	}
    }


PROTOTYPES: DISABLE

CV *
_multikeysorter(SV *types, SV *gen, SV *post)
PREINIT:
    AV *defaults;
CODE:
    if (!SvOK(types) || sv_len(types)<1)
	croak("invalid packed types argument");
    RETVAL = newXS(0, &XS_Sort__Key__multikeysort, __FILE__);
    defaults = (AV*)sv_2mortal((SV*)newAV());
    av_store(defaults, 0, newSVsv(types));
    av_store(defaults, 1, newSVsv(gen));
    av_store(defaults, 2, newSVsv(post));
    _xclosure_make(aTHX_ RETVAL, defaults);
    if (!SvOK(gen))
	sv_setpv((SV*)RETVAL, "&@");
OUTPUT:
    RETVAL

CV *
_multikeysorter_inplace(SV *types, SV *gen, SV *post)
PREINIT:
    AV *defaults;
CODE:
    if (!SvOK(types) || sv_len(types)<1)
	croak("invalid packed types argument");
    RETVAL = newXS(0, &XS_Sort__Key__multikeysort_inplace, __FILE__);
    defaults = (AV*)sv_2mortal((SV*)newAV());
    av_store(defaults, 0, newSVsv(types));
    av_store(defaults, 1, newSVsv(gen));
    av_store(defaults, 2, newSVsv(post));
    _xclosure_make(aTHX_ RETVAL, defaults);
    if (!SvOK(gen))
	sv_setpv((SV*)RETVAL, "&\\@");
    else
	sv_setpv((SV*)RETVAL, "\\@");
OUTPUT:
    RETVAL


