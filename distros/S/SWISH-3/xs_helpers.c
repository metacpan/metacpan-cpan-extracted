/*
 * This file is part of libswish3
 * Copyright (C) 2010 Peter Karman
 *
 *  libswish3 is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  libswish3 is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with libswish3; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

/* C code to make writing XS easier */

#include <wctype.h>

static AV*      sp_hv_keys(HV* hash);
static AV*      sp_hv_values(HV* hash);
static SV*      sp_hv_store( HV* h, const char* key, SV* val );
static SV*      sp_hv_store_char( HV* h, const char* key, char *val );
static SV*      sp_hvref_store( SV* h, const char* key, SV* val );
static SV*      sp_hvref_store_char( SV* h, const char* key, char *val );
static SV*      sp_hv_fetch( HV* h, const char* key );
static SV*      sp_hvref_fetch( SV* h, const char* key );
static char*    sp_hv_fetch_as_char( HV* h, const char* key );
static char*    sp_hvref_fetch_as_char( SV* h, const char* key );
static bool     sp_hv_exists( HV* h, const char* key );
static bool     sp_hvref_exists( SV* h, const char* key );
static SV*      sp_hv_delete( HV* h, const char* key );
static SV*      sp_hvref_delete( SV* h, const char* key );
static void     sp_hv_replace( HV *h, const char* key, SV* value );
static void     sp_hvref_replace( SV * hashref, char* key, SV* value );
static SV*      sp_bless_ptr( char* CLASS, void * c_ptr );
static char*    sp_get_objects_class( SV* object );
static HV*      sp_extract_hash( SV* object );
static void     sp_dump_hash( SV* hash_ref );
static void     sp_describe_object( SV* object );
static void*    sp_extract_ptr( SV* object );
static AV*      sp_get_xml2_hash_keys( xmlHashTablePtr xml2_hash );
static void     sp_add_key_to_array(xmlChar *val, AV *keys, xmlChar *key);
static SV*      sp_xml2_hash_to_perl_hash( xmlHashTablePtr xml2_hash, const char* class );
static void     sp_perl_hash_to_xml2_hash( HV* perlhash, xmlHashTablePtr xml2hash );
static void     sp_nb_hash_to_phash(xmlBufferPtr buf, HV *phash, xmlChar *key);
static HV*      sp_nb_to_hash( swish_NamedBuffer* nb );
static void     sp_test_handler( swish_ParserData* parse_data );
static void     sp_handler( swish_ParserData* parse_data );
static int      sp_tokenize3( swish_TokenIterator *ti,
                              xmlChar *buf, 
                              swish_MetaName *meta,
                              xmlChar *context );
static void     sp_SV_is_qr( SV *qr );
static REGEXP*  sp_get_regex_from_sv( SV* regex_sv );


/* implement nearly all methods for SWISH::3::Stash, a private class */

static SV*      sp_Stash_new();
static void     sp_Stash_set( SV *stash, const char *key, SV *value );
static void     sp_Stash_set_char( SV *stash, const char *key, char *value );
static void     sp_Stash_set_int( SV *stash, const char *key, int i);
static SV*      sp_Stash_get( SV *stash, const char *key );
static char*    sp_Stash_get_char( SV *stash, const char *key );
static void     sp_Stash_replace( SV *stash, const char *key, SV *value );
static int      sp_Stash_inner_refcnt( SV *stash );
static void     sp_Stash_destroy( SV *stash );
static void     sp_Stash_dec_values( SV *stash );
static void     sp_isw_report( uint32_t codepoint );


static SV*
sp_Stash_new()
{
    dTHX;
    HV *hash;
    SV *object;
    hash    = newHV();
    object  = sv_bless( newRV((SV*)hash), gv_stashpv("SWISH::3::Stash",0) );
    //sp_describe_object(object);
    SvREFCNT_dec( hash );   /* we want the refcnt to == 1 */
    return object;
}

static void
sp_Stash_set( SV *object, const char *key, SV *value )
{
    dTHX;
    HV *hash;
    hash = sp_extract_hash( object );
    sp_hv_store( hash, key, value );
}

static void
sp_Stash_set_char( SV *object, const char *key, char *value )
{
    dTHX;
    HV *hash;
    hash = sp_extract_hash( object );
    //warn("Storing %s => %s in stash\n", key, value);
    sp_hv_store_char( hash, key, value );
}

