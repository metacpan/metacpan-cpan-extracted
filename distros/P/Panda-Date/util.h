#pragma once
#include "Date.h"

namespace xs { namespace date {

Date* date_new   (pTHX_ SV* arg, const Timezone* zone, Date* operand=NULL);
Date* date_set   (pTHX_ SV* arg, const Timezone* zone, Date* operand=NULL);
Date* date_clone (pTHX_ SV* arg, const Timezone* zone, Date* operand=NULL);

void        date_freeze (Date* date, char* buf);
const char* date_thaw   (ptime_t* epoch, const Timezone** zone, const char* ptr, size_t len);

inline size_t date_freeze_len (Date* date) {
    if (date->timezone()->is_local) return sizeof(ptime_t);
    return sizeof(ptime_t) + date->timezone()->name.length();
}

DateRel* daterel_new (pTHX_ SV* arg, DateRel* operand=NULL);
DateRel* daterel_set (pTHX_ SV* arg, DateRel* operand=NULL);
DateRel* daterel_new (pTHX_ SV* from, SV* till, DateRel* operand=NULL);
DateRel* daterel_set (pTHX_ SV* from, SV* till, DateRel* operand=NULL);

DateInt* dateint_new (pTHX_ SV* arg, DateInt* operand=NULL);
DateInt* dateint_set (pTHX_ SV* arg, DateInt* operand=NULL);
DateInt* dateint_new (pTHX_ SV* from, SV* till, DateInt* operand=NULL);
DateInt* dateint_set (pTHX_ SV* from, SV* till, DateInt* operand=NULL);

HV* export_timezone (pTHX_ const Timezone* zone);

}}
