#ifndef MARSHALL_PRIMITIVES_H
#define MARSHALL_PRIMITIVES_H

template <>
bool perl_to_primitive<bool>(SV* sv) {
    if ( !SvOK(sv) )
        return false;
    if ( SvROK(sv) ) // Because they could pass in a Qt::Bool
        return SvTRUE( SvRV(sv) ) ? true : false;
    return SvTRUE(sv) ? true : false;
}
template <>
SV* primitive_to_perl<bool>(bool sv) {
    return boolSV(sv);
}

//-----------------------------------------------------------------------------
template <>
signed char perl_to_primitive<signed char>(SV *sv) {
    UNTESTED_HANDLER("perl_to_primitive<signed char>");
    if ( !SvOK(sv) )
        return 0;
    if ( SvIOK( sv ) )
        return (char)SvIV(sv);
    return (char)*SvPV_nolen(sv);
}
template <>
SV *primitive_to_perl<signed char>(signed char sv) {
    return newSViv(sv);
}

//-----------------------------------------------------------------------------
template <>
unsigned char perl_to_primitive<unsigned char>(SV *sv) {
    if ( !SvOK(sv) )
        return 0;
    if ( SvROK(sv) )
        sv = SvRV(sv);
    if ( SvIOK( sv ) )
        return (unsigned char)SvIV(sv);
    return (unsigned char)*SvPV_nolen(sv);
}
template <>
SV *primitive_to_perl<unsigned char>(unsigned char sv) {
    return newSViv(sv);
}

//-----------------------------------------------------------------------------
template <>
short perl_to_primitive<short>(SV *sv) {
    if ( !SvOK(sv) )
        return 0;
    if ( SvROK(sv) )
        sv = SvRV(sv);
    return (short)SvIV(sv);
}
template <>
SV *primitive_to_perl<short>(short sv) {
    UNTESTED_HANDLER("primitive_to_perl<short>");
    return newSViv(sv);
}

//-----------------------------------------------------------------------------
template <>
unsigned short perl_to_primitive<unsigned short>(SV *sv) {
    if ( !SvOK(sv) )
        return 0;
    if ( SvROK(sv) )
        sv = SvRV(sv);
    return (unsigned short)SvIV(sv);
}
template <>
SV *primitive_to_perl<unsigned short>(unsigned short sv) {
    return newSViv((unsigned short) sv);
}

//-----------------------------------------------------------------------------
template<>
int perl_to_primitive<int>(SV* sv) {
    if ( !SvOK(sv) )
        return 0;
    if ( SvROK(sv) ) // Because enums can be used as ints
        return SvIV( SvRV(sv) );
    return SvIV(sv);
}

template<>
SV* primitive_to_perl<int>(int sv) {
    return newSViv(sv);
}

//-----------------------------------------------------------------------------
template <>
unsigned int perl_to_primitive<unsigned int>(SV* sv) {
    if ( !SvOK(sv) )
        return 0;
    if ( SvROK(sv) )
        return SvUV( SvRV(sv) );
    return SvUV(sv);
}
template <>
SV* primitive_to_perl<unsigned int>(unsigned int sv) {
    return newSVuv(sv);
}

//-----------------------------------------------------------------------------
template <>
long perl_to_primitive<long>(SV *sv) {
    if ( !SvOK(sv) )
        return 0;
    if ( SvROK(sv) )
        sv = SvRV(sv);
    return (long) SvIV(sv);
}
template <>
SV *primitive_to_perl<long>(long sv) {
    return newSViv(sv);
}

//-----------------------------------------------------------------------------
template <>
unsigned long perl_to_primitive<unsigned long>(SV *sv) {
    UNTESTED_HANDLER("perl_to_primitive<unsigned long>");
    if ( !SvOK(sv) ) {
        return 0;
    //} else if (TYPE(sv) == T_OBJECT) {
        //return (unsigned long) NUM2ULONG(rb_funcall(qt_internal_module, rb_intern("get_qinteger"), 1, sv));
    } else {
        return (unsigned long) SvIV(sv);
    }
}

