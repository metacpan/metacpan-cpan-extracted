/*---------------------------------------------------------------------------
 * Module::Generic - Generic.xs
 * Version v0.2.0
 * Copyright(c) 2026 DEGUEST Pte. Ltd.
 * Author: Jacques Deguest <jack@deguest.jp>
 * Created  2026/03/07
 * Modified 2026/03/27
 *
 * XS implementations of the most frequently called type-inspection helpers.
 * Moving them here eliminates Perl dispatch overhead and the temporary
 * allocations created by the Perl call stack on every invocation.
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
 * correct namespace. This pattern is also used by Time::HiRes and POSIX.
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
 * Function pointer typedefs: mirrors <magic.h> without including it.
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

/* Required; set only when dlopen succeeds */
static fn_magic_open        _fn_open        = NULL;
static fn_magic_close       _fn_close       = NULL;
static fn_magic_load        _fn_load        = NULL;
static fn_magic_file        _fn_file        = NULL;
static fn_magic_buffer      _fn_buffer      = NULL;
static fn_magic_descriptor  _fn_descriptor  = NULL;
static fn_magic_error       _fn_error       = NULL;
static fn_magic_setflags    _fn_setflags    = NULL;

/* Optional; NULL when absent; callers check before use */
static fn_magic_getflags    _fn_getflags    = NULL;
static fn_magic_version     _fn_version     = NULL;
static fn_magic_compile     _fn_compile     = NULL;
static fn_magic_check       _fn_check       = NULL;
static fn_magic_list        _fn_list        = NULL;

/*
 * _resolve( handle, name )
 * Calls dlsym; returns the symbol or NULL on failure.
 * Used for required symbols; the BOOT block checks the return value.
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
    /* Use GV_ADD | GV_ADDMULTI to mark the symbol as "seen multiple times",
     * suppressing the "used only once" warning from DynaLoader. */
    SV* sv = get_sv( "Module::Generic::File::Magic::BACKEND", GV_ADD | GV_ADDMULTI );
    sv_setpv( sv, value );
    SvPOK_on( sv );
}

/* mg_get_sv_arg: safely fetch argument n from the XS stack.
 * Returns &PL_sv_undef when n is beyond the actual argument count, preventing the
 * "uninitialized value in subroutine entry" warning that xsubpp-declared SV* parameters
 * generate when undef is passed. */
static SV*
mg_get_sv_arg( I32 n, I32 count, SV** sp )
{
    SV* sv;
    if( n >= count )
        return( &PL_sv_undef );
    sv = sp[n];
    /* For tied scalars, SvGETMAGIC alone does not update SvROK.
     * We need a full copy via sv_mortalcopy which triggers FETCH and returns a new SV
     * reflecting the actual underlying value.
     * This mirrors what Scalar::Util::reftype() does internally. */
    if( SvGMAGICAL( sv ) )
        sv = sv_mortalcopy( sv );
    return( sv );
}

/*
 * XS MODULE
 */

/*---------------------------------------------------------------------------
 * Module::Generic::File::Magic - Magic.xs
 *---------------------------------------------------------------------------*/
MODULE = Module::Generic    PACKAGE = Module::Generic::File::Magic

PROTOTYPES: DISABLE

#---------------------------------------------------------------------------
# BOOT block
# Executed once when Perl's DynaLoader loads this .so.
#
# Tries candidate sonames in order. If none loads, sets $BACKEND = "json"
# and returns, but no croak. The Perl layer detects this and uses the
# pure-Perl JSON backend.
#
# If dlopen succeeds but a required symbol is missing (corrupted or extremely
# old libmagic), we do croak, because that is a genuine installation problem
# that the user must fix.
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
        /* libmagic not installed: degrade gracefully to JSON backend */
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

        /* Resolve optional symbols; NULL is fine */
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
# All return undef / 0 when libmagic is absent; gated by magic_backend() in the Perl layer.

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

