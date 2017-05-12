#ifndef _HELPER_C_
#define _HELPER_C_

#include "helper.h"
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

my_stack_t * new_my_stack() {

    my_stack_opts_t * opts = malloc( sizeof( *opts ) );
    my_stack_t * out = malloc( sizeof( *out ) );

    out -> opts = opts;
    opts -> strict_signature = 0;

    return out;
}

char * call_load_parameterizable_type_class( char * class, char * word ) {

    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK( SP );

    XPUSHs( sv_2mortal( newSVpvn( class, strlen( class ) ) ) );
    XPUSHs( sv_2mortal( newSVpvn( word, strlen( word ) ) ) );

    PUTBACK;

    const char * suffix = "::load_parameterizable_type_class\0";
    char * path = malloc( strlen( class ) + strlen( suffix ) + 1 );

    strcpy( path, class );
    strcat( path, suffix );

    int count = call_pv( path, G_SCALAR );

    free( path );

    SPAGAIN;

    if ( count != 1 ) croak( "Can't call load_parameterizable_type_class()\n" );

    char * out = strdup( POPp );

    PUTBACK;
    FREETMPS;
    LEAVE;

    return out;
}

static inline void hash_set_sv( HV * hash, char * key, SV * value ) {

    hv_store( hash, key, strlen( key ), value, 0 );
}

static inline void hash_set_str( HV * hash, char * key, char * value ) {

    hash_set_sv( hash, key, newSVpvn( value, strlen( value ) ) );
}

static inline void hash_set_short( HV * hash, char * key, short value ) {

    hash_set_sv( hash, key, newSViv( value ) );
}

static HV * token_to_perl( intptr_t token );

HV * tokens_to_perl( my_stack_t * stack ) {

    if( stack == 0 ) croak( "Parser error\n" );

    int size = stack -> size;

    AV * perl_tokens = newAV();

    for( int i = 0; i < size; ++i ) {

        HV * perl_token = token_to_perl( stack -> data[ i ] );

        av_push( perl_tokens, newRV_noinc( (SV*)perl_token ) );
    }

    HV * perl_token = newHV();
    hash_set_sv( perl_token, "data\0", newRV_noinc( (SV*)perl_tokens ) );

    HV * perl_opts = newHV();

    my_stack_opts_t * opts = stack -> opts;
    hash_set_short( perl_opts, "strict\0", opts -> strict_signature );

    hash_set_sv( perl_token, "opts\0", newRV_noinc( (SV*)perl_opts ) );

    return perl_token;
}

static HV * token_to_perl( intptr_t token ) {

    HV * perl_token = newHV();
    short token_type = ((abstract_type_t*)token) -> token_type;

    if( token_type == TOKEN_TYPE_BASIC ) {

        hash_set_str( perl_token, "type\0", ((basic_type_t*)token) -> type );

    } else if( token_type == TOKEN_TYPE_MAYBE ) {

        HV * stack = tokens_to_perl( ((maybe_type_t*)token) -> stack );
        hash_set_sv( perl_token, "maybe\0", newRV_noinc( (SV*)stack ) );

    } else if( token_type == TOKEN_TYPE_PARAMETRIZABLE ) {

        hash_set_str( perl_token, "class\0", ((parameterizable_type_t*)token) -> class );

        HV * param = tokens_to_perl( ((parameterizable_type_t*)token) -> param );
        hash_set_sv( perl_token, "param\0", newRV_noinc( (SV*)param ) );

        HV * base = tokens_to_perl( ((parameterizable_type_t*)token) -> stack );
        hash_set_sv( perl_token, "base\0", newRV_noinc( (SV*)base ) );

    } else if( token_type == TOKEN_TYPE_SIGNED ) {

        HV * perl_param = newHV();

        hash_set_str( perl_param, "source\0", ((signed_type_t*)token) -> source );

        HV * type = token_to_perl( ((signed_type_t*)token) -> type );
        hash_set_sv( perl_param, "type\0", newRV_noinc( (SV*)type ) );

        HV * signature = tokens_to_perl( ((signed_type_t*)token) -> signature );
        hash_set_sv( perl_param, "signature\0", newRV_noinc( (SV*)signature ) );

        hash_set_sv( perl_token, "signed\0", newRV_noinc( (SV*)perl_param ) );

    } else if( token_type == TOKEN_TYPE_SIGNATURE_ITEM ) {

        signature_param_t * param = ((signature_item_t*)token) -> param;

        HV * type = tokens_to_perl( ((signature_item_t*)token) -> type );
        hash_set_sv( perl_token, "type\0", newRV_noinc( (SV*)type ) );

        HV * perl_param = newHV();

        hash_set_str( perl_param, "name\0", param -> name );
        hash_set_short( perl_param, "named\0", param -> named );
        hash_set_short( perl_param, "positional\0", param -> positional );
        hash_set_short( perl_param, "required\0", param -> required );
        hash_set_short( perl_param, "optional\0", param -> optional );

        hash_set_sv( perl_token, "param\0", newRV_noinc( (SV*)perl_param ) );

    } else if ( token_type == TOKEN_TYPE_LENGTH ) {

        HV * perl_param = newHV();

        HV * type = token_to_perl( ((length_type_t*)token) -> type );
        hash_set_sv( perl_param, "type\0", newRV_noinc( (SV*)type ) );

        if( ((length_type_t*)token) -> has_min == 1 ) {

            hash_set_str( perl_param, "min\0", ((length_type_t*)token) -> min );

        } else {

            hash_set_sv( perl_param, "min\0", newSVsv( &PL_sv_undef ) );
        }

        if( ((length_type_t*)token) -> has_max == 1 ) {

            hash_set_str( perl_param, "max\0", ((length_type_t*)token) -> max );

        } else {

            hash_set_sv( perl_param, "max\0", newSVsv( &PL_sv_undef ) );
        }

        hash_set_sv( perl_token, "length\0", newRV_noinc( (SV*)perl_param ) );
    }

    return perl_token;
}