static void
sp_Stash_set_int( SV *object, const char *key, int i)
{
    dTHX;
    HV *hash;
    SV *value;
    value = newSViv((const IV)i);
    hash = sp_extract_hash( object );
    sp_hv_store( hash, key, value );
}

static SV*
sp_Stash_get( SV *object, const char *key )
{
    dTHX;
    HV *hash;
    hash = sp_extract_hash( object );
    //return SvREFCNT_inc( sp_hv_fetch( hash, key ) );
    return sp_hv_fetch( hash, key );
}

static char*
sp_Stash_get_char( SV *object, const char *key )
{
    dTHX;
    HV *hash;
    hash = sp_extract_hash( object );
    return sp_hv_fetch_as_char( hash, key );
}

static void
sp_Stash_replace( SV *object, const char *key, SV *value )
{
    dTHX;
    HV *hash;
    hash = sp_extract_hash( object );
    return sp_hv_replace( hash, key, value );
}

static int
sp_Stash_inner_refcnt( SV *object )
{
    dTHX;
    return SvREFCNT((SV*)SvRV((SV*)object));
}

static void
sp_Stash_destroy( SV *object )
{
    dTHX;
    SvREFCNT_dec(object);
    return;
    
    // this is redundant, as Perl does this for us...
    HV *hash;
    sp_Stash_dec_values(object);
    hash = sp_extract_hash( object );
    if ( SWISH_DEBUG ) {
        warn("Stash_destroy Stash object %s for class %s [%ld]", 
            SvPV(object, PL_na), sp_hv_fetch_as_char(hash, SELF_CLASS_KEY), (long)object);
        warn("Stash object refcnt = %d", (int)SvREFCNT(object));
        warn("Stash hash   refcnt = %d", (int)SvREFCNT(hash));
    }
    hv_undef(hash);
    //sp_describe_object( object );
    if (SvREFCNT( hash )) {
        SvREFCNT_dec( hash );
    }
    if (SvREFCNT( object ) ) {
        SvREFCNT_dec( object );
    }
}

static void
sp_Stash_dec_values(SV* stash)
{
    dTHX;
    HV* hash;
    HE* hash_entry;
    int num_keys, i;
    SV* sv_val;
    
    hash = sp_extract_hash( stash );
    num_keys = hv_iterinit(hash);
    //warn("Stash has %d keys", num_keys);
    for (i = 0; i < num_keys; i++) {
        hash_entry  = hv_iternext(hash);
        sv_val      = hv_iterval(hash, hash_entry);
        if( SvREFCNT(sv_val) > 1 ) { //&& SvTYPE(SvRV(sv_val)) == SVt_IV ) {
            warn("Stash value '%s' is a ptr object with refcount = %d", 
                SvPV(sv_val, PL_na), (int)SvREFCNT(sv_val));
            SvREFCNT_dec( sv_val );
        }
    }
}



static void
sp_SV_is_qr( SV *qr )
{
    dTHX;
    
    REGEXP *regex;
    
    regex = sp_get_regex_from_sv(qr);
}

static AV* 
sp_hv_keys(HV* hash) 
{
    dTHX;
    HE* hash_entry;
    int num_keys, i;
    SV* sv_key;
    char* key;
    SV* sv_keep;
    AV* keys;
    
    keys        = newAV();
    num_keys    = hv_iterinit(hash);
    av_extend(keys, (I32)num_keys);    
    
    for (i = 0; i < num_keys; i++) {
        hash_entry  = hv_iternext(hash);
        sv_key      = hv_iterkeysv(hash_entry);
        key         = SvPV(sv_key, PL_na);
        if ( xmlStrEqual( (xmlChar*)SELF_CLASS_KEY, (xmlChar*)key ) ) 
            continue;
            
        sv_keep     = newSVpv( key, 0 );
        av_push(keys, sv_keep);
    }
    
    //SvREFCNT_inc(keys);
    
    return keys;
}

