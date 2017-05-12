#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#ifndef gv_fetchsv
#define gv_fetchsv(n,f,t) gv_fetchpv(SvPV_nolen(n), f, t)
#endif

#ifndef mro_method_changed_in
#define mro_method_changed_in(x) PL_sub_generation++
#endif

#ifndef HvENAME
#define HvENAME HvNAME
#endif

#ifndef hv_name_set
#define hv_name_set(stash, name, namelen, flags) \
    (HvNAME(stash) = savepvn(name, namelen))
#endif

#ifdef newSVhek
#define newSVhe(he) newSVhek(HeKEY_hek(he))
#else
#define newSVhe(he) newSVpv(HePV(he, PL_na), 0)
#endif

#ifndef GvCV_set
#define GvCV_set(gv, cv) (GvCV(gv) = (CV*)(cv))
#endif

#ifndef MUTABLE_PTR
#define MUTABLE_PTR(p) ((void *) (p))
#endif

#ifndef MUTABLE_SV
#define MUTABLE_SV(p) ((SV *)MUTABLE_PTR(p))
#endif

#ifndef SVT_SCALAR
#define SVT_SCALAR(svt) (svt <= SVt_PVLV)
#endif

#ifndef SVT_ARRAY
#define SVT_ARRAY(svt) (svt == SVt_PVAV)
#endif

#ifndef SVT_HASH
#define SVT_HASH(svt) (svt == SVt_PVHV)
#endif

#ifndef SVT_CODE
#define SVT_CODE(svt) (svt == SVt_PVCV)
#endif

#ifndef SVT_IO
#define SVT_IO(svt) (svt == SVt_PVIO)
#endif

#ifndef SVT_FORMAT
#define SVT_FORMAT(svt) (svt == SVt_PVFM)
#endif

/* HACK: scalar slots are always populated on perl < 5.10, so treat undef
 * as nonexistent. this is consistent with the previous behavior of the pure
 * perl version of this module (since this is the behavior that perl sees
 * in all versions */
#if PERL_VERSION < 10
#define GvSVOK(g) (GvSV(g) && SvTYPE(GvSV(g)) != SVt_NULL)
#else
#define GvSVOK(g) GvSV(g)
#endif

#define GvAVOK(g) GvAV(g)
#define GvHVOK(g) GvHV(g)
#define GvCVOK(g) GvCVu(g) /* XXX: should this really be GvCVu? or GvCV? */
#define GvIOOK(g) GvIO(g)

/* see above - don't let scalar slots become unpopulated, this breaks
 * assumptions in core */
#if PERL_VERSION < 10
#define GvSetSV(g,v) do {               \
    SV *_v = (SV*)(v);                  \
    SvREFCNT_dec(GvSV(g));              \
    if ((GvSV(g) = _v ? _v : newSV(0))) \
        GvIMPORTED_SV_on(g);            \
} while (0)
#else
#define GvSetSV(g,v) do {               \
    SvREFCNT_dec(GvSV(g));              \
    if ((GvSV(g) = (SV*)(v)))           \
        GvIMPORTED_SV_on(g);            \
} while (0)
#endif

#define GvSetAV(g,v) do {               \
    SvREFCNT_dec(GvAV(g));              \
    if ((GvAV(g) = (AV*)(v)))           \
        GvIMPORTED_AV_on(g);            \
} while (0)
#define GvSetHV(g,v) do {               \
    SvREFCNT_dec(GvHV(g));              \
    if ((GvHV(g) = (HV*)(v)))           \
        GvIMPORTED_HV_on(g);            \
} while (0)
#define GvSetCV(g,v) do {               \
    SvREFCNT_dec(GvCV(g));              \
    if ((GvCV_set(g, (CV*)(v)))) {      \
        GvIMPORTED_CV_on(g);            \
        GvASSUMECV_on(g);               \
    }                                   \
    GvCVGEN(g) = 0;                     \
    mro_method_changed_in(GvSTASH(g));  \
} while (0)
#define GvSetIO(g,v) do {               \
    SvREFCNT_dec(GvIO(g));              \
    GvIOp(g) = (IO*)(v);                \
} while (0)

