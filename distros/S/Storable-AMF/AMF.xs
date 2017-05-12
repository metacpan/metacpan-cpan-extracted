/* 
 * vim: ts=8 sw=4 sts=4 et
 * */
#define _CRT_SECURE_NO_DEPRECATE /* Win32 compilers close eyes... */
#define PERL_NO_GET_CONTEXT
#undef  PERL_IMPLICIT_SYS /* Sigsetjmp will not work under this */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_mg_findext
#define NEED_grok_number
#define NEED_grok_numeric_radix
#define NEED_newRV_noinc
#define NEED_sv_2pv_flags
#include "ppport.h"


#ifndef PERL_UNUSED_VAR
#  define PERL_UNUSED_VAR(var) if (0) var = var
#endif

#ifndef STATIC_INLINE /* a public perl API from 5.13.4 */
#   if defined(__GNUC__) || defined(__cplusplus__) || (defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 199901L))
#       define STATIC_INLINE static inline
#   else
#       define STATIC_INLINE static
#   endif
#endif /* STATIC_INLINE */

#ifndef inline /* don't like borgs definitions */ /* inline is keyword for STDC compiler  */
#   if defined(__GNUC__) || defined(__cplusplus__) || (defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 199901L))
#   	if defined(__APPLE__)
#	    define inline 
#	endif
#   else
#	if defined(WIN32) && defined(_MSV) /* Microsoft Compiler */
#	    define inline _inline
#	else 
#	    define inline 
#	endif
#   endif
#endif /* inline  */
/* Stupid FreeBSD compiler failed with plain inline */
#define FREE_INLINE STATIC_INLINE

#define MARKER3_UNDEF	  '\x00'
#define MARKER3_NULL	  '\x01'
#define MARKER3_FALSE	  '\x02'
#define MARKER3_TRUE	  '\x03'
#define MARKER3_INTEGER	  '\x04'
#define MARKER3_DOUBLE    '\x05'
#define MARKER3_STRING    '\x06'
#define MARKER3_XML_DOC   '\x07'
#define MARKER3_DATE      '\x08'
#define MARKER3_ARRAY	  '\x09'
#define MARKER3_OBJECT	  '\x0a'
#define MARKER3_XML	  '\x0b'
#define MARKER3_BYTEARRAY '\x0c'
#define MARKER3_AMF_PLUS	  '\x11' 

#define MARKER0_NUMBER		  '\x00'
#define MARKER0_BOOLEAN		  '\x01'
#define MARKER0_STRING  	  '\x02'
#define MARKER0_OBJECT		  '\x03'
#define MARKER0_CLIP		  '\x04'
#define MARKER0_UNDEFINED  	  '\x05'
#define MARKER0_NULL		  '\x06'
#define MARKER0_REFERENCE 	  '\x07'
#define MARKER0_ECMA_ARRAY 	  '\x08'
#define MARKER0_OBJECT_END	  '\x09'
#define MARKER0_STRICT_ARRAY	  '\x0a'
#define MARKER0_DATE	  	  '\x0b'
#define MARKER0_LONG_STRING       '\x0c'
#define MARKER0_UNSUPPORTED	  '\x0d'
#define MARKER0_RECORDSET	  '\x0e'
#define MARKER0_XML_DOCUMENT      '\x0f'
#define MARKER0_TYPED_OBJECT	  '\x10'
#define MARKER0_AMF_PLUS	  '\x11' 

#define ERR_EOF                 1
#define ERR_AMF0_REF            2
#define ERR_MARKER              3
#define ERR_BAD_OBJECT          4
#define ERR_OVERFLOW            5
#define ERR_UNIMPLEMENTED       6
#define ERR_BAD_STRING_REF      7
#define ERR_BAD_DATE_REF        8
#define ERR_BAD_OBJECT_REF      9
#define ERR_BAD_ARRAY_REF       10
#define ERR_BAD_STRING_REF_UNUSED 11
#define ERR_BAD_TRAIT_REF       12
#define ERR_BAD_XML_REF         13
#define ERR_BAD_BYTEARRAY_REF   14
#define ERR_EXTRA_BYTE          15
#define ERR_INT_OVERFLOW        16
#define ERR_RECURRENT_OBJECT    17
#define ERR_BAD_REFVAL          18
#define ERR_INTERNAL            19
#define ERR_ARRAY_TOO_BIG       20
#define ERR_BAD_OPTION          21

#define OPT_STRICT        1
#define OPT_DECODE_UTF8   2
#define OPT_ENCODE_UTF8   4
#define OPT_RAISE_ERROR   8
#define OPT_MILLSEC_DATE  16
#define OPT_PREFER_NUMBER 32
#define OPT_JSON_BOOLEAN  64
#define OPT_MAPPER        128
#define OPT_TARG          256
#define OPT_SKIP_BAD      512

#define STR_EMPTY    '\x01'
#define EXPERIMENT1

#define AMF0_VERSION 0
#define AMF3_VERSION 3

#if BYTEORDER == 0x1234
    #define GAX "LIT"
    #define GET_NBYTE(ALL, IPOS, TYPE) (ALL - 1 - IPOS)
#else
#if BYTEORDER == 0x12345678
    #define GAX "LIT"
    #define GET_NBYTE(ALL, IPOS, TYPE) (ALL - 1 - IPOS)
#else
#if BYTEORDER == 0x87654321
    #define GAX "BIG"
    #define GET_NBYTE(ALL, IPOS, TYPE) (sizeof(TYPE) -ALL + IPOS)
#else
#if  BYTEORDER == 0x4321
    #define GAX "BIG"
    #define GET_NBYTE(ALL, IPOS, TYPE) (sizeof(TYPE) -ALL + IPOS)
#else
    #error Unknown byteorder. Please append your byteorder to Storable/AMF.xs
#endif
#endif
#endif
#endif

#define ARRAY_SIZE(x) (sizeof(x)/sizeof(x[0]))

#define SIGN_BOOL_APPLY( obj, sign, mask ) ( sign > 0 ? obj|=mask : sign <0 ? obj&=~mask : 0 ) 
#define DEFAULT_MASK (OPT_PREFER_NUMBER|OPT_TARG)

STATIC MGVTBL my_vtbl_empty = {0, 0, 0, 0, 0, 0, 0};

char *error_messages[] = {
    "ERR_EOF", 
    "ERR_BAD_AMF0_REF", 
    "ERR_MARKER", 
    "ERR_BAD_OBJECT", 
    "ERR_OVERFLOW", 
    "ERR_UNIMPLEMENTED", 
    "ERR_BAD_STRING_REF", 
    "ERR_BAD_DATE_REF", 
    "ERR_BAD_OBJECT_REF", 
    "ERR_BAD_ARRAY_REF", 
    "ERR_BAD_STRING_REF_UNUSED",
    "ERR_BAD_TRAIT_REF",
    "ERR_BAD_XML_REF", 
    "ERR_BAD_BYTEARRAY_REF", 
    "ERR_EXTRA_BYTE", 
    "ERR_INT_OVERFLOW", 
    "ERR_RECURRENT_OBJECT", 
    "ERR_BAD_REFVAL",  
    "ERR_INTERNAL",
    "ERR_ARRAY_TOO_BIG",
    "ERR_BAD_OPTION",
    0
};
struct io_amf_option;
/*#define TRACE0 */
struct amf3_restore_point{
    int offset_buffer;
    int offset_object;
    int offset_trait;
    int offset_string;
    int arr_max;
};

struct io_struct{
    unsigned char * ptr;
    unsigned char * pos;
    unsigned char * end;
    SV *sv_buffer;
    AV *arr_object;
    AV *arr_string;
    AV *arr_trait;
    HV *hv_object;
    HV *hv_string;
    HV *hv_trait;
    SV *sv_buffer2;
    AV *arr_object2;
    AV *arr_string2;
    AV *arr_trait2;
    HV *hv_object2;
    HV *hv_string2;
    HV *hv_trait2;
    int rc_object;
    int rc_string;
    int rc_trait;
    int version;
    int final_version;
    int buffer_step_inc;
    int arr_max;
    int error_code;
    Sigjmp_buf target_error;
    SV * (*parse_one_object)(pTHX_ struct io_struct * io);
    char *subname;
    int options;
    int default_options;
    SV * Bool[2];
    int bool_init;
    char status;
    bool reuse;
};

FREE_INLINE void ref_clear(pTHX_ HV * go_once, SV *sv);
FREE_INLINE SV*  tmpstorage_create_sv( pTHX_ CV *cv, SV *option );
FREE_INLINE void tmpstorage_destroy_sv( pTHX_ SV *self);
FREE_INLINE struct io_struct * tmpstorage_create_io( pTHX_ void * );
FREE_INLINE void tmpstorage_destroy_io( pTHX_ struct io_struct *io);

STATIC_INLINE SV * amf0_parse_one(pTHX_ struct io_struct * io);
STATIC_INLINE SV * amf3_parse_one(pTHX_ struct io_struct * io);
FREE_INLINE void io_in_destroy(pTHX_ struct io_struct * io, AV *);
FREE_INLINE void io_in_cleanup(pTHX_ struct io_struct *io);
FREE_INLINE void io_out_cleanup(pTHX_ struct io_struct * io);

FREE_INLINE void io_test_eof(pTHX_ struct io_struct *io);
FREE_INLINE void io_register_error(struct io_struct *io, int);
FREE_INLINE void io_register_error_and_free(pTHX_ struct io_struct *io, int, SV *);
FREE_INLINE int
io_position(struct io_struct *io){
    return io->pos-io->ptr;
}

FREE_INLINE void
io_set_position(struct io_struct *io, int pos){
    io->pos = io->ptr + pos;
}

FREE_INLINE void 
io_savepoint(pTHX_ struct io_struct *io, struct amf3_restore_point *p){
    p->offset_buffer = io_position(io);
    p->offset_object = av_len(io->arr_object);
    p->offset_trait  = av_len(io->arr_trait);
    p->offset_string = av_len(io->arr_string);
}
FREE_INLINE void
io_restorepoint(pTHX_ struct io_struct *io, struct amf3_restore_point *p){
    io_set_position(io, p->offset_buffer);	
    while(av_len(io->arr_object) > p->offset_object){
        SV * abc = av_pop(io->arr_object);
        sv_2mortal(abc);
    }
    while(av_len(io->arr_trait) > p->offset_trait){
        sv_2mortal(av_pop(io->arr_trait));
    }
    while(av_len(io->arr_string) > p->offset_string){
        sv_2mortal(av_pop(io->arr_string));
    }
}


FREE_INLINE void
io_move_backward(struct io_struct *io, int step){
    io->pos-= step;
}

FREE_INLINE void
io_move_forward(struct io_struct *io, int len){
    io->pos+=len;	
}

FREE_INLINE void
io_require(struct io_struct *io, int len){
    if (io->end - io->pos < len){
        io_register_error(io, ERR_EOF);
    }
}

FREE_INLINE void
io_reserve(pTHX_ struct io_struct *io, int len){
    if (io->end - io->pos< len){
        unsigned int ipos = io->pos - io->ptr;
        unsigned int buf_len;

        SvCUR_set(io->sv_buffer, ipos);
        buf_len = SvLEN(io->sv_buffer);
        while( buf_len < ipos + len + io->buffer_step_inc){
            buf_len *= 4;
            buf_len += len+io->buffer_step_inc;
        }
        io->ptr = (unsigned char *) SvGROW(io->sv_buffer, buf_len);
        io->pos = io->ptr + ipos;
        io->end = io->ptr + SvLEN(io->sv_buffer);
    }
}
FREE_INLINE void io_register_error(struct io_struct *io, int errtype){
    io->error_code = errtype;
    Siglongjmp(io->target_error, errtype);
}

FREE_INLINE void io_test_eof(pTHX_ struct io_struct *io){
    if (io->pos!=io->end){
	io_register_error(io, ERR_EOF );
    }
}
void io_format_error(pTHX_ struct io_struct *io ){
    int error_code = io->error_code;
    char *message;
    if ( error_code < 1 || error_code >= ARRAY_SIZE( error_messages )){
	error_code = ERR_INTERNAL;
    };
    message = error_messages[ error_code - 1];

    if ( io->status == 'r' ){
	io_in_destroy(aTHX_  io, 0); /* all objects */
	if (io->options & OPT_RAISE_ERROR){
	    croak("Parse AMF%d: %s (ERR-%d)", io->version, message, error_code);
	}
	else {
	    sv_setiv(ERRSV, error_code);
	    sv_setpvf(ERRSV, "Parse AMF%d: %s (ERR-%d)", io->version, message, error_code);
	    SvIOK_on(ERRSV);
	}
    }
    else { /* io->status == 'w' */
        io_out_cleanup(aTHX_ io);
	if (io->options & OPT_RAISE_ERROR){
	    croak("Format AMF%d: %s (ERR-%d)", io->version, message, error_code);
	}
	else {
	    sv_setiv(ERRSV, error_code);
	    sv_setpvf(ERRSV, "Format AMF%d: %s (ERR-%d)", io->version, message, error_code);
	    SvIOK_on(ERRSV);
	}
    }
}

