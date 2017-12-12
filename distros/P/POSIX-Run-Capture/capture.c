#include "capture.h"
#include <stdlib.h>

static inline void
croak_nomem(void)
{
	croak("Out of memory");
}

static void
call_monitor(SV *cv, const char *ptr, size_t sz)
{
	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newSVpv(ptr, sz)));
	PUTBACK;

	call_sv(cv, G_DISCARD);

	FREETMPS;
	LEAVE;
}

static void
line_monitor(const char *ptr, size_t sz, void *closure)
{
	struct line_closure *lc = closure;

	if (lc->len || ptr[sz-1] != '\n') {
		size_t newsz = lc->len + sz + 1;

		if (newsz > lc->size) {
			lc->str = realloc(lc->str, newsz);
			if (!lc->str)
				croak_nomem();
			lc->size = newsz;
		}
		memcpy(lc->str + lc->len, ptr, sz);
		lc->len += sz;
		lc->str[lc->len] = 0;

		if (lc->str[lc->len - 1] == '\n') {
			call_monitor(lc->cv, lc->str, lc->len);
			lc->len = 0;
		}
	} else
		call_monitor(lc->cv, ptr, sz);
}

void
XS_pack_ARGV(SV *const sv, ARGV argv)
{
	AV *av = newAV();

	if (argv) {
		int i;
		for (i = 0; argv[i]; i++)
			av_push(av, newSVpv(argv[i], 0));
	}
	sv_setsv(sv, newRV_inc((SV*)av));
}

ARGV 
XS_unpack_ARGV(SV *sv)
{
	AV *av;
	I32 i, n;
	char **argv;

	if (!sv || !SvOK(sv) || !SvROK(sv) || (SvTYPE(SvRV(sv)) != SVt_PVAV))
		croak ("array reference expected");

	av = (AV *)SvRV(sv);
	
	n = av_len(av);
	if (n == -1) {
		argv = NULL;
	} else {
		argv = calloc(n + 2, sizeof *argv);
		if (!argv)
			croak_nomem();
		for (i = 0; i <= n; i++) {
			SV *sv, **psv = av_fetch(av, i, 0);
			if (!psv)
				croak("element %d doesn't exist", i);
			sv = *psv;
			if (SvROK(sv)) {
				croak("argument #%d is not a scalar", i);
			} else {
				char *s = SvPV_nolen(sv);
				if ((argv[i] = strdup(s)) == NULL)
					croak_nomem();
			}
		}
		argv[i] = NULL;
	}
	return argv;
}

static void
free_argv(struct capture *cp)
{
	if (cp->rc.rc_argv) {
		size_t i;
		for (i = 0; cp->rc.rc_argv[i]; i++) {
			free(cp->rc.rc_argv[i]);
		}
		free(cp->rc.rc_argv);
		cp->rc.rc_argv = NULL;
	}
}

struct capture *
capture_new(SV *program, ARGV argv, unsigned timeout, SV *cb[2], SV *input)
{
	struct capture *cp;
	I32 i, n;

	cp = malloc(sizeof *cp);
	if (!cp)
		croak_nomem();
	memset(cp, 0, sizeof *cp);

	cp->rc.rc_argv = argv;
	
	cp->program = program;
	if (program != &PL_sv_undef) {
		SvREFCNT_inc(program);
		cp->rc.rc_program = SvPV_nolen(program);
		cp->flags |= RCF_PROGRAM;
	}
	
	if (timeout) {
		cp->rc.rc_timeout = timeout;
		cp->flags |= RCF_TIMEOUT;
	}

	cp->closure[0].cv = cb[0];
	if (cb[0] != &PL_sv_undef) {
		SvREFCNT_inc(cb[0]);
		cp->rc.rc_cap[RUNCAP_STDOUT].sc_linemon = line_monitor;
		cp->rc.rc_cap[RUNCAP_STDOUT].sc_monarg = &cp->closure[0];
		cp->flags |= RCF_STDOUT_LINEMON;
	}

	cp->closure[1].cv = cb[1];
	if (cb[1] != &PL_sv_undef) {
		SvREFCNT_inc(cb[1]);
		cp->closure[1].cv = cb[1];
		cp->rc.rc_cap[RUNCAP_STDERR].sc_linemon = line_monitor;
		cp->rc.rc_cap[RUNCAP_STDERR].sc_monarg = &cp->closure[1];
		cp->flags |= RCF_STDERR_LINEMON;
	}

	cp->input = &PL_sv_undef;
	capture_set_input(cp, input);
	
	return cp;
}