static inline SV ** hash_get( HV * hash, char * key ) {

    return hv_fetch( hash, key, strlen( key ), 0 );
}

tokenizer_options_t * perl_to_options( HV * options ) {

    tokenizer_options_t * out = malloc( sizeof( *out ) );

    SV ** perl_loose = hash_get( options, "loose\0" );

    if( perl_loose != 0 ) {

        out -> loose = SvIV( *perl_loose );

    } else {

        out -> loose = 0;
    }

    return out;
}

HV * mortalize_hv( HV * v ) {

    return (HV*)sv_2mortal( (SV*)v );
}

static void free_token( intptr_t token );

void free_stack_arr( intptr_t * stack, int size ) {

    for( int i = 0; i < size; ++i ) {

        free_token( stack[ i ] );
    }

    free( stack );
}

void free_my_stack( my_stack_t * stack ) {

    free_stack_arr( stack -> data, stack -> size );
    free( stack -> opts );
    free( stack );
}

static void free_token( intptr_t token ) {

    short token_type = ((abstract_type_t*)token) -> token_type;

    if( token_type == TOKEN_TYPE_BASIC ) {

        free( ((basic_type_t*)token) -> type );
        free((basic_type_t*)token);

    } else if( token_type == TOKEN_TYPE_MAYBE ) {

        free_my_stack( ((maybe_type_t*)token) -> stack );
        free((maybe_type_t*)token);

    } else if( token_type == TOKEN_TYPE_PARAMETRIZABLE ) {

        free( ((parameterizable_type_t*)token) -> class );
        free_my_stack( ((parameterizable_type_t*)token) -> param );
        free_my_stack( ((parameterizable_type_t*)token) -> stack );
        free((parameterizable_type_t*)token);

    } else if( token_type == TOKEN_TYPE_SIGNED ) {

        free( ((signed_type_t*)token) -> source );
        free_token( ((signed_type_t*)token) -> type );
        free_my_stack( ((signed_type_t*)token) -> signature );
        free((signed_type_t*)token);

    } else if( token_type == TOKEN_TYPE_SIGNATURE_ITEM ) {

        signature_param_t * param = ((signature_item_t*)token) -> param;

        free_my_stack( ((signature_item_t*)token) -> type );
        free( param -> name );
        free( param );
        free((signature_item_t*)token);

    } else if ( token_type == TOKEN_TYPE_LENGTH ) {

        free_token( ((length_type_t*)token) -> type );
        if( ((length_type_t*)token) -> has_min == 1 ) free( ((length_type_t*)token) -> min );
        if( ((length_type_t*)token) -> has_max == 1 ) free( ((length_type_t*)token) -> max );
        free((length_type_t*)token);
    }
}

void p_die( char * s ) {

    croak( "%s", s );
}

#endif /* end of include guard: _HELPER_C_ */