# ---------------------------------------------------------------------------
# Module::Generic utility methods
#
# XS implementations of the most frequently called type-inspection helpers.
# Moving them here eliminates Perl dispatch overhead and the temporary
# allocations created by the Perl call stack on every invocation.
#
# These are installed in Module::Generic and inherited by all subclasses via
# the normal @ISA mechanism; no changes needed in subclasses.
# ---------------------------------------------------------------------------

MODULE = Module::Generic    PACKAGE = Module::Generic

PROTOTYPES: DISABLE

# ---------------------------------------------------------------------------
# _get_args_as_array( $self, @args )
#
# If called with a single arrayref argument, returns it directly.
# Otherwise wraps all arguments in a new arrayref.
# Returns [] if no arguments provided.
# ---------------------------------------------------------------------------

SV*
_get_args_as_array( self, ... )
    SV* self
  PREINIT:
    AV* av;
    I32 i;
  CODE:
    if( items <= 1 )
    {
        /* No args: return [] */
        RETVAL = newRV_noinc( (SV*)newAV() );
    }
    else if( items == 2 &&
             SvROK( ST(1) ) &&
             SvTYPE( SvRV( ST(1) ) ) == SVt_PVAV )
    {
        /* Single arrayref argument: return it directly.
         * No SvOK check: mirrors _is_array which does not require SvOK,
         * and blessed arrayrefs may not have scalar-value flags set. */
        RETVAL = SvREFCNT_inc( ST(1) );
    }
    else
    {
        /* Multiple args (or single non-arrayref): wrap in new arrayref.
         * Use newSVsv() to copy each SV rather than SvREFCNT_inc() so that
         * the array holds independent mutable copies, not read-only aliases
         * to the Perl call stack, thus mirroring Perl's [ @_ ] behaviour. */
        av = newAV();
        av_extend( av, items - 2 );
        for( i = 1; i < items; i++ )
        {
            av_store( av, i - 1, newSVsv( ST(i) ) );
        }
        RETVAL = newRV_noinc( (SV*)av );
    }
  OUTPUT:
    RETVAL

# ---------------------------------------------------------------------------
# _is_array( $self, $val )
#
# Returns true if reftype($val) eq 'ARRAY'.
# Uses SvTYPE() directly; one integer comparison, no string allocation.
# ---------------------------------------------------------------------------

int
_is_array( self, ... )
    SV* self
  CODE:
    {
        SV* val = mg_get_sv_arg( 1, items, &ST(0) );
        RETVAL = ( SvROK( val ) && SvTYPE( SvRV( val ) ) == SVt_PVAV ) ? 1 : 0;
    }
  OUTPUT:
    RETVAL

# ---------------------------------------------------------------------------
# _is_code( $self, $val )
#
# Returns true if $val is a CODE reference (blessed or not).
# Uses ref() semantics: blessed coderefs also return true.
# ---------------------------------------------------------------------------

int
_is_code( self, ... )
    SV* self
  CODE:
    {
        SV* val = mg_get_sv_arg( 1, items, &ST(0) );
        /* SvROK alone (without SvOK) handles blessed coderefs correctly.
         * SvOK fails on blessed refs because they lack scalar-value flags.
         * Mirrors Scalar::Util::reftype($val) eq 'CODE'. */
        RETVAL = ( SvROK( val ) && SvTYPE( SvRV( val ) ) == SVt_PVCV ) ? 1 : 0;
    }
  OUTPUT:
    RETVAL

# ---------------------------------------------------------------------------
# _is_glob( $self, $val )
#
# Returns true if reftype($val) eq 'GLOB'.
# ---------------------------------------------------------------------------

int
_is_glob( self, ... )
    SV* self
  CODE:
    {
        SV* val = mg_get_sv_arg( 1, items, &ST(0) );
        /* Mirrors Scalar::Util::reftype($val) eq 'GLOB'. */
        RETVAL = ( SvROK( val ) && SvTYPE( SvRV( val ) ) == SVt_PVGV ) ? 1 : 0;
    }
  OUTPUT:
    RETVAL