typedef enum {
    VAR_NONE = 0,
    VAR_SCALAR,
    VAR_ARRAY,
    VAR_HASH,
    VAR_CODE,
    VAR_IO,
    VAR_GLOB,  /* TODO: unimplemented */
    VAR_FORMAT /* TODO: unimplemented */
} vartype_t;

typedef struct {
    vartype_t type;
    SV *name;
} varspec_t;

static U32 name_hash, namespace_hash, type_hash;
static SV *name_key, *namespace_key, *type_key;
static REGEXP *valid_module_regex;

static const char *vartype_to_string(vartype_t type)
{
    switch (type) {
    case VAR_SCALAR:
        return "SCALAR";
    case VAR_ARRAY:
        return "ARRAY";
    case VAR_HASH:
        return "HASH";
    case VAR_CODE:
        return "CODE";
    case VAR_IO:
        return "IO";
    default:
        return "unknown";
    }
}

static I32 vartype_to_svtype(vartype_t type)
{
    switch (type) {
    case VAR_SCALAR:
        return SVt_PV; /* or whatever */
    case VAR_ARRAY:
        return SVt_PVAV;
    case VAR_HASH:
        return SVt_PVHV;
    case VAR_CODE:
        return SVt_PVCV;
    case VAR_IO:
        return SVt_PVIO;
    default:
        return SVt_NULL;
    }
}

static vartype_t string_to_vartype(char *vartype)
{
    if (strEQ(vartype, "SCALAR")) {
        return VAR_SCALAR;
    }
    else if (strEQ(vartype, "ARRAY")) {
        return VAR_ARRAY;
    }
    else if (strEQ(vartype, "HASH")) {
        return VAR_HASH;
    }
    else if (strEQ(vartype, "CODE")) {
        return VAR_CODE;
    }
    else if (strEQ(vartype, "IO")) {
        return VAR_IO;
    }
    else {
        croak("Type must be one of 'SCALAR', 'ARRAY', 'HASH', 'CODE', or 'IO', not '%s'", vartype);
    }
}

static int _is_valid_module_name(SV *package)
{
    char *buf;
    STRLEN len;
    SV *sv;

    buf = SvPV(package, len);

    /* whee cargo cult */
    sv = sv_newmortal();
    sv_upgrade(sv, SVt_PV);
    SvREADONLY_on(sv);
    SvLEN(sv) = 0;
    SvUTF8_on(sv);
    SvPVX(sv) = buf;
    SvCUR_set(sv, len);
    SvPOK_on(sv);

    return pregexec(valid_module_regex, buf, buf + len, buf, 1, sv, 1);
}

static void _deconstruct_variable_name(SV *variable, varspec_t *varspec)
{
    char *varpv;

    if (!SvCUR(variable))
        croak("You must pass a variable name");

    varspec->name = sv_2mortal(newSVsv(variable));

    varpv = SvPV_nolen(varspec->name);
    switch (varpv[0]) {
    case '$':
        varspec->type = VAR_SCALAR;
        sv_chop(varspec->name, &varpv[1]);
        break;
    case '@':
        varspec->type = VAR_ARRAY;
        sv_chop(varspec->name, &varpv[1]);
        break;
    case '%':
        varspec->type = VAR_HASH;
        sv_chop(varspec->name, &varpv[1]);
        break;
    case '&':
        varspec->type = VAR_CODE;
        sv_chop(varspec->name, &varpv[1]);
        break;
    default:
        varspec->type = VAR_IO;
        break;
    }
}

static void _deconstruct_variable_hash(HV *variable, varspec_t *varspec)
{
    HE *val;

    val = hv_fetch_ent(variable, name_key, 0, name_hash);
    if (!val)
        croak("The 'name' key is required in variable specs");

    varspec->name = sv_2mortal(newSVsv(HeVAL(val)));

    val = hv_fetch_ent(variable, type_key, 0, type_hash);
    if (!val)
        croak("The 'type' key is required in variable specs");

    varspec->type = string_to_vartype(SvPV_nolen(HeVAL(val)));
}

