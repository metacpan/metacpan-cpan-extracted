#include "capture.h"

MODULE = POSIX::Run::Capture		PACKAGE = POSIX::Run::Capture PREFIX = capture_
PROTOTYPES: ENABLE

POSIX::Run::Capture
capture_new(package, ...)
	char *package;
  PREINIT:
        ARGV argv = NULL;
        unsigned timeout = 0;
        SV *cb[2] = { &PL_sv_undef, &PL_sv_undef };
        SV *prog = &PL_sv_undef;
        SV *input = &PL_sv_undef;
  CODE:
        if (items == 2) {
		SV *sv = ST(1);
		if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV) {
			argv = XS_unpack_ARGV(sv);
		} else
			croak("single argument must be an array ref");
	} else if (items % 2 == 0)
		croak("Bad number of arguments");
        else {
		int i;
		for (i = 1; i < items; i += 2) {
			char *kw;
			SV *sv = ST(i);
			SV *val = ST(i+1);
			
			if (!SvPOK(sv))
				croak("bad arguments near #%d", i);
			kw = SvPV_nolen(sv);
			if (strcmp(kw, "argv") == 0) {
				if (SvROK(val)
				    && SvTYPE(SvRV(val)) == SVt_PVAV) {
					argv = XS_unpack_ARGV(val);
				} else
					croak("argv must be an array ref");
			} else if (strcmp(kw, "stdout") == 0
				   || strcmp(kw, "stderr") == 0) {
				if (SvROK(val)
				    && SvTYPE(SvRV(val)) == SVt_PVCV) {
					cb[kw[3] == 'o' ? 0 : 1] = SvRV(val);
				} else
					croak("%s must be a code ref", kw);
			} else if (strcmp(kw, "timeout") == 0) {
				if (SvIOK(val)) {
					timeout = SvUV(val);
				} else
					croak("timeout must be a number of seconds");
			} else if (strcmp(kw, "program") == 0) {
				if (SvROK(val))
					croak("program argument is not a scalar");
				else 
					prog = val;
			} else if (strcmp(kw, "input") == 0
				   || strcmp(kw, "stdin") == 0) {
				input = val;
			} else
				croak("unknown keyword argument %s", kw);
		}
	}
        RETVAL = capture_new(prog, argv, timeout, cb, input);
  OUTPUT:
        RETVAL

void
capture_DESTROY(cp)
	POSIX::Run::Capture cp;

=head2 $obj->set_argv_ref($aref)

Sets command argument vector. The B<$aref> parameter is an array reference.

This is an auxiliary method. Use B<set_argv> instead.

=cut
	
void
capture_set_argv_ref(cp, argv)
	POSIX::Run::Capture cp;
	ARGV argv;

void
capture_set_program(cp, prog)
	POSIX::Run::Capture cp;
	char *prog = NO_INIT;
  PPCODE:
	if (cp->program != &PL_sv_undef)
		SvREFCNT_dec(cp->program);
	cp->program = ST(1);
        if (cp->program != &PL_sv_undef) {
		SvREFCNT_inc(cp->program);
		cp->rc.rc_program = SvPV_nolen(cp->program);
		cp->flags |= RCF_PROGRAM;
	} else 
		cp->flags &= ~RCF_PROGRAM;

void
capture_set_timeout(cp, timeout)
	POSIX::Run::Capture cp;
	unsigned timeout;
  CODE:
	if (timeout) {
		cp->rc.rc_timeout = timeout;
		cp->flags |= RCF_TIMEOUT;
	} else {
		cp->flags &= ~RCF_TIMEOUT;
	}

void
capture_set_input(cp, inp)
	POSIX::Run::Capture cp;
	SV *inp;
		
ARGV
capture_argv(cp)
	POSIX::Run::Capture cp;
  CODE:
	RETVAL = cp->rc.rc_argv;
  OUTPUT:
        RETVAL

void
capture_program(cp)
	POSIX::Run::Capture cp;
  PPCODE:
	if (cp->program == &PL_sv_undef && cp->rc.rc_argv) {
		ST(0) = newSVpv(cp->rc.rc_argv[0], 0);
		sv_2mortal(ST(0));
	} else
		ST(0) = cp->program;
        XSRETURN(1);

unsigned
capture_timeout(cp)
	POSIX::Run::Capture cp;
  CODE:
	RETVAL = (cp->flags & RCF_TIMEOUT) ? cp->rc.rc_timeout : 0;
  OUTPUT:
        RETVAL

int
capture_run(cp)
	POSIX::Run::Capture cp;

int
capture_status(cp)
	POSIX::Run::Capture cp;
  CODE:
	RETVAL = cp->rc.rc_status;
  OUTPUT:
        RETVAL

int
capture_errno(cp)
	POSIX::Run::Capture cp;
  CODE:
	RETVAL = cp->rc.rc_errno;
  OUTPUT:
        RETVAL

size_t
capture_nlines(cp, n)
	POSIX::Run::Capture cp;
	int n;
  CODE:
	if (n != RUNCAP_STDOUT && n != RUNCAP_STDERR) {
		croak("invalid stream number: %d", n);
	}
        RETVAL = cp->rc.rc_cap[n].sc_nlines;
  OUTPUT:
        RETVAL

size_t
capture_length(cp, n)
	POSIX::Run::Capture cp;
	int n;
  CODE:
	if (n != RUNCAP_STDOUT && n != RUNCAP_STDERR) {
		croak("invalid stream number: %d", n);
	}
        RETVAL = cp->rc.rc_cap[n].sc_leng;
  OUTPUT:
        RETVAL
	
char *
capture_next_line(cp, n)
	POSIX::Run::Capture cp;
	int n;

void
capture_rewind(cp, n)
	POSIX::Run::Capture cp;
	int n;
   CODE:
        runcap_rewind(&cp->rc, n);