# ---------------------------------------------------------------------------
# _is_hash( $self, $val, $strict? )
#
# Returns true if reftype($val) eq 'HASH'.
# Optional third argument 'strict': if defined and eq 'strict', only unblessed
# hashrefs return true (mirrors ref($val) eq 'HASH').
# ---------------------------------------------------------------------------

int
_is_hash( self, ... )
    SV* self
  PREINIT:
    SV* rv;
  CODE:
    {
        SV* val = mg_get_sv_arg( 1, items, &ST(0) );
        if( !SvROK( val ) )
        {
            RETVAL = 0;
        }
        else
        {
            rv = SvRV( val );
            if( SvTYPE( rv ) != SVt_PVHV )
            {
                RETVAL = 0;
            }
            else if( items > 2 && SvOK( ST(2) ) )
            {
                /* strict mode: mirrors ref($val) eq 'HASH'; unblessed only */
                RETVAL = SvOBJECT( rv ) ? 0 : 1;
            }
            else
            {
                /* non-strict: mirrors reftype($val) eq 'HASH'; blessed or unblessed */
                RETVAL = 1;
            }
        }
    }
  OUTPUT:
    RETVAL

# ---------------------------------------------------------------------------
# _is_integer( $self, $val )
#
# Returns true if $val is a plain scalar matching /^[+-]?\d+$/.
# We use the Perl regex engine via pregexec for correctness and Unicode
# safety, but avoid the overhead of compiling the pattern each call by using
# a static compiled regexp.
# ---------------------------------------------------------------------------

int
_is_integer( self, ... )
    SV* self
  PREINIT:
    STRLEN len;
    const char* s;
    const char* p;
    const char* end;
  CODE:
    {
        SV* val = mg_get_sv_arg( 1, items, &ST(0) );
        /* Mirrors: !defined($_[1]) -> 0 */
        if( !SvOK( val ) )
        {
            RETVAL = 0;
        }
        else
        {
            /* Stringify via sv_2pv_flags with SV_GMAGIC so that overloaded
             * objects (e.g. Module::Generic::Number) go through their ""
             * operator first, exactly as Perl's regex match operator does.
             * This handles both plain scalars and overloaded objects. */
            s = sv_2pv_flags( val, &len, SV_GMAGIC );
            if( len == 0 )
            {
                RETVAL = 0;
            }
            else
            {
                p   = s;
                end = s + len;
                /* Optional leading sign; mirrors: /^[\+\-]?\d+$/ */
                if( *p == '+' || *p == '-' )
                    p++;
                /* Must have at least one digit after optional sign */
                if( p >= end )
                {
                    RETVAL = 0;
                }
                else
                {
                    RETVAL = 1;
                    while( p < end )
                    {
                        if( *p < '0' || *p > '9' )
                        {
                            RETVAL = 0;
                            break;
                        }
                        p++;
                    }
                }
            }
        }
    }
  OUTPUT:
    RETVAL

# ---------------------------------------------------------------------------
# _is_number( $self, $val )
#
# Returns true only if $val carries actual numeric flags (SVf_IOK or SVf_NOK),
# i.e. it was produced as a number, not merely looks like one.
# This is exactly what the Perl implementation does via B::svref_2object, but
# without the overhead of loading B or calling into it.
# ---------------------------------------------------------------------------

int
_is_number( self, ... )
    SV* self
  CODE:
    {
        SV* val = mg_get_sv_arg( 1, items, &ST(0) );
        /* Mirrors: !defined($v) -> 0, ref($v) -> 0
         * SvOK: correct here since val is a plain scalar, not a ref.
         * SVf_IOK/SVf_NOK: mirrors B::SVf_IOK()|B::SVf_NOK() flags check. */
        if( !SvOK( val ) || SvROK( val ) )
        {
            RETVAL = 0;
        }
        else
        {
            /* SVf_IOK: integer value is valid; SVf_NOK: float value is valid */
            RETVAL = ( SvFLAGS( val ) & ( SVf_IOK | SVf_NOK ) ) ? 1 : 0;
        }
    }
  OUTPUT:
    RETVAL