static void _check_varspec_is_valid(varspec_t *varspec)
{
    if (strstr(SvPV_nolen(varspec->name), "::")) {
        croak("Variable names may not contain ::");
    }
}

static int _valid_for_type(SV *value, vartype_t type)
{
    svtype sv_type = SvROK(value) ? SvTYPE(SvRV(value)) : SVt_NULL;

    switch (type) {
    case VAR_SCALAR:
        /* XXX is a glob a scalar? assigning a glob to the scalar slot seems
         * to work here, but in pure perl i'm pretty sure it goes to the EGV
         * slot, which seems more correct to me. just disable it for now
         * i guess */
        return SVT_SCALAR(sv_type) && sv_type != SVt_PVGV;
    case VAR_ARRAY:
        return SVT_ARRAY(sv_type);
    case VAR_HASH:
        return SVT_HASH(sv_type);
    case VAR_CODE:
        return SVT_CODE(sv_type);
    case VAR_IO:
        return SVT_IO(sv_type);
    default:
        return 0;
    }
}

static HV *_get_namespace(SV *self)
{
    dSP;
    SV *ret;

    PUSHMARK(SP);
    XPUSHs(self);
    PUTBACK;

    call_method("namespace", G_SCALAR);

    SPAGAIN;
    ret = POPs;
    PUTBACK;

    return (HV*)SvRV(ret);
}

static SV *_get_name(SV *self)
{
    dSP;
    SV *ret;

    PUSHMARK(SP);
    XPUSHs(self);
    PUTBACK;

    call_method("name", G_SCALAR);

    SPAGAIN;
    ret = POPs;
    PUTBACK;

    return ret;
}

static void _real_gv_init(GV *gv, HV *stash, SV *name)
{
    char *name_pv;
    STRLEN name_len;

    name_pv = SvPV(name, name_len);
    if (!HvENAME(stash)) {
        hv_name_set(stash, "__ANON__", 8, 0);
    }
    gv_init(gv, stash, name_pv, name_len, 1);

    /* XXX: copied and pasted from gv_fetchpvn_flags and such */
    /* ignoring the stuff for CORE:: and main:: for now, and also
     * ignoring the GvMULTI_on bits, since we pass 1 to gv_init above */
    switch (name_pv[0]) {
        case 'I':
            if (strEQ(&name_pv[1], "SA")) {
                AV *av;

                av = GvAVn(gv);
                sv_magic(MUTABLE_SV(av), MUTABLE_SV(gv), PERL_MAGIC_isa,
                        NULL, 0);
            }
            break;
        case 'O':
            if (strEQ(&name_pv[1], "VERLOAD")) {
                HV *hv;

                hv = GvHVn(gv);
                hv_magic(hv, NULL, PERL_MAGIC_overload);
            }
            break;
        default:
            break;
    }
}

static void _expand_glob(SV *self, SV *varname, HE *entry, HV *namespace,
                         int lval)
{
    GV *glob;

    if (entry) {
        glob = (GV*)HeVAL(entry);
        if (isGV(glob)) {
            croak("_expand_glob called on stash slot with expanded glob: %"SVf,
                  varname);
        }
        else {
            SvREFCNT_inc(glob);
            _real_gv_init(glob, namespace, varname);
            if (HeVAL(entry)) {
                SvREFCNT_dec(HeVAL(entry));
            }
            HeVAL(entry) = (SV*)glob;
        }
    }
    else {
        croak("_expand_glob called on nonexistent stash slot");
    }
}

static SV *_undef_for_type(vartype_t type)
{
    switch (type) {
    case VAR_SCALAR:
        return newSV(0);
        break;
    case VAR_ARRAY:
        return (SV*)newAV();
        break;
    case VAR_HASH:
        return (SV*)newHV();
        break;
    case VAR_CODE:
        croak("Don't know how to vivify CODE variables");
    case VAR_IO:
        return (SV*)newIO();
        break;
    default:
        croak("Unknown type in vivification");
    }
}

