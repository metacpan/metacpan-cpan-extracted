/* Copyright 2009 Peter Karman
 *
 * This program is free software; you can redistribute it and/or modify
 * under the same terms as Perl itself.
 */

/*
 * Standard XS greeting.
 */
#ifdef __cplusplus
extern "C" {
#endif
#define PERL_NO_GET_CONTEXT 
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#ifdef __cplusplus
}
#endif

#ifdef EXTERN
  #undef EXTERN
#endif

#define EXTERN static

/* pure C helpers */
#include "search-tools.c"

/********************************************************************/

MODULE = Search::Tools       PACKAGE = Search::Tools

PROTOTYPES: enable


void
describe(thing)
    SV *thing
    
    CODE:
        st_describe_object(thing);
        st_dump_sv(thing);
        

######################################################################
MODULE = Search::Tools       PACKAGE = Search::Tools::UTF8

PROTOTYPES: enable

int
byte_length(string)
    SV* string;
    
    PREINIT:
        STRLEN len;
        U8 * bytes;
        
    CODE:
        bytes  = (U8*)SvPV(string, len);
        RETVAL = len;
    
    OUTPUT:
        RETVAL


int
is_perl_utf8_string(string)
    SV* string;
    
    PREINIT:
        STRLEN len;
        U8 * bytes;
        
    CODE:
        bytes  = (U8*)SvPV(string, len);
        RETVAL = is_utf8_string(bytes, len);
        
    OUTPUT:
        RETVAL
        
                

SV*
find_bad_utf8(string)
    SV* string;
            
    CODE:
        RETVAL = st_find_bad_utf8(string);

    OUTPUT:
        RETVAL

     
# benchmarks show these XS versions are 9x faster
# than their native Perl regex counterparts
boolean 
is_ascii(string)
    SV* string;
            
    CODE:
        RETVAL = st_is_ascii(string);

    OUTPUT:
        RETVAL


boolean
is_latin1(string)
    SV* string;

    PREINIT:
        STRLEN         len;
        unsigned char* bytes;
        unsigned int   i;

    CODE:
        bytes  = (unsigned char*)SvPV(string, len);
        RETVAL = 1;
        for(i=0; i < len; i++) {
            if (bytes[i] > 0x7f && bytes[i] < 0xa0) {
                RETVAL = 0;
                break;
            }
        }

    OUTPUT:
        RETVAL


void
debug_bytes(string)
    SV* string;

    PREINIT:
        STRLEN         len;
        unsigned char* bytes;
        unsigned int   i;

    CODE:
        bytes  = (unsigned char*)SvPV(string, len);
        for(i=0; i < len; i++) {
            warn("'%c' \\x%x \\%d\n", bytes[i], bytes[i], bytes[i]);
        }


IV
find_bad_ascii(string)
    SV* string;
    
    PREINIT:
        STRLEN          len;
        unsigned char*  bytes;
        int             i;
        
    CODE:
        bytes  = (unsigned char*)SvPV(string, len);
        RETVAL = -1;
        for(i=0; i < len; i++) {
            if (bytes[i] >= 0x80) {
                RETVAL = i;
                break;
            }  
        }

    OUTPUT:
        RETVAL

int
find_bad_latin1(string)
    SV* string;

    PREINIT:
        STRLEN          len;
        unsigned char*  bytes;
        int             i;

    CODE:
        bytes  = (unsigned char*)SvPV(string, len);
        RETVAL = -1;
        for(i=0; i < len; i++) {
            if (bytes[i] > 0x7f && bytes[i] < 0xa0) {
                RETVAL = i;
                break;
            }
        }

    OUTPUT:
        RETVAL



#############################################################################

MODULE = Search::Tools       PACKAGE = Search::Tools::Tokenizer

PROTOTYPES: enable

SV*
tokenize(self, str, ...)
    SV* self;
    SV* str;
    
    PREINIT:
        SV* token_re;
        SV* token_list_sv;
        STRLEN len;
        U8* bytes;
        SV* heat_seeker = NULL;
        IV match_num;
        
    CODE:
        if (items > 2) {
            heat_seeker = ST(2);
        }
        match_num = 0;
        if (items > 3) {
            match_num = SvIV(ST(3));
        }
        
        /* test if utf8 flag on and make sure it is.
         * otherwise, regex for \w can fail for multibyte chars.
         * we do a slight (~7%) optimization for ascii str because
         * the regex engine is faster for all-ascii texts.
         * the logic is: 
         *  if the flag is on, ok.
         *  else, 
         *      if the string is ascii, ok for flag to be off,
         *      but we don't turn it off. 
         *      if the string is NOT ascii, make sure it is utf8
         *      and turn the flag on. 
         */
        if (!SvUTF8(str)) {
            if (!st_is_ascii(str)) {
                bytes  = (U8*)SvPV(str, len);
                if(!is_utf8_string(bytes, len)) {
                    croak(ST_BAD_UTF8);
                }
                SvUTF8_on(str);
            }
        }

        token_re = st_hvref_fetch(self, "re");
        token_list_sv = st_tokenize(str, token_re, heat_seeker, match_num);
        RETVAL = token_list_sv;
    
    OUTPUT:
        RETVAL