# ---------------------------------------------------------------------------
# _is_object( $self, $val )
#
# Returns true if $val is a blessed reference, which is equivalent to
# Scalar::Util::blessed($val), but without the Perl dispatch overhead.
# ---------------------------------------------------------------------------

int
_is_object( self, ... )
    SV* self
  CODE:
    {
        SV* val = mg_get_sv_arg( 1, items, &ST(0) );
        /* Mirrors Scalar::Util::blessed($val) in boolean context: 1 if blessed, 0 otherwise. */
        RETVAL = ( SvROK( val ) && SvOBJECT( SvRV( val ) ) ) ? 1 : 0;
    }
  OUTPUT:
    RETVAL

# ---------------------------------------------------------------------------
# _is_overloaded( $self, $val )
#
# Returns true if $val is a blessed object that has any overloading.
# Equivalent to overload::Overloaded($val).
# HvAMAGIC(stash) checks SVf_AMAGIC (0x10000000) on the stash HV, which Perl
# sets automatically when a package installs overload methods.
# ---------------------------------------------------------------------------

int
_is_overloaded( self, ... )
    SV* self
  PREINIT:
    HV*  stash;
    GV*  gv;
  CODE:
    {
        SV* val = mg_get_sv_arg( 1, items, &ST(0) );
        /* Mirrors: !scalar(@_) || !defined($_[0]) || !blessed($_[0]) -> 0
         * Then: overload::Overloaded($_[0]) ? 1 : 0
         * gv_fetchmeth_pvn looks up "()" in the stash with inheritance (-1),
         *
         * HvAMAGIC is unreliable: it is set on all packages that inherit from
         * any class using overload, not just those that define overloads directly.
         * The "()" slot is only present when the package itself uses overload. */
        if( !SvROK( val ) || !SvOBJECT( SvRV( val ) ) )
        {
            RETVAL = 0;
        }
        else
        {
            stash = SvSTASH( SvRV( val ) );
            if( !stash )
            {
                RETVAL = 0;
            }
            else
            {
                gv = gv_fetchmeth_pvn( stash, "()", 2, -1, 0 );
                RETVAL = ( gv && isGV( gv ) ) ? 1 : 0;
            }
        }
    }
  OUTPUT:
    RETVAL

# ---------------------------------------------------------------------------
# _is_scalar( $self, $val )
#
# Returns true if reftype($val) eq 'SCALAR' or 'REF'.
# A reference to a plain scalar has type SVt_PVMG or lower in older perls,
# and SVt_IV/SVt_PV on newer ones. The reliable test is: it's a ref, it's
# not AV/HV/CV/GV/FM/IO, and it's not overloaded (which would be PVMG+BLESS).
# We mirror Scalar::Util::reftype: returns true for \$scalar and \$ref.
# ---------------------------------------------------------------------------

int
_is_scalar( self, ... )
    SV* self
  CODE:
    {
        SV* val = mg_get_sv_arg( 1, items, &ST(0) );
        /* Mirrors Scalar::Util::reftype($val) eq 'SCALAR'.
         * reftype returns 'SCALAR' when the referent is a plain scalar,
         * and 'REF' when the referent is itself a reference.
         * The distinction in XS: SvROK(SvRV(val)) is true for REF, false for SCALAR. */
        RETVAL = ( SvROK( val ) && !SvROK( SvRV( val ) ) &&
                   SvTYPE( SvRV( val ) ) != SVt_PVAV &&
                   SvTYPE( SvRV( val ) ) != SVt_PVHV &&
                   SvTYPE( SvRV( val ) ) != SVt_PVCV &&
                   SvTYPE( SvRV( val ) ) != SVt_PVGV &&
                   SvTYPE( SvRV( val ) ) != SVt_PVFM &&
                   SvTYPE( SvRV( val ) ) != SVt_PVIO ) ? 1 : 0;
    }
  OUTPUT:
    RETVAL