static void _add_symbol_entry(SV *self, varspec_t variable, SV *initial,
                              HE *entry, HV *namespace)
{
    GV *glob;
    SV *val;

    if (entry && isGV(HeVAL(entry))) {
        glob = (GV*)HeVAL(entry);
    }
    else if (entry) {
        glob = (GV*)newSV(0);
        _real_gv_init(glob, namespace, variable.name);
        if (HeVAL(entry)) {
            SvREFCNT_dec(HeVAL(entry));
        }
        HeVAL(entry) = (SV*)glob;
    }
    else {
        croak("invalid entry passed to _add_symbol_entry");
    }

    if (!initial) {
        val = _undef_for_type(variable.type);
    }
    else if (SvROK(initial)) {
        val = SvRV(initial);
        SvREFCNT_inc_simple_void_NN(val);
    }
    else {
        val = newSVsv(initial);
    }

    switch (variable.type) {
    case VAR_SCALAR:
        GvSetSV(glob, val);
        break;
    case VAR_ARRAY:
        GvSetAV(glob, val);
        break;
    case VAR_HASH:
        GvSetHV(glob, val);
        break;
    case VAR_CODE:
        GvSetCV(glob, val);
        break;
    case VAR_IO:
        GvSetIO(glob, val);
        break;
    default:
        croak("Unknown variable type in add_symbol");
        break;
    }
}

static void _add_symbol(SV *self, varspec_t variable, SV *initial)
{
    HV *namespace;
    HE *entry;

    namespace = _get_namespace(self);
    entry = hv_fetch_ent(namespace, variable.name, 1, 0);

    _add_symbol_entry(self, variable, initial, entry, namespace);
}

static int _slot_exists(GV *glob, vartype_t type)
{
    switch (type) {
    case VAR_SCALAR:
        return GvSVOK(glob) ? 1 : 0;
        break;
    case VAR_ARRAY:
        return GvAVOK(glob) ? 1 : 0;
        break;
    case VAR_HASH:
        return GvHVOK(glob) ? 1 : 0;
        break;
    case VAR_CODE:
        croak("Don't know how to vivify CODE variables");
    case VAR_IO:
        return GvIOOK(glob) ? 1 : 0;
        break;
    default:
        croak("Unknown type in vivification");
    }

    return 0;
}

static SV *_get_symbol(SV *self, varspec_t *variable, int vivify)
{
    HV *namespace;
    HE *entry;
    GV *glob;

    namespace = _get_namespace(self);
    entry = hv_fetch_ent(namespace, variable->name,
                         vivify && !hv_exists_ent(namespace, variable->name, 0),
                         0);
    if (!entry)
        return NULL;

    glob = (GV*)(HeVAL(entry));
    if (!isGV(glob))
        _expand_glob(self, variable->name, entry, namespace, vivify);

    if (vivify && !_slot_exists(glob, variable->type)) {
        _add_symbol_entry(self, *variable, NULL, entry, namespace);
    }

    switch (variable->type) {
    case VAR_SCALAR:
        return GvSV(glob);
    case VAR_ARRAY:
        return (SV*)GvAV(glob);
    case VAR_HASH:
        return (SV*)GvHV(glob);
    case VAR_CODE:
        return (SV*)GvCV(glob);
    case VAR_IO:
        return (SV*)GvIO(glob);
    default:
        return NULL;
    }
}

MODULE = Package::Stash::XS  PACKAGE = Package::Stash::XS

PROTOTYPES: DISABLE

SV*
new(class, package)
    SV *class
    SV *package
  PREINIT:
    HV *instance;
  CODE:
    if (SvPOK(package)) {
        if (!_is_valid_module_name(package))
            croak("%s is not a module name", SvPV_nolen(package));

        instance = newHV();

        if (!hv_store(instance, "name", 4, SvREFCNT_inc_simple_NN(package), 0)) {
            SvREFCNT_dec(package);
            SvREFCNT_dec(instance);
            croak("Couldn't initialize the 'name' key, hv_store failed");
        }
    }
    else if (SvROK(package) && SvTYPE(SvRV(package)) == SVt_PVHV) {
#if PERL_VERSION < 10
        croak("The XS implementation of Package::Stash does not support "
              "anonymous stashes before perl 5.10");
#else
        instance = newHV();

        if (!hv_store(instance, "namespace", 9, SvREFCNT_inc_simple_NN(package), 0)) {
            SvREFCNT_dec(package);
            SvREFCNT_dec(instance);
            croak("Couldn't initialize the 'namespace' key, hv_store failed");
        }
#endif
    }
    else {
        croak("Package::Stash->new must be passed the name of the package to access");
    }

    RETVAL = sv_bless(newRV_noinc((SV*)instance), gv_stashsv(class, 0));
  OUTPUT:
    RETVAL

