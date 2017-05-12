#ifndef SMOKEPERL_H
#define SMOKEPERL_H

#include "QtCore/QHash"
#include "binding.h"
#include "smoke.h"
#include "smokehelp.h"

struct smokeperl_object {
    bool allocated;
    Smoke* smoke;
    int classId;
    void* ptr;
};

typedef const char* (*ResolveClassNameFn)(smokeperl_object * o);
typedef void (*ClassCreatedFn)(const char* package, SV* module, SV* klass);
typedef bool (*MarshallSlotReturnValueFn)(Smoke::ModuleIndex classId, void** o, Smoke::Stack stack);

struct PerlQt4Module {
    const char *name;
    ResolveClassNameFn resolve_classname;
    ClassCreatedFn class_created;
    PerlQt4::Binding *binding;
    MarshallSlotReturnValueFn slot_returnvalue;
};

extern Q_DECL_EXPORT QHash<Smoke*, PerlQt4Module> perlqt_modules;

inline smokeperl_object* sv_obj_info(SV* sv) { // ptr on success, null on fail
    if(!sv || !SvROK(sv) || !(SvTYPE(SvRV(sv)) == SVt_PVHV || SvTYPE(SvRV(sv)) == SVt_PVAV))
        return 0;
    SV *obj = SvRV(sv);
    MAGIC *mg = mg_find(obj, '~');
    if(!mg ){//|| mg->mg_virtual != &vtbl_smoke) {
        // FIXME: die or something?
        return 0;
    }
    smokeperl_object *o = (smokeperl_object*)mg->mg_ptr;
    return o;
}

// keep this enum in sync with lib/Qt4/debug.pm
enum Qt4DebugChannel {
    qtdb_none = 0x00,
    qtdb_ambiguous = 0x01,
    qtdb_autoload = 0x02,
    qtdb_calls = 0x04,
    qtdb_gc = 0x08,
    qtdb_virtual = 0x10,
    qtdb_verbose = 0x20,
    qtdb_signals = 0x40,
    qtdb_slots = 0x80,
};

enum MocArgumentType {
    xmoc_ptr,
    xmoc_bool,
    xmoc_int,
    xmoc_uint,
    xmoc_long,
    xmoc_ulong,
    xmoc_double,
    xmoc_charstar,
    xmoc_QString,
    xmoc_void
};

struct MocArgument {
    // smoke object and associated typeid
    SmokeType st;
    MocArgumentType argType;
};

#endif //SMOKEPERL_H
