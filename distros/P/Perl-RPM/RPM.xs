#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "RPM.h"

extern XS(boot_RPM__Constants);
extern XS(boot_RPM__Header);
extern XS(boot_RPM__Database);
extern XS(boot_RPM__Error);

void *rpm_hvref2ptr(pTHX_ SV *arg, const char *ntype)
{
    void *var = Null(void *);
    if (arg &&
        sv_isobject(arg) &&
        sv_derived_from(arg, ntype) &&
        SvTYPE(SvRV(arg)) == SVt_PVHV)
    {
        MAGIC *mg = mg_find(SvRV(arg), '~');
        if (mg)
            var = INT2PTR(void *, SvIV(mg->mg_obj));
    }
    return var;
}

SV *rpm_ptr2hvref(pTHX_ void *var, const char *ntype)
{
    SV *arg = &PL_sv_undef;
    if (var) {
        HV *hv = newHV();
        SV *mg = newSViv(PTR2IV(var));
        sv_magic((SV*)hv, Nullsv, 'P', Nullch, 0);
        sv_magic((SV*)hv, mg, '~', Nullch, 0);
        SvREFCNT_dec(mg);
        arg = sv_bless(newRV_noinc((SV*)hv), gv_stashpv(ntype, TRUE));
    }
    return arg;
}

static HV* rpmtag_hv_pv2iv;
static HV* rpmtag_hv_iv2pv;

static void setup_tag_mappings(pTHX)
{
    const char *name;
    char str_num[32];
    size_t len, num_len;
    int i, tag;

    rpmtag_hv_pv2iv = get_hv("RPM::tag2num", TRUE);
    rpmtag_hv_iv2pv = get_hv("RPM::num2tag", TRUE);
    for (i = 0; i < rpmTagTableSize; i++)
    {
        name = rpmTagTable[i].name;
        tag = rpmTagTable[i].val;
        len = strlen(name);
        if (len <= 7 || strnNE(name, "RPMTAG_", 7)) {
            warn("Invalid rpm tag `%s'", name);
            continue;
        }
        name += 7;
        len -= 7;
        hv_store(rpmtag_hv_pv2iv, name, len, newSViv(tag), FALSE);
        num_len = snprintf(str_num, sizeof(str_num), "%d", tag);
        hv_store(rpmtag_hv_iv2pv, str_num, num_len,
                 newSVpvn_share(name, len, 0), FALSE);
    }
}

int rpmtag_pv2iv(pTHX_ const char *name)
{
    SV **svp;
    char uc_name[32];
    int i, len;

    if (! (name && *name)) {
        rpmError(RPMERR_BADARG, "Unknown rpm tag name (null)");
        return 0;
    }

    len = strlen(name);
    if (len > 7 && strnEQ(name, "RPMTAG_", 7)) {
        name += 7;
        len -= 7;
    }
    if (len > sizeof(uc_name)) {
        rpmError(RPMERR_BADARG, "Bad rpm tag name `%.*s...' (too long)",
                 sizeof(uc_name), name);
        return 0;
    }

    for (i = 0; i < len; i++)
        uc_name[i] = toUPPER(name[i]);

    svp = hv_fetch(rpmtag_hv_pv2iv, uc_name, len, FALSE);

    if (svp && SvOK(*svp) && SvIOK(*svp))
        return SvIV(*svp);
    rpmError(RPMERR_BADARG, "Unknown rpm tag name `%s'", name);
    return 0;
}

const char *rpmtag_iv2pv(pTHX_ int tag)
{
    SV **svp;
    int len;
    char str_num[32];

    len = snprintf(str_num, sizeof(str_num), "%d", tag);
    svp = hv_fetch(rpmtag_hv_iv2pv, str_num, len, FALSE);
    if (svp && SvOK(*svp) && SvPOK(*svp))
        return SvPV_nolen(*svp);
    rpmError(RPMERR_BADARG, "Unknown rpm tag number %d", tag);
    return Nullch;
}

SV *rpmtag_iv2sv(pTHX_ int tag)
{
    SV *sv = &PL_sv_undef;
    const char *name = rpmtag_iv2pv(aTHX_ tag);
    if (name) {
        sv = newSVpv(name, 0);
        sv_setiv(sv, tag);
        SvPOK_on(sv);
    }
    return sv;
}

int rpmtag_sv2iv(pTHX_ SV *sv)
{
    if (! (sv && SvOK(sv))) {
        rpmError(RPMERR_BADARG, "Unknown rpm tag (undef)");
        return 0;
    }
    if (SvIOK(sv)) {
        int tag = SvIV(sv);
        const char *name = rpmtag_iv2pv(aTHX_ tag);
        return name ? tag : 0;
    }
    if (SvPOK(sv)) {
        const char *name = SvPV_nolen(sv);
        return rpmtag_pv2iv(aTHX_ name);
    }
    rpmError(RPMERR_BADARG, "Unknown rpm tag (bad argument)");
    return 0;
}

MODULE = RPM            PACKAGE = RPM           PREFIX = rpm_

const char *
rpm_rpm_osname()
    PROTOTYPE:
    CODE:
    rpmGetOsInfo(&RETVAL, Null(int *));
    OUTPUT:
    RETVAL

const char *
rpm_rpm_archname()
    PROTOTYPE:
    CODE:
    rpmGetArchInfo(&RETVAL, Null(int *));
    OUTPUT:
    RETVAL

const char *
rpm_rpm_version()
    PROTOTYPE:
    CODE:
    RETVAL = RPMVERSION;
    OUTPUT:
    RETVAL

BOOT:
{
    SV * config_loaded;

    config_loaded = get_sv("RPM::__config_loaded", TRUE);
    if (! (SvOK(config_loaded) && SvTRUE(config_loaded)))
    {
        rpmReadConfigFiles(NULL, NULL);
        sv_setiv(config_loaded, TRUE);
    }

    setup_tag_mappings(aTHX);

    newXS("RPM::bootstrap_Constants", boot_RPM__Constants, file);
    newXS("RPM::bootstrap_Header", boot_RPM__Header, file);
    newXS("RPM::bootstrap_Database", boot_RPM__Database, file);
    newXS("RPM::bootstrap_Error", boot_RPM__Error, file);
}