SV*
name(self)
    SV *self
  PREINIT:
    HE *slot;
  CODE:
    if (!sv_isobject(self))
        croak("Can't call name as a class method");
    if (slot = hv_fetch_ent((HV*)SvRV(self), name_key, 0, name_hash)) {
        RETVAL = SvREFCNT_inc_simple_NN(HeVAL(slot));
    }
    else {
        croak("Can't get the name of an anonymous package");
    }
  OUTPUT:
    RETVAL

SV*
namespace(self)
    SV *self
  PREINIT:
    HE *slot;
    SV *package_name;
  CODE:
    if (!sv_isobject(self))
        croak("Can't call namespace as a class method");
#if PERL_VERSION < 10
    package_name = _get_name(self);
    RETVAL = newRV_inc((SV*)gv_stashpv(SvPV_nolen(package_name), GV_ADD));
#else
    slot = hv_fetch_ent((HV*)SvRV(self), namespace_key, 0, namespace_hash);
    if (slot) {
        RETVAL = SvREFCNT_inc_simple_NN(HeVAL(slot));
    }
    else {
        HV *namespace;
        SV *nsref;

        package_name = _get_name(self);
        namespace = gv_stashpv(SvPV_nolen(package_name), GV_ADD);
        nsref = newRV_inc((SV*)namespace);
        sv_rvweaken(nsref);
        if (!hv_store((HV*)SvRV(self), "namespace", 9, nsref, 0)) {
            SvREFCNT_dec(nsref);
            SvREFCNT_dec(self);
            croak("Couldn't initialize the 'namespace' key, hv_store failed");
        }
        RETVAL = SvREFCNT_inc_simple_NN(nsref);
    }
#endif
  OUTPUT:
    RETVAL

void
add_symbol(self, variable, initial=NULL, ...)
    SV *self
    varspec_t variable
    SV *initial
  CODE:
    if (initial && !_valid_for_type(initial, variable.type))
        croak("%s is not of type %s",
              SvPV_nolen(initial), vartype_to_string(variable.type));

    if (items > 2 && (PL_perldb & 0x10) && variable.type == VAR_CODE) {
        int i;
        char *filename = NULL;
        I32 first_line_num = -1, last_line_num = -1;
        SV *dbval, *name;
        HV *dbsub;

        if ((items - 3) % 2)
            croak("add_symbol: Odd number of elements in %%opts");

        for (i = 3; i < items; i += 2) {
            char *key;
            key = SvPV_nolen(ST(i));
            if (strEQ(key, "filename")) {
                if (!SvPOK(ST(i + 1)))
                    croak("add_symbol: filename must be a string");
                filename = SvPV_nolen(ST(i + 1));
            }
            else if (strEQ(key, "first_line_num")) {
                if (!SvIOK(ST(i + 1)))
                    croak("add_symbol: first_line_num must be an integer");
                first_line_num = SvIV(ST(i + 1));
            }
            else if (strEQ(key, "last_line_num")) {
                if (!SvIOK(ST(i + 1)))
                    croak("add_symbol: last_line_num must be an integer");
                last_line_num = SvIV(ST(i + 1));
            }
        }

        if (!filename || first_line_num == -1) {
            if (!filename)
                filename = CopFILE(PL_curcop);
            if (first_line_num == -1)
                first_line_num = PL_curcop->cop_line;
        }

        if (last_line_num == -1)
            last_line_num = first_line_num;

        name = newSVsv(_get_name(self));
        sv_catpvs(name, "::");
        sv_catsv(name, variable.name);

        /* http://perldoc.perl.org/perldebguts.html#Debugger-Internals */
        dbsub = get_hv("DB::sub", 1);
        dbval = newSVpvf("%s:%d-%d", filename, first_line_num, last_line_num);
        if (!hv_store_ent(dbsub, name, dbval, 0)) {
            warn("Failed to update $DB::sub for subroutine %s",
                 SvPV_nolen(name));
            SvREFCNT_dec(dbval);
        }

        SvREFCNT_dec(name);
    }

    _add_symbol(self, variable, initial);

