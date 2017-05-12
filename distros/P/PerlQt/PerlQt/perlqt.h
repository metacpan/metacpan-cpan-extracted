#ifndef PERLQT_H
#define PERLQT_H

#include "marshall.h"

struct smokeperl_object {
    bool allocated;
    Smoke *smoke;
    int classId;
    void *ptr;
};

struct TypeHandler {
    const char *name;
    Marshall::HandlerFn fn;
};

extern int do_debug;   // evil
extern SV *sv_qapp;
extern int object_count;

// keep this enum in sync with lib/Qt/debug.pm

enum QtDebugChannel {
    qtdb_none = 0x00,
    qtdb_ambiguous = 0x01,
    qtdb_autoload = 0x02,
    qtdb_calls = 0x04,
    qtdb_gc = 0x08,
    qtdb_virtual = 0x10,
    qtdb_verbose = 0x20
};

void unmapPointer(smokeperl_object *, Smoke::Index, void*);
SV *getPointerObject(void *ptr);
void mapPointer(SV *, smokeperl_object *, HV *, Smoke::Index, void *);


extern struct mgvtbl vtbl_smoke;

inline smokeperl_object *sv_obj_info(SV *sv) {  // ptr on success, null on fail
    if(!sv || !SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVHV)
	return 0;
    SV *obj = SvRV(sv);
    MAGIC *mg = mg_find(obj, '~');
    if(!mg || mg->mg_virtual != &vtbl_smoke) {
	// FIXME: die or something?
	return 0;
    }
    smokeperl_object *o = (smokeperl_object*)mg->mg_ptr;
    return o;
}

#endif // PERLQT_H