FREE_INLINE void io_register_error_and_free(pTHX_ struct io_struct *io, int errtype, SV *pointer){
    if (pointer)
        sv_2mortal((SV*) pointer);
    Siglongjmp(io->target_error, errtype);
}
FREE_INLINE struct io_struct *  tmpstorage_create_io(pTHX_ void*ignore){
    int ibuf_size = 10240;
    struct io_struct * io;
    SV *sv ;
    PERL_UNUSED_VAR(ignore);
    Newxz( io, 1, struct io_struct );
    io->arr_object2 = newAV();
    io->arr_string2 = newAV();
    io->arr_trait2  = newAV();
    io->arr_object  = io->arr_object2;
    io->arr_string  = io->arr_string2;
    io->arr_trait   = io->arr_trait2;
    av_extend( io->arr_object, 32 ); 
    av_extend( io->arr_string, 32 ); 
    av_extend( io->arr_trait, 32 ); 

    io->hv_object        = newHV();
    HvSHAREKEYS_off( io->hv_object );
    io->hv_string        = newHV();
    HvSHAREKEYS_off( io->hv_string );
    io->hv_trait         = newHV();
    HvSHAREKEYS_off( io->hv_trait );
    io->hv_object2 = io->hv_object;
    io->hv_string2 = io->hv_string;
    io->hv_trait2  = io->hv_trait;

    io->sv_buffer2 = newSV(0);
    (void)SvUPGRADE(io->sv_buffer2, SVt_PV);
    SvPOK_on( io->sv_buffer2);
    SvGROW( io->sv_buffer2, ibuf_size ); 
    io->default_options = DEFAULT_MASK;
    io->options = DEFAULT_MASK;
    io->reuse   = 1;

    return io;
}
FREE_INLINE struct io_struct *  tmpstorage_create_and_cache(pTHX_ CV *cv){
    MAGIC *mg;
    struct io_struct *io;
    SV *cache_sv;
    mg = mg_findext( (SV *)cv, PERL_MAGIC_ext, &my_vtbl_empty);
    if (mg){
        /* fprintf(stderr, "Found magic=%p\n", mg->mg_ptr); */
        io = (struct io_struct *)mg->mg_ptr;
        return io;
    }
    cache_sv = get_sv("Storable::AMF0::CacheIO", GV_ADDMULTI | GV_ADD);
    mg = SvTYPE(cache_sv) ? mg_findext( (SV *)cache_sv, PERL_MAGIC_ext, &my_vtbl_empty) : NULL;
    if (mg){
        /* fprintf(stderr, "Found with var magic=%p\n", mg->mg_ptr); */
        io = (struct io_struct *)mg->mg_ptr;
    }
    else {
        /* fprintf(stderr, "Not Found magic=%p\n", io); */
        io = tmpstorage_create_io(aTHX_ NULL); 
        sv_magicext( (SV *)cache_sv, NULL, PERL_MAGIC_ext, &my_vtbl_empty, (const char * const)io, 0);
    }

    sv_magicext( (SV *)cv, NULL, PERL_MAGIC_ext, &my_vtbl_empty, (const char * const)io, 0);
    return io;
}
FREE_INLINE SV*  tmpstorage_create_sv(pTHX_ CV *cv, SV* option){
    struct io_struct * io;
    SV *sv ;
    io = tmpstorage_create_io(aTHX_ NULL);
    if ( option ){
        io->options = SvIV(option);
        io->default_options= SvIV(option);
    }
    else {
        io->options = DEFAULT_MASK;
        io->default_options= DEFAULT_MASK;
    }
    sv = sv_newmortal();
    sv_setref_iv( sv, "Storable::AMF0::TemporaryStorage", PTR2IV( io ) );
    return sv;
}
FREE_INLINE void tmpstorage_destroy_io( pTHX_ struct io_struct *io ){
    SvREFCNT_dec( (SV *) io->arr_object2 );
    SvREFCNT_dec( (SV *) io->arr_string2 );
    SvREFCNT_dec( (SV *) io->arr_trait2 );
    SvREFCNT_dec( (SV *) io->hv_object2 );
    SvREFCNT_dec( (SV *) io->hv_string2 );
    SvREFCNT_dec( (SV *) io->hv_trait2 );
    SvREFCNT_dec( (SV *) io->sv_buffer2 );
    Safefree( io );  
    /*    fprintf( stderr, "Destroy\n"); */
}
FREE_INLINE void tmpstorage_destroy_sv( pTHX_ SV *self ){
    if ( ! SvROK( self )) {
        croak( "Bad Storable::AMF0::TemporaryStorage" );
    }
    else {
        tmpstorage_destroy_io( aTHX_ INT2PTR( struct io_struct*, SvIV( SvRV( self ) ) ) );
    }
}
FREE_INLINE void io_in_cleanup(pTHX_ struct io_struct *io){
    av_clear( io->arr_object );
    if ( AMF3_VERSION == io->final_version ){
        av_clear( io->arr_string );
        av_clear( io->arr_trait );
    };
}
FREE_INLINE void io_out_cleanup(pTHX_ struct io_struct *io){
    hv_clear( io->hv_object );
    if ( AMF3_VERSION == io->version ){
        hv_clear( io->hv_string );
        hv_clear( io->hv_trait );
    };
}
FREE_INLINE void io_in_init(pTHX_ struct io_struct * io,  SV* data, int amf_version, SV * sv_option){
    struct io_struct *reuse_storage_ptr=io;
    bool reuse_storage = 1;
    if ( sv_option ){
        if (! SvIOK(sv_option)){
            if ( ! sv_isobject( sv_option )){
                warn( "options are not integer" );
                io_register_error(io, ERR_BAD_OPTION );
                return;
            }
            else {
                reuse_storage_ptr = INT2PTR( struct io_struct *, SvIV( SvRV( sv_option )));
                io->options       = reuse_storage_ptr->options;
            }
        } 
        else {        
	    io->options = SvIV(sv_option); 
	    io->bool_init = 0;
        }
    }
    else {
        io->options = io->default_options;
    }
    io->reuse = reuse_storage_ptr != io;
    
    if (SvMAGICAL(data))
        mg_get(data);

    if (!SvPOKp(data))
        croak("%s. data must be a string", io->subname);

    if (SvUTF8(data)) 
        croak("%s: data is utf8. Can't process utf8", io->subname);
    
    io->ptr = (unsigned char *) SvPVX(data);
    io->end = io->ptr + SvCUR(data);
    io->pos = io->ptr;
    io->status  = 'r';
    io->version = amf_version;
    if ( amf_version == AMF0_VERSION && (io->ptr[0] == MARKER0_AMF_PLUS) ){
	amf_version = AMF3_VERSION;
	++io->pos;
    };
    io->final_version = amf_version; 
    /* Support when  array extend is too big */
    io->arr_max = SvCUR( data );

    if (amf_version == AMF3_VERSION) {
        if ( reuse_storage ){
            io->arr_object = reuse_storage_ptr->arr_object2;
            io->arr_string = reuse_storage_ptr->arr_string2;
            io->arr_trait =  reuse_storage_ptr->arr_trait2;
            io->reuse = 1;
        }
        else {
            io->arr_object = newAV();
            sv_2mortal( (SV *) (io->arr_object) );
            io->arr_string = newAV();
            sv_2mortal((SV*) io->arr_string);
            io->arr_trait = newAV();
            sv_2mortal((SV*) io->arr_trait);
        }
    }
    else {
        if ( reuse_storage ){
            io->arr_object = reuse_storage_ptr->arr_object2;
            io->reuse = 1;
        }
        else {
            io->arr_object = newAV();
            sv_2mortal( (SV *) (io->arr_object) );
        }
    }
    if (amf_version == AMF3_VERSION) {
        io->parse_one_object = amf3_parse_one;
    }
    else {
        io->parse_one_object = amf0_parse_one;
    }
    return;
}
FREE_INLINE void io_in_destroy(pTHX_ struct io_struct * io, AV *a){
    int i;
    SV **ref_item;
    int alen;
    SV *item;
    if (a) {
        alen = av_len(a);
        for(i = 0; i<= alen; ++i){
            ref_item = av_fetch(a,i,0);
            if (ref_item){
                if (SvROK(*ref_item)){
                    item = SvRV(*ref_item);
                    if (SvTYPE(item) == SVt_PVAV){
                        av_clear((AV*) item);
                    }
                    else if (SvTYPE(item) == SVt_PVHV){
                        HV * h = (HV*) item;
                        hv_clear(h);
                    }
                }
            }
        }
        av_clear(a); /* cleaning array */
    }
    else {
        if (io->final_version == AMF0_VERSION){
            io_in_destroy(aTHX_  io, io->arr_object);
        }
        else if (io->final_version == AMF3_VERSION) {
            io_in_destroy(aTHX_  io, io->arr_object);
            io_in_destroy(aTHX_  io, io->arr_trait); /* May be not needed */
            io_in_destroy(aTHX_  io, io->arr_string);
        }
        else {
            croak("bad version at destroy");
        }
    }
}
STATIC_INLINE void io_out_init(pTHX_ struct io_struct *io, SV*sv_option, int amf_version){
    unsigned int ibuf_size = 10240;
    unsigned int ibuf_step = 20480;
    struct io_struct *reuse_storage_ptr = io;
    SV *sv_buffer;
    io->version = amf_version;

    io->reuse = 1;

    if ( sv_option ){
        if ( SvROK(sv_option) && sv_isobject( sv_option )){
            reuse_storage_ptr = INT2PTR( struct io_struct *, SvIV( SvRV( sv_option )));
            io->options       = reuse_storage_ptr->options;
        }
        else if ( !SvIOK(sv_option)){
            io_register_error(io, ERR_BAD_OPTION );
        }
        else {
            io->options = SvIV( sv_option );
        }
    }
    else {
        io->options = io->default_options;
    };

    if ( io->options & OPT_TARG ){
        dXSTARG;

        sv_buffer = TARG;
        (void)SvUPGRADE(sv_buffer, SVt_PV);
        SvPOK_on(sv_buffer);
        SvGROW( sv_buffer, 7 );
        if (SvLEN(sv_buffer) <= 64 ){
            sv_buffer = reuse_storage_ptr->sv_buffer2;
        }
    }
    else {
        if (io->reuse){
            sv_buffer = reuse_storage_ptr->sv_buffer2;
        }
        else {
            sv_buffer = sv_2mortal(newSVpvn("",0));
            SvGROW(sv_buffer, ibuf_size);
        }
    }
    io->sv_buffer = sv_buffer;
    if (amf_version) {
        if (io->reuse){
            io->hv_object = reuse_storage_ptr->hv_object2;
            io->hv_string = reuse_storage_ptr->hv_string2;
            io->hv_trait  = reuse_storage_ptr->hv_trait2;
        }
        else {
            io->hv_object = newHV();
            io->hv_string = newHV();
            io->hv_trait  = newHV();

            HvSHAREKEYS_off( io->hv_object );
            HvSHAREKEYS_off( io->hv_string );
            HvSHAREKEYS_off( io->hv_trait );

            sv_2mortal((SV *)io->hv_object);
            sv_2mortal((SV *)io->hv_string);
            sv_2mortal((SV *)io->hv_trait);
        }

        io->rc_object = 0;
        io->rc_string = 0;
        io->rc_trait  = 0;
    }
    else {
        if (io->reuse ){
            io->hv_object = reuse_storage_ptr->hv_object2;
        }
        else {
            io->hv_object   = newHV();
            HvSHAREKEYS_off( io->hv_object ); 
            sv_2mortal((SV*)io->hv_object);
        }
        io->rc_object = 0;
    }
    io->buffer_step_inc = ibuf_step;
    io->ptr = (unsigned char *) SvPV_nolen(sv_buffer);
    io->pos = io->ptr;
    io->end = (unsigned char *) SvEND(sv_buffer);
    io->status  = 'w';
}

FREE_INLINE SV * io_buffer(struct io_struct *io){
    SvCUR_set(io->sv_buffer, io->pos - io->ptr);
    return io->sv_buffer;
}

FREE_INLINE double io_read_double(struct io_struct *io);
FREE_INLINE unsigned char io_read_marker(struct io_struct * io);
FREE_INLINE int io_read_u8(struct io_struct * io);
FREE_INLINE int io_read_u16(struct io_struct * io);
FREE_INLINE int io_read_u32(struct io_struct * io);
FREE_INLINE int io_read_u24(struct io_struct * io);


#define MOVERFLOW(VALUE, MAXVALUE, PROC)\
	if (VALUE > MAXVALUE) { \
		fprintf( stderr, "Overflow in %s. expected less %d. got %d\n", PROC, MAXVALUE, VALUE); \
		io_register_error(io, ERR_OVERFLOW); \
	}



FREE_INLINE void io_write_double(pTHX_ struct io_struct *io, double value){
    const int step = 8;
    union {
        signed   int iv;
        unsigned int uv;
        double nv;
        char   c[8];
    } v;
    io_reserve(aTHX_  io, step );
    v.nv = value;
    io->pos[0] = v.c[GET_NBYTE(step, 0, value)];
    io->pos[1] = v.c[GET_NBYTE(step, 1, value)];
    io->pos[2] = v.c[GET_NBYTE(step, 2, value)];
    io->pos[3] = v.c[GET_NBYTE(step, 3, value)];
    io->pos[4] = v.c[GET_NBYTE(step, 4, value)];
    io->pos[5] = v.c[GET_NBYTE(step, 5, value)];
    io->pos[6] = v.c[GET_NBYTE(step, 6, value)];
    io->pos[7] = v.c[GET_NBYTE(step, 7, value)];
    io->pos+= step ;
    return;
}
FREE_INLINE void io_write_marker(pTHX_ struct io_struct * io, char value)	{
    const int step = 1;
    io_reserve(aTHX_  io, 1);
    io->pos[0]= value;
    io->pos+=step;
    return;
}
FREE_INLINE void io_write_uchar (pTHX_ struct io_struct * io, unsigned char value)	{
    const int step = 1;
    io_reserve(aTHX_  io, 1);
    io->pos[0]= value;
    io->pos+=step;
    return;
}

FREE_INLINE void io_write_u8(pTHX_ struct io_struct * io, unsigned int value){
    const int step = 1;
    union {
        signed   int iv;
        unsigned int uv;
        double nv;
        char   c[8];
    } v;
    v.uv = value;
    MOVERFLOW(value, 255, "write_u8");
    io_reserve(aTHX_  io, 1);
    io->pos[0]= v.c[GET_NBYTE(step, 0,value)]; 
    io->pos+=step ;
    return;
}


FREE_INLINE void io_write_s16(pTHX_ struct io_struct * io, signed int value){
    const int step = 2;
    union {
        signed   int iv;
        unsigned int uv;
        double nv;
        char   c[8];
    } v;
    v.iv = value;
    MOVERFLOW(value, 32767, "write_s16");
    io_reserve(aTHX_  io, step);
    io->pos[0]= v.c[GET_NBYTE(step, 0, value)];
    io->pos[1]= v.c[GET_NBYTE(step, 1, value)];
    io->pos+=step;
    return;
}

