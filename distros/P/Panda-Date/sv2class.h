#undef SV2C_DATE_FUNC
#undef SV2C_DATE_ACTION
#undef SV2C_DATE_DEFVALS
#undef SV2C_DATEREL_FUNC
#undef SV2C_DATEREL_ACTION
#undef SV2C_DATEINT_FUNC
#undef SV2C_DATEINT_ACTION

#ifdef SV2C_NEW
#  define SV2C_DATE_FUNC      date_new
#  define SV2C_DATE_ACTION    operand = new Date
#  define SV2C_DATE_DEFVALS   {2000, 1, 1, 0, 0, 0, -1}
#  define SV2C_DATEREL_FUNC   daterel_new
#  define SV2C_DATEREL_ACTION operand = new DateRel
#  define SV2C_DATEINT_FUNC   dateint_new
#  define SV2C_DATEINT_ACTION operand = new DateInt
#elif defined SV2C_SET
#  define SV2C_DATE_FUNC      date_set
#  define SV2C_DATE_ACTION    operand->set
#  define SV2C_DATE_DEFVALS   {2000, 1, 1, 0, 0, 0, -1}
#  define SV2C_DATEREL_FUNC   daterel_set
#  define SV2C_DATEREL_ACTION operand->set
#  define SV2C_DATEINT_FUNC   dateint_set
#  define SV2C_DATEINT_ACTION operand->set
#elif defined SV2C_CLONE
#  define SV2C_DATE_FUNC    date_clone
#  define SV2C_DATE_ACTION  operand = operand->clone
#  define SV2C_DATE_DEFVALS {-1, -1, -1, -1, -1, -1, -1}
#else
#  error "should not be here"
#endif

#ifndef SV2C_TYPE_CROAK
#  define SV2C_TYPE_CROAK croak("Panda::Date: cannot create/set/clone object - argument of unknown type passed")
#endif