static AV*
sp_hv_values(HV* hash) 
{
    dTHX;
    HE* hash_entry;
    int num_keys, i;
    SV* sv_val;
    SV* sv_key;
    char* key;
    AV* values;
        
    values = newAV();
    num_keys    = hv_iterinit(hash);
    av_extend(values, (I32)num_keys);
    
    for (i = 0; i < num_keys; i++) {
        hash_entry  = hv_iternext(hash);
        sv_key      = hv_iterkeysv(hash_entry);
        key         = SvPV(sv_key, PL_na);
        if ( xmlStrEqual( (xmlChar*)SELF_CLASS_KEY, (xmlChar*)key ) ) 
            continue;
            
        sv_val      = hv_iterval(hash, hash_entry);
        av_push(values, sv_val);
    }
    
    return values;
}



/* store SV* in a hash, incrementing its refcnt */
static SV*
sp_hv_store( HV* h, const char* key, SV* val)
{
    dTHX;
    SV** ok;
    ok = hv_store(h, key, strlen(key), SvREFCNT_inc(val), 0);
    if (ok != NULL)
    {
       if (SWISH_DEBUG)
        SWISH_DEBUG_MSG("stored %s ok in hash: %s", key, SvPV( *ok, PL_na ));
    }
    else
    {
        croak("failed to store %s in hash", key);
    }
    return *ok;
}

static SV*
sp_hv_store_char( HV* h, const char *key, char *val)
{
    dTHX;
    SV *value;
    value = newSVpv(val, 0);
    sp_hv_store( h, key, value );
    SvREFCNT_dec(value);
    return value;
}

static SV*
sp_hvref_store( SV* h, const char* key, SV* val)
{
    dTHX;
    return sp_hv_store( (HV*)SvRV(h), key, val );
}

static SV*
sp_hvref_store_char( SV* h, const char* key, char *val)
{
    dTHX;
    return sp_hv_store_char( (HV*)SvRV(h), key, val );
}

/* fetch SV* from hash */
static SV*
sp_hv_fetch( HV* h, const char* key )
{
    dTHX;
    SV** ok;
    ok = hv_fetch(h, key, strlen(key), 0);
    if (ok != NULL)
    {
       if (SWISH_DEBUG)
        SWISH_DEBUG_MSG("fetched %s ok: %s", key, SvPV( *ok, PL_na ));
    }
    else
    {
        croak("failed to fetch %s", key);
    }
    return *ok;
}

static SV*
sp_hvref_fetch( SV* h, const char* key )
{
    dTHX;
    return sp_hv_fetch((HV*)SvRV(h), key);
}

static bool
sp_hv_exists( HV* h, const char* key )
{
    dTHX;
    return hv_exists(h, key, strlen(key));
} 

static bool
sp_hvref_exists( SV* h, const char* key )
{
    dTHX;
    return sp_hv_exists((HV*)SvRV(h), key);
}

/* fetch SV* from hash */
static char*
sp_hv_fetch_as_char( HV* h, const char* key )
{
    dTHX;
    SV** ok;
    ok = hv_fetch(h, key, strlen(key), 0);
    if (ok != NULL)
    {
       if (SWISH_DEBUG)
        SWISH_DEBUG_MSG("fetched %s ok from hash: %s", key, SvPV( *ok, PL_na ));
    }
    else
    {
        croak("failed to fetch %s from hash", key);
    }
    return SvPV((SV*)*ok, PL_na);
}

static char*
sp_hvref_fetch_as_char( SV* h, const char* key )
{
    dTHX;
    return sp_hv_fetch_as_char( (HV*)SvRV(h), key );
}


/* delete SV* from hash, returning the deleted SV* */
static SV*
sp_hv_delete( HV* h, const char* key )
{
    dTHX;
    SV* oldval;
    oldval = hv_delete(h, key, strlen(key), 0 );
    if (oldval != NULL)
    {
        if (SWISH_DEBUG)
         SWISH_DEBUG_MSG("deleted %s ok from hash: %s", key, SvPV( oldval, PL_na ));
    }
    else
    {
        croak("failed to delete %s from hash", key);
    }
    return oldval;
}

static SV*
sp_hvref_delete( SV* h, const char* key )
{
    dTHX;
    return sp_hv_delete( (HV*)SvRV(h), key );
}