FREE_INLINE void io_write_u16(pTHX_ struct io_struct * io, unsigned int value){
    const int step = 2;
    union {
        signed   int iv;
        unsigned int uv;
        double nv;
        char   c[8];
    } v;
    io_reserve(aTHX_  io,step);
    MOVERFLOW(value, 65535 , "write_u16");
    v.uv = value;
    io->pos[0] = v.c[GET_NBYTE(step, 0, value)];
    io->pos[1] = v.c[GET_NBYTE(step, 1, value)];
    io->pos+=step;
    return;
}

FREE_INLINE void io_write_u32(pTHX_ struct io_struct * io, unsigned int value){
    const int step = 4;
    union {
        signed   int iv;
        unsigned int uv;
        double nv;
        char   c[8];
    } v;
    io_reserve(aTHX_  io,step);
    v.uv = value;
    io->pos[0] = v.c[GET_NBYTE(step, 0, value)];
    io->pos[1] = v.c[GET_NBYTE(step, 1, value)];
    io->pos[2] = v.c[GET_NBYTE(step, 2, value)];
    io->pos[3] = v.c[GET_NBYTE(step, 3, value)];
    io->pos+=step;
    return;
}

FREE_INLINE void io_write_u24(pTHX_ struct io_struct * io, unsigned int value){
    const int step = 3;
    union {
        signed   int iv;
        unsigned int uv;
        double nv;
        char   c[8];
    } v;
    io_reserve(aTHX_  io,step);
    MOVERFLOW(value,16777215 , "write_u16");
    v.uv = value;
    io->pos[0] = v.c[GET_NBYTE(step, 0, value)];
    io->pos[1] = v.c[GET_NBYTE(step, 1, value)];
    io->pos[2] = v.c[GET_NBYTE(step, 2, value)];
    io->pos+=step;
    return;
}
FREE_INLINE void io_write_bytes(pTHX_ struct io_struct* io, const char * const buffer, int len){
    io_reserve(aTHX_  io, len);
    Copy(buffer, io->pos, len, char);
    io->pos+=len;
}	
/* Date checking */
FREE_INLINE bool   util_is_date(SV *one);
FREE_INLINE double util_date_time(SV *one);

STATIC_INLINE void amf0_format_one(pTHX_ struct io_struct *io, SV * one);
STATIC_INLINE void amf0_format_number(pTHX_ struct io_struct *io, SV * one);
STATIC_INLINE void amf0_format_string(pTHX_ struct io_struct *io, SV * one);
STATIC_INLINE void amf0_format_strict_array(pTHX_ struct io_struct *io, AV * one);
STATIC_INLINE void amf0_format_object(pTHX_ struct io_struct *io, HV * one);
STATIC_INLINE void amf0_format_null(pTHX_ struct io_struct *io);
STATIC_INLINE void amf0_format_typed_object(pTHX_ struct io_struct *io, HV * one);

FREE_INLINE bool util_is_date(SV *one){
    if (SvNOKp(one)){
	HV* stash = SvSTASH(one);
	char *class_name = HvNAME(stash);
	if (*class_name == '*' && class_name[1] == 0){
	    return 1;
	}
	else {
	    return 0;
	}
    }
    else {
	return 0;
    }
}
FREE_INLINE double util_date_time(SV *one){
    return (SvNVX(one)*1000);
}
FREE_INLINE void amf0_format_reference(pTHX_ struct io_struct * io, SV *ref_sv){
    io_write_marker(aTHX_  io, MARKER0_REFERENCE);
    io_write_u16(aTHX_  io, SvIV(ref_sv));
}
FREE_INLINE void amf0_format_scalar_ref(pTHX_ struct io_struct * io, SV *ref_sv){
    const char *const reftype = "REFVAL";
    
    io_write_marker(aTHX_  io, MARKER0_TYPED_OBJECT);
    /* special type */
    io_write_u16(aTHX_  io, 6);
    io_write_bytes(aTHX_  io, reftype, 6);

    /* type */
    io_write_u16(aTHX_  io, 6);
    io_write_bytes(aTHX_  io, reftype, 6);
    amf0_format_one(aTHX_  io, ref_sv);
    /* end marker */
    io_write_u16(aTHX_  io, 0);
    io_write_marker(aTHX_  io, MARKER0_OBJECT_END);
}

FREE_INLINE void amf0_format_one(pTHX_ struct io_struct *io, SV * one){
    SV *rv = 0;
    bool is_perl_bool = 0;
    if (SvROK(one)){
        rv = (SV*) SvRV(one);
	if ( sv_isobject( one )){
            HV* stash = SvSTASH(rv);
            char *class_name = HvNAME(stash);
            if ( class_name[0] == 'J' ){
                if ( sv_isa(one, "JSON::PP::Boolean")){
                    is_perl_bool =  1;
                }
                else if ( sv_isa(one, "JSON::XS::Boolean") ){
                    is_perl_bool =  1;
                }
            }
            else if ( class_name[0] == 'b' ){
                if ( sv_isa(one, "boolean" )){
                    is_perl_bool  = 1;
                }
            }
	    if ( is_perl_bool ){
		io_write_marker(aTHX_ io, MARKER0_BOOLEAN );
		/*  TODO SvTRUE can call die or something like */
		io_write_uchar(aTHX_  io, SvTRUE( SvRV( one  )) ? 1 : 0);
		return ;
	    }
	}
    }

    if (rv){
        /*  test has stored */
        SV **OK = hv_fetch(io->hv_object, (char *)(&rv), sizeof (rv), 1);
        if (SvOK(*OK)) {
            amf0_format_reference(aTHX_  io, *OK);
        }
        else {
            int type = SvTYPE(rv);
            sv_setiv(*OK, io->rc_object);
            ++io->rc_object;

            if (sv_isobject(one)) {
		if ( io->options & OPT_MAPPER ){
		    GV *to_amf = gv_fetchmethod_autoload (SvSTASH (rv), "TO_AMF", 0);
		    if ( to_amf ) {
		    dSP;

		    ENTER; SAVETMPS; PUSHMARK (SP);
		    XPUSHs (sv_bless (sv_2mortal (newRV_inc (rv)), SvSTASH (rv)));

		    /* calling with G_SCALAR ensures that we always get a 1 return value */
		    PUTBACK;
		    call_sv ((SV *)GvCV (to_amf), G_SCALAR);
		    SPAGAIN;

		    /* catch this surprisingly common error */
		    if (SvROK (TOPs) && SvRV (TOPs) == rv)
			croak ("%s::TO_AMF method returned same object as was passed instead of a new one", HvNAME (SvSTASH (rv)));

		    rv = POPs;
		    PUTBACK;

		    amf0_format_one( aTHX_  io, rv);

		    FREETMPS; LEAVE;
		    return ;

		    }
		}
                if (SvTYPE(rv) == SVt_PVHV){
                    amf0_format_typed_object(aTHX_  io, (HV *) rv);
                }
		else if ( util_is_date( rv ) ) {
		    io_write_marker(aTHX_ io, MARKER0_DATE );
		    io_write_double(aTHX_ io, util_date_time( rv ));
		    io_write_s16(aTHX_ io, 0 );
		}
		else {		    
                    /* may be i has to format as undef */
		    if ( io->options & OPT_SKIP_BAD ){
			io_write_marker( aTHX_ io, MARKER0_UNDEFINED );
		    }
		    else 
			io_register_error(io, ERR_BAD_OBJECT);
                }
            }
            else if (SvTYPE(rv) == SVt_PVAV) 
                amf0_format_strict_array(aTHX_  io, (AV*) rv);
            else if (SvTYPE(rv) == SVt_PVHV) {
                io_write_marker(aTHX_  io, MARKER0_OBJECT);
                amf0_format_object(aTHX_  io, (HV*) rv);
            }
            else if ( type != SVt_PVCV && type !=  SVt_PVGV ) {
                amf0_format_scalar_ref(aTHX_  io, (SV*) rv);
            }
            else {
		if ( io->options & OPT_SKIP_BAD ) 
		    io_write_marker( aTHX_ io, MARKER0_UNDEFINED );
		else
		    io_register_error(io, ERR_BAD_OBJECT);
            }
        }
    }
    else {
        if (SvOK(one)){
	    #if defined( EXPERIMENT1 )
	    if ( (io->options & OPT_PREFER_NUMBER )){
		if (SvNIOK(one)){
		    amf0_format_number(aTHX_  io, one);
		}
		else {
		    amf0_format_string(aTHX_  io, one);
		}
	    }
	    else 
	    #endif
		if (SvPOK(one)){
		    amf0_format_string(aTHX_  io, one);
		}
		else if ( SvNIOK(one) ){
		    amf0_format_number(aTHX_  io, one);
		}
		else {
		    if (io->options & OPT_SKIP_BAD ){
			io_write_marker(aTHX_ io, MARKER0_UNDEFINED );
		    }
		    else 
			io_register_error( io, ERR_BAD_OBJECT);
		}
        }
        else {
            amf0_format_null(aTHX_  io);
        }
    }
}

FREE_INLINE void amf0_format_number(pTHX_ struct io_struct *io, SV * one){

    io_write_marker(aTHX_  io, MARKER0_NUMBER);
    io_write_double(aTHX_  io, SvNV(one));	
}
FREE_INLINE void amf0_format_string(pTHX_ struct io_struct *io, SV * one){

    /* TODO: process long string */
    if (SvPOK(one)){
        STRLEN str_len;
        char * pv;
        pv = SvPV(one, str_len);
        if (str_len > 65500){
            io_write_marker(aTHX_  io, MARKER0_LONG_STRING);
            io_write_u32(aTHX_  io, str_len);
            io_write_bytes(aTHX_  io, pv, str_len);
        }
        else {

            io_write_marker(aTHX_  io, MARKER0_STRING);
            io_write_u16(aTHX_  io, SvCUR(one));
            io_write_bytes(aTHX_  io, SvPV_nolen(one), SvCUR(one));
        }
    }else{
        amf0_format_null(aTHX_  io);
    }
}
FREE_INLINE void amf0_format_strict_array(pTHX_ struct io_struct *io, AV * one){
    int i, len;
    AV * one_array;
    one_array =  one;
    len = av_len(one_array);

    io_write_marker(aTHX_  io, '\012');
    io_write_u32(aTHX_  io, len + 1);
    for(i = 0; i <= len; ++i){
        SV ** ref_value = av_fetch(one_array, i, 0);
        if (ref_value) {
            amf0_format_one(aTHX_  io, *ref_value);
        }
        else {
            amf0_format_null(aTHX_  io);
        }
    }
}
FREE_INLINE void amf0_format_object(pTHX_ struct io_struct *io, HV * one){
    I32 key_len;
    SV * value;
    char *key_str;
    hv_iterinit(one);
    while(( value = hv_iternextsv(one, &key_str, &key_len))){
	io_write_u16(aTHX_  io, key_len);
	io_write_bytes(aTHX_  io, key_str, key_len);
	amf0_format_one(aTHX_  io, value);
    }
    io_write_u16(aTHX_  io, 0);
    io_write_marker(aTHX_  io, MARKER0_OBJECT_END);
}
FREE_INLINE void amf0_format_null(pTHX_ struct io_struct *io){

    io_write_marker(aTHX_  io, MARKER0_UNDEFINED);
}
FREE_INLINE void amf0_format_typed_object(pTHX_ struct io_struct *io,  HV * one){
    HV* stash = SvSTASH(one);
    char *class_name = HvNAME(stash);
    io_write_marker(aTHX_  io, MARKER0_TYPED_OBJECT);
    io_write_u16(aTHX_  io, (U16) strlen(class_name));
    io_write_bytes(aTHX_  io, class_name, strlen(class_name));
    amf0_format_object(aTHX_  io, one);
}

STATIC_INLINE SV * amf0_parse_one(pTHX_ struct io_struct * io);
STATIC_INLINE SV* amf0_parse_boolean(pTHX_ struct io_struct *io);
STATIC_INLINE SV* amf0_parse_object(pTHX_ struct io_struct *io);
STATIC_INLINE SV* amf0_parse_movieclip(pTHX_ struct io_struct *io);
STATIC_INLINE SV* amf0_parse_null(pTHX_ struct io_struct *io);
STATIC_INLINE SV* amf0_parse_undefined(pTHX_ struct io_struct *io);
STATIC_INLINE SV* amf0_parse_reference(pTHX_ struct io_struct *io);
STATIC_INLINE SV* amf0_parse_object_end(pTHX_ struct io_struct *io);
STATIC_INLINE SV* amf0_parse_strict_array(pTHX_ struct io_struct *io);
STATIC_INLINE SV* amf0_parse_ecma_array(pTHX_ struct io_struct *io);
STATIC_INLINE SV* amf0_parse_date(pTHX_ struct io_struct *io);
STATIC_INLINE SV* amf0_parse_long_string(pTHX_ struct io_struct *io);
STATIC_INLINE SV* amf0_parse_unsupported(pTHX_ struct io_struct *io);
STATIC_INLINE SV* amf0_parse_recordset(pTHX_ struct io_struct *io);
STATIC_INLINE SV* amf0_parse_xml_document(pTHX_ struct io_struct *io);
STATIC_INLINE SV* amf0_parse_typed_object(pTHX_ struct io_struct *io);

FREE_INLINE  void io_write_double(pTHX_ struct io_struct *io, double value);
FREE_INLINE  void io_write_marker(pTHX_ struct io_struct * io, char value);
FREE_INLINE  void io_write_uchar (pTHX_ struct io_struct * io, unsigned char value);
FREE_INLINE  void io_write_u8(pTHX_ struct io_struct * io, unsigned int value);
FREE_INLINE  void io_write_s16(pTHX_ struct io_struct * io, signed int value);
FREE_INLINE  void io_write_u16(pTHX_ struct io_struct * io, unsigned int value);
FREE_INLINE  void io_write_u32(pTHX_ struct io_struct * io, unsigned int value);
FREE_INLINE  void io_write_u24(pTHX_ struct io_struct * io, unsigned int value);
/*
*/

