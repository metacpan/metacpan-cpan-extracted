
=head1 NAME

Unbound.xs - Perl interface to libunbound

=head1 DESCRIPTION

Perl XS extension providing access to the NLnetLabs libunbound library.

This implementation is intended to support Net::DNS::Resolver::Unbound.
It is NOT, nor will it ever be, suitable for general use.


=head1 COPYRIGHT

Copyright (c)2022 Dick Franks

All Rights Reserved

=head1 LICENSE

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted, provided
that the original copyright notices appear in all copies and that both
copyright notice and this permission notice appear in supporting
documentation, and that the name of the author not be used in advertising
or publicity pertaining to distribution of the software without specific
prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=cut


#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT
#define PERL_REENTRANT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <unbound.h>

#ifdef __cplusplus
}
#endif


#define UNBOUND_VERSION (UNBOUND_VERSION_MAJOR*100 + UNBOUND_VERSION_MINOR)*100 + UNBOUND_VERSION_MICRO

#define checkerr(arg)	checkret( (arg), __LINE__ )
static void checkret(const int err, int line)
{
	if (err) croak( "%s (%d)  %s line %d", ub_strerror(err), err, __FILE__, line );
}


typedef struct ub_ctx* Net__DNS__Resolver__Unbound__Context;
typedef struct ub_result* Net__DNS__Resolver__Unbound__Result;
typedef struct av* Net__DNS__Resolver__Unbound__Handle;


static void async_callback(void* mydata, int err, struct ub_result* result)
{
	dTHX;	/* fetch context */
	SV* resobj = newSV(0);
	sv_setref_pv(resobj, "Net::DNS::Resolver::Unbound::Result", (void*)result);
	av_push( (AV*)mydata, newSViv(err) );
	av_push( (AV*)mydata, resobj );
	return;
}



MODULE = Net::DNS::Resolver::Unbound	PACKAGE = Net::DNS::Resolver::Unbound::Handle

PROTOTYPES: ENABLE

void
DESTROY(struct av* handle)
    CODE:
	sv_2mortal( (SV*) handle );

int
query_id(struct av* handle)
    INIT:
	SV** index = av_fetch(handle, 0, 0);
    CODE:
	RETVAL = SvIVX(*index);
    OUTPUT:
	RETVAL

SV*
err(struct av* handle)
    INIT:
	SV** index = av_fetch(handle, 1, 0);
	int err = index ? SvIVX(*index) : 0;
    CODE:
	RETVAL = newSVpvf( err ? "%s (%d)" : "", ub_strerror(err), err );
    OUTPUT:
	RETVAL

SV*
result(struct av* handle)
    INIT:
	SV** index = av_fetch(handle, 2, 0);
    CODE:
	RETVAL = index ?  av_pop(handle) : NULL;
    OUTPUT:
	RETVAL

int
waiting(struct av* handle)
    INIT:
	SV** index = av_fetch(handle, 1, 0);
    CODE:
	RETVAL = index ? 0 : 1;
    OUTPUT:
	RETVAL



MODULE = Net::DNS::Resolver::Unbound	PACKAGE = Net::DNS::Resolver::Unbound::Result

void
DESTROY(struct ub_result* result)
    CODE:
	ub_resolve_free(result);

SV*
answer_packet(struct ub_result* result)
    CODE:
	RETVAL = newSVpvn( result->answer_packet, result->answer_len );
    OUTPUT:
	RETVAL

int
secure(struct ub_result* result)
    CODE:
	RETVAL = result->secure;
    OUTPUT:
	RETVAL

int
bogus(struct ub_result* result)
    CODE:
	RETVAL = result->bogus;
    OUTPUT:
	RETVAL

SV*
why_bogus(struct ub_result* result)
    CODE:
	RETVAL = newSVpv( result->why_bogus, 0 );
    OUTPUT:
	RETVAL



MODULE = Net::DNS::Resolver::Unbound	PACKAGE = Net::DNS::Resolver::Unbound::Context

Net::DNS::Resolver::Unbound::Context
new(void)
    CODE:
	RETVAL = ub_ctx_create();
    OUTPUT:
	RETVAL

void
DESTROY(struct ub_ctx* context)
    CODE:
	ub_ctx_delete(context);

void
set_option(struct ub_ctx* ctx, SV* opt, SV* val)
    CODE:
	checkerr( ub_ctx_set_option(ctx, (const char*) SvPVX(opt), (const char*) SvPVX(val)) );

SV*
get_option(struct ub_ctx* ctx, SV* opt)
    INIT:
	char* value;
    CODE:
	checkerr( ub_ctx_get_option(ctx, (const char*) SvPVX(opt), &value) );
	RETVAL = newSVpv( value, 0 );
	free(value);
    OUTPUT:
	RETVAL