/* make a Perl blessed object from a C pointer */
static SV* 
sp_bless_ptr( char* CLASS, void * c_ptr )
{
    dTHX;
    // use sv_newmortal() rather than newSViv(c_ptr) because refcount is more consistent across platforms.
    // this is not what perlapi claims but what testing bears out.
    SV* obj = sv_newmortal(); 
    sv_setref_pv(obj, CLASS, c_ptr);
    //warn("refcnt of object %s == %d\n", SvPV(obj, PL_na), SvREFCNT(obj));
    return obj;
}

/* what class is an object blessed into? like Scalar::Util::blessed */
static char* 
sp_get_objects_class( SV* object )
{
    dTHX;
    char* class = (char*)sv_reftype(SvRV(object), 1);
    //warn("object belongs to %s\n", class);
    return class;
}

static HV* 
sp_extract_hash( SV* object )
{
    dTHX;
    HV* hash;
    char* class;
    
    class = sp_get_objects_class( object );
    if (SvROK(object) && SvTYPE(SvRV(object))==SVt_PVHV)
        hash = (HV*)SvRV(object);
    else if (SvROK(object) && SvTYPE(SvRV(object))==SVt_PVMG)
        croak("%s is a magic reference not a hash reference", class);
    else
        croak("%s is reference but not a hash reference", class);
        
    return hash;
}

static void 
sp_dump_hash(SV* hash_ref) 
{
    dTHX;
    HV* hash;
    HE* hash_entry;
    int num_keys, i;
    SV* sv_key;
    SV* sv_val;
    int refcnt;
    
    if (SvTYPE(SvRV(hash_ref))==SVt_PVHV) {
        warn("SV is a hash reference");
        hash        = (HV*)SvRV(hash_ref);
        num_keys    = hv_iterinit(hash);
        for (i = 0; i < num_keys; i++) {
            hash_entry  = hv_iternext(hash);
            sv_key      = hv_iterkeysv(hash_entry);
            sv_val      = hv_iterval(hash, hash_entry);
            refcnt      = SvREFCNT(sv_val);
            warn("  %s => %s  [%d]\n", SvPV(sv_key, PL_na), SvPV(sv_val, PL_na), refcnt);
        }
    }
    else if (SvTYPE(SvRV(hash_ref))==SVt_PVAV) {
        warn("SV is an array reference");
        
    }
    
    return;
}

static void 
sp_describe_object( SV* object )
{
    dTHX;
    char* str;
    
    warn("describing object\n");
    str = SvPV( object, PL_na );
    if (SvROK(object))
    {
      if (SvTYPE(SvRV(object))==SVt_PVHV)
        warn("%s is a magic blessed reference\n", str);
      else if (SvTYPE(SvRV(object))==SVt_PVMG)
        warn("%s is a magic reference", str);
      else if (SvTYPE(SvRV(object))==SVt_IV)
        warn("%s is a IV reference (pointer)", str); 
      else
        warn("%s is a reference of some kind", str);
    }
    else
    {
        warn("%s is not a reference", str);
        if (sv_isobject(object))
            warn("however, %s is an object", str);
        
        
    }
    warn("object dump");
    Perl_sv_dump( aTHX_ object );
    warn("object ref dump");
    Perl_sv_dump( aTHX_ (SV*)SvRV(object) );
    sp_dump_hash( object );
}

/* return the C pointer from a Perl blessed O_OBJECT */
static void* 
sp_extract_ptr( SV* object )
{
    dTHX;
    return INT2PTR( void*, SvIV(SvRV( object )) );
}

static void
sp_hv_replace( HV *hash, const char *key, SV *value )
{
    dTHX;
    if (sp_hv_exists(hash, key)) {
        sp_hv_delete(hash, key);
    }
    sp_hv_store( hash, key, value );
}

static void
sp_hvref_replace( SV * hashref, char* key, SV* value )
{
    dTHX;
    if (sp_hvref_exists(hashref, key)) {
        sp_hvref_delete(hashref, key);
    }
    sp_hvref_store( hashref, key, value );
}


static void 
sp_add_key_to_array(xmlChar* val, AV* mykeys, xmlChar* key)
{
    dTHX;
    SV *k = newSVpvn((char*)key, strlen((char*)key));
    av_push(mykeys, k);
}
 
static AV* 
sp_get_xml2_hash_keys( xmlHashTablePtr xml2_hash )
{
    dTHX;
    AV* mykeys = newAV();
    //SvREFCNT_inc((SV*)mykeys); /* needed?? */
    xmlHashScan(xml2_hash, (xmlHashScanner)sp_add_key_to_array, mykeys);
    return mykeys;
}