FREE_INLINE  double io_read_double(struct io_struct *io){
    const int step = sizeof(double);
    double a;
    unsigned char * ptr_in  = io->pos;
    char * ptr_out = (char *) &a; 
    io_require(io, step);
    ptr_out[GET_NBYTE(step, 0, a)] = ptr_in[0] ;
    ptr_out[GET_NBYTE(step, 1, a)] = ptr_in[1] ;
    ptr_out[GET_NBYTE(step, 2, a)] = ptr_in[2] ;
    ptr_out[GET_NBYTE(step, 3, a)] = ptr_in[3] ;
    ptr_out[GET_NBYTE(step, 4, a)] = ptr_in[4] ;
    ptr_out[GET_NBYTE(step, 5, a)] = ptr_in[5] ;
    ptr_out[GET_NBYTE(step, 6, a)] = ptr_in[6] ;
    ptr_out[GET_NBYTE(step, 7, a)] = ptr_in[7] ;
    io->pos += step;
    return a;
}
FREE_INLINE  char *io_read_bytes(struct io_struct *io, int len){
    char * pos = ( char * )io->pos;
    io_require(io, len);
    io->pos+=len;
    return pos;
}
FREE_INLINE  char *io_read_chars(struct io_struct *io, int len){
    char * pos = ( char * )io->pos;
    io_require(io, len);
    io->pos+=len;
    return pos;
}

FREE_INLINE  unsigned char io_read_marker(struct io_struct * io){
    const int step = 1;
    unsigned char marker;
    io_require(io, step);
    marker = *(io->pos);
    io->pos++;
    return marker;
}
FREE_INLINE  int io_read_u8(struct io_struct * io){
    const int step = 1;
    union{
        unsigned int x;
        unsigned char bytes[8];
    } str;
    io_require(io, step);
    str.x = 0;
    str.bytes[GET_NBYTE(step, 0, str.x)] = io->pos[0];
    io->pos+= step;
    return (int) str.x;
}
FREE_INLINE  int io_read_s16(struct io_struct * io){
    const int step = 2;
    union{
        int x;
        char bytes[8];
    } str;
    io_require(io, step);
    str.x =  io->pos[step - 1] & '\x80' ? -1 : 0;
    str.bytes[GET_NBYTE(step, 0, str.x)] = io->pos[0];
    str.bytes[GET_NBYTE(step, 1, str.x)] = io->pos[1];
    io->pos+= step;
    return (int) str.x;
}
FREE_INLINE  int io_read_u16(struct io_struct * io){
    const int step = 2;
    union{
        unsigned int x;
        char bytes[8];
    } str;
    io_require(io, step);
    str.x = 0;
    str.bytes[GET_NBYTE(step, 0, str.x)] = io->pos[0];
    str.bytes[GET_NBYTE(step, 1, str.x)] = io->pos[1];
    io->pos+= step;
    return (int) str.x;
}
FREE_INLINE  int io_read_u24(struct io_struct * io){
    const int step = 3;
    union{
        unsigned int x;
        char bytes[8];
    } str;
    io_require(io, step);
    str.x = 0;
    str.bytes[GET_NBYTE(step, 0, str.x)] = io->pos[0];
    str.bytes[GET_NBYTE(step, 1, str.x)] = io->pos[1];
    str.bytes[GET_NBYTE(step, 2, str.x)] = io->pos[2];
    io->pos+= step;
    return (int) str.x;
}
FREE_INLINE  int io_read_u32(struct io_struct * io){
    const int step = 4;
    union{
        unsigned int x;
        char bytes[8];
    } str;
    io_require(io, step);
    str.x = 0;
    str.bytes[GET_NBYTE(step, 0, str.x)] = io->pos[0];
    str.bytes[GET_NBYTE(step, 1, str.x)] = io->pos[1];
    str.bytes[GET_NBYTE(step, 2, str.x)] = io->pos[2];
    str.bytes[GET_NBYTE(step, 3, str.x)] = io->pos[3];
    io->pos+= step;
    return (int) str.x;
}
FREE_INLINE  void amf3_write_integer(pTHX_ struct io_struct *io, IV ivalue){
    UV value;
    if (ivalue<0){
	if ( ivalue < -( 1 << 28) ){
	    io_register_error( io, ERR_INT_OVERFLOW );
	};
        value = 0x1fffffff & (UV) ivalue;	
    }
    else {
        value = ivalue;
    }
    if (value<128){
        io_reserve(aTHX_  io, 1);
        io->pos[0]= (U8) value;
        io->pos+=1;
    }
    else if (value<= 0x3fff ) {
        io_reserve(aTHX_  io, 2);
        io->pos[0] = (U8) (value>>7) | 128;
        io->pos[1] = (U8) (value & 0x7f);
        io->pos+=2;
    }
    else if (value <= 0x1fffff) {
        io_reserve(aTHX_  io, 3);

        io->pos[0] = (U8) (value>>14) | 128;
        io->pos[1] = (U8) (value>>7 & 0x7f) |128;
        io->pos[2] = (U8) (value & 0x7f);
        io->pos+=3;
    }
    else if ((value <= 0x1fffffff)){
        io_reserve(aTHX_  io, 4);

        io->pos[0] = (U8) (value>>22 & 0xff) |128;
        io->pos[1] = (U8) (value>>15 & 0x7f) |128;
        io->pos[2] = (U8) (value>>8  & 0x7f) |128;
        io->pos[3] = (U8) (value     & 0xff);
        io->pos+=4;
    }
    else {
        io_register_error( io, ERR_INT_OVERFLOW);
        return;
    }
    return;
}

FREE_INLINE int amf3_read_integer(struct io_struct *io){
    I32 value;
    io_require(io, 1);
    if ((U8) io->pos[0] > 0x7f) {
        io_require(io, 2);
        if ((U8) io->pos[1] >0x7f) {

            io_require(io, 3);
            if ((U8) io->pos[2] >0x7f) {
                io_require(io, 4);

                value =  ((io->pos[0] & 0x7f) <<22)| ((io->pos[1] & 0x7f) <<15) | ((io->pos[2] & 0x7f) <<8) | io->pos[3];

                if ((U8) io->pos[0] >= 0xc0) {
                    value = value | ~(0x0fffffff);
                }
                else {
                    /* no return value; */ ;
                }
                io_move_forward(io, 4);
            }
            else {
                value = ((io->pos[0] & 0x7f) <<14) + ((io->pos[1] & 0x7f) <<7) + io->pos[2];
                io_move_forward(io, 3);
            }
        }
        else {
            value = ((io->pos[0] & 0x7f) << 7) + io->pos[1];
            io_move_forward(io, 2);
        }
    }
    else {
        value = (U8) io->pos[0];
        io_move_forward(io, 1);
    }
    return value;
}
STATIC_INLINE SV * amf0_parse_utf8(pTHX_ struct io_struct * io){
    int string_len = io_read_u16(io);
    SV * RETVALUE;
    char *x = io_read_chars(io, string_len);
    RETVALUE = newSVpvn(x, string_len);
    if (io->options & OPT_DECODE_UTF8)
	SvUTF8_on(RETVALUE);

    return RETVALUE;
}

STATIC_INLINE SV * amf0_parse_object(pTHX_ struct io_struct * io){
    HV * obj;
    int len_next;
    char * key;
    SV * value;
    SV *RETVALUE;

    obj =  newHV();
    RETVALUE = newRV_noinc( (SV *) obj );
    av_push(io->arr_object, RETVALUE);
    while(1){
        len_next = io_read_u16(io);
        if (len_next == 0) {
            char object_end;
            object_end= io_read_marker(io);
            if ( MARKER0_OBJECT_END == object_end )
            {
                if (io->options & OPT_STRICT){
                    if (SvREFCNT(RETVALUE) > 1)
                        io_register_error( io, ERR_RECURRENT_OBJECT);
                    ;
                    SvREFCNT_inc_simple_void_NN(RETVALUE);
                    return RETVALUE;
                }
                else {
                    SvREFCNT_inc_simple_void_NN(RETVALUE);
                    return RETVALUE;
                }
            }
            else {
                io->pos--;
                key = "";
                value = amf0_parse_one(aTHX_  io);
            }
        }
        else {
            key = io_read_chars(io, len_next);
            value = amf0_parse_one(aTHX_  io);
        }

        (void) hv_store(obj, key, len_next, value, 0);
    }
}

STATIC_INLINE SV* amf0_parse_movieclip(pTHX_ struct io_struct *io){
    SV* RETVALUE;
    RETVALUE = newSV(0);
    return RETVALUE;
}
STATIC_INLINE SV* amf0_parse_null(pTHX_ struct io_struct *io){
    SV* RETVALUE;
    RETVALUE = newSV(0);
    return RETVALUE;
}

STATIC_INLINE SV* amf0_parse_undefined(pTHX_ struct io_struct *io){
    SV* RETVALUE;
    RETVALUE = newSV(0);
    return RETVALUE;
}

STATIC_INLINE SV* amf0_parse_reference(pTHX_ struct io_struct *io){
    SV* RETVALUE;
    int object_offset;
    AV * ar_refs;
    object_offset = io_read_u16(io);
    ar_refs = (AV *) io->arr_object;
    if (object_offset > av_len(ar_refs)){
        io_register_error( io, ERR_AMF0_REF);
    }
    else {
        RETVALUE = *av_fetch(ar_refs, object_offset, 0);
        SvREFCNT_inc_simple_void_NN(RETVALUE);
    }
    return RETVALUE;
}

STATIC_INLINE SV* amf0_parse_object_end(pTHX_ struct io_struct *io){
    io_read_marker(io);
    return 0;
}

STATIC_INLINE SV* amf0_parse_strict_array(pTHX_ struct io_struct *io){
    SV* RETVALUE;
    int array_len;
    AV* this_array;
    AV * refs = io->arr_object;
    int i;

    refs = (AV*) io->arr_object;
    array_len = io_read_u32(io);
    
    /* report error before av_extent */
    if ( array_len > io->arr_max )
	io_register_error( io, ERR_ARRAY_TOO_BIG );
    else 
	io->arr_max -= array_len;

    this_array = newAV();
    av_extend(this_array, array_len);
    av_push(refs, RETVALUE = newRV_noinc((SV*) this_array));

    for(i=0; i<array_len; ++i){
        av_push(this_array, amf0_parse_one(aTHX_  io));
    }
    if (SvREFCNT(RETVALUE) > 1 && io->options & OPT_STRICT)
    io_register_error( io, ERR_RECURRENT_OBJECT);
    SvREFCNT_inc_simple_void_NN(RETVALUE);

    return RETVALUE;
}

STATIC_INLINE SV* amf0_parse_ecma_array(pTHX_ struct io_struct *io){
    SV* RETVALUE;

    U32 array_len;
    AV * this_array;
    AV * refs = io->arr_object;
    int  position; /*remember offset for array convertion to hash */
    int last_len;
    char last_marker;
    int av_refs_len;
    int key_len;
    char *key_ptr;
    array_len = io_read_u32(io);
    position= io_position(io);


    /* report_array early */
    if ( array_len > io->arr_max )
	io_register_error( io, ERR_ARRAY_TOO_BIG);
    else 
	io->arr_max -= array_len;

    this_array = newAV();
    av_extend(this_array, array_len);

    av_refs_len = av_len(refs);
    av_push(refs, RETVALUE = newRV_noinc((SV*) this_array));

    #ifdef TRACEA
    fprintf( stderr, "Start parse array %d\n", array_len);
    fprintf( stderr, "position %d\n", io_position(io));
    #endif
    if (1){
        bool ok;
        UV index;
        key_len = io_read_u16(io);
        key_ptr = io_read_chars(io, key_len);


        ok = ((key_len == 1) && (IS_NUMBER_IN_UV & grok_number(key_ptr, key_len, &index)) &&	 (index < array_len ));
        if (ok){
            av_store(this_array, index, amf0_parse_one(aTHX_  io));
        }
        else {
            if (((key_len) == 6  &&  strnEQ(key_ptr, "length", 6))){
                ok = 1;
                array_len++; /* safe for flash v.9.0 */
                sv_2mortal( amf0_parse_one(aTHX_  io));
            }
            else {
                ok = 0;
            };
        }
        if (ok){ 
	    U32 i;
            for(i=1; i<array_len; ++i){
                UV index;
                int key_len= io_read_u16(io);
                char *s = io_read_chars(io, key_len);

                #ifdef TRACEA
                fprintf( stderr, "index =%d, position %d\n", i, io_position(io));
                #endif
                if ((IS_NUMBER_IN_UV & grok_number(s, key_len, &index)) &&
                    (index < array_len)){
                    av_store(this_array, index, amf0_parse_one(aTHX_  io));
                    #ifdef TRACEA
                    fprintf( stderr, "index =%d, position %d\n", i, io_position(io));
                    #endif
                }
                else {
                    if ((key_len) != 6  || strnEQ(key_ptr, "length", 6)!=0){
                        io_move_backward(io, key_len + 2);
                        break;
                    }
                    else {
                        array_len++;
                        sv_2mortal( amf0_parse_one(aTHX_  io));
                    }
                }
            }
        }
        else {
            io_move_backward(io, key_len + 2);
        }
    }


    #ifdef TRACEA
    fprintf( stderr, "almost at end parse array %d\n", array_len);
    fprintf( stderr, "position %d\n", io_position(io));
    #endif
    last_len = io_read_u16(io);
    last_marker = io_read_marker(io);
    #ifdef TRACEA
    fprintf( stderr, "at end parse array %d\n", array_len);
    fprintf( stderr, "position %d\n", io_position(io));
    #endif
    if ((last_len == 0) && (last_marker == MARKER0_OBJECT_END)) {
        if (io->options & OPT_STRICT && (SvREFCNT(RETVALUE) > 1))
            io_register_error( io, ERR_RECURRENT_OBJECT); ;
        SvREFCNT_inc_simple_void_NN(RETVALUE);
    }
    else{
        /* Need rollback referenses */
        int i;
        for( i = av_len(refs) - av_refs_len; i>0 ;--i){
            SV * ref_sv = av_pop(refs);
            SV * value= SvRV(ref_sv);
            if ( SVt_PVHV == SvTYPE( value ) )
                hv_clear( (HV *) value );
            else if ( SVt_PVAV == SvTYPE( value ))
                av_clear( (AV *) value);
            else {
                /* FIXME I am not sure about simple mortalizing values this need to be reused or cleanups*/
                sv_2mortal(ref_sv);
                io_register_error( io, ERR_INTERNAL );
            }
            sv_2mortal(ref_sv);
        }
        io_set_position(io, position);
        RETVALUE = amf0_parse_object(aTHX_  io);
    }
    return RETVALUE;
}

