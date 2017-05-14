#ifndef QT_H
#define QT_H

#include "smokeperl.h"
#include "smokehelp.h"

//#define Q_DECL_EXPORT __attribute__ ((visibility("default")))

#ifdef PERLQTDEBUG
SV* catArguments(SV** sp, int n);
SV* catCallerInfo( int count );
#endif
const char* get_SVt(SV* sv);
Q_DECL_EXPORT SV* getPointerObject(void* ptr);
int isDerivedFrom(Smoke *smoke, Smoke::Index classId, Smoke::Index baseId, int cnt);
int isDerivedFrom(Smoke *smoke, const char *className, const char *baseClassName, int cnt);
void mapPointer(SV *obj, smokeperl_object *o, HV *hv, Smoke::Index classId, void *lastptr);
void unmapPointer( smokeperl_object* o, Smoke::Index classId, void* lastptr);

extern SV* sv_this;
extern HV* pointer_map;
extern int do_debug;

#endif // QT_H
