
=head1 NAME

Unbound.xs - Perl interface to libunbound

=head1 DESCRIPTION

Perl XS extension providing access to the NLnetLabs libunbound library.
This is intended to support Net::DNS::Resolver::Unbound only, not
suitable for general use.


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

#ifdef my_perl		/* contrary to advice given in perldoc perlxs */
#define PERL_NO_GET_CONTEXT
#endif			/* accepting risk that this might get fixed properly */
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


static void async_callback(void* mydata, int err, struct ub_result* result)
{
	dSP;
	ENTER;
	SAVETMPS;
	SV* perl_callback = newRV( (SV*) mydata);
	SV* result_sv = sv_newmortal();
	sv_setref_pv(result_sv, Nullch, (void*)result);
	PUSHMARK(SP);
	XPUSHs(sv_2mortal( newSViv(err) ));
	XPUSHs( result_sv );
	PUTBACK;
	call_sv(perl_callback, G_VOID | G_DISCARD);
	SPAGAIN;
	FREETMPS;
	LEAVE;
	return;
}


MODULE = Net::DNS::Resolver::Unbound	PACKAGE = Net::DNS::Resolver::libunbound

PROTOTYPES: ENABLE

SV*
VERSION(void)
    INIT:
	const char* result = ub_version();
    CODE:
	RETVAL = newSVpv( result, 0 );
    OUTPUT:
	RETVAL


struct ub_ctx*
ub_ctx_create()

void
ub_ctx_delete(struct ub_ctx* ctx)


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


struct ub_result*
ub_resolve(struct ub_ctx* ctx, SV* name, int rrtype, int rrclass)
    INIT:
	struct ub_result* result = NULL;
	int status = 0;
    CODE:
	status = ub_resolve(ctx, (const char*) SvPVX(name), rrtype, rrclass, &result);
	RETVAL = result;
	checkerr(status);
    OUTPUT:
	RETVAL

void
ub_resolve_free(struct ub_result* result)

SV*
ub_result_packet(struct ub_result* result)
    INIT:
	const char* packet = (char*) result->answer_packet;
	int length = result->answer_len;
    CODE:
	RETVAL = newSVpvn( packet, length );
    OUTPUT:
	RETVAL


int
ub_resolve_async(struct ub_ctx* ctx, SV* name, int rrtype, int rrclass, SV* perl_callback)
    INIT:
	int async_id = 0;
	void* mydata = (void*) SvRV(perl_callback);
    CODE:
	ub_resolve_async(ctx, (const char*) SvPVX(name), rrtype, rrclass, mydata, async_callback, &async_id);
	RETVAL = async_id;
    OUTPUT:
	RETVAL


int
ub_cancel(struct ub_ctx* ctx, int async_id)

int
ub_poll(struct ub_ctx* ctx)

int
ub_process(struct ub_ctx* ctx)

int
ub_wait(struct ub_ctx* ctx)


void
ub_ctx_debuglevel(struct ub_ctx* ctx, int d)
    CODE:
	checkerr( ub_ctx_debuglevel(ctx, d) );

void
ub_ctx_async(struct ub_ctx* ctx, int dothread)
    CODE:
	checkerr( ub_ctx_async(ctx, dothread) );


const char*
ub_version()

const char*
ub_strerror(int err)

####################

#ifdef croak_memory_wrap
void
croak_memory_wrap()

#endif

####################