STATIC_INLINE SV* amf0_parse_date(pTHX_ struct io_struct *io){
    SV* RETVALUE;
    double time;
    time = io_read_double(io);
    (void)io_read_s16(io);
    if ( io->options & OPT_MILLSEC_DATE )
	RETVALUE = newSVnv(time);
    else 
	RETVALUE = newSVnv(time/1000.0);
    av_push(io->arr_object, RETVALUE);
    SvREFCNT_inc_simple_void_NN(RETVALUE);
    return RETVALUE;
}

STATIC_INLINE SV* amf0_parse_long_string(pTHX_ struct io_struct *io){
    SV* RETVALUE;
    STRLEN len;
    len = io_read_u32(io);

    RETVALUE = newSVpvn(io_read_chars(io, len), len);
    if (io->options & OPT_DECODE_UTF8)
	SvUTF8_on(RETVALUE);
    return RETVALUE;
}

STATIC_INLINE SV* amf0_parse_unsupported(pTHX_ struct io_struct *io){
    io_register_error( io, ERR_UNIMPLEMENTED);
    return 0;
}
STATIC_INLINE SV* amf0_parse_recordset(pTHX_ struct io_struct *io){
    io_register_error( io, ERR_UNIMPLEMENTED);
    return 0;
}
STATIC_INLINE SV* amf0_parse_xml_document(pTHX_ struct io_struct *io){
    SV* RETVALUE;
    RETVALUE = amf0_parse_long_string(aTHX_  io);
    SvREFCNT_inc_simple_void_NN(RETVALUE);
    av_push(io->arr_object, RETVALUE);
    return RETVALUE;
}
FREE_INLINE SV *parse_scalar_ref(pTHX_ struct io_struct *io){
        SV * obj;
        int obj_pos;
        int len_next;
        char *key;
        SV *value;

        io->pos+=6;
        obj =  newSV(0);
        av_push(io->arr_object,  obj);
        obj_pos = av_len(io->arr_object);
        value = 0;

        while(1){
            len_next = io_read_u16(io);
            if (len_next == 0) {
                char object_end;
                object_end= io_read_marker(io);
                if (MARKER0_OBJECT_END == object_end)
                {
                    SV* RETVALUE = *av_fetch(io->arr_object, obj_pos, 0);
                    if (!value)
                        io_register_error( io, ERR_BAD_REFVAL);
                        sv_setsv(obj, newRV_noinc(value));

                    if (io->options & OPT_STRICT){
                        if (SvREFCNT(RETVALUE) > 1)
                            io_register_error_and_free(aTHX_ io, ERR_RECURRENT_OBJECT, value);
                        ;
                        SvREFCNT_inc_simple_void_NN(RETVALUE);
                        return RETVALUE;
                    }
                    else {
                        SvREFCNT_inc_simple_void_NN(RETVALUE);
                        return RETVALUE;
                    }
                }
                else {
                    io_register_error_and_free(aTHX_ io, ERR_BAD_REFVAL, value);
                }
            }
            else if ( len_next ==  6) {
                key = io_read_chars(io, len_next);
                if (strncmp(key, "REFVAL", 6) || value )
                    io_register_error_and_free(aTHX_ io, ERR_BAD_REFVAL, value);
                
                value = amf0_parse_one(aTHX_  io);
            }
            else {
                io_register_error_and_free(aTHX_ io, ERR_BAD_REFVAL, value);
            }
    }
}
STATIC_INLINE SV* amf0_parse_typed_object(pTHX_ struct io_struct *io){
    SV* RETVALUE;
    HV *stash;
    int len;

    len = io_read_u16(io);
    if (len == 6 && !strncmp( (char *)io->pos, "REFVAL", 6)){
        /* SCALAR */
        RETVALUE = parse_scalar_ref(aTHX_ io);
        if (RETVALUE)
            return RETVALUE;
        
    }
    if (io->options & OPT_STRICT){
        stash = gv_stashpvn((char *)io->pos, len, 0);
    }
    else {
        stash = gv_stashpvn((char *)io->pos, len, GV_ADD );
    }
    io->pos+=len;
    RETVALUE = amf0_parse_object(aTHX_  io);
    if (stash) 
    sv_bless(RETVALUE, stash);
    return RETVALUE;
}
STATIC_INLINE SV* amf0_parse_double(pTHX_ struct io_struct * io){
    return newSVnv(io_read_double(io));
}

FREE_INLINE SV*  util_boolean(pTHX_ struct io_struct *io, bool value){
    AV *Bool;
    SV *sv;
    if (  0 == ( io->options & OPT_JSON_BOOLEAN ) ){
	sv = boolSV( value );
	/* SvREFCNT_inc_simple_void_NN( sv ); */
	return sv;
    } 
    else {
	if (!io->bool_init){
	    Bool=get_av("Storable::AMF0::Bool", 0); 
	    io->Bool[0]=*(av_fetch(Bool, 0, 0));
	    io->Bool[1]=*(av_fetch(Bool, 1, 0));
	    io->bool_init = 1;
	}
	SvREFCNT_inc_simple_void_NN( io->Bool[value] );
	return io->Bool[value];
    }
}

STATIC_INLINE SV* amf0_parse_boolean(pTHX_ struct io_struct * io){
    unsigned char marker;
    bool value; 
    marker = io_read_marker(io);
    value = (marker != '\000');
    return util_boolean(aTHX_ io, value ? 1 : 0);
}

/* 
STATIC_INLINE SV* parse_boolean(pTHX_ struct io_struct * io){
    char marker;
    marker = io_read_marker(io);

    int count;
    SV *value = 0;
    SAVETMPS;

    dSP;

    ENTER; SAVETMPS; PUSHMARK (SP);
    PUTBACK;
    if ( marker == '\000' ) {
        count = call_pv("JSON::XS::false", G_SCALAR);
    }
    else {
        count = call_pv("JSON::XS::true", G_SCALAR);
    }
    SPAGAIN;
    if (count == 1)
        value = newSVsv(POPs);

    if (count != 1 || !SvOK(value)) {
        value = newSViv( marker == '\000' ? 0 : 1 );
    }

    PUTBACK;
    FREETMPS; LEAVE;
    return value;
}
*/ 
FREE_INLINE SV * amf3_parse_one(pTHX_ struct io_struct *io);
STATIC_INLINE SV * amf3_parse_undefined(pTHX_ struct io_struct *io){
    SV * RETVALUE;
    RETVALUE = newSV(0);
    return RETVALUE;
}
STATIC_INLINE SV * amf3_parse_null(pTHX_ struct io_struct *io){
    SV * RETVALUE;
    RETVALUE = newSV(0);
    return RETVALUE;
}
STATIC_INLINE SV * amf3_parse_false(pTHX_ struct io_struct *io){
    SV * RETVALUE;
    RETVALUE =  util_boolean( aTHX_ io, 0 );
    return RETVALUE;
}

STATIC_INLINE SV * amf3_parse_true(pTHX_ struct io_struct *io){
    SV * RETVALUE;
    RETVALUE =  util_boolean( aTHX_ io, 1 );
    return RETVALUE;
}
STATIC_INLINE SV * amf3_parse_integer(pTHX_ struct io_struct *io){
    SV * RETVALUE;
    RETVALUE = newSViv(amf3_read_integer(io));
    return RETVALUE;
}
STATIC_INLINE SV * amf3_parse_double(pTHX_ struct io_struct *io){
    SV * RETVALUE;
    RETVALUE = newSVnv(io_read_double(io));
    return RETVALUE;
}
FREE_INLINE char * amf3_read_string(pTHX_ struct io_struct *io, int ref_len, STRLEN *str_len){

    AV * arr_string = io->arr_string;
    if (ref_len & 1) {
        *str_len = ref_len >> 1;
        if (*str_len>0){
            char *pstr;
            pstr = io_read_chars(io, *str_len);
            av_push(io->arr_string, newSVpvn(pstr, *str_len));
            return pstr;
        }
        else {
            return "";
        }
    }
    else {
        int ref_idx = ref_len >> 1;	
        SV ** ref_sv  = av_fetch(arr_string, ref_idx, 0);
        if (ref_sv) {
            char* pstr;
            pstr = SvPV(*ref_sv, *str_len);
            return pstr; 
        }
        else {
            /* Exception: May be there throw some */
            io_register_error( io, ERR_BAD_STRING_REF);
	    return 0; /* Never reach this lime */
        }
    }
}
STATIC_INLINE SV * amf3_parse_string(pTHX_ struct io_struct *io){
    SV * RETVALUE;
    int ref_len;
    STRLEN plen;
    char* pstr;
    ref_len  = amf3_read_integer(io);
    pstr = amf3_read_string(aTHX_  io, ref_len, &plen);
    RETVALUE = newSVpvn(pstr, plen);
    if (io->options & OPT_DECODE_UTF8) 
	SvUTF8_on(RETVALUE);
    return RETVALUE;
}
STATIC_INLINE SV * amf3_parse_xml(pTHX_ struct io_struct *io);
STATIC_INLINE SV * amf3_parse_xml_doc(pTHX_ struct io_struct *io){
    SV * RETVALUE;
    RETVALUE = amf3_parse_xml(aTHX_  io);
    return RETVALUE;
}
STATIC_INLINE SV * amf3_parse_date(pTHX_ struct io_struct *io){
    SV * RETVALUE;
    int i = amf3_read_integer(io);
    if (i&1){

        double x = io_read_double(io);
	if ( io->options & OPT_MILLSEC_DATE ){
	    RETVALUE = newSVnv(x);
	}
	else {
	    RETVALUE = newSVnv(x/1000.0);
	};
	SvREFCNT_inc_simple_void_NN(RETVALUE);
        av_push(io->arr_object, RETVALUE);
    }
    else {
        SV ** item = av_fetch(io->arr_object, i>>1, 0);
        if (item) {
            RETVALUE = *item;
            SvREFCNT_inc_simple_void_NN(RETVALUE);
        }
        else{
            io_register_error( io, ERR_BAD_DATE_REF);
	    RETVALUE = 0; /* did not make any harm */
        }
    }
    return RETVALUE;
}


FREE_INLINE void amf3_store_object(pTHX_ struct io_struct *io, SV * item){
    av_push(io->arr_object, newRV_noinc(item));
}
FREE_INLINE void amf3_store_object_rv(pTHX_ struct io_struct *io, SV * item){
    av_push(io->arr_object, item);
}