void
remove_glob(self, name)
    SV *self
    SV *name
  CODE:
    hv_delete_ent(_get_namespace(self), name, G_DISCARD, 0);

int
has_symbol(self, variable)
    SV *self
    varspec_t variable
  PREINIT:
    HV *namespace;
    HE *entry;
    SV *val;
  CODE:
    namespace = _get_namespace(self);
    entry = hv_fetch_ent(namespace, variable.name, 0, 0);
    if (!entry)
        XSRETURN_UNDEF;

    val = HeVAL(entry);
    if (isGV(val)) {
        GV *glob = (GV*)val;
        switch (variable.type) {
        case VAR_SCALAR:
            RETVAL = GvSVOK(glob) ? 1 : 0;
            break;
        case VAR_ARRAY:
            RETVAL = GvAVOK(glob) ? 1 : 0;
            break;
        case VAR_HASH:
            RETVAL = GvHVOK(glob) ? 1 : 0;
            break;
        case VAR_CODE:
            RETVAL = GvCVOK(glob) ? 1 : 0;
            break;
        case VAR_IO:
            RETVAL = GvIOOK(glob) ? 1 : 0;
            break;
        default:
            croak("Unknown variable type in has_symbol");
        }
    }
    else {
        RETVAL = (variable.type == VAR_CODE);
    }
  OUTPUT:
    RETVAL

SV*
get_symbol(self, variable)
    SV *self
    varspec_t variable
  PREINIT:
    SV *val;
  CODE:
    val = _get_symbol(self, &variable, 0);
    if (!val)
        XSRETURN_UNDEF;
    RETVAL = newRV_inc(val);
  OUTPUT:
    RETVAL

SV*
get_or_add_symbol(self, variable)
    SV *self
    varspec_t variable
  PREINIT:
    SV *val;
  CODE:
    val = _get_symbol(self, &variable, 1);
    if (!val)
        XSRETURN_UNDEF;
    RETVAL = newRV_inc(val);
  OUTPUT:
    RETVAL

void
remove_symbol(self, variable)
    SV *self
    varspec_t variable
  PREINIT:
    HV *namespace;
    HE *entry;
    SV *val;
  CODE:
    namespace = _get_namespace(self);
    entry = hv_fetch_ent(namespace, variable.name, 0, 0);
    if (!entry)
        XSRETURN_EMPTY;

    val = HeVAL(entry);
    if (isGV(val)) {
        GV *glob = (GV*)val;
        switch (variable.type) {
        case VAR_SCALAR:
            GvSetSV(glob, NULL);
            break;
        case VAR_ARRAY:
            GvSetAV(glob, NULL);
            break;
        case VAR_HASH:
            GvSetHV(glob, NULL);
            break;
        case VAR_CODE:
            GvSetCV(glob, NULL);
            break;
        case VAR_IO:
            GvSetIO(glob, NULL);
            break;
        default:
            croak("Unknown variable type in remove_symbol");
            break;
        }
    }
    else {
        if (variable.type == VAR_CODE) {
            hv_delete_ent(namespace, variable.name, G_DISCARD, 0);
        }
    }

