static inline TWindow* sv2tv_h(SV *sv) {
    // SvTYPE(SvRV(SV*)) === SVt_PVHV    Hash
    HV *hv = (HV*) SvRV(sv);
    SV** f = hv_fetch(hv, "obj", 3, 0);
    if (!f)
	croak("obj key does not contain tvision object");
    TWindow* w = *((TWindow**) SvPV_nolen(*f));
    return w;
}
static inline TWindow* sv2tv_a(SV *sv) {
    // SvTYPE(SvRV(SV*)) === SVt_PVAV    Array
    AV *av = (AV*) SvRV(sv);
    SV** f = av_fetch(av, 0, 0);
    if (!f)
	croak("self[0] does not contain tvision object");
    TWindow* w = *((TWindow**) SvPV_nolen(*f));
    return w;
}
#define sv2tv_s(sv,type) *((type**) SvPV_nolen(SvRV(sv)))
#define new_tv_a(w, pkg) \
    AV *self = newAV(); \
    av_store(self, 0, newSVpvn((const char *)&w, sizeof(w))); \
    SV *rself = newRV_inc((SV*) self); \
    sv_bless(rself, gv_stashpv(pkg, GV_ADD))
#define new_tvobj_a(self, w, pkg) \
    av_store(self, 0, newSVpvn((const char *)&w, sizeof(w))); \
    SV *rself = newRV_inc((SV*) self); \
    sv_bless(rself, gv_stashpv(pkg, GV_ADD))


#ifndef _NO_TV
class TVApp : public TApplication {
public:
    TVApp();
    static TStatusLine *initStatusLine( TRect r );
    static TMenuBar *initMenuBar( TRect r );
    virtual void handleEvent(TEvent& Event);
    virtual void getEvent(TEvent& event);
    virtual void idle();
};
#endif