# ---------------------------------------------------------------------------
# _obj2h( $self )
#
# Returns the underlying hash for an object, for direct field access.
# Hot path (blessed HASH ref) is a single SvREFCNT_inc; effectively free.
#
# Mirrors the Perl original:
#   HASH ref  -> return $self as-is
#   GLOB ref  -> return reference to its hash slot
#   non-ref   -> build minimal { debug, verbose, error } hash blessed into $self
#   other     -> return {}
# ---------------------------------------------------------------------------

SV*
_obj2h( self )
    SV* self
  PREINIT:
    SV* rv;
    U32 type;
  CODE:
    if( !SvROK( self ) )
    {
        /* Package->method call: mirrors the Perl non-ref branch.
         * Builds { debug => $Pkg::DEBUG, verbose => $Pkg::VERBOSE, error => $Pkg::ERROR }
         * blessed into the package. Uses get_sv() with the fully-qualified name
         * to mirror ${ "${class}::VAR" } semantics. */
        HV*    hash  = newHV();
        STRLEN pkg_len;
        char*  pkg   = SvPV( self, pkg_len );
        HV*    stash = gv_stashpvn( pkg, (U32)pkg_len, GV_ADD );
        SV*    tmp;
        char   varname[512];

        /* $Package::DEBUG */
        snprintf( varname, sizeof(varname), "%.*s::DEBUG", (int)pkg_len, pkg );
        tmp = get_sv( varname, 0 );
        hv_stores( hash, "debug",   tmp ? SvREFCNT_inc(tmp) : newSViv(0) );

        /* $Package::VERBOSE */
        snprintf( varname, sizeof(varname), "%.*s::VERBOSE", (int)pkg_len, pkg );
        tmp = get_sv( varname, 0 );
        hv_stores( hash, "verbose", tmp ? SvREFCNT_inc(tmp) : newSViv(0) );

        /* $Package::ERROR */
        snprintf( varname, sizeof(varname), "%.*s::ERROR", (int)pkg_len, pkg );
        tmp = get_sv( varname, 0 );
        hv_stores( hash, "error",   tmp ? SvREFCNT_inc(tmp) : newSViv(0) );

        RETVAL = sv_bless( newRV_noinc( (SV*)hash ), stash );
    }
    else
    {
        rv   = SvRV( self );
        type = SvTYPE( rv );

        if( type == SVt_PVHV )
        {
            /* Blessed or plain HASH — the common case, return self directly */
            RETVAL = SvREFCNT_inc( self );
        }
        else if( type == SVt_PVGV )
        {
            /* GLOB — return a reference to its hash slot */
            HV* hv = GvHV( (GV*)rv );
            if( !hv )
            {
                hv = newHV();
                GvHV( (GV*)rv ) = hv;
            }
            RETVAL = newRV_inc( (SV*)hv );
        }
        else
        {
            /* Anything else — return an empty hashref */
            RETVAL = newRV_noinc( (SV*)newHV() );
        }
    }
  OUTPUT:
    RETVAL

# ---------------------------------------------------------------------------
# _refaddr( $self, $val )
#
# Returns the memory address of the referent of $val as an unsigned integer,
# equivalent to Scalar::Util::refaddr($val).
# ---------------------------------------------------------------------------

SV*
_refaddr( self, ... )
    SV* self
  CODE:
    {
        SV* val = mg_get_sv_arg( 1, items, &ST(0) );
        /* Mirrors Scalar::Util::refaddr($val): undef for non-refs, memory address of
         * the referent for refs. */
        if( !SvROK( val ) )
        {
            RETVAL = &PL_sv_undef;
        }
        else
        {
            RETVAL = newSVuv( PTR2UV( SvRV( val ) ) );
        }
    }
  OUTPUT:
    RETVAL