SV*
set_debug(self, val)
    SV* self;
    boolean val;
    
    CODE:
        SV* st_debug_var;
        st_debug_var = get_sv("Search::Tools::XS_DEBUG", GV_ADD);
        //warn(" st_debug_var before = '%s'\n", SvPV_nolen(st_debug_var));
        SvIV_set(st_debug_var, val);
        SvIOK_on(st_debug_var);
        //warn("ST_DEBUG set to %d", val);
        //warn(" st_debug_var set = '%d'\n", ST_DEBUG);
        if (SvREFCNT(st_debug_var) == 1) {
            // IMPORTANT because we access var from Perl and C
            SvREFCNT_inc(st_debug_var);
        }
        RETVAL = st_debug_var;
    
    OUTPUT:
        RETVAL


SV*
get_offsets(self, str, regex)
    SV* self;
    SV* str;
    SV* regex;
    
    CODE:
        RETVAL = newRV_noinc((SV*)st_heat_seeker_offsets(str, regex));
    
    OUTPUT:
        RETVAL



############################################################################

MODULE = Search::Tools       PACKAGE = Search::Tools::TokenList

PROTOTYPES: enable

void
dump(self)
    st_token_list *self;
    
    CODE:
        st_dump_token_list(self);


SV*
next(self)
    st_token_list *self;
   
    PREINIT:
        IV len;
        
    CODE:
        len = av_len(self->tokens);
        //warn("len = %d and pos = %d", len, self->pos);
        
        if (len == -1) {
            // empty list
            RETVAL = &PL_sv_undef;
        }
        else if (self->pos > len) {
            // exceeded end of list
            RETVAL = &PL_sv_undef;
        }
        else {
            if (!av_exists(self->tokens, self->pos)) {
                ST_CROAK("no such index at %d", self->pos);
            }
            //st_dump_sv( st_av_fetch(self->tokens, self->pos) );
            RETVAL = SvREFCNT_inc(st_av_fetch(self->tokens, self->pos++));
            
        }
        
            
    OUTPUT:
        RETVAL


SV*
prev(self)
    st_token_list *self;
   
    PREINIT:
        IV len;
        
    CODE:
        len = av_len(self->tokens);
        if (len == -1) {
            // empty list
            RETVAL = &PL_sv_undef;
        }
        else if (self->pos < 0) {
            // exceeded start of list
            RETVAL = &PL_sv_undef;
        }
        else {
            if (!av_exists(self->tokens, (self->pos-1))) {
                ST_CROAK("no such index at %d", (self->pos-1));
            }
            RETVAL = SvREFCNT_inc(st_av_fetch(self->tokens, --(self->pos)));
        }
        
            
    OUTPUT:
        RETVAL


SV*
get_token(self, pos)
    st_token_list *self;
    IV pos;
    
    CODE:
        if (!av_exists(self->tokens, pos)) {
            RETVAL = &PL_sv_undef;
        }
        else {
            RETVAL = SvREFCNT_inc(st_av_fetch(self->tokens, pos));
        }
    
    OUTPUT:
        RETVAL


IV
set_pos(self, new_pos)
    st_token_list *self;
    IV  new_pos;
            
    CODE:
        RETVAL = self->pos;
        self->pos = new_pos;
       
    OUTPUT:
        RETVAL


IV
reset(self)
    st_token_list *self;
        
    CODE:
        RETVAL = self->pos;
        self->pos = 0;
    
    OUTPUT:
        RETVAL
 

IV
len(self)
    st_token_list *self;
    
    CODE:
        RETVAL = av_len(self->tokens) + 1;
        
    OUTPUT:
        RETVAL


IV
num(self)
    st_token_list *self;
    
    CODE:
        RETVAL = self->num;
    
    OUTPUT:
        RETVAL


IV
pos(self)
    st_token_list *self;
    
    CODE:
        RETVAL = self->pos;
    
    OUTPUT:
        RETVAL


SV*
as_array(self)
    st_token_list *self;
    
    CODE:
        RETVAL = newRV_inc((SV*)self->tokens);
    
    OUTPUT:
        RETVAL
        

SV*
get_heat(self)
    st_token_list *self;
    
    PREINIT:
        AV *heat;
        IV len;
        IV pos;
        SV* h;
    
    CODE:
        heat = newAV();
        pos = 0;
        len = av_len(self->heat)+1;
        while (pos < len) {
            h = st_av_fetch(self->heat, pos++);
            av_push(heat, h);
        }
        RETVAL = newRV((SV*)heat);    /* no _inc -- this is a copy */
    
    OUTPUT:
        RETVAL