void
list_all_symbols(self, vartype=VAR_NONE)
    SV *self
    vartype_t vartype
  PPCODE:
    if (vartype == VAR_NONE) {
        HV *namespace;
        HE *entry;
        int keys;

        namespace = _get_namespace(self);
        keys = hv_iterinit(namespace);
        EXTEND(SP, keys);
        while ((entry = hv_iternext(namespace))) {
#if PERL_VERSION < 10
            char *pv;
            STRLEN len;
            pv = HePV(entry, len);
            if (strnEQ(entry, "::ISA::CACHE::", len)) {
                continue;
            }
#endif
            mPUSHs(newSVhe(entry));
        }
    }
    else {
        HV *namespace;
        SV *val;
        char *key;
        I32 len;

        namespace = _get_namespace(self);
        hv_iterinit(namespace);
        while ((val = hv_iternextsv(namespace, &key, &len))) {
            GV *gv = (GV*)val;
#if PERL_VERSION < 10
            if (vartype == VAR_SCALAR && strnEQ(key, "::ISA::CACHE::", len)) {
                continue;
            }
#endif
            if (isGV(gv)) {
                switch (vartype) {
                case VAR_SCALAR:
                    if (GvSVOK(val))
                        mXPUSHp(key, len);
                    break;
                case VAR_ARRAY:
                    if (GvAVOK(val))
                        mXPUSHp(key, len);
                    break;
                case VAR_HASH:
                    if (GvHVOK(val))
                        mXPUSHp(key, len);
                    break;
                case VAR_CODE:
                    if (GvCVOK(val))
                        mXPUSHp(key, len);
                    break;
                case VAR_IO:
                    if (GvIOOK(val))
                        mXPUSHp(key, len);
                    break;
                default:
                    croak("Unknown variable type in list_all_symbols");
                }
            }
            else if (vartype == VAR_CODE) {
                mXPUSHp(key, len);
            }
        }
    }

void
get_all_symbols(self, vartype=VAR_NONE)
    SV *self
    vartype_t vartype
  PREINIT:
    HV *namespace, *ret;
    HE *entry;
  PPCODE:
    namespace = _get_namespace(self);
    ret = newHV();

    hv_iterinit(namespace);
    while ((entry = hv_iternext(namespace))) {
        GV *gv = (GV*)hv_iterval(namespace, entry);
        char *key;
        I32 len;

        key = hv_iterkey(entry, &len);
#if PERL_VERSION < 10
        if ((vartype == VAR_SCALAR || vartype == VAR_NONE)
            && strnEQ(key, "::ISA::CACHE::", len)) {
            continue;
        }
#endif

        if (!isGV(gv)) {
            SV *keysv = newSVpvn(key, len);
            _expand_glob(self, keysv, entry, namespace, 0);
            SvREFCNT_dec(keysv);
        }

        switch (vartype) {
        case VAR_SCALAR:
            if (GvSVOK(gv))
                hv_store(ret, key, len, newRV_inc(GvSV(gv)), 0);
            break;
        case VAR_ARRAY:
            if (GvAVOK(gv))
                hv_store(ret, key, len, newRV_inc((SV*)GvAV(gv)), 0);
            break;
        case VAR_HASH:
            if (GvHVOK(gv))
                hv_store(ret, key, len, newRV_inc((SV*)GvHV(gv)), 0);
            break;
        case VAR_CODE:
            if (GvCVOK(gv))
                hv_store(ret, key, len, newRV_inc((SV*)GvCV(gv)), 0);
            break;
        case VAR_IO:
            if (GvIOOK(gv))
                hv_store(ret, key, len, newRV_inc((SV*)GvIO(gv)), 0);
            break;
        case VAR_NONE:
            hv_store(ret, key, len, SvREFCNT_inc_simple_NN((SV*)gv), 0);
            break;
        default:
            croak("Unknown variable type in get_all_symbols");
        }
    }

    mPUSHs(newRV_noinc((SV*)ret));

BOOT:
    {
        const char *vmre = "\\A[0-9A-Z_a-z]+(?:::[0-9A-Z_a-z]+)*\\z";
#if (PERL_VERSION < 9) || ((PERL_VERSION == 9) && (PERL_SUBVERSION < 5))
        PMOP fakepmop;

        fakepmop.op_pmflags = 0;
        valid_module_regex = pregcomp(vmre, vmre + strlen(vmre), &fakepmop);
#else
        SV *re;

        re = newSVpv(vmre, 0);
        valid_module_regex = pregcomp(re, 0);
#endif

        name_key = newSVpvs("name");
        PERL_HASH(name_hash, "name", 4);

        namespace_key = newSVpvs("namespace");
        PERL_HASH(namespace_hash, "namespace", 9);

        type_key = newSVpvs("type");
        PERL_HASH(type_hash, "type", 4);
    }