STATIC_INLINE SV * amf3_parse_array(pTHX_ struct io_struct *io){
    SV * RETVALUE;
    int ref_len = amf3_read_integer(io);
    if (ref_len & 1){
        /* Not referense */
        int len = ref_len>>1;
        int str_len;
        SV * item;
        char * pstr;
        bool recover;
        STRLEN plen;		
        struct amf3_restore_point rec_point; 
        int old_vlen;
        SV * item_value;
        UV item_index;

        AV * array;
        str_len = amf3_read_integer(io);
        old_vlen = str_len;

        io_savepoint(aTHX_  io, &rec_point);		

        /* Пытаемся востановить как массив 
         Считаем что это массив если первый индекс от 0 до 9 и все индексы числовые
        */
        array=newAV();
        item = (SV *) array;
        RETVALUE = newRV_noinc(item);

        amf3_store_object_rv(aTHX_  io, RETVALUE);

        recover = FALSE;
        if (str_len !=1){
            pstr = amf3_read_string(aTHX_  io, str_len, &plen);
            if (IS_NUMBER_IN_UV & grok_number(pstr, plen, &item_index) && item_index< 10){

                item_value= amf3_parse_one(aTHX_  io);
                av_store(array, item_index, item_value);

                str_len = amf3_read_integer(io);
                while(str_len != 1){
                    pstr = amf3_read_string(aTHX_  io, str_len, &plen);
                    if (IS_NUMBER_IN_UV & grok_number(pstr, plen, &item_index)){

                        item_value= amf3_parse_one(aTHX_  io);
                        av_store(array, item_index, item_value);

                        str_len = amf3_read_integer(io);
                    }
                    else {
                        /* recover */
                        recover = TRUE;
                        break;
                    }
                };
            }
            else {
                /* recover */
                recover = TRUE;
            }
        }

        if (!recover) {
            int i;
            for(i=0; i< len; ++i){
                SV *item = amf3_parse_one(aTHX_  io);
                av_store(array, i, item);
            };
        }
        else {
            /*востанавливаем как хэш */
            HV * hv;
            char *pstr;
            STRLEN plen;
            char buf[2+2*sizeof(int)];
            int i;

            io_restorepoint(aTHX_  io, &rec_point);	

            str_len = old_vlen;
            hv   = newHV();
            item = (SV *) hv;
            RETVALUE = newRV_noinc(item);
            amf3_store_object_rv(aTHX_  io, RETVALUE);
            while(str_len != 1){
                SV *one;
                pstr = amf3_read_string(aTHX_  io, str_len, &plen);
                one = amf3_parse_one(aTHX_  io);
                (void) hv_store(hv, pstr, plen, one, 0);
                str_len = amf3_read_integer(io);

            };
            for(i=0; i<len;++i){
                (void) snprintf(buf, sizeof(buf), "%d", i);
                (void) hv_store(hv, buf, strlen(buf), amf3_parse_one(aTHX_  io), 0);
            }

            /* (void) snprintf(buf, sizeof(buf), "%d", 2);
            (void) hv_store(hv, buf, strlen(buf), newSVpvn( "abc", 3), 0);
            (void) snprintf(buf, sizeof(buf), "%d", 1);
            (void) hv_store(hv, buf, strlen(buf), newSVpvn( "abd", 3), 0); */

        };
        if (io->options & OPT_STRICT){
            if (SvREFCNT(RETVALUE)>1){
                io_register_error( io, ERR_RECURRENT_OBJECT);
            }
        }
        SvREFCNT_inc_simple_void_NN(RETVALUE);
    }
    else {
        SV ** value = av_fetch(io->arr_object, ref_len>>1, 0);	
        if (value) {
            SvREFCNT_inc_simple_void_NN(*value);
            RETVALUE = *value;
        }
        else {
            io_register_error( io, ERR_BAD_ARRAY_REF);
	    RETVALUE = 0; /* did not make any harm */
        }
    }
    return RETVALUE;
}
struct amf3_trait_struct{
    int sealed;
    bool dynamic;
    bool externalizable;
    SV* class_name;
    HV* stash;
};
STATIC_INLINE SV * amf3_parse_object(pTHX_ struct io_struct *io){
    SV * RETVALUE;
    int obj_ref = amf3_read_integer(io);
    #ifdef TRACE0
    fprintf(stderr, "obj_ref = %d\n", obj_ref);
    #endif
    if (obj_ref & 1) {/* not a ref object */
        AV * trait;
        int sealed;
        bool dynamic;
	bool externalizable;
        SV * class_name_sv;
        HV *one;
        int i;

        if (!(obj_ref & 2)){/* not trait ref */
            SV** trait_item	= av_fetch(io->arr_trait, obj_ref>>2, 0);
            if (! trait_item) {
                io_register_error( io, ERR_BAD_TRAIT_REF);
            };
            trait = (AV *) SvRV(*trait_item);

            sealed  = (int)  SvIV(*av_fetch(trait, 0, 0));
            dynamic = (bool) SvIV(*av_fetch(trait, 1, 0));
	    externalizable = (bool) SvIV(*av_fetch(trait, 2, 0));
            class_name_sv = *av_fetch(trait, 3, 0);
        }
        else {	
            int i;
	    trait = newAV();
	    av_push(io->arr_trait, newRV_noinc((SV *) trait));
	    sealed  = obj_ref >>4;
	    dynamic = obj_ref & 8;
	    externalizable = ( obj_ref  & 0x04) != 0;
	    class_name_sv = amf3_parse_string(aTHX_  io);

	    av_push(trait, newSViv(sealed));
	    av_push(trait, newSViv(dynamic));
	    av_push(trait, newSViv( externalizable )); /* external processing */
	    av_push(trait, class_name_sv);

	    for(i =0; i<sealed; ++i){
		SV * prop_name;

		prop_name = amf3_parse_string(aTHX_  io);
		av_push(trait, prop_name);
	    }			
        };
        one = newHV();
        RETVALUE = newRV_noinc((SV*) one);
        amf3_store_object_rv(aTHX_  io, RETVALUE);

	if ( externalizable ){
	    (void) hv_store( one, "externalizedData", 16, amf3_parse_one(aTHX_  io), 0);
	};

        for(i=0; i<sealed; ++i){
            (void) hv_store_ent( one, *av_fetch(trait, 4+i, 0), amf3_parse_one(aTHX_  io), 0);	
        };

        if (dynamic) {
            char *pstr;
            STRLEN plen;
            int varlen;
            varlen = amf3_read_integer(io);
            pstr = amf3_read_string(aTHX_  io, varlen, &plen);

            while(plen != 0) { 
                (void) hv_store(one, pstr, plen, amf3_parse_one(aTHX_  io), 0);				
                varlen = -1;
                plen = -1;
                varlen = amf3_read_integer(io);
                pstr = amf3_read_string(aTHX_  io, varlen, &plen);
            }
        }
        if (SvREFCNT(RETVALUE) > 1 && io->options & OPT_STRICT){
            io_register_error( io, ERR_RECURRENT_OBJECT);
        };
        SvREFCNT_inc_simple_void_NN(RETVALUE);
        if (SvCUR(class_name_sv)) {
            HV *stash;
            if (io->options & OPT_STRICT){
                stash = gv_stashsv(class_name_sv, 0 );
            }
            else {
                stash = gv_stashsv(class_name_sv, GV_ADD );
            }
            if (stash) 
            sv_bless(RETVALUE, stash);
        }
        else {
            /* No bless */
        }
    }
    else {
        SV ** ref_sv = av_fetch(io->arr_object, obj_ref>>1, 0);
        if (ref_sv) {
            RETVALUE = *ref_sv;
            SvREFCNT_inc_simple_void_NN(RETVALUE);
        }
        else {
            io_register_error( io, ERR_BAD_TRAIT_REF);
            RETVALUE = &PL_sv_undef;	
        }
    }
    return RETVALUE;
}
STATIC_INLINE SV * amf3_parse_xml(pTHX_ struct io_struct *io){
    SV * RETVALUE;
    int Bi = amf3_read_integer(io);
    if (Bi & 1) { /* value */
        int len = Bi>>1;
        char *b = io_read_bytes(io, len);
        RETVALUE = newSVpvn(b, len);
        if (io->options & OPT_DECODE_UTF8)
	    SvUTF8_on(RETVALUE);
        SvREFCNT_inc_simple_void_NN(RETVALUE);
        av_push(io->arr_object, RETVALUE);
    }
    else {
        SV ** sv = av_fetch(io->arr_object, Bi>>1, 0);
        if (sv) {
            RETVALUE = newSVsv(*sv);
        }		
        else {
            io_register_error( io, ERR_BAD_XML_REF);
        }
    }
    return RETVALUE;
}
STATIC_INLINE SV * amf3_parse_bytearray(pTHX_ struct io_struct *io){
    SV * RETVALUE;
    int Bi = amf3_read_integer(io);
    if (Bi & 1) { /* value */
        int len = Bi>>1;
        char *b = io_read_bytes(io, len);
        RETVALUE = newSVpvn(b, len);
        SvREFCNT_inc_simple_void_NN(RETVALUE);
        av_push(io->arr_object, RETVALUE);
    }
    else {
        SV ** sv = av_fetch(io->arr_object, Bi>>1, 0);
        if (sv) {
            RETVALUE = newSVsv(*sv);
        }		
        else {
            io_register_error( io, ERR_BAD_BYTEARRAY_REF);
        }
    }
    return RETVALUE;
}
FREE_INLINE void amf3_format_date( pTHX_ struct io_struct *io, SV * one){
    io_write_marker( aTHX_ io, MARKER3_DATE );
    amf3_write_integer( aTHX_ io, 1 );
    io_write_double( aTHX_ io, util_date_time( one ));
}
FREE_INLINE void amf3_format_one(pTHX_ struct io_struct *io, SV * one);
FREE_INLINE void amf3_format_integer(pTHX_ struct io_struct *io, SV *one){

    IV i = SvIV(one);
    if (i <= 0xfffffff && i>= -(0x10000000)){
        io_write_marker(aTHX_  io, MARKER3_INTEGER);
        amf3_write_integer(aTHX_  io, SvIV(one));
    }
    else {
        io_write_marker(aTHX_  io, MARKER3_DOUBLE);
        io_write_double(aTHX_  io, (double) i);
    }
}

FREE_INLINE void amf3_format_double(pTHX_ struct io_struct * io, SV *one){

    io_write_marker(aTHX_  io, MARKER3_DOUBLE);
    io_write_double(aTHX_  io, SvNV(one));
}

FREE_INLINE void amf3_format_undef(pTHX_ struct io_struct *io){
    io_write_marker(aTHX_  io, MARKER3_UNDEF);
}
FREE_INLINE void amf3_format_null(pTHX_ struct io_struct *io){
    io_write_marker(aTHX_  io, MARKER3_NULL);
}

FREE_INLINE void amf3_write_string_pvn(pTHX_ struct io_struct *io, char *pstr, STRLEN plen){
    HV* rhv;
    SV ** hv_item;

    rhv = io->hv_string;
    hv_item = hv_fetch(rhv, pstr, plen, 0);

    if (hv_item && SvOK(*hv_item)){
        int sref = SvIV(*hv_item);
        amf3_write_integer(aTHX_  io, sref <<1);
    }
    else {
        if (plen) {
            amf3_write_integer(aTHX_  io, (plen << 1)	| 1);
            io_write_bytes(aTHX_  io, pstr, plen);
            (void) hv_store(rhv, pstr, plen, newSViv(io->rc_string), 0);
            io->rc_string++;
        }
        else {
            io_write_marker(aTHX_  io, STR_EMPTY);
        }
    }
}

FREE_INLINE void amf3_format_string(pTHX_ struct io_struct *io, SV *one){
    char *pstr;
    STRLEN plen;
    pstr = SvPV(one, plen);
    io_write_marker(aTHX_  io, MARKER3_STRING);
    amf3_write_string_pvn(aTHX_  io, pstr, plen);
}

FREE_INLINE void amf3_format_reference(pTHX_ struct io_struct *io, SV *num){
    amf3_write_integer(aTHX_  io, SvIV(num)<<1);
}

FREE_INLINE void amf3_format_array(pTHX_ struct io_struct *io, AV * one){
    int alen;
    int i;
    SV ** aitem;
    io_write_marker(aTHX_  io, MARKER3_ARRAY);
    alen = av_len(one)+1;
    amf3_write_integer(aTHX_  io, 1 | (alen) <<1 );
    io_write_marker(aTHX_  io, STR_EMPTY); /*  no sparse array; */
    for( i = 0; i<alen ; ++i){
        aitem = av_fetch(one, i, 0);
        if (aitem) {
            amf3_format_one(aTHX_  io, *aitem);
        }
        else {
            io_write_marker(aTHX_  io, MARKER3_NULL);
        }
    }
}
FREE_INLINE void amf3_format_object(pTHX_ struct io_struct *io, SV * rone){
    AV * trait;
    SV ** rv_trait;
    char *class_name;
    int class_name_len;
    HV *one;
    one =(HV *) SvRV(rone);

    io_write_marker(aTHX_  io, MARKER3_OBJECT);
    if (sv_isobject((SV*)rone)){
        HV* stash = SvSTASH(one);
        class_name = HvNAME(stash);
        class_name_len = strlen(class_name);
    }
    else {

        class_name = "";
        class_name_len = 0;
    };

    rv_trait = hv_fetch(io->hv_trait, class_name, class_name_len, 0);
    if (rv_trait){
        int ref_trait;
        trait = (AV *) SvRV(*rv_trait);	
        ref_trait = SvIV( *av_fetch(trait, 1, 0));

        amf3_write_integer(aTHX_  io, (ref_trait<< 2) | 1);		
    }
    else {
        SV * class_name_sv;
        int const sealed_count = 0;
        trait = newAV();
        av_extend(trait, 3);
        class_name_sv = newSVpvn(class_name, class_name_len);
        rv_trait = hv_store( io->hv_trait, class_name, class_name_len, newRV_noinc((SV*)trait), 0);
        av_store(trait, 0, class_name_sv);
        av_store(trait, 1, newSViv(io->rc_trait));
        av_store(trait, 2, newSViv(0));

        amf3_write_integer(aTHX_  io, ( sealed_count << 4) | 0x0b );
        amf3_write_string_pvn(aTHX_  io, class_name, class_name_len);
        io->rc_trait++;

    }

    /* where must enumeration of sealed attributes

    where will dynamic properties
    */

    if (1){
        HV *hv;
        SV * value;
        char * key_str;
        I32 key_len;

        hv = one;

        hv_iterinit(hv);
        while( (value  = hv_iternextsv(hv, &key_str, &key_len)) ){
            if (key_len){
                amf3_write_string_pvn(aTHX_  io, key_str, key_len);
                amf3_format_one(aTHX_  io, value);
            };
        }
    }

    io_write_marker(aTHX_  io, STR_EMPTY); 
}

