#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION \
	PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define PERL_VERSION_GE(r,v,s) \
	(PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))

#ifndef CvISXSUB
# define CvISXSUB(cv) (!!CvXSUB(cv))
#endif /* !CvISXSUB */

#ifndef SvSTASH_set
# define SvSTASH_set(sv, stash) (SvSTASH(sv) = (stash))
#endif /* !SvSTASH_set */

#ifndef gv_stashpvs
# define gv_stashpvs(name, flags) gv_stashpvn(""name"", sizeof(name)-1, flags)
#endif /* !gv_stashpvs */

#ifdef PadlistARRAY
# define QUSE_PADLIST_STRUCT 1
#else /* !PadlistARRAY */
# define QUSE_PADLIST_STRUCT 0
typedef AV PADNAMELIST;
# define PadlistARRAY(pl) ((PAD**)AvARRAY(pl))
# define PadlistNAMES(pl) (PadlistARRAY(pl)[0])
#endif /* !PadlistARRAY */

#define safe_av_fetch(av, key) THX_safe_av_fetch(aTHX_ av, key)
static SV *THX_safe_av_fetch(pTHX_ AV *av, I32 key)
{
	SV **item_ptr = av_fetch(av, key, 0);
	return item_ptr ? *item_ptr : &PL_sv_undef;
}

#define sv_unbless(sv) THX_sv_unbless(aTHX_ sv)
static void THX_sv_unbless(pTHX_ SV *sv)
{
	SV *oldstash;
	if(!SvOBJECT(sv)) return;
	SvOBJECT_off(sv);
	if((oldstash = (SV*)SvSTASH(sv))) {
#if !PERL_VERSION_GE(5,17,10)
		PL_sv_objcount--;
#endif /* <5.17.10 */
		SvSTASH_set(sv, NULL);
		SvREFCNT_dec(oldstash);
	}
}

/*
 * Pending actions to apply to a sub are handled in several stages.  The
 * mechanism is quite convoluted, which is unavoidable given the lack of
 * support from the core.
 *
 * Initially, when an action is to be tied to a partially-built sub, a
 * marker object gets stored in the sub's pad.  Specifically, it is
 * added to the slot used by the @_-in-waiting.  The pad and the future
 * @_ will be created if necessary.  If the pad gets thrown away, by the
 * CV dying or being "undef"ed, the marker object also dies, and the
 * actions are never triggered.  If the partial sub content is moved
 * from one CV to another, such as by "sub foo; sub foo { ... }", the
 * marker moves with it.  The marker doesn't know which CV it is
 * attached to; it is the presence of the marker in a CV's pad that is
 * significant.
 *
 * The actions waiting to be performed are stored in the marker object.
 * If another action is requested, on a CV that already has a marker, it
 * gets added to the existing marker.
 *
 * When a partially-built sub gets its body attached, the peephole
 * optimiser is triggered.  Code in this module is in the chain, and
 * looks for the marker.  If present, it removes the marker from the
 * CV (actually: makes it a non-marker) and starts processing actions.
 *
 * While actions are being processed, the queue of pending actions is made
 * accessible through a chain of AVs (running_actions).  If another action
 * is requested, while this is in progress, it gets added to the queue.
 *
 * If an action is requested on a sub that already has a body and does
 * not have a running queue, the queueing function sets up a running
 * queue and starts processing actions.  Doing this, rather than just
 * performing the action directly, keeps actions sequential, in case
 * another action is requested while one is already executing.
 */

static void (*next_peep)(pTHX_ OP*);
static void my_peep(pTHX_ OP*);
static SV *running_actions;
static HV *stash_wblist;

#define new_minimal_padlist() THX_new_minimal_padlist(aTHX)
static PADLIST *THX_new_minimal_padlist(pTHX)
{
	PADLIST *padlist;
	PAD *pad;
	PADNAMELIST *padname;
	pad = newAV();
	av_store(pad, 0, &PL_sv_undef);
#if QUSE_PADLIST_STRUCT
	Newxz(padlist, 1, PADLIST);
	Newx(PadlistARRAY(padlist), 2, PAD *);
#else /* !QUSE_PADLIST_STRUCT */
	padlist = newAV();
# if !PERL_VERSION_GE(5,15,3)
	AvREAL_off(padlist);
# endif /* < 5.15.3 */
	av_extend(padlist, 1);
#endif /* !QUSE_PADLIST_STRUCT */
#if PERL_VERSION_GE(5,21,7)
	padname = newPADNAMELIST(0);
#else /* <5.21.7 */
	padname = newAV();
# ifdef AvPAD_NAMELIST_on
	AvPAD_NAMELIST_on(padname);
# endif /* AvPAD_NAMELIST_on */
#endif /* <5.21.7 */
	PadlistARRAY(padlist)[0] = (PAD*)padname;
	PadlistARRAY(padlist)[1] = pad;
	return padlist;
}

