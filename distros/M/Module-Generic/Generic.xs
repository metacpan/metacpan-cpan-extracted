/*---------------------------------------------------------------------------
 * Module::Generic::File::Magic - Magic.xs
 * Version v0.1.0
 * Copyright(c) 2026 DEGUEST Pte. Ltd.
 * Author: Jacques Deguest <jack@deguest.jp>
 * Created  2026/03/07
 * Modified 2026/03/08
 *
 * XS bindings for libmagic, loaded dynamically at runtime via dlopen(3).
 *
 * Design goals:
 *   - No magic.h required at build time
 *   - No libmagic-dev / file-devel required at build time
 *   - Only libmagic.so.1 (the binary runtime package) needed at runtime
 *   - All symbols resolved via dlopen + dlsym in the BOOT block
 *   - If dlopen fails (libmagic absent), BOOT does NOT croak — instead it
 *     sets $Module::Generic::File::Magic::BACKEND to "json" so the Perl
 *     layer falls back to the pure-Perl JSON backend
 *   - Optional symbols (magic_getflags, magic_version, magic_compile,
 *     magic_check, magic_list) silently degrade to undef if absent
 *
 * The magic_t cookie is stored and passed as a Perl IV (integer large
 * enough to hold a pointer on both ILP32 and LP64 platforms).
 *
 * NOTE on MODULE vs PACKAGE:
 * MODULE = Module::Generic so that XSLoader::load("Module::Generic") in
 * Magic.pm resolves the bootstrap symbol boot_Module__Generic correctly,
 * matching the Generic.so produced by EUMM with NAME = "Module::Generic".
 * PACKAGE = Module::Generic::File::Magic installs all XS functions in the
 * correct namespace.  This pattern is also used by Time::HiRes and POSIX.
 *---------------------------------------------------------------------------*/
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <dlfcn.h>
#include <stddef.h>
#include <string.h>

/*
 * Opaque handle type.
 * libmagic defines magic_t as struct magic_set* internally; we treat it
 * as void* since we never dereference it.
 */
typedef void* magic_t;

/*
 * Function pointer typedefs — mirrors <magic.h> without including it.
 */
typedef magic_t     (*fn_magic_open)        ( int flags );
typedef void        (*fn_magic_close)       ( magic_t cookie );
typedef int         (*fn_magic_load)        ( magic_t cookie, const char* filename );
typedef const char* (*fn_magic_file)        ( magic_t cookie, const char* filename );
typedef const char* (*fn_magic_buffer)      ( magic_t cookie, const void* buffer, size_t length );
typedef const char* (*fn_magic_descriptor)  ( magic_t cookie, int fd );
typedef const char* (*fn_magic_error)       ( magic_t cookie );
typedef int         (*fn_magic_setflags)    ( magic_t cookie, int flags );
typedef int         (*fn_magic_getflags)    ( magic_t cookie );          /* optional */
typedef int         (*fn_magic_version)     ( void );                    /* optional */
typedef int         (*fn_magic_compile)     ( magic_t cookie, const char* filename ); /* optional */
typedef int         (*fn_magic_check)       ( magic_t cookie, const char* filename ); /* optional */
typedef int         (*fn_magic_list)        ( magic_t cookie, const char* filename ); /* optional */

/*
 * Module-level state.
 * Populated once in BOOT; never freed (library lives for the process).
 */
static void*                _libhandle   = NULL;

/* Required — set only when dlopen succeeds */
static fn_magic_open        _fn_open        = NULL;
static fn_magic_close       _fn_close       = NULL;
static fn_magic_load        _fn_load        = NULL;
static fn_magic_file        _fn_file        = NULL;
static fn_magic_buffer      _fn_buffer      = NULL;
static fn_magic_descriptor  _fn_descriptor  = NULL;
static fn_magic_error       _fn_error       = NULL;
static fn_magic_setflags    _fn_setflags    = NULL;

/* Optional — NULL when absent; callers check before use */
static fn_magic_getflags    _fn_getflags    = NULL;
static fn_magic_version     _fn_version     = NULL;
static fn_magic_compile     _fn_compile     = NULL;
static fn_magic_check       _fn_check       = NULL;
static fn_magic_list        _fn_list        = NULL;

/*
 * _resolve( handle, name )
 * Calls dlsym; returns the symbol or NULL on failure.
 * Used for required symbols — the BOOT block checks the return value.
 */
static void*
_resolve( void* handle, const char* name )
{
    return( dlsym( handle, name ) );
}