FREE_INLINE void amf3_format_one(pTHX_ struct io_struct *io, SV * one){
    SV *rv=0;
    bool is_perl_bool = 0;
    if (SvROK(one)){
        rv = (SV*) SvRV(one);
	if ( sv_isobject( one )){
            HV* stash = SvSTASH(rv);
            char *class_name = HvNAME(stash);
            if ( class_name[0] == 'J' ){
                if ( sv_isa(one, "JSON::PP::Boolean")){
                    is_perl_bool =  1;
                }
                else if ( sv_isa(one, "JSON::XS::Boolean") ){
                    is_perl_bool =  1;
                }
            }
            else if ( class_name[0] == 'b' ){
                if ( sv_isa(one, "boolean" )){
                    is_perl_bool  = 1;
                }
            }
	    if ( is_perl_bool ){
		io_write_marker(aTHX_ io, (SvTRUE( SvRV( one )) ? MARKER3_TRUE : MARKER3_FALSE ) );
		return ;
	    }
	}
    }

    if (rv){
        /* test has stored */
        SV **OK = hv_fetch(io->hv_object, (char *)(&rv), sizeof (rv), 1);
        if (SvOK(*OK)) {
            if (SvTYPE(rv) == SVt_PVAV) {
                io_write_marker(aTHX_  io, MARKER3_ARRAY);
                amf3_format_reference(aTHX_  io, *OK);
            }
            else if (SvTYPE(rv) == SVt_PVHV){
                io_write_marker(aTHX_  io, MARKER3_OBJECT);
                amf3_format_reference(aTHX_  io, *OK);
            }
	    else if (sv_isobject(one) && util_is_date(rv)){
		io_write_marker(aTHX_ io, MARKER3_OBJECT ); /*#TODO */
		amf3_format_reference(aTHX_  io, *OK);
	    }
            else {
		if ( io->options & OPT_SKIP_BAD ){
		    io_write_marker( aTHX_ io, MARKER3_UNDEF );
		}
		else {
		    io_register_error( io, ERR_BAD_OBJECT);
		}
            }
        }
        else {
            sv_setiv(*OK, io->rc_object);
            (void) hv_store(io->hv_object, (char *) (&rv), sizeof (rv), newSViv(io->rc_object), 0);
            ++io->rc_object;

	    if ( io->options & OPT_MAPPER ){
		if ( sv_isobject( one ) ){
		    
		    GV *to_amf = gv_fetchmethod_autoload (SvSTASH (rv), "TO_AMF", 0);
		    if ( to_amf ) {
			dSP;

			ENTER; SAVETMPS; PUSHMARK (SP);
			XPUSHs (sv_bless (sv_2mortal (newRV_inc (rv)), SvSTASH (rv)));

			/* calling with G_SCALAR ensures that we always get a 1 return value */
			PUTBACK;
			call_sv ((SV *)GvCV (to_amf), G_SCALAR);
			SPAGAIN;

			/* catch this surprisingly common error */
			if (SvROK (TOPs) && SvRV (TOPs) == rv)
			    croak ("%s::TO_AMF method returned same object as was passed instead of a new one", HvNAME (SvSTASH (rv)));

			rv = POPs;
			PUTBACK;

			amf3_format_object( aTHX_  io, rv);

			FREETMPS; LEAVE;
			return ;
		    }
		}
	    }

            if (SvTYPE(rv) == SVt_PVAV) 
		amf3_format_array(aTHX_  io, (AV*) rv);
            else if (SvTYPE(rv) == SVt_PVHV) {
                amf3_format_object(aTHX_  io, one);
            }
	    else if (sv_isobject( one ) && util_is_date( rv ) ){
		amf3_format_date(aTHX_ io, rv );
	    }
            else {
		if ( io->options & OPT_SKIP_BAD )
		    io_write_marker( aTHX_ io, MARKER3_UNDEF );
		else 
		    io_register_error( io, ERR_BAD_OBJECT);
            }
        }
    }
    else {
        if (SvOK(one)){
	    #if defined( EXPERIMENT1 )
	    if ( (io->options & OPT_PREFER_NUMBER )){
		if (SvNIOK(one)){
		    if ( SvIOK( one ) ){
			amf3_format_integer(aTHX_ io, one );
		    }
		    else {
			amf3_format_double(aTHX_  io, one);
		    }
		}
		else {
		    amf3_format_string(aTHX_  io, one);
		}
	    }
	    else 
	    #endif
            if (SvPOK(one)) {
                amf3_format_string(aTHX_  io, one);
            } else 
            if (SvIOK(one)){
                amf3_format_integer(aTHX_  io, one);
            }
            else if (SvNOK(one)){
                amf3_format_double(aTHX_  io, one);
            }
	    else {
		if ( io->options & OPT_SKIP_BAD )
		    io_write_marker( aTHX_ io, MARKER3_UNDEF );
		else 
		    io_register_error( io, ERR_BAD_OBJECT );
	    }
        }
        else {
            amf3_format_null(aTHX_  io);
        }
    }
}
typedef SV* (*parse_sub)(pTHX_ struct io_struct *io);


parse_sub parse_subs[] = {
    &amf0_parse_double,
    &amf0_parse_boolean,
    &amf0_parse_utf8,
    &amf0_parse_object,
    &amf0_parse_movieclip,
    &amf0_parse_null,
    &amf0_parse_undefined,
    &amf0_parse_reference,
    &amf0_parse_ecma_array,
    &amf0_parse_object_end,
    &amf0_parse_strict_array,
    &amf0_parse_date,
    &amf0_parse_long_string,
    &amf0_parse_unsupported,
    &amf0_parse_recordset,
    &amf0_parse_xml_document,
    &amf0_parse_typed_object
};

parse_sub amf3_parse_subs[] = {
    &amf3_parse_undefined,
    &amf3_parse_null,
    &amf3_parse_false,
    &amf3_parse_true,
    &amf3_parse_integer,
    &amf3_parse_double,
    &amf3_parse_string,
    &amf3_parse_xml_doc,
    &amf3_parse_date,
    &amf3_parse_array,
    &amf3_parse_object,
    &amf3_parse_xml,
    &amf3_parse_bytearray,
};

FREE_INLINE SV * amf3_parse_one(pTHX_ struct io_struct * io){
    unsigned char marker;

    marker = (unsigned char) io_read_marker(io);
    if (marker < ARRAY_SIZE( amf3_parse_subs )){
        return (amf3_parse_subs[marker])(aTHX_ io);
    }
    else {
        io_register_error( io, ERR_MARKER);
	return 0; /* Never reach this statement */
    }
}
FREE_INLINE SV* amf0_parse_one_tmp( pTHX_ struct io_struct *io, SV * reuse ){
    SV * RETVALUE;
    HV * obj;

    int len_next;
    char * key;
    SV * value;
    int obj_pos;

    io_require( io, 1 );
    RETVALUE = reuse;

    if ( MARKER0_OBJECT != MARKER0_OBJECT || ! SvROK( reuse ) ){
        io_register_error(  io, ERR_BAD_OBJECT );
    }
    obj = (HV *) SvRV(reuse);
    if ( SvTYPE( obj ) != SVt_PVHV ){
        io_register_error(  io, ERR_BAD_OBJECT );
    }
    ++io->pos;
        

    hv_clear( obj );
    SvREFCNT_inc_simple_void_NN( RETVALUE );
    av_push(io->arr_object, RETVALUE);
    obj_pos = av_len(io->arr_object);
    while(1){
        len_next = io_read_u16(io);
        if (len_next == 0) {
            char object_end;
            object_end= io_read_marker(io);
            if (MARKER0_OBJECT_END == object_end)
            {
                if (io->options & OPT_STRICT){
                    SV* RETVALUE = *av_fetch(io->arr_object, obj_pos, 0);
                    if (SvREFCNT(RETVALUE) > 1)
                        io_register_error( io, ERR_RECURRENT_OBJECT);
                    ;
                    SvREFCNT_inc_simple_void_NN(RETVALUE);
                    return RETVALUE;
                }
                else {
                    SvREFCNT_inc_simple_void_NN( RETVALUE );
                    return RETVALUE;
                    /* return (SV*) newRV_inc((SV*)obj); */
                }
            }
            else {
                io->pos--;
                key = "";
                value = amf0_parse_one(aTHX_  io);
            }
        }
        else {
            key = io_read_chars(io, len_next);
            value = amf0_parse_one(aTHX_  io);
        }

        (void) hv_store(obj, key, len_next, value, 0);
    }
}
STATIC_INLINE SV * amf0_parse_one(pTHX_ struct io_struct * io){
    unsigned char marker;
    marker = (unsigned char) io_read_marker(io);
    if ( marker < ARRAY_SIZE( parse_subs )){
        return (parse_subs[marker])(aTHX_ io);
    }
    else {
        return io_register_error( io, ERR_MARKER),(SV *)0;
    }
}
FREE_INLINE SV * deep_clone(pTHX_ SV * value);
FREE_INLINE AV * deep_array(pTHX_ AV* value){
    AV* copy =  (AV*) newAV();
    int c_len;
    int i;
    av_extend(copy, c_len = av_len(value));
    for(i = 0; i <= c_len; ++i){
        av_store(copy, i, deep_clone(aTHX_  *av_fetch(value, i, 0)));
    }
    return copy;
}

FREE_INLINE HV * deep_hash(pTHX_ HV* value){
    HV * copy =  (HV*) newHV();
    SV * key_value;
    char * key_str;
    I32 key_len;
    SV*	copy_val;

    hv_iterinit(value);
    while((key_value  = hv_iternextsv(value, &key_str, &key_len)) ){
        copy_val = deep_clone(aTHX_  key_value);
        (void) hv_store(copy, key_str, key_len, copy_val, 0);
    }
    return copy;
}

FREE_INLINE SV * deep_scalar(pTHX_ SV * value){
    return deep_clone(aTHX_  value);
}

FREE_INLINE SV * deep_clone(pTHX_ SV * value){
    if (SvROK(value)){
        SV * rv = (SV*) SvRV(value);
        SV * copy;
        if (SvTYPE(rv) == SVt_PVHV) {
            copy = newRV_noinc((SV*)deep_hash(aTHX_  (HV*) rv));
        }
        else if (SvTYPE(rv) == SVt_PVAV) {
            copy = newRV_noinc((SV*)deep_array(aTHX_  (AV*) rv));
        }
        else if (SvROK(rv)) {
            copy = newRV_noinc((SV*)deep_clone(aTHX_  (SV*) rv));
        }
        else {
            /* TODO: error checking
            return newSV(0); */
            copy = newRV_noinc(deep_clone(aTHX_  rv));
        }
        if (sv_isobject(value)) {
            HV * stash;
            stash = SvSTASH(rv);
            sv_bless(copy, stash);
        }
        return copy;
    }
    else {
        SV * copy;
        copy = newSV(0);
        if (SvOK(value)){
            sv_setsv(copy, value);
        }
        return copy;
    }
}
FREE_INLINE void ref_clear(pTHX_ HV * go_once, SV *sv){

    SV *ref_addr;
    if (! SvROK(sv))
    return;
    ref_addr = SvRV(sv);
    if (hv_exists(go_once, (char *) &ref_addr, sizeof (ref_addr)))
    return;
    (void) hv_store( go_once, (char *) &ref_addr, sizeof(ref_addr), &PL_sv_undef, 0);

    if (SvTYPE(ref_addr) == SVt_PVAV){
        AV * refarray = (AV*) ref_addr;
        int ref_len = av_len(refarray);
        int ref_index;
        for( ref_index = 0; ref_index <= ref_len; ++ref_index){
            SV ** ref_item = av_fetch( refarray, ref_index, 0);
            if (ref_item)
            ref_clear(aTHX_  go_once, *ref_item);
        }
        av_clear(refarray);
    }
    else if (SvTYPE(ref_addr) == SVt_PVHV){
        HV *ref_hash = (HV *) ref_addr;
        char *   key;
        I32  key_len;
        SV*  item;

        hv_iterinit(ref_hash);
        while( (item = hv_iternextsv(ref_hash, &key, &key_len)) ){
            ref_clear(aTHX_  go_once, item);
        };
        hv_clear(ref_hash);
    }
}    
/* Start XS defines
 *
 *
 *
 *
 *
 */

/* Temporary Intenale Storage */
#define check_bounds(low,high, mess) \
    if (items < low || items > high )\
        croak( mess );

MODULE = Storable::AMF0 PACKAGE = Storable::AMF0::TemporaryStorage
PROTOTYPES: DISABLE 

void
new(SV *class, SV *option=0)
    PPCODE:
    PERL_UNUSED_VAR( class );
    XPUSHs( sv_2mortal( tmpstorage_create_sv( aTHX_ NULL, option )));

void
DESTROY(SV *self)
    PPCODE:
    tmpstorage_destroy_sv( aTHX_ self );

PROTOTYPES: ENABLE

MODULE = Storable::AMF0 PACKAGE = Storable::AMF0		

void 
dclone(SV * data)
    ALIAS:
	Storable::AMF::dclone= 1
	Storable::AMF3::dclone= 2
    PROTOTYPE: $
    INIT:
        SV* retvalue;
    PPCODE:
	PERL_UNUSED_VAR(ix);
        retvalue = deep_clone(aTHX_  data);
        sv_2mortal(retvalue);
        XPUSHs(retvalue);

void 
amf_tmp_storage(...)
    INIT:
        SV * retvalue;
        SV * sv_option;
    PROTOTYPE: ;$
    PPCODE:
        if (items<0 || items > 1)
            croak("sv_option=0");
        if (items<1)
            sv_option = 0;
        else 
            sv_option = ST(0);

        retvalue = tmpstorage_create_sv(aTHX_ NULL, sv_option);
        XPUSHs(retvalue);

void
thaw(SV *data, ... )
    ALIAS:
	Storable::AMF::thaw=1
	Storable::AMF::thaw0=2
    PROTOTYPE: $;$
    INIT:
        SV* retvalue;
        SV* sv_option;
        struct io_struct *io;
    PPCODE:
	PERL_UNUSED_VAR(ix);
        check_bounds(1,2, "sv_option=0");
        if ( items == 1 )
            sv_option = 0;
        else 
            sv_option = ST(1);
        io = tmpstorage_create_and_cache(aTHX_ cv );
        if ( ! Sigsetjmp(io->target_error, 0) ){
            io->subname = "Storable::AMF0::thaw( data, option )";
            io_in_init(aTHX_  io, data, AMF0_VERSION, sv_option);
            retvalue = (SV*) (io->parse_one_object(aTHX_  io));
            retvalue = sv_2mortal(retvalue);
            io_test_eof( aTHX_ io );
            /* clean up storable unless need */
            if (io->reuse)
                io_in_cleanup(aTHX_ io);
            sv_setsv(ERRSV, &PL_sv_undef);
            XPUSHs(retvalue);
        }
        else {
            io_format_error( aTHX_ io );
        }

void
deparse_amf(SV *data, ... )
    PROTOTYPE: $;$
    ALIAS:
	Storable::AMF::deparse_amf=1
	Storable::AMF::deparse_amf0=2
    INIT:
        SV* retvalue;
        SV* sv_option;
	struct io_struct *io;
    PPCODE:
        check_bounds(1,2, "sv_option=0");
        if ( items == 1 )
            sv_option = 0;
        else 
            sv_option = ST(1);
	PERL_UNUSED_VAR(ix);
        io = tmpstorage_create_and_cache(aTHX_ cv );
        if ( ! Sigsetjmp(io->target_error, 0)){
            io->subname = "Storable::AMF0::deparse( data, option )";
            io_in_init(aTHX_  io, data, AMF0_VERSION, sv_option);
            
            retvalue = (SV*) (io->parse_one_object(aTHX_  io));
            sv_2mortal(retvalue);
            /* clean up storable unless need */
            if ( io->reuse )
                io_in_cleanup(aTHX_ io);
            sv_setsv(ERRSV, &PL_sv_undef);
            if (GIMME_V == G_ARRAY){
                XPUSHs(retvalue);
                XPUSHs( sv_2mortal(newSViv( io->pos - io->ptr )) );
            }
            else {
                XPUSHs(retvalue);
            }
        }
        else {
            io_format_error( aTHX_ io );
        }


