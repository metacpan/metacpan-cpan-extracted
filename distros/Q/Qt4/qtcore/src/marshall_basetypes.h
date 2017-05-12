#ifndef MARSHALL_BASETYPES_H
#define MARSHALL_BASETYPES_H

template <class T> T* smoke_ptr(Marshall *m) { return (T*) m->item().s_voidp; }

template<> bool* smoke_ptr<bool>(Marshall *m) { return &m->item().s_bool; }
template<> signed char* smoke_ptr<signed char>(Marshall *m) { return &m->item().s_char; }
template<> unsigned char* smoke_ptr<unsigned char>(Marshall *m) { return &m->item().s_uchar; }
template<> short* smoke_ptr<short>(Marshall *m) { return &m->item().s_short; }
template<> unsigned short* smoke_ptr<unsigned short>(Marshall *m) { return &m->item().s_ushort; }
template<> int* smoke_ptr<int>(Marshall *m) { return &m->item().s_int; }
template<> unsigned int* smoke_ptr<unsigned int>(Marshall *m) { return &m->item().s_uint; }
template<> long* smoke_ptr<long>(Marshall *m) { 	return &m->item().s_long; }
template<> unsigned long* smoke_ptr<unsigned long>(Marshall *m) { return &m->item().s_ulong; }
template<> float* smoke_ptr<float>(Marshall *m) { return &m->item().s_float; }
template<> double* smoke_ptr<double>(Marshall *m) { return &m->item().s_double; }
template<> void* smoke_ptr<void>(Marshall *m) { return m->item().s_voidp; }

template <class T> T perl_to_primitive(SV*);
template <class T> SV* primitive_to_perl(T);

template <class T>
static void marshall_from_perl(Marshall *m) {
    (*smoke_ptr<T>(m)) = perl_to_primitive<T>(m->var());
}

template <class T>
static void marshall_to_perl(Marshall *m) {
    sv_setsv_mg(m->var(), primitive_to_perl<T>( *smoke_ptr<T>(m) ));
}

#include "marshall_primitives.h"
#include "marshall_complex.h"

// Special case marshallers

template<>
void marshall_from_perl<char*>(Marshall* m) {
    SV* sv = m->var();
    char* buf = perl_to_primitive<char*>(sv);
    m->item().s_voidp = buf;
    m->next();
    if(!m->type().isConst() && !SvREADONLY(sv)) {
        sv_setpv(sv, buf);
    }
}

template<>
void marshall_to_perl<char*>(Marshall* m) {
    char* sv = (char*)m->item().s_voidp;
    SV* obj = newSV(0);
    if(sv)
        sv_setpv(obj, sv);
    else
        sv_setsv( obj, &PL_sv_undef );
    
    if(m->cleanup())
        delete[] sv;

    sv_setsv_mg(m->var(), obj);
}

template<>
void marshall_from_perl<char*&>(Marshall* m) {
    char** buf = new char*;
    SV* sv = m->var();
    *buf = perl_to_primitive<char*>(sv);
    m->item().s_voidp = (void*)buf;
    m->next();
    sv_setpv( SvRV(sv), *(char**)buf );
}

template<>
void marshall_to_perl<char*&>(Marshall* m) {
    m->unsupported();
}

template <>
void marshall_from_perl<unsigned char*>(Marshall *m) {
    m->item().s_voidp = perl_to_primitive<unsigned char*>(m->var());
}

template <>
void marshall_to_perl<unsigned char *>(Marshall *m)
{
	m->unsupported();
}

#endif //MARSHALL_BASETYPES_H