namespace xs { namespace date {

Date* SV2C_DATE_FUNC (pTHX_ SV* arg, const Timezone* zone, Date* operand) {
#ifndef SV2C_CLONE
    ptime_t epoch = 0;
#endif
    
    if (SvOK(arg)) {
        if (SvROK(arg)) {
            if (sv_isobject(arg)) {
#ifndef SV2C_CLONE
                if (sv_isa(arg, DATE_CLASS)) {
                    SV2C_DATE_ACTION((Date *) SvIV(SvRV(arg)), zone);
                    return operand;
                }
                else SV2C_TYPE_CROAK;
#endif
            }
            else {
                SV* rarg = SvRV(arg);
                ptime_t vals[] = SV2C_DATE_DEFVALS;
                SV** ref;
                if (SvTYPE(rarg) == SVt_PVHV) {
                    HV* hash = (HV*) rarg;
                    
                    ref = hv_fetch(hash, "year", 4, 0);
                    if (ref != NULL) vals[0] = SvMIV(*ref);
                    ref = hv_fetch(hash, "month", 5, 0);
                    if (ref != NULL) vals[1] = SvMIV(*ref);
                    ref = hv_fetch(hash, "day", 3, 0);
                    if (ref != NULL) vals[2] = SvMIV(*ref);
                    ref = hv_fetch(hash, "hour", 4, 0);
                    if (ref != NULL) vals[3] = SvMIV(*ref);
                    ref = hv_fetch(hash, "min", 3, 0);
                    if (ref != NULL) vals[4] = SvMIV(*ref);
                    ref = hv_fetch(hash, "sec", 3, 0);
                    if (ref != NULL) vals[5] = SvMIV(*ref);
                    ref = hv_fetch(hash, "isdst", 5, 0);
                    if (ref != NULL) vals[6] = SvMIV(*ref);
                    
                    if (zone == NULL) {
                        ref = hv_fetch(hash, "tz", 2, 0);
                        if (ref != NULL) zone = tzget_required(aTHX_ *ref);
                    }
                }
                else if (SvTYPE(rarg) == SVt_PVAV) {
                    AV* array = (AV*) rarg;
                    I32 len = av_len(array);
                    for (int i = 0; i <= len; i++) {
                        ref = av_fetch(array, i, 0);
                        if (ref != NULL && SvOK(*ref)) vals[i] = SvMIV(*ref);
                    }
                } else {
                    SV2C_TYPE_CROAK;
                }

                SV2C_DATE_ACTION(vals[0], vals[1], vals[2], vals[3], vals[4], vals[5], vals[6], zone);
                return operand;                
            }
        }
#ifndef SV2C_CLONE
        else if (looks_like_number(arg)) {
            epoch = SvMIV(arg);
        }
        else {
            STRLEN len;
            const char* str = SvPV(arg, len);
            SV2C_DATE_ACTION(string_view(str, len), zone);
            return operand;
        }
#endif
    }

#ifdef SV2C_CLONE
    SV2C_TYPE_CROAK;
#else
    SV2C_DATE_ACTION(epoch, zone);
    return operand;
#endif
}

#ifdef SV2C_DATEREL_FUNC

DateRel* SV2C_DATEREL_FUNC (pTHX_ SV* arg, DateRel* operand) {
    if (!SvOK(arg)) {
        SV2C_DATEREL_ACTION(0,0,0,0,0,0);
        return operand;
    }
    
    ptime_t vals[] = {0, 0, 0, 0, 0, 0};

    if (SvROK(arg)) {
        if (sv_isobject(arg) && sv_isa(arg, DATEREL_CLASS)) {
            SV2C_DATEREL_ACTION((DateRel *) SvIV(SvRV(arg)));
            return operand;
        }
        else {
            SV* rarg = SvRV(arg);
            SV** ref;
            if (SvTYPE(rarg) == SVt_PVHV) {
                HV* hash = (HV*) rarg;
                ref = hv_fetch(hash, "year", 4, 0);
                if (ref != NULL) vals[0] = SvMIV(*ref);
                ref = hv_fetch(hash, "month", 5, 0);
                if (ref != NULL) vals[1] = SvMIV(*ref);
                ref = hv_fetch(hash, "day", 3, 0);
                if (ref != NULL) vals[2] = SvMIV(*ref);
                ref = hv_fetch(hash, "hour", 4, 0);
                if (ref != NULL) vals[3] = SvMIV(*ref);
                ref = hv_fetch(hash, "min", 3, 0);
                if (ref != NULL) vals[4] = SvMIV(*ref);
                ref = hv_fetch(hash, "sec", 3, 0);
                if (ref != NULL) vals[5] = SvMIV(*ref);
            }
            else if (SvTYPE(rarg) == SVt_PVAV) {
                AV* array = (AV*) rarg;
                I32 len = av_len(array);
                for (int i = 0; i <= len; i++) {
                    ref = av_fetch(array, i, 0);
                    if (ref != NULL) vals[i] = SvMIV(*ref);
                }
            }
            else {
                SV2C_TYPE_CROAK;
            }
            
            SV2C_DATEREL_ACTION(vals[0], vals[1], vals[2], vals[3], vals[4], vals[5]);
            return operand;                 
        }
    }
    else if (looks_like_number(arg)) {
        SV2C_DATEREL_ACTION(0, 0, 0, 0, 0, SvMIV(arg));
        return operand;
    }
    else {
        STRLEN len;
        const char* str = SvPV(arg, len);
        SV2C_DATEREL_ACTION(string_view(str, len));
        return operand;
    }
}

DateRel* SV2C_DATEREL_FUNC (pTHX_ SV* fromSV, SV* tillSV, DateRel* operand) {
    Date from((ptime_t) 0);
    Date till((ptime_t) 0);
    date_set(aTHX_ fromSV, NULL, &from);
    date_set(aTHX_ tillSV, NULL, &till);
    SV2C_DATEREL_ACTION(from.date(), till.date());
    return operand;
}

#endif

#ifdef SV2C_DATEINT_FUNC

DateInt* SV2C_DATEINT_FUNC (pTHX_ SV* arg, DateInt* operand) {
    if (SvOK(arg) && SvROK(arg)) {
        SV* argval = SvRV(arg);
        if (SvTYPE(argval) == SVt_PVAV) {
            AV* arr = (AV*) argval;
            SV** elemref1 = av_fetch(arr, 0, 0);
            SV** elemref2 = av_fetch(arr, 1, 0);
            if (elemref1 != NULL && elemref2 != NULL) return SV2C_DATEINT_FUNC(aTHX_ *elemref1, *elemref2, operand);
        }
    }
    else if (SvPOK(arg)) {
        STRLEN len;
        const char* str = SvPV(arg, len);
        SV2C_DATEINT_ACTION(string_view(str, len));
        return operand;
    }
    
    SV2C_TYPE_CROAK;
}

DateInt* SV2C_DATEINT_FUNC (pTHX_ SV* fromSV, SV* tillSV, DateInt* operand) {
    Date from((ptime_t) 0);
    Date till((ptime_t) 0);
    date_set(aTHX_ fromSV, NULL, &from);
    date_set(aTHX_ tillSV, NULL, &till);
    SV2C_DATEINT_ACTION(&from, &till);
    return operand;
}

#endif

}}