static void 
sp_make_perl_hash(char* value, SV* stash, xmlChar* key)
{
    dTHX;
    sp_Stash_set_char(stash, (const char*)key, value );
}


static SV* 
sp_xml2_hash_to_perl_hash( xmlHashTablePtr xml2_hash, const char* class )
{
    dTHX;
    SV* stash;
    stash = sp_Stash_new();
    sp_Stash_set_char(stash, SELF_CLASS_KEY, "xml2hash");
    xmlHashScan(xml2_hash, (xmlHashScanner)sp_make_perl_hash, stash);
    sp_describe_object( stash );
    return stash;
}

static void
sp_perl_hash_to_xml2_hash( HV* perlhash, xmlHashTablePtr xml2hash )
{
    croak("TODO");
}

static void
sp_nb_hash_to_phash(xmlBufferPtr buf, HV *phash, xmlChar *key)
{
    dTHX;
    AV* strings         = newAV();
    const xmlChar *str  = xmlBufferContent(buf);
    const xmlChar *tmp;
    int bump            = strlen(SWISH_TOKENPOS_BUMPER);
    int len;

    //warn("%s nb_content: '%s'\n", key, str);
        
    /* analogous to @strings = split(/SWISH_TOKENPOS_BUMPER/, str) */
    while((tmp = xmlStrstr(str, (xmlChar*)SWISH_TOKENPOS_BUMPER)) != NULL)
    {
        //warn("%s split: '%s'\n", key, str);
        len = tmp - str;
        if(len && !swish_str_all_ws_len((xmlChar*)str, len)) {
            av_push(strings, newSVpvn((char*)str, len));
        }
        str = tmp + bump;  /* move the pointer up */
    }
    
    /* no match and/or last match */
    if ( !xmlStrstr(str, (xmlChar*)SWISH_TOKENPOS_BUMPER) 
      && strlen((char*)str) 
      && !swish_str_all_ws((xmlChar*)str)
    ) {
        av_push(strings, newSVpvn((char*)str, strlen((char*)str)));
    }
        
    hv_store(phash,
            (char*)key, 
            strlen((char*)key), 
            (void*)newRV_noinc((SV*)strings), 
            0);
}

static HV* 
sp_nb_to_hash( swish_NamedBuffer* nb )
{
    dTHX;
    HV* perl_hash = newHV();
    xmlHashScan(nb->hash, (xmlHashScanner)sp_nb_hash_to_phash, perl_hash);
    return perl_hash;
}


static void 
sp_test_handler( swish_ParserData* parse_data )
{
    dTHX;
    warn("handler called!\n");
    swish_docinfo_debug( parse_data->docinfo );
    swish_token_list_debug( parse_data->token_iterator );
    swish_nb_debug( parse_data->properties, (xmlChar*)"Property" );
    swish_nb_debug( parse_data->metanames, (xmlChar*)"MetaName" );
    warn("\n");
}

/* C wrapper for our Perl handler.
   the parser object is passed in the parse_data stash.
   we dereference it, pull out the SV* CODE ref, and execute
   the Perl code.
*/
static void 
sp_handler( swish_ParserData* parse_data )
{
    dTHX;
    dSP;

    swish_3    *s3;
    SV         *handler; 
    SV         *obj;
    char       *data_class;
    
    //warn("sp_handler called");
    
    s3          = (swish_3*)parse_data->s3;
    
    //warn("got s3");
    //sp_describe_object(s3->stash);
    
    handler     = sp_Stash_get(s3->stash, HANDLER_KEY);
    
    //warn("got handler and s3");
    
    data_class  = sp_Stash_get_char(s3->stash, DATA_CLASS_KEY);
    
    //warn("data_class = %s", data_class);
    
    obj         = sp_bless_ptr( data_class, parse_data );
    
    //sp_describe_object(obj);
    
    PUSHMARK(SP);
    XPUSHs(obj);
    PUTBACK;

    call_sv(handler, G_DISCARD);
}