void
capture_DESTROY(struct capture *cp)
{
	if (cp->program != &PL_sv_undef)
		SvREFCNT_dec(cp->program);

	if (cp->input != &PL_sv_undef) 
		SvREFCNT_dec(cp->input);
	/* Make sure runcap_free won't free the input sc_base pointer
	 */
	cp->rc.rc_cap[RUNCAP_STDIN].sc_base = NULL;
	cp->rc.rc_cap[RUNCAP_STDIN].sc_fd = -1;
	
	free(cp->closure[0].str);
	if (cp->closure[0].cv != &PL_sv_undef)
		SvREFCNT_dec(cp->closure[0].cv);

	free(cp->closure[1].str);
	if (cp->closure[1].cv != &PL_sv_undef)
		SvREFCNT_dec(cp->closure[1].cv);

	free_argv(cp);
	runcap_free(&cp->rc);
	
	free(cp);
}	

void
capture_set_input(struct capture *cp, SV *inp)
{
	if (cp->flags & RCF_STDIN) {
		cp->flags &= ~RCF_STDIN;
		if (cp->input != &PL_sv_undef) {
			SvREFCNT_dec(cp->input);
			cp->input = &PL_sv_undef;
			if (cp->rc.rc_cap[RUNCAP_STDIN].sc_base) {
				free(cp->rc.rc_cap[RUNCAP_STDIN].sc_base);
				cp->rc.rc_cap[RUNCAP_STDIN].sc_base = NULL;
			}
		}
	}
	if (inp != &PL_sv_undef) {
		if (SvROK(inp)) {
			if (SvTYPE(SvRV(inp)) == SVt_PVGV) {
				PerlIO *fh = IoIFP(sv_2io(inp));
				PerlIO_flush(fh);
				PerlIO_rewind(fh);
				cp->rc.rc_cap[RUNCAP_STDIN].sc_fd = PerlIO_fileno(fh);
				if (cp->rc.rc_cap[RUNCAP_STDIN].sc_fd == -1)
					croak("no file descriptor associated to hanlde");
				cp->rc.rc_cap[RUNCAP_STDIN].sc_base = NULL;
				cp->rc.rc_cap[RUNCAP_STDIN].sc_size = 0;
			} else {
				croak("argument must be a string or file handle");
			}
		} else {
			cp->rc.rc_cap[RUNCAP_STDIN].sc_base
				= SvPV(inp, cp->rc.rc_cap[RUNCAP_STDIN].sc_size);
			cp->rc.rc_cap[RUNCAP_STDIN].sc_fd = -1;
		}
		SvREFCNT_inc(inp);
		cp->input = inp;
		cp->flags |= RCF_STDIN;
	}
}

void
capture_set_argv_ref(struct capture *cp, ARGV argv)
{
	free_argv(cp);
	cp->rc.rc_argv = argv;
}

char *
capture_next_line(struct capture *cp, int fd)
{
	char *buf = NULL;
        size_t sz = 0;
        ssize_t n;
	
	if (fd != RUNCAP_STDOUT && fd != RUNCAP_STDERR) {
		croak("invalid stream number: %d", fd);
	}
        n = runcap_getline(&cp->rc, fd, &buf, &sz);
        if (n == -1)
		croak("error getting line: %s", strerror(errno));
        if (n == 0)
		return NULL;
	return realloc(buf, n + 1);
}

int
capture_run(struct capture *cp)
{
	int res;
	
	if (!cp->rc.rc_argv)
		croak("no command line given");
	
	res = runcap(&cp->rc, cp->flags);

	if (cp->flags & RCF_STDOUT_LINEMON && cp->closure[0].len) {
		call_monitor(cp->closure[0].cv,
			     cp->closure[0].str,
			     cp->closure[0].len);
		cp->closure[0].len = 0;
	}

	if (cp->flags & RCF_STDERR_LINEMON && cp->closure[1].len) {
		call_monitor(cp->closure[1].cv,
			     cp->closure[1].str,
			     cp->closure[1].len);
		cp->closure[1].len = 0;
	}

	return res == 0;
}