#define cv_find_wblist(sub) THX_cv_find_wblist(aTHX_ sub)
static AV *THX_cv_find_wblist(pTHX_ CV *sub)
{
	PADLIST *padlist;
	AV *argav;
	I32 pos;
	if(CvISXSUB(sub) || CvDEPTH(sub) != 0) return NULL;
	padlist = CvPADLIST(sub);
	if(!padlist) return NULL;
	argav = (AV*)safe_av_fetch(PadlistARRAY(padlist)[1], 0);
	if(SvTYPE((SV*)argav) != SVt_PVAV) return NULL;
	for(pos = av_len(argav); pos >= 0; pos--) {
		SV *v = safe_av_fetch(argav, pos);
		if(SvTYPE(v) == SVt_PVAV && SvOBJECT(v) &&
				SvSTASH(v) == stash_wblist)
			return (AV*)v;
	}
	return NULL;
}

#define cv_force_wblist(sub) THX_cv_force_wblist(aTHX_ sub)
static AV *THX_cv_force_wblist(pTHX_ CV *sub)
{
	PADLIST *padlist;
	PAD *pad;
	AV *argav, *wbl;
	I32 pos;
	padlist = CvPADLIST(sub);
	if(!padlist) goto create_padlist;
	pad = PadlistARRAY(padlist)[1];
	argav = (AV*)safe_av_fetch(pad, 0);
	if(SvTYPE((SV*)argav) != SVt_PVAV) goto create_argav;
	for(pos = av_len(argav); pos >= 0; pos--) {
		SV *v = safe_av_fetch(argav, pos);
		if(SvTYPE(v) == SVt_PVAV && SvOBJECT(v) &&
				SvSTASH(v) == stash_wblist)
			return (AV*)v;
	}
	goto create_wblist;
	create_padlist:
	CvPADLIST(sub) = padlist = new_minimal_padlist();
	pad = PadlistARRAY(padlist)[1];
	create_argav:
	argav = newAV();
	av_extend(argav, 0);
	av_store(pad, 0, (SV*)argav);
	create_wblist:
	wbl = newAV();
	sv_bless(sv_2mortal(newRV_inc((SV*)wbl)), stash_wblist);
	av_push(argav, (SV*)wbl);
	if(!next_peep) {
		next_peep = PL_peepp;
		PL_peepp = my_peep;
	}
	return wbl;
}

#define find_running_wblist(sub) THX_find_running_wblist(aTHX_ sub)
static AV *THX_find_running_wblist(pTHX_ CV *sub)
{
	AV *runav = (AV*)running_actions;
	while(SvTYPE((SV*)runav) == SVt_PVAV) {
		CV *runsubject = (CV*)*av_fetch(runav, 0, 0);
		if(runsubject == sub) return (AV*)*av_fetch(runav, 1, 0);
		runav = (AV*)*av_fetch(runav, 2, 0);
	}
	return NULL;
}

#define setup_wblist_to_run(sub, wbl) THX_setup_wblist_to_run(aTHX_ sub, wbl)
static void THX_setup_wblist_to_run(pTHX_ CV *sub, AV *wbl)
{
	AV *runav = newAV();
	av_extend(runav, 2);
	av_store(runav, 0, SvREFCNT_inc((SV*)sub));
	av_store(runav, 1, SvREFCNT_inc((SV*)wbl));
	av_store(runav, 2, SvREFCNT_inc(running_actions));
	SAVEGENERICSV(running_actions);
	running_actions = (SV*)runav;
}

#define run_actions(sub, wbl) \
	THX_run_actions(aTHX_ sub, wbl)
static void THX_run_actions(pTHX_ CV *sub, AV *wbl)
{
	SV *subject_ref = sv_2mortal(newRV_inc((SV*)sub));
	while(av_len(wbl) != -1) {
		dSP;
		PUSHMARK(SP);
		XPUSHs(subject_ref);
		PUTBACK;
		call_sv(sv_2mortal(av_shift(wbl)), G_VOID|G_DISCARD);
	}
}

static void my_peep(pTHX_ OP*o)
{
	CV *sub = PL_compcv;
	AV *wbl = cv_find_wblist(PL_compcv);
	if(!wbl || find_running_wblist(sub)) {
		next_peep(aTHX_ o);
		return;
	}
	ENTER;
	setup_wblist_to_run(sub, wbl);
	sv_unbless((SV*)wbl);
	next_peep(aTHX_ o);
	run_actions(sub, wbl);
	LEAVE;
}

MODULE = Sub::WhenBodied PACKAGE = Sub::WhenBodied

PROTOTYPES: DISABLE

BOOT:
	stash_wblist = gv_stashpvs("Sub::WhenBodied::__WBLIST__", 1);
	running_actions = &PL_sv_no;

void
when_sub_bodied(CV *sub, CV *action)
PROTOTYPE: $$
PREINIT:
	AV *wbl;
CODE:
	if(!CvISXSUB(sub) && !CvROOT(sub)) {
		wbl = cv_force_wblist(sub);
		av_push(wbl, SvREFCNT_inc((SV*)action));
	} else if((wbl = cv_find_wblist(sub))) {
		av_push(wbl, SvREFCNT_inc((SV*)action));
	} else if((wbl = find_running_wblist(sub))) {
		av_push(wbl, SvREFCNT_inc((SV*)action));
	} else {
		wbl = newAV();
		av_push(wbl, SvREFCNT_inc((SV*)action));
		ENTER;
		setup_wblist_to_run(sub, wbl);
		SvREFCNT_dec(wbl);
		run_actions(sub, wbl);
		LEAVE;
	}
