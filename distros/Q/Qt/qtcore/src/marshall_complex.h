#ifndef MARSHALL_COMPLEX_H
#define MARSHALL_COMPLEX_H

//-----------------------------------------------------------------------------
template <>
void marshall_from_perl<long long>(Marshall *m) {
    SV *obj = m->var();
    m->item().s_voidp = new long long;
    *(long long *)m->item().s_voidp = perl_to_primitive<long long>(obj);

    m->next();

    if(m->cleanup() && m->type().isConst()) {
        delete (long long int *) m->item().s_voidp;
    }	
}

//-----------------------------------------------------------------------------
template <>
void marshall_from_perl<unsigned long long>(Marshall *m) {
    UNTESTED_HANDLER("marshall_from_perl<unsigned long long>");
    SV *obj = m->var();
    m->item().s_voidp = new unsigned long long;
    *(long long *)m->item().s_voidp = perl_to_primitive<unsigned long long>(obj);

    m->next();

    if(m->cleanup() && m->type().isConst()) {
        delete (long long int *) m->item().s_voidp;
    }	
}

//-----------------------------------------------------------------------------
template<>
void marshall_from_perl<int*>(Marshall* m) {
    SV *sv = m->var();
    if ( !SvOK(sv) ) {
        sv_setiv( sv, 0 );
    }
    if ( SvROK(sv) ) {
        sv = SvRV(sv);
    }

    if ( !SvIOK(sv) ) {
        sv_setiv( sv, 0 );
    }

    int *i = new int(SvIV(sv));
    m->item().s_voidp = i;
    m->next();

    if(m->cleanup() && m->type().isConst()) {
        delete i;
    } else {
        sv_setiv(sv, *i);
    }
}
template<>
void marshall_to_perl<int*>(Marshall* m) {
    UNTESTED_HANDLER("marshall_to_perl<int*>");
    int* sv = (int*)m->item().s_voidp;
    if( !sv ) {
        sv_setsv( m->var(), &PL_sv_undef );
        return;
    }

    sv_setiv( m->var(), *sv );
    m->next();
    if( !m->type().isConst() )
        *sv = SvIV(m->var());
}

//-----------------------------------------------------------------------------
template <>
void marshall_from_perl<unsigned int *>(Marshall *m) {
    UNTESTED_HANDLER("marshall_from_perl<unsigned int *>");
    SV *sv = m->var();

    if ( !SvOK(sv) ) {
        m->item().s_voidp = 0;
        return;
    }
    if ( SvROK(sv) ) {
        sv = SvRV(sv);
    }
    unsigned int *i = new unsigned int(SvUV(sv));
    m->item().s_voidp = i;
    m->next();

    // XXX Is this right?
    if(m->cleanup() && m->type().isConst()) {
        delete i;
    } else {
        sv_setuv(sv, *i);
    }
}
template <>
void marshall_to_perl<unsigned int *>(Marshall *m) {
    unsigned int *ip = (unsigned int*) m->item().s_voidp;
    SV *sv = m->var();
    if (ip == 0) {
        sv_setsv( sv, &PL_sv_undef );
        return;
    }

    sv_setiv( m->var(), *ip );
    m->next();
    if(!m->type().isConst())
        *ip = SvIV(m->var());
}

//-----------------------------------------------------------------------------
template<>
void marshall_from_perl<short*>(Marshall* m) {
    SV *sv = m->var();
    if ( !SvOK(sv) ) {
        sv_setiv( sv, 0 );
    }
    if ( SvROK(sv) ) {
        sv = SvRV(sv);
    }

    if ( !SvIOK(sv) ) {
        sv_setiv( sv, 0 );
    }

    short *i = new short(SvIV(sv));
    m->item().s_voidp = i;
    m->next();

    if(m->cleanup() && m->type().isConst()) {
        delete i;
    } else {
        sv_setiv(sv, *i);
    }
}
template<>
void marshall_to_perl<short*>(Marshall* m) {
    UNTESTED_HANDLER("marshall_to_perl<short*>");
    short* sv = (short*)m->item().s_voidp;
    if( !sv ) {
        sv_setsv( m->var(), &PL_sv_undef );
        return;
    }

    sv_setiv( m->var(), *sv );
    m->next();
    if( !m->type().isConst() )
        *sv = SvIV(m->var());
}

//-----------------------------------------------------------------------------
template<>
void marshall_from_perl<unsigned short*>(Marshall* m) {
    SV *sv = m->var();
    if ( !SvOK(sv) ) {
        sv_setiv( sv, 0 );
    }
    if ( SvROK(sv) ) {
        sv = SvRV(sv);
    }

    if ( !SvIOK(sv) ) {
        sv_setiv( sv, 0 );
    }

    unsigned short *i = new unsigned short(SvIV(sv));
    m->item().s_voidp = i;
    m->next();

    if(m->cleanup() && m->type().isConst()) {
        delete i;
    } else {
        sv_setiv(sv, *i);
    }
}
template<>
void marshall_to_perl<unsigned short*>(Marshall* m) {
    UNTESTED_HANDLER("marshall_to_perl<unsigned short*>");
    unsigned short* sv = (unsigned short*)m->item().s_voidp;
    if( !sv ) {
        sv_setsv( m->var(), &PL_sv_undef );
        return;
    }

    sv_setiv( m->var(), *sv );
    m->next();
    if( !m->type().isConst() )
        *sv = SvIV(m->var());
}

//-----------------------------------------------------------------------------
template <>
void marshall_from_perl<bool *>(Marshall *m) {
    UNTESTED_HANDLER("marshall_from_perl<bool *>");
    SV *sv = m->var();
    bool * b = new bool;

    *b = SvTRUE(sv);
    m->item().s_voidp = b;
    m->next();

    if(m->cleanup() && m->type().isConst()) {
        delete b;
    }
    else {
        sv_setsv( m->var(), *b ? &PL_sv_yes : & PL_sv_no );
    }
}

template <>
void marshall_to_perl<bool *>(Marshall *m) {
    UNTESTED_HANDLER("marshall_to_perl<bool *>");
    bool *ip = (bool*)m->item().s_voidp;
    if(!ip) {
        sv_setsv( m->var(), &PL_sv_undef );
        return;
    }
    sv_setiv( m->var(), *ip?1:0);
    m->next();
    if(!m->type().isConst())
        *ip = SvTRUE(m->var()) ? true : false;
}

#endif // MARSHALL_COMPLEX_H
