/* pmcp_abi.h - the two C ABIs this dist calls, resolved once at BOOT.
 *
 * Needs: pmcp_clos.h, frj_abi.h, jsf_abi.h.
 * Gives: PMCP_FRJ (File::Raw::JSON) and PMCP_JSF (JSON::Schema::Fast), both
 * non-NULL once BOOT has returned, so no later header checks for NULL.
 *
 * The house _abi_ptr pattern (memory: reference_abi_pattern). The pointer is
 * read back as a UV, never an IV: a library mapped above the sign bit gives a
 * negative IV, which is real on illumos and on 32-bit builds. The version gate
 * is >=, never ==, because the tables are append-only and an equality check
 * turns every provider release into a breaking change.
 *
 * Unlike Maat, which falls back when a table is missing, this dist has no slow
 * path: every message is decoded by frj and every schema is compiled by jsf. So
 * BOOT croaks, naming the provider, the ABI it needs and what it found.
 */

#ifndef PMCP_ABI_H
#define PMCP_ABI_H

static const frj_abi *PMCP_FRJ = NULL;
static const jsf_abi *PMCP_JSF = NULL;

/* One provider's table address, or 0 with *why set to a mortal reason. */
static UV pmcp_abi_ptr(pTHX_ const char *module, SV **why)
{
    SV *err = NULL;
    SV *fn, *r;
    UV p = 0;

    *why = NULL;
    if (!pmcp_require(aTHX_ module, &err)) {
        *why = sv_2mortal(err);
        return 0;
    }
    fn = sv_2mortal(newSVpvf("%s::_abi_ptr", module));
    r = pmcp_call_sv(aTHX_ fn, NULL, 0, G_SCALAR, &err);
    if (!r) {
        *why = sv_2mortal(err);
        return 0;
    }
    if (SvOK(r)) p = SvUV(r);
    SvREFCNT_dec(r);
    if (!p) *why = sv_2mortal(newSVpvs("its _abi_ptr returned nothing"));
    return p;
}

/* The provider's own $VERSION, mortal, or "none" when it did not load. */
static SV *pmcp_dist_version(pTHX_ const char *module)
{
    SV *name = sv_2mortal(newSVpvf("%s::VERSION", module));
    SV *v = get_sv(SvPV_nolen(name), 0);
    return (v && SvOK(v)) ? v : sv_2mortal(newSVpvs("none"));
}

/* Croak unless `found` is a table at ABI `need` or later. `version` is the
 * table's abi_version, read by the caller because the two structs are
 * different types. `why` explains a 0 address. Kept apart from the resolve so
 * t/02 can hand it an old table without an old provider installed. */
static void pmcp_abi_check(pTHX_ const char *module, UV found, int version,
                           int need, const char *since, SV *why)
{
    if (found && version >= need) return;
    if (!found)
        croak("%s needs %s %s or later for its C ABI %d, and %s is unusable "
              "(version %" SVf "): %" SVf,
              PMCP_DIST, module, since, need, module,
              SVfARG(pmcp_dist_version(aTHX_ module)),
              SVfARG(why ? why : sv_2mortal(newSVpvs("no reason given"))));
    croak("%s needs %s %s or later for its C ABI %d, and found %s %" SVf
          " with C ABI %d",
          PMCP_DIST, module, since, need, module,
          SVfARG(pmcp_dist_version(aTHX_ module)), version);
}

#define PMCP_FRJ_SINCE "0.08"
#define PMCP_JSF_SINCE "0.10"

/* BOOT: resolve both tables or croak. */
static void pmcp_abi_boot(pTHX)
{
    SV *why;
    UV p;

    p = pmcp_abi_ptr(aTHX_ "File::Raw::JSON", &why);
    pmcp_abi_check(aTHX_ "File::Raw::JSON", p,
                   p ? (INT2PTR(const frj_abi *, p))->abi_version : 0,
                   FRJ_ABI_VERSION, PMCP_FRJ_SINCE, why);
    PMCP_FRJ = INT2PTR(const frj_abi *, p);

    p = pmcp_abi_ptr(aTHX_ "JSON::Schema::Fast", &why);
    pmcp_abi_check(aTHX_ "JSON::Schema::Fast", p,
                   p ? (INT2PTR(const jsf_abi *, p))->abi_version : 0,
                   JSF_ABI_VERSION, PMCP_JSF_SINCE, why);
    PMCP_JSF = INT2PTR(const jsf_abi *, p);
}

#endif /* PMCP_ABI_H */
