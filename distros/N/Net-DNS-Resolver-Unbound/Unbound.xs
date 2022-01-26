
=head1 NAME

Unbound.xs - Perl interface to libunbound

=head1 DESCRIPTION

Perl XS extension providing access to the NLnetLabs libunbound library.

This is a minimal implementation to support Net::DNS::Resolver::Unbound
which is NOT suitable for general use.


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


#define checkerr(arg)	checkret( (arg), __LINE__ )
static void checkret(const int err, int line)
{
	if (err) croak( "%s (%d)  %s line %d", ub_strerror(err), err, __FILE__, line );
}


typedef struct ub_ctx* Net__DNS__Resolver__Unbound__Context;
typedef struct ub_result* Net__DNS__Resolver__Unbound__Result;


=head1	async_callback

The asynchronous resolver result is received as an argument to async_callback (C),
within which it is convenient to incorporate the constructor for this package (Perl XS):

	MODULE = Net::DNS::Resolver::Unbound	PACKAGE = Net::DNS::Resolver::Unbound::Result

=cut

static void async_callback(void* mydata, int err, struct ub_result* result)
{
	dTHX;	/* fetch context */
	AV* handle = (AV*) mydata;
	SV* result_sv = newSV(0);
	sv_setptrobj(result_sv, (void*) result, "Net::DNS::Resolver::Unbound::Result");
	av_push(handle, newSViv(err) );
	av_push(handle, result_sv);
	return;
}

MODULE = Net::DNS::Resolver::Unbound	PACKAGE = Net::DNS::Resolver::Unbound::Result

void
DESTROY(struct ub_result* result)
    CODE:
	ub_resolve_free(result);



MODULE = Net::DNS::Resolver::Unbound	PACKAGE = Net::DNS::Resolver::Unbound::Context

Net::DNS::Resolver::Unbound::Context
new(void)
    INIT:
	struct ub_ctx* context = ub_ctx_create();
    CODE:
	RETVAL = context;
    OUTPUT:
	RETVAL

void
DESTROY(struct ub_ctx* context)
    CODE:
	ub_ctx_delete(context);



MODULE = Net::DNS::Resolver::Unbound	PACKAGE = Net::DNS::Resolver::libunbound

PROTOTYPES: ENABLE

SV*
VERSION(void)
    CODE:
	RETVAL = newSVpv( ub_version(), 0 );
    OUTPUT:
	RETVAL


struct ub_result*
ub_resolve(struct ub_ctx* ctx, SV* name, int rrtype, int rrclass)
    INIT:
	struct ub_result* result = NULL;
    CODE:
	checkerr( ub_resolve(ctx, (const char*) SvPVX(name), rrtype, rrclass, &result) );
	RETVAL = result;
    OUTPUT:
	RETVAL

SV*
ub_result_packet(struct ub_result* result)
    INIT:
	const char* packet = (char*) result->answer_packet;
	int length = result->answer_len;
    CODE:
	RETVAL = newSVpvn( packet, length );
    OUTPUT:
	RETVAL


void
ub_resolve_async(struct ub_ctx* ctx, SV* name, int rrtype, int rrclass, SV* handle)
    INIT:
	int async_id = 0;
	void* mydata = (void*) SvRV(handle);
	AV* handle_av = (AV*) mydata;
    CODE:
	checkerr( ub_resolve_async(ctx, (const char*) SvPVX(name), rrtype, rrclass,
						mydata, async_callback, &async_id) );
	av_push(handle_av, newSViv(async_id) );

void
ub_process(struct ub_ctx* ctx)
    CODE:
	checkerr( ub_process(ctx) );

void
ub_wait(struct ub_ctx* ctx)
    CODE:
	checkerr( ub_wait(ctx) );


void
ub_ctx_set_option(struct ub_ctx* ctx, SV* opt, SV* val)
    CODE:
	checkerr( ub_ctx_set_option(ctx, (const char*) SvPVX(opt), (const char*) SvPVX(val)) );

SV*
ub_ctx_get_option(struct ub_ctx* ctx, SV* opt)
    INIT:
	char* result;
    CODE:
	checkerr( ub_ctx_get_option(ctx, (const char*) SvPVX(opt), &result) );
	RETVAL = newSVpv( result, 0 );
	free(result);
    OUTPUT:
	RETVAL


void
ub_ctx_config(struct ub_ctx* ctx, const char* fname)
    CODE:
	checkerr( ub_ctx_config(ctx, fname) );

void
ub_ctx_set_fwd(struct ub_ctx* ctx, const char* addr)
    CODE:
	checkerr( ub_ctx_set_fwd(ctx, addr) );

void
ub_ctx_set_tls(struct ub_ctx* ctx, int tls)
    CODE:
	checkerr( ub_ctx_set_tls(ctx, tls) );

void
ub_ctx_set_stub(struct ub_ctx* ctx, const char* zone, const char* addr, int isprime)
    CODE:
	checkerr( ub_ctx_set_stub(ctx, zone, addr, isprime) );

void
ub_ctx_add_ta(struct ub_ctx* ctx, const char* ta)
    CODE:
	checkerr( ub_ctx_add_ta(ctx, ta) );

void
ub_ctx_add_ta_file(struct ub_ctx* ctx, const char* fname)
    CODE:
	checkerr( ub_ctx_add_ta_file(ctx, fname) );

void
ub_ctx_trustedkeys(struct ub_ctx* ctx, const char* fname)
    CODE:
	checkerr( ub_ctx_trustedkeys(ctx, fname) );

void
ub_ctx_debuglevel(struct ub_ctx* ctx, int d)
    CODE:
	checkerr( ub_ctx_debuglevel(ctx, d) );

void
ub_ctx_async(struct ub_ctx* ctx, int dothread)
    CODE:
	checkerr( ub_ctx_async(ctx, dothread) );


const char*
ub_strerror(int err)


####################
# TEST PURPOSES ONLY
####################

void
async_callback(void* mydata, int err, struct ub_result* result=NULL)

#ifdef croak_memory_wrap
void
croak_memory_wrap()

#endif

####################

