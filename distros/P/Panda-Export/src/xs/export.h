#pragma once
#include <xs/xs.h>

namespace xs { namespace exp {

const size_t MAX_ITEMS = 1 << 31;

struct constant_t {
    const char* name;
    int64_t     value;
    const char* svalue;
};

void create_constants (pTHX_ HV* stash, HV* constants);
void create_constants (pTHX_ HV* stash, SV** list, size_t items);
void create_constants (pTHX_ HV* stash, constant_t* list, size_t items = MAX_ITEMS);

void create_constant  (pTHX_ HV* stash, SV*         name, SV*         value, AV* stash_constants_list = NULL);
void create_constant  (pTHX_ HV* stash, const char* name, const char* value, AV* stash_constants_list = NULL);
void create_constant  (pTHX_ HV* stash, const char* name, int64_t     value, AV* stash_constants_list = NULL);
void create_constant  (pTHX_ HV* stash, constant_t constant, AV* stash_constants_list = NULL);

void register_export (pTHX_ HV* stash, CV* sub);
void register_export (pTHX_ HV* stash, SV* sub);
void register_export (pTHX_ HV* stash, const char* name);

void export_constants (pTHX_ HV* from, HV* to);
void export_subs      (pTHX_ HV* from, HV* to, SV** list, size_t items);
void export_subs      (pTHX_ HV* from, HV* to, const char** list, size_t items = MAX_ITEMS);

inline void export_subs (pTHX_ HV* from, HV* to, AV* list) {
    export_subs(aTHX_ from, to, AvARRAY(list), AvFILLp(list)+1);
}

void export_sub (pTHX_ HV* from, HV* to, SV* name);
void export_sub (pTHX_ HV* from, HV* to, const char* name);

AV* constants_list (pTHX_ HV* stash);

}}