template <>
SV *primitive_to_perl<unsigned long>(unsigned long sv) {
    UNTESTED_HANDLER("primitive_to_perl<unsigned long>");
    return newSViv(sv);
}

//-----------------------------------------------------------------------------
template <>
long long perl_to_primitive<long long>(SV *sv) {
    if ( !SvOK(sv) ) {
        return 0;
    } else {
        return SvIV(sv);
    }
}
template <>
SV *primitive_to_perl<long long>(long long sv) {
    return newSViv(sv);
}

//-----------------------------------------------------------------------------
template <>
unsigned long long perl_to_primitive<unsigned long long>(SV *sv) {
    UNTESTED_HANDLER("perl_to_primitive<unsigned long long>");
    if ( !SvOK(sv) ) {
        return 0;
    } else {
        return (unsigned long long)SvIV(sv);
    }
}
template <>
SV *primitive_to_perl<unsigned long long>(unsigned long long sv) {
    UNTESTED_HANDLER("primitive_to_perl<unsigned long long>");
    return newSViv(sv);
}

//-----------------------------------------------------------------------------
template <>
float perl_to_primitive<float>(SV *sv) {
    UNTESTED_HANDLER("perl_to_primitive<float>");
    if ( !SvOK(sv) ) {
        return 0.0;
    } else {
        return (float) SvNV(sv);
    }
}
template <>
SV *primitive_to_perl<float>(float sv) {
    UNTESTED_HANDLER("primitive_to_perl<float>");
    return newSVnv((double) sv);
}

//-----------------------------------------------------------------------------
template <>
double perl_to_primitive<double>(SV* sv) {
    if ( !SvOK(sv) )
        return 0;
    return SvNV(sv);
}
template <>
SV* primitive_to_perl<double>(double sv) {
    return newSVnv(sv);
}

//-----------------------------------------------------------------------------
template<>
char* perl_to_primitive<char*>( SV* sv ) {
    if( !SvOK(sv) )
        return 0;
    if( SvROK(sv) )
        sv = SvRV(sv);
    return SvPV_nolen(sv);
}

//-----------------------------------------------------------------------------
template <>
unsigned char* perl_to_primitive<unsigned char *>(SV *sv) {
    if ( !SvOK(sv) )
        return 0;

    return (unsigned char*)SvPV_nolen(sv);
}

//-----------------------------------------------------------------------------
template <>
SV *primitive_to_perl<int*>(int* sv) {
    UNTESTED_HANDLER("primitive_to_perl<int*>");
    if ( !sv )
        return &PL_sv_undef;

    return primitive_to_perl<int>(*sv);
}

//-----------------------------------------------------------------------------
#if defined(Q_OS_WIN32)
template <>
WId perl_to_primitive<WId>(SV *sv) {
    UNTESTED_HANDLER("perl_to_primitive<WId>");
    if ( !SvOK(sv) )
        return 0;
#ifdef Q_WS_MAC32
    return (WId) SvIV(sv);
#else
    return (WId) SvIV(sv);
#endif
}

template <>
SV *primitive_to_perl<WId>(WId sv) {
    UNTESTED_HANDLER("primitive_to_perl<WId>");
#ifdef Q_WS_MAC32
    return newSViv((unsigned long) sv);
#else
    return newSViv((unsigned long) sv);
#endif
}

//-----------------------------------------------------------------------------
template <>
Q_PID perl_to_primitive<Q_PID>(SV *sv) {
    UNTESTED_HANDLER("perl_to_primitive<Q_PID>");
    if ( !SvOK(sv) )
        return 0;

    return (Q_PID) SvIV(sv);
}
template <>
SV *primitive_to_perl<Q_PID>(Q_PID sv) {
    UNTESTED_HANDLER("primitive_to_perl<Q_PID>");
    return newSViv((unsigned long) sv);
}

#endif

#endif //MARSHALL_PRIMITIVES_H