void
config(struct ub_ctx* ctx, const char* fname)
    CODE:
	checkerr( ub_ctx_config(ctx, fname) );

void
set_fwd(struct ub_ctx* ctx, const char* addr)
    CODE:
	checkerr( ub_ctx_set_fwd(ctx, addr) );

void
resolv_conf(struct ub_ctx* ctx, const char* fname)
    CODE:
	checkerr( ub_ctx_resolvconf(ctx, fname) );

void
hosts(struct ub_ctx* ctx, const char* fname)
    CODE:
	checkerr( ub_ctx_hosts(ctx, fname) );

void
add_ta(struct ub_ctx* ctx, const char* ta)
    CODE:
	checkerr( ub_ctx_add_ta(ctx, ta) );

void
add_ta_file(struct ub_ctx* ctx, const char* fname)
    CODE:
	checkerr( ub_ctx_add_ta_file(ctx, fname) );

void
trusted_keys(struct ub_ctx* ctx, const char* fname)
    CODE:
	checkerr( ub_ctx_trustedkeys(ctx, fname) );

void
debug_out(struct ub_ctx* ctx, const char* out)
    CODE:
	checkerr( ub_ctx_debugout(ctx, (void*) out) );

void
debug_level(struct ub_ctx* ctx, int d)
    CODE:
	checkerr( ub_ctx_debuglevel(ctx, d) );

void
async(struct ub_ctx* ctx, int dothread)
    CODE:
	checkerr( ub_ctx_async(ctx, dothread) );


Net::DNS::Resolver::Unbound::Result
ub_resolve(struct ub_ctx* ctx, SV* name, int rrtype, int rrclass)
    CODE:
	checkerr( ub_resolve(ctx, (const char*) SvPVX(name), rrtype, rrclass, &RETVAL) );
    OUTPUT:
	RETVAL


Net::DNS::Resolver::Unbound::Handle
ub_resolve_async(struct ub_ctx* ctx, SV* name, int rrtype, int rrclass, int query_id=0)
    CODE:
	RETVAL = newAV();
	checkerr( ub_resolve_async(ctx, (const char*) SvPVX(name), rrtype, rrclass,
					(void*) RETVAL, async_callback, NULL) );
	av_push(RETVAL, newSViv(query_id) );
    OUTPUT:
	RETVAL

void
ub_process(struct ub_ctx* ctx)
    CODE:
	checkerr( ub_process(ctx) );

void
ub_wait(struct ub_ctx* ctx)
    CODE:
	checkerr( ub_wait(ctx) );


#if !(UNBOUND_VERSION < 10900)
void
set_stub(struct ub_ctx* ctx, const char* zone, const char* addr, int isprime)
    CODE:
	checkerr( ub_ctx_set_stub(ctx, zone, addr, isprime) );

void
add_ta_autr(struct ub_ctx* ctx, const char* fname)
    CODE:
	checkerr( ub_ctx_add_ta_autr(ctx, fname) );

void
set_tls(struct ub_ctx* ctx, int tls)
    CODE:
	checkerr( ub_ctx_set_tls(ctx, tls) );

#endif


########################
## TEST PURPOSES ONLY ##
########################

Net::DNS::Resolver::Unbound::Result
mock_resolve(struct ub_ctx* ctx, SV* name, int secure, int bogus)
    CODE:
	checkerr( ub_resolve(ctx, (const char*) SvPVX(name), 1, 1, &RETVAL) );
	if (bogus) RETVAL->answer_packet = NULL;
	RETVAL->secure = secure;
	RETVAL->bogus  = bogus;
    OUTPUT:
	RETVAL


MODULE = Net::DNS::Resolver::Unbound	PACKAGE = Net::DNS::Resolver::libunbound

SV*
VERSION(void)
    CODE:
	RETVAL = newSVpv( ub_version(), 0 );
    OUTPUT:
	RETVAL

Net::DNS::Resolver::Unbound::Handle
emulate_callback(int query_id, int err, struct ub_result* result=NULL)
    CODE:
	RETVAL = newAV();
	av_push(RETVAL, newSViv(query_id) );
	async_callback( (void*) RETVAL, err, result );
    OUTPUT:
	RETVAL

Net::DNS::Resolver::Unbound::Handle
emulate_wait(int query_id)
    CODE:
	RETVAL = newAV();
	av_push(RETVAL, newSViv(query_id) );
    OUTPUT:
	RETVAL


#ifdef croak_memory_wrap
void
croak_memory_wrap()

#endif

########################