/* SvRX does this in Perl >= 5.10 */
static REGEXP*
sp_get_regex_from_sv( SV *regex_sv ) {
    dTHX;   /* thread-safe perlism */
    
    REGEXP *rx;
    MAGIC *mg;
    mg = NULL;

#if ((PERL_VERSION > 9) || (PERL_VERSION == 9 && PERL_SUBVERSION >= 5))
    rx = SvRX(regex_sv);
#else
    /* extract regexp struct from qr// entity */
    if (SvROK(regex_sv)) {
        SV *sv = SvRV(regex_sv);
        if (SvMAGICAL(sv))
            mg = mg_find(sv, PERL_MAGIC_qr);
    }
    if (!mg)
        croak("regex is not a qr// entity: %s", SvPV_nolen( regex_sv ));
        
    rx = (REGEXP*)mg->mg_obj;
#endif

    if (rx == NULL) {
        croak("Failed to extract REGEXP from regex_sv %s", 
            SvPV_nolen( regex_sv ));
    }
    
    return rx;
}



/* this regex wizardry cribbed from KS - thanks Marvin! */
static int
sp_tokenize3(
    swish_TokenIterator *ti,
    xmlChar *buf,
    swish_MetaName *meta,
    xmlChar *context
)
{
    dTHX;

/* declare */
    unsigned int    num_tokens;
    MAGIC           *mg;
    REGEXP          *rx;
    SV              *wrapper;
    xmlChar         *str_start;
    int              str_len;
    int              minwordlen, maxwordlen;
    xmlChar         *str_end;
    SV              *token_re;
#if (PERL_VERSION > 10)
    regexp          *r;
#endif

/* initialize */
    num_tokens      = 0;
    mg              = NULL;
    rx              = NULL;
    wrapper         = sv_newmortal();
    str_start       = buf;
    str_len         = strlen((char*)buf);
    str_end         = str_start + str_len;
    token_re        = ti->a->regex;
    minwordlen      = ti->a->minwordlen;
    maxwordlen      = ti->a->maxwordlen;
    
    rx = sp_get_regex_from_sv(token_re);
#if (PERL_VERSION > 10)
    r  = (regexp*)SvANY(rx);
#endif

    
/* fake up an SV wrapper to feed to the regex engine */
    sv_upgrade(wrapper, SVt_PV);
    SvREADONLY_on(wrapper);
    SvLEN(wrapper) = 0;
    SvUTF8_on(wrapper);     /* do UTF8 matching -- we trust str is already utf-8 encoded. */
    
/* wrap the string in an SV to please the regex engine */
    SvPVX(wrapper) = (char*)str_start;
    SvCUR_set(wrapper, str_len);
    SvPOK_on(wrapper);
    
    while ( pregexec(rx, (char*)buf, (char*)str_end, (char*)buf, 1, wrapper, 1) ) 
    {
        int token_len;
        xmlChar* start_ptr;
        xmlChar* end_ptr;
        
#if ((PERL_VERSION == 10) || (PERL_VERSION == 9 && PERL_SUBVERSION >= 5))
        start_ptr = buf + rx->offs[0].start;
        end_ptr   = buf + rx->offs[0].end;
#elif (PERL_VERSION > 10)
        start_ptr = buf + r->offs[0].start;
        end_ptr   = buf + r->offs[0].end;
#else
        start_ptr = buf + rx->startp[0];
        end_ptr   = buf + rx->endp[0];
#endif
        
        buf = end_ptr;

        //warn("Token: %s", start_ptr);

        token_len = (end_ptr - start_ptr) + 1;
        
        if (token_len < minwordlen)
            continue;
        
        if (token_len > maxwordlen)
            continue;
        
        swish_token_list_add_token(ti->tl, start_ptr, token_len, meta, context);
        num_tokens++;
        
    }
    
    return num_tokens;
}

static char *wctypes[] = {
    "alnum", "cntrl", "ideogram", "print", "special",
    "alpha", "digit", "lower", "punct", "upper",
    "blank", "graph", "phonogram", "space", "xdigit"
};

static int n_wctypes = 15;

static void
sp_isw_report( 
    uint32_t codepoint 
)
{
    int j;

    warn("%lc  %d  0x%04x\n", (wint_t)codepoint, codepoint, codepoint);

    for (j = 0; j < n_wctypes; j++) {
        warn("%10s => %d\n", wctypes[j], iswctype(codepoint, wctype(wctypes[j])));
    }
}