void freeze(SV *data, ... )
    ALIAS:
	Storable::AMF::freeze=1
	Storable::AMF::freeze0=2
    PROTOTYPE: $;$
    INIT:
        SV * retvalue;
        SV * sv_option;
        struct io_struct *io;
    PPCODE:
        check_bounds(1,2, "sv_option=0");
        if ( items == 1 )
            sv_option = 0;
        else 
            sv_option = ST(1);
	PERL_UNUSED_VAR(ix);
        io = tmpstorage_create_and_cache(aTHX_ cv );
        if (! Sigsetjmp(io->target_error, 0)){
            io_out_init(aTHX_  io, sv_option, AMF0_VERSION);
            amf0_format_one(aTHX_  io, data);
            if (io->reuse )
                io_out_cleanup(aTHX_ io);
            retvalue = io_buffer(io);
            XPUSHs(retvalue);
            sv_setsv(ERRSV, &PL_sv_undef);
        }
        else{
	    io_format_error( aTHX_ io );
        }


MODULE = Storable::AMF0		PACKAGE = Storable::AMF3		

void
deparse_amf(SV *data, ... )
    ALIAS: 
        Storable::AMF::deparse_amf3 = 1
    PROTOTYPE: $;$
    INIT:
        SV* retvalue;
        SV* sv_option = 0;
        struct io_struct *io;
    PPCODE:
        check_bounds(1,2, "sv_option=0");
        if ( items == 1 )
            sv_option = 0;
        else 
            sv_option = ST(1);
	PERL_UNUSED_VAR(ix);
        io = tmpstorage_create_and_cache(aTHX_ cv );
        if ( ! Sigsetjmp(io->target_error, 0)){
            io->subname = "Storable::AMF3::deparse_amf( data, option )";
            io_in_init(aTHX_  io, data, AMF3_VERSION, sv_option);
            retvalue = (SV*) (amf3_parse_one(aTHX_  io));
            sv_2mortal(retvalue);
            /* clean up storable unless need */
            if ( io->reuse )
                io_in_cleanup(aTHX_ io);
            sv_setsv(ERRSV, &PL_sv_undef);

            XPUSHs(retvalue);
            if (GIMME_V == G_ARRAY){
                XPUSHs( sv_2mortal(newSViv( io->pos - io->ptr )) );
            }
        }
        else {
            io_format_error(aTHX_ io );
        }

void
thaw(SV *data, ... )
    PROTOTYPE: $;$
    INIT:
        SV* retvalue;
        SV *sv_option = 0;
        struct io_struct *io;
    ALIAS:
	Storable::AMF::thaw3=1
    PPCODE:
        check_bounds(1,2, "sv_option=0");
        if ( items == 1 )
            sv_option = 0;
        else 
            sv_option = ST(1);
	PERL_UNUSED_VAR(ix);
        io = tmpstorage_create_and_cache(aTHX_ cv );
        if ( ! Sigsetjmp(io->target_error, 0)){
            io->subname = "Storable::AMF3::thaw( data, option )";
            io_in_init(aTHX_  io, data, AMF3_VERSION, sv_option);
            retvalue = (SV*) (amf3_parse_one(aTHX_  io));
            sv_2mortal(retvalue);
            io_test_eof( aTHX_ io );
            /* clean up storable unless need */
            if ( io->reuse )
                io_in_cleanup(aTHX_ io);
            sv_setsv(ERRSV, &PL_sv_undef);
            XPUSHs(retvalue);
        }
        else {
            io_format_error(aTHX_ io);
        }

void
_test_thaw_integer(SV*data)
    PROTOTYPE: $
    INIT:
        SV* retvalue;
        struct io_struct *io;
    PPCODE:
        io = tmpstorage_create_and_cache(aTHX_ cv );
        if ( ! Sigsetjmp(io->target_error, 0)){
            io->subname = "Storable::AMF3::_test_thaw_integer( data, option )";
            io_in_init(aTHX_  io, data, AMF3_VERSION, 0 );
            retvalue = (SV*) (amf3_parse_integer(aTHX_  io));
            sv_2mortal(retvalue);
            io_test_eof( aTHX_ io );

            sv_setsv(ERRSV, &PL_sv_undef);
            XPUSHs(retvalue);
        }
        else {
            io_format_error(aTHX_ io );
        }

void
_test_freeze_integer(SV*data)
    PROTOTYPE: $
    PREINIT:
        SV * retvalue;
        struct io_struct *io;
    PPCODE:
        io = tmpstorage_create_and_cache(aTHX_ cv );
        if (! Sigsetjmp(io->target_error, 0)){
            io_out_init(aTHX_  io, 0, AMF3_VERSION);
            amf3_write_integer(aTHX_  io, SvIV(data));
            retvalue = io_buffer(io);
            XPUSHs(retvalue);
            sv_setsv(ERRSV, &PL_sv_undef);
        }
        else {
	    io_format_error( aTHX_ io );
        }


void 
endian()
    PROTOTYPE:
    PREINIT:
        SV * retvalue;
    PPCODE:
    retvalue = newSVpvf("%s %x\n",GAX, BYTEORDER);
    sv_2mortal(retvalue);
    XPUSHs(retvalue);

void freeze(SV *data, SV *sv_option = 0 )
    PROTOTYPE: $;$
    PREINIT:
        SV * retvalue;
        struct io_struct *io;
    ALIAS:
	Storable::AMF::freeze3=1
    PPCODE:
	PERL_UNUSED_VAR(ix); 
        io = tmpstorage_create_and_cache(aTHX_ cv );
        if (! Sigsetjmp(io->target_error, 0)){
            io_out_init(aTHX_  io, sv_option, AMF3_VERSION);
            amf3_format_one(aTHX_  io, data);
            if (io->reuse )
                io_out_cleanup(aTHX_ io);
            retvalue = io_buffer(io);
            XPUSHs(retvalue);
            sv_setsv(ERRSV, &PL_sv_undef);
        }
        else {
	    io_format_error( aTHX_ io );
        }

void
new_amfdate(NV timestamp )
    PREINIT:
    SV *mortal;
    PROTOTYPE: $
    ALIAS:
	Storable::AMF::new_amfdate =1
	Storable::AMF0::new_amfdate=2
	Storable::AMF::new_date =3
	Storable::AMF0::new_date=4
	Storable::AMF3::new_date=5
    PPCODE:
	PERL_UNUSED_VAR( ix );
	mortal=sv_newmortal();
	sv_setref_nv( mortal, "*", timestamp ); /*Stupid but it works */
	XPUSHs( mortal );

void 
perl_date(SV *date)
    PREINIT:
    SV *mortal;
    PROTOTYPE: $
    ALIAS: 
	Storable::AMF::perl_date=1
	Storable::AMF0::perl_date=2
    PPCODE:
	PERL_UNUSED_VAR( ix );
	if ( SvROK( date ) && util_is_date( (SV*) SvRV(date))){
	    XPUSHs((SV*) SvRV(date));
	}
	else if ( SvNOK( date )){
	    mortal = sv_newmortal();
	    sv_setnv( mortal, SvNV( date ));
	    XPUSHs(mortal);
	}
	else {
	    croak("Expecting perl/amf date as argument" );
	}

void
parse_option(char * s, int options=0)
    PREINIT: 
    int s_strict;
    int s_utf8_decode;
    int s_utf8_encode;
    int s_milldate;
    int s_raise_error;
    int s_prefer_number;
    int s_ext_boolean; /* I8 -> int*/
    int s_targ;
    int sign;  
    char *word;
    char *current;
    bool error;
    PROTOTYPE: $;$
    ALIAS:
    Storable::AMF::parse_option=1
    Storable::AMF0::parse_option=2
    Storable::AMF::parse_serializator_option=3
    Storable::AMF3::parse_serializator_option=4
    Storable::AMF0::parse_serializator_option=5
    PPCODE:
    PERL_UNUSED_VAR( ix );
    s_strict = 0;
    s_utf8_decode = 0;
    s_utf8_encode = 0;
    s_milldate    = 0;
    s_raise_error = 0;
    s_prefer_number = 0;
    s_ext_boolean   = 0;
    options         = 0;
    s_targ          = 1;

    for( current = s;*current && ( !isALPHA( *current ) && *current!='+' && *current!='-' ) ; ++current ); 

    word = current;
    while( *word ){
	++current;
	error = 0;
	sign  = 1;
	if ( *word == '+' ){
	    ++word;
	}
	else if ( *word =='-' ){
	    sign = -1;
	    ++word;
	}
	for( ; *current && ( isALNUM( *current ) || *current == '_' ); ++current );
	switch( current - word ){
        case 4:
            if ( !strncmp( "targ", word, 4)){
                    s_targ = sign;
            }
            else {
                error = 1;
            };
            break;
	case 6:
	    if (!strncmp("strict", word, 6)){
		s_strict = sign;
	    }
	    else {
		error = 1;
	    };
	    break;
	case 11:
	    if (!strncmp( "utf8_decode", word, 11)){
		s_utf8_decode = sign;
	    }
	    else if (!strncmp( "utf8_encode", word, 11)){
		s_utf8_encode = sign;
	    }
	    else if (!strncmp("raise_error", word, 9)){
		s_raise_error=sign;
	    }
	    else {
		error = 1;
	    }
	    break;
	case 13:
	    if (!strncmp( "prefer_number", word, 13)){
		s_prefer_number = sign;
	    }
	    else {
		error = 1;
	    };
	    break;
	case   12:
	    if (!strncmp("json_boolean", word, 12)){
		s_ext_boolean = sign;
	    }
	    else if (!strncmp("boolean_json", word, 12)){
		s_ext_boolean = sign;
	    }
	    else  
		error = 1;
	    break;
	case   16:
	    if (!strncmp("millisecond_date", word, 16)){
		s_milldate = sign;
	    }
	    else 
		error = 1;
	    break;
	default:
	    error = 1;
	};
	if (error)
	    croak("Storable::AMF0::parse_option: unknown option '%.*s'", (int)(current - word), word);

	for(; *current && !isALPHA(*current) && *current!='+' && *current!='-'; ++current);
	word = current;
    };	
    SIGN_BOOL_APPLY( options, s_strict,        OPT_STRICT );
    SIGN_BOOL_APPLY( options, s_milldate,      OPT_MILLSEC_DATE );
    SIGN_BOOL_APPLY( options, s_utf8_decode,   OPT_DECODE_UTF8 );
    SIGN_BOOL_APPLY( options, s_utf8_encode,   OPT_ENCODE_UTF8 );
    SIGN_BOOL_APPLY( options, s_raise_error,   OPT_RAISE_ERROR );
    SIGN_BOOL_APPLY( options, s_prefer_number, OPT_PREFER_NUMBER );
    SIGN_BOOL_APPLY( options, s_ext_boolean,   OPT_JSON_BOOLEAN );
    SIGN_BOOL_APPLY( options, s_targ,          OPT_TARG );
    mXPUSHi(  options ); 

MODULE = Storable::AMF0 PACKAGE = Storable::AMF::Util

void
total_sv()
    PROTOTYPE: 
    PPCODE:
    I32 visited  = 0;
    SV* sva;
    for( sva = PL_sv_arenaroot; sva; sva = (SV*)SvANY(sva)) {
        SV * svend = &sva[SvREFCNT(sva)];
        SV * svi;
        /* fprintf( stderr, "=%p %d\n", sva, SvREFCNT( sva ) ); */
        for( svi = sva + 1; svi<svend; ++svi ){
            if ( (unsigned int)SvTYPE(svi) != SVTYPEMASK && SvREFCNT(svi) ){
                /** skip pads, they have a PVAV as their first element inside a PVAV **/
                if (SvTYPE(svi) == SVt_PVAV &&  av_len( (AV*) svi) != -1) {
                    SV** first = AvARRAY((AV*)svi);
                    if (first && *first && SvTYPE(*first) == SVt_PVAV) {
                        continue;
                    }
                    if (first && *first && SvTYPE(*first) == SVt_PVCV) {
                        continue;
                    }
                }
                if (SvTYPE(svi) == SVt_PVCV && CvROOT((CV*)svi) == 0) {
                    continue;
                }
                ++visited;
            }
        }
    }
    mXPUSHi( visited );

MODULE=Storable::AMF0 PACKAGE = Storable::AMF 

void 
thaw0_sv(SV * data, SV * element, ... )
    PROTOTYPE: $$;$
    INIT: 
        SV * retvalue;
        SV *sv_option;
        struct io_struct *io;
    PPCODE:
        check_bounds(2,3, "sv_option=0");
        if ( items == 2 )
            sv_option = 0;
        else 
            sv_option = ST(2);
	/* PERL_UNUSED_VAR(ix); */
        io = tmpstorage_create_and_cache(aTHX_ cv );
        if ( ! Sigsetjmp(io->target_error, 0) ){
            io->subname = "Storable::AMF0::thaw( data, option )";
            io_in_init(aTHX_  io, data, AMF0_VERSION, sv_option);
            retvalue = (SV*) (amf0_parse_one_tmp( aTHX_  io, element ));
            /* clean up storable unless need */
            retvalue = sv_2mortal(retvalue);
            io_test_eof( aTHX_ io );
            if ( io->reuse )
                io_in_cleanup(aTHX_ io);
            sv_setsv(ERRSV, &PL_sv_undef);

            /* XPUSHs(retvalue); */
        }
        else {
            io_format_error( aTHX_ io );
        }

MODULE=Storable::AMF