/*
 * _set_backend( pkg, value )
 * Sets $Module::Generic::File::Magic::BACKEND to the given string value.
 */
static void
_set_backend( pTHX_ const char* value )
{
    SV* sv = get_sv( "Module::Generic::File::Magic::BACKEND", GV_ADD );
    sv_setpv( sv, value );
    SvPOK_on( sv );
}

/*
 * XS MODULE
 */

MODULE = Module::Generic    PACKAGE = Module::Generic::File::Magic

PROTOTYPES: DISABLE

#---------------------------------------------------------------------------
# BOOT block
# Executed once when Perl's DynaLoader loads this .so.
#
# Tries candidate sonames in order.  If none loads, sets $BACKEND = "json"
# and returns — no croak.  The Perl layer detects this and uses the
# pure-Perl JSON backend.
#
# If dlopen succeeds but a required symbol is missing (corrupted or
# extremely old libmagic), we do croak — that is a genuine installation
# problem that the user must fix.
#---------------------------------------------------------------------------
BOOT:
{
    static const char* candidates[] = {
        "libmagic.so.1",
        "libmagic.so",
        "libmagic.1.dylib",
        "libmagic.dylib",
        NULL
    };
    int   i;
    void* sym;

    for( i = 0; candidates[i] != NULL; i++ )
    {
        _libhandle = dlopen( candidates[i], RTLD_LAZY | RTLD_GLOBAL );
        if( _libhandle != NULL )
            break;
    }

    if( _libhandle == NULL )
    {
        /* libmagic not installed — degrade gracefully to JSON backend */
        _set_backend( aTHX_ "json" );
    }
    else
    {
        /* Resolve required symbols — croak on failure (corrupt install) */
        _fn_open       = (fn_magic_open)       _resolve( _libhandle, "magic_open"       );
        _fn_close      = (fn_magic_close)      _resolve( _libhandle, "magic_close"      );
        _fn_load       = (fn_magic_load)       _resolve( _libhandle, "magic_load"       );
        _fn_file       = (fn_magic_file)       _resolve( _libhandle, "magic_file"       );
        _fn_buffer     = (fn_magic_buffer)     _resolve( _libhandle, "magic_buffer"     );
        _fn_descriptor = (fn_magic_descriptor) _resolve( _libhandle, "magic_descriptor" );
        _fn_error      = (fn_magic_error)      _resolve( _libhandle, "magic_error"      );
        _fn_setflags   = (fn_magic_setflags)   _resolve( _libhandle, "magic_setflags"   );

        /* Verify all required symbols resolved */
        if(  !_fn_open || !_fn_close  || !_fn_load   || !_fn_file
          || !_fn_buffer || !_fn_descriptor || !_fn_error || !_fn_setflags )
        {
            Perl_croak( aTHX_
                "Module::Generic::File::Magic: one or more required libmagic "
                "symbols could not be resolved. Your libmagic installation "
                "may be corrupt.\ndlopen error: %s\n",
                dlerror()
            );
        }

        /* Resolve optional symbols — NULL is fine */
        _fn_getflags = (fn_magic_getflags) dlsym( _libhandle, "magic_getflags" );
        _fn_version  = (fn_magic_version)  dlsym( _libhandle, "magic_version"  );
        _fn_compile  = (fn_magic_compile)  dlsym( _libhandle, "magic_compile"  );
        _fn_check    = (fn_magic_check)    dlsym( _libhandle, "magic_check"    );
        _fn_list     = (fn_magic_list)     dlsym( _libhandle, "magic_list"     );

        _set_backend( aTHX_ "xs" );
    }
}

# Backend predicate

# magic_backend() -> "xs" | "json"
const char*
magic_backend()
  CODE:
    RETVAL = ( _libhandle != NULL ) ? "xs" : "json";
  OUTPUT:
    RETVAL

# XS backend functions
# All return undef / 0 when libmagic is absent; gated by magic_backend()
# in the Perl layer.

IV
magic_open( flags )
    int flags
  CODE:
    RETVAL = _fn_open ? (IV)( _fn_open( flags ) ) : 0;
  OUTPUT:
    RETVAL

void
magic_close( cookie )
    IV cookie
  CODE:
    if( _fn_close && cookie )
        _fn_close( (magic_t)(cookie) );

int
magic_load( cookie, filename )
    IV   cookie
    SV*  filename
  CODE:
    if( !_fn_load ) { RETVAL = -1; }
    else
    {
        const char* path = SvOK( filename ) ? SvPVbyte_nolen( filename ) : NULL;
        RETVAL = _fn_load( (magic_t)(cookie), path );
    }
  OUTPUT:
    RETVAL

