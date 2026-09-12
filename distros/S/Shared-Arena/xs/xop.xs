# The op layer's Perl-visible ends: what it hooked, and what it did.

MODULE = Shared::Arena    PACKAGE = Shared::Arena    PREFIX = sax_

# hooked / hits / delegated / method-op only
#
# The fourth is call sites where another dist already owned the entersub, so
# only the method op is ours. Those never reach a door and so never count a
# hit, which is worth knowing before reading the third number as a problem.
void
sax__xop_stats(...)
    PPCODE:
        EXTEND(SP, 4);
        mPUSHi(sa_xop_hook);
        mPUSHi(sa_xop_hits);
        mPUSHi(sa_xop_miss);
        mPUSHi(sa_xop_meth);

void
sax__xop_reset(...)
    CODE:
        sa_xop_hits = sa_xop_miss = 0;

MODULE = Shared::Arena    PACKAGE = Shared::Arena

BOOT:
{
    sa_stash_cache = gv_stashpv("Shared::Arena::Cache", GV_ADD);
    sa_stash_map   = gv_stashpv("Shared::Arena::Map", GV_ADD);
    sa_stash_bloom = gv_stashpv("Shared::Arena::Bloom", GV_ADD);
    sa_stash_hist  = gv_stashpv("Shared::Arena::Histogram", GV_ADD);
    sa_stash_ring  = gv_stashpv("Shared::Arena::Ring", GV_ADD);
    sa_stash_rate  = gv_stashpv("Shared::Arena::Rate", GV_ADD);
    sa_stash_cms   = gv_stashpv("Shared::Arena::CountMin", GV_ADD);
    sa_stash_cuckoo = gv_stashpv("Shared::Arena::Cuckoo", GV_ADD);

    /* Two things per door: the GLOB, whose current CV the method op pushes so
     * a monkeypatch takes effect, and the CV that was in it at BOOT, which the
     * entersub op compares against and never calls. A reference is held on the
     * original so that deleting the sub cannot free the CV and let a later
     * allocation reuse the address and pass an identity check it should fail. */
#define SA_DOOR_BOOT(door, path)                                          \
    sa_gv_##door = gv_fetchpv(path, 0, SVt_PVCV);                         \
    if (sa_gv_##door) {                                                   \
        sa_cv_##door = GvCV(sa_gv_##door);                                \
        if (sa_cv_##door) SvREFCNT_inc((SV *)sa_cv_##door);               \
    }
    SA_DOORS(SA_DOOR_BOOT)
#undef SA_DOOR_BOOT

    /* An off switch, because the hook is not free for programs that get
     * nothing from it: every `->get` and `->set` in the process pays a
     * nanosecond or two to be declined. Set SHARED_ARENA_NO_XOP=1 and every
     * door goes through the ordinary XSUB, which is what it did before this
     * file existed. Read once, here, because the rewriting happens at compile
     * time and there is nothing to switch later. */
    if (!getenv("SHARED_ARENA_NO_XOP")
        && PL_check[OP_ENTERSUB] != sa_ck_entersub) {
        sa_prev_ck_entersub   = PL_check[OP_ENTERSUB];
        PL_check[OP_ENTERSUB] = sa_ck_entersub;
    }
}