SV*
get_sentence_starts(self)
    st_token_list *self;
    
    PREINIT:
        AV *starts;
        IV len;
        IV pos;
        SV* sstart;
    
    CODE:
        starts = newAV();
        pos = 0;
        len = av_len(self->sentence_starts)+1;
        while (pos < len) {
            sstart = st_av_fetch(self->sentence_starts, pos++);
            av_push(starts, sstart);
        }
        RETVAL = newRV((SV*)starts);    /* no _inc -- this is a copy */
    
    OUTPUT:
        RETVAL


SV*
matches(self)
    st_token_list *self;
    
    PREINIT:
        AV *matches;
        IV pos;
        IV len;
        SV* tok;
        st_token *token;
    
    CODE:
        matches = newAV();
        pos = 0;
        len = av_len(self->tokens)+1;
        while (pos < len) {
            tok = st_av_fetch(self->tokens, pos++);
            token = (st_token*)st_extract_ptr(tok);
            if (token->is_match) {
                av_push(matches, tok);
            }
        }
        RETVAL = newRV((SV*)matches); /* no _inc -- this is only copy */
    
    OUTPUT:
        RETVAL


IV
num_matches(self)
    st_token_list *self;
    
    PREINIT:
        IV pos;
        IV len;
        IV num_matches;
        st_token *token;
    
    CODE:
        num_matches = 0;
        pos = 0;
        len = av_len(self->tokens)+1;
        while (pos < len) {
            token = (st_token*)st_av_fetch_ptr(self->tokens, pos++);
            if (token->is_match) {
                num_matches++;
            }
        }
        RETVAL = num_matches;
    
    OUTPUT:
        RETVAL


void
DESTROY(self)
    SV *self;
    
    PREINIT:
        st_token_list *tl;
        
    CODE:
        
        
        tl = (st_token_list*)st_extract_ptr(self);
        tl->ref_cnt--;
        if (ST_DEBUG) {
            warn("............................");
            warn("DESTROY %s [%ld] [0x%lx]\n", 
                SvPV_nolen(self), (unsigned long)tl->ref_cnt, (unsigned long)tl);
            st_describe_object(self);
            st_dump_sv((SV*)tl->tokens);
        }
        if (tl->ref_cnt < 1) {
            st_free_token_list(tl);
        }



############################################################################

MODULE = Search::Tools       PACKAGE = Search::Tools::Token

PROTOTYPES: enable

IV
pos(self)
    st_token *self;
    
    CODE:
        RETVAL = self->pos;
    
    OUTPUT:
        RETVAL


SV*
str(self)
    st_token *self;
            
    CODE:
        RETVAL = SvREFCNT_inc(self->str);

    OUTPUT:
        RETVAL


IV
len(self)
    st_token *self;
    
    CODE:
        RETVAL = self->len;
    
    OUTPUT:
        RETVAL


IV
u8len(self)
    st_token *self;
    
    CODE:
        RETVAL = self->u8len;
    
    OUTPUT:
        RETVAL


IV
is_hot(self)
    st_token *self;
    
    CODE:
        RETVAL = self->is_hot;
    
    OUTPUT:
        RETVAL


IV
is_match(self)
    st_token *self;
    
    CODE:
        RETVAL = self->is_match;
    
    OUTPUT:
        RETVAL


IV
is_sentence_start(self)
    st_token *self;
    
    CODE:
        RETVAL = self->is_sentence_start;
    
    OUTPUT:
        RETVAL


IV
is_sentence_end(self)
    st_token *self;
    
    CODE:
        RETVAL = self->is_sentence_end;
    
    OUTPUT:
        RETVAL

IV
is_abbreviation(self)
    st_token *self;
    
    CODE:
        RETVAL = self->is_abbreviation;
    
    OUTPUT:
        RETVAL
        
IV
set_match(self, val)
    st_token *self;
    IV val;
    
    CODE:
        RETVAL = self->is_match;
        self->is_match = val;
    
    OUTPUT:
        RETVAL


IV
set_hot(self, val)
    st_token *self;
    IV val;
    
    CODE:
        RETVAL = self->is_hot;
        self->is_hot = val;
    
    OUTPUT:
        RETVAL


void
dump(self)
    st_token *self;
    
    CODE:
        st_dump_token(self);


void
DESTROY(self)
    SV *self;
    
    PREINIT:
        st_token *tok;
        
    CODE:
        tok = (st_token*)st_extract_ptr(self);
        tok->ref_cnt--;
        if (ST_DEBUG) {
            warn("............................");
            warn("DESTROY %s [%ld] [0x%lx]\n", 
                SvPV_nolen(self), (unsigned long)tok->ref_cnt, (unsigned long)tok);
        }
        if (tok->ref_cnt < 1) {
            st_free_token(tok);
        }
    

############################################################################

MODULE = Search::Tools       PACKAGE = Search::Tools::XML

PROTOTYPES: enable

SV*
_escape_xml(text, is_flagged_utf8)
    char *text;
    int   is_flagged_utf8;

    CODE:
        RETVAL = st_escape_xml(text);
        if (is_flagged_utf8) {
            SvUTF8_on(RETVAL);
        }
    
    OUTPUT:
        RETVAL
 
