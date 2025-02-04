#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#define MY_CXT_KEY "Signal::Unsafe" XSVERSION
typedef struct {
	CV* handlers[NSIG];
} my_cxt_t;

START_MY_CXT;

typedef int SysRet;

static SV* S_make_args(pTHX_ siginfo_t* info) {
	SV* result = newSV(0);
	sv_setref_pvn(result, "Signal::Info", (const char*)info, sizeof(*info));
	return result;
}
#define make_args(info) S_make_args(aTHX_ info)

static void smart_handler(int signo, siginfo_t* info, void* context) {
	dTHX;
	dMY_CXT;
	dSP;
	CV* callback = MY_CXT.handlers[signo];
	if (!callback) {
		Perl_warn(aTHX_ "No handler for signal %d", signo);
		return;
	}
    PUSHSTACKi(PERLSI_SIGNAL);
	SAVETMPS;
	PUSHMARK(SP);
	EXTEND(SP, 3);
	mPUSHi(signo);
	mPUSHs(make_args(info));
	mPUSHu(PTR2UV(context));
	PUTBACK;
	call_sv((SV*)callback, G_VOID | G_DISCARD);
	FREETMPS;
	POPSTACK;
}

static void dumb_handler(int signo) {
	dTHX;
	dMY_CXT;
	dSP;
	CV* callback = MY_CXT.handlers[signo];
	if (!callback) {
		Perl_warn(aTHX_ "No handler for signal %d", signo);
		return;
	}
    PUSHSTACKi(PERLSI_SIGNAL);
	SAVETMPS;
	PUSHMARK(SP);
	EXTEND(SP, 1);
	PUSHs(sv_2mortal(newSViv(signo)));
	PUTBACK;
	call_sv((SV*)callback, G_VOID | G_DISCARD);
	FREETMPS;
	POPSTACK;
}

static HV* S_get_action(pTHX_ SV* input) {
    if(SvTRUE(input)) {
		if(SvROK(input) && sv_isa(input, "POSIX::SigAction"))
			return (HV*)SvRV(input);
		else
			Perl_croak(aTHX_ "Action is not of type POSIX::SigAction: %s", SvPV_nolen(input));
	}
}
#define get_action(input)  S_get_action(aTHX_ input)

static void S_hash_to_sigaction(pTHX_ struct sigaction* ptr, CV** new_handler, HV* values) {
	if (hv_exists(values, "FLAGS", 5)) {
		SV** flags_ptr = hv_fetchs(values, "FLAGS", 0);
		ptr->sa_flags = SvIV(*flags_ptr);
	}
	if (hv_exists(values, "HANDLER", 7)) {
		SV** handler_ptr = hv_fetchs(values, "HANDLER", 0);
		if (!SvOK(*handler_ptr) || strEQ(SvPV_nolen(*handler_ptr), "DEFAULT")) {
			ptr->sa_flags &= ~SA_SIGINFO;
			ptr->sa_handler = SIG_DFL;
		}
		else if (strEQ(SvPV_nolen(*handler_ptr), "IGNORE")) {
			ptr->sa_flags &= ~SA_SIGINFO;
			ptr->sa_handler = SIG_IGN;
		}
		else {
			GV* gv;
			HV* stash;
			*new_handler = sv_2cv(*handler_ptr, &stash, &gv, 0);

			if (ptr->sa_flags & SA_SIGINFO)
				ptr->sa_sigaction = smart_handler;
			else
				ptr->sa_handler = dumb_handler;
		}
	}
	else {
		Perl_croak(aTHX_ "No handler given");
	}

	if (hv_exists(values, "MASK", 4)) {
		SV** mask_ptr = hv_fetchs(values, "MASK", 0);
		if (SvROK(*mask_ptr))
			ptr->sa_mask = *(const sigset_t *) SvPV_nolen(SvRV(*mask_ptr)); // XXX
	}
}
#define hash_to_sigaction(ptr, handler, val) S_hash_to_sigaction(aTHX_ ptr, handler, val)

void S_sigaction_to_hash(pTHX_ struct sigaction* ptr, HV* hash, CV* handler) {
	dMY_CXT;
	SV* mask;

	if ((void*)ptr->sa_sigaction == SIG_DFL)
		hv_stores(hash, "HANDLER", newSVpvs("DEFAULT"));
	else if ((void*)ptr->sa_sigaction == SIG_IGN)
		hv_stores(hash, "HANDLER", newSVpvs("IGNORE"));
	else
		hv_stores(hash, "HANDLER", newRV_inc((SV*)handler));

	hv_stores(hash, "FLAGS", newSVuv(ptr->sa_flags));
#if PERL_VERSION > 15 || PERL_VERSION == 15 && PERL_SUBVERSION > 2
	mask = newSVpvn((const char*)&ptr->sa_mask, sizeof(sigset_t));
#else
	sigset_t* set = PerlMem_malloc(sizeof(sigset_t));
	Copy(&ptr->sa_mask, set, 1, sigset_t);
	mask = newSViv(PTR2IV(set));
#endif
	hv_stores(hash, "MASK", sv_bless(newRV_noinc(mask), gv_stashpvs("POSIX::SigSet", 0)));
}
#define sigaction_to_hash(sig_action, hash, handler) S_sigaction_to_hash(aTHX_ sig_action, hash, handler)

static void remove_handler(pTHX_ void* ptr) {
	SAVEFREESV(*(SV**)ptr);
	*(SV**)ptr = NULL;
}

MODULE = Signal::Unsafe				PACKAGE = Signal::Unsafe

BOOT:
	MY_CXT_INIT;

void
CLONE(...)
	CODE:
		Perl_croak(aTHX_ "Cloning is not yet supported...");

SysRet
sigaction(sig, newaction, oldaction = 0)
	int	 sig
	HV* newaction = $arg && SvOK($arg) ? get_action($arg) : 0;
	HV* oldaction = items == 3 && SvOK($arg) ? get_action($arg) : 0;
	PREINIT:
		dMY_CXT;
		struct sigaction newact = {0}, oldact = {0};
		CV* oldhandler;
		CV* new_handler = NULL;
    CODE:
		if (newaction)
			hash_to_sigaction(&newact, &new_handler, newaction);

		oldhandler = MY_CXT.handlers[sig];
		if (newaction) {
			if (new_handler) {
				if (MY_CXT.handlers[sig])
					SvREFCNT_dec(MY_CXT.handlers[sig]);
				MY_CXT.handlers[sig] = (CV*)SvREFCNT_inc(new_handler);
			}
			else {
				SAVEDESTRUCTOR_X(&remove_handler, MY_CXT.handlers + sig);
			}
		}
		RETVAL = sigaction(sig, newaction ? &newact : NULL, oldaction ? &oldact : NULL);

		if (oldaction)
			sigaction_to_hash(&oldact, oldaction, oldhandler);
	OUTPUT:
		RETVAL