SV*
magic_file( cookie, filename )
    IV          cookie
    const char* filename
  CODE:
    if( !_fn_file ) { RETVAL = &PL_sv_undef; }
    else
    {
        const char* result = _fn_file( (magic_t)(cookie), filename );
        RETVAL = result ? newSVpv( result, 0 ) : &PL_sv_undef;
    }
  OUTPUT:
    RETVAL

SV*
magic_buffer( cookie, buffer )
    IV   cookie
    SV*  buffer
  CODE:
    if( !_fn_buffer ) { RETVAL = &PL_sv_undef; }
    else
    {
        STRLEN      len;
        const char* ptr    = SvPVbyte( buffer, len );
        const char* result = _fn_buffer( (magic_t)(cookie), (const void*)ptr, (size_t)len );
        RETVAL = result ? newSVpv( result, 0 ) : &PL_sv_undef;
    }
  OUTPUT:
    RETVAL

SV*
magic_descriptor( cookie, fd )
    IV  cookie
    int fd
  CODE:
    if( !_fn_descriptor ) { RETVAL = &PL_sv_undef; }
    else
    {
        const char* result = _fn_descriptor( (magic_t)(cookie), fd );
        RETVAL = result ? newSVpv( result, 0 ) : &PL_sv_undef;
    }
  OUTPUT:
    RETVAL

SV*
magic_error( cookie )
    IV cookie
  CODE:
    if( !_fn_error ) { RETVAL = &PL_sv_undef; }
    else
    {
        const char* msg = _fn_error( (magic_t)(cookie) );
        RETVAL = msg ? newSVpv( msg, 0 ) : &PL_sv_undef;
    }
  OUTPUT:
    RETVAL

int
magic_setflags( cookie, flags )
    IV  cookie
    int flags
  CODE:
    RETVAL = _fn_setflags ? _fn_setflags( (magic_t)(cookie), flags ) : -1;
  OUTPUT:
    RETVAL

SV*
magic_getflags( cookie )
    IV cookie
  CODE:
    RETVAL = ( _fn_getflags && cookie )
        ? newSViv( _fn_getflags( (magic_t)(cookie) ) )
        : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV*
magic_version()
  CODE:
    RETVAL = _fn_version ? newSViv( _fn_version() ) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV*
magic_compile( cookie, filename )
    IV  cookie
    SV* filename
  CODE:
    if( !_fn_compile ) { RETVAL = &PL_sv_undef; }
    else
    {
        const char* path = SvOK( filename ) ? SvPVbyte_nolen( filename ) : NULL;
        RETVAL = newSViv( _fn_compile( (magic_t)(cookie), path ) );
    }
  OUTPUT:
    RETVAL

SV*
magic_check( cookie, filename )
    IV  cookie
    SV* filename
  CODE:
    if( !_fn_check ) { RETVAL = &PL_sv_undef; }
    else
    {
        const char* path = SvOK( filename ) ? SvPVbyte_nolen( filename ) : NULL;
        RETVAL = newSViv( _fn_check( (magic_t)(cookie), path ) );
    }
  OUTPUT:
    RETVAL

SV*
magic_list( cookie, filename )
    IV  cookie
    SV* filename
  CODE:
    if( !_fn_list ) { RETVAL = &PL_sv_undef; }
    else
    {
        const char* path = SvOK( filename ) ? SvPVbyte_nolen( filename ) : NULL;
        RETVAL = newSViv( _fn_list( (magic_t)(cookie), path ) );
    }
  OUTPUT:
    RETVAL

# Availability predicates for optional symbols

int
magic_has_getflags()
  CODE:
    RETVAL = ( _fn_getflags != NULL ) ? 1 : 0;
  OUTPUT:
    RETVAL

int
magic_has_version()
  CODE:
    RETVAL = ( _fn_version != NULL ) ? 1 : 0;
  OUTPUT:
    RETVAL

int
magic_has_compile()
  CODE:
    RETVAL = ( _fn_compile != NULL ) ? 1 : 0;
  OUTPUT:
    RETVAL

int
magic_has_check()
  CODE:
    RETVAL = ( _fn_check != NULL ) ? 1 : 0;
  OUTPUT:
    RETVAL

int
magic_has_list()
  CODE:
    RETVAL = ( _fn_list != NULL ) ? 1 : 0;
  OUTPUT:
    RETVAL
