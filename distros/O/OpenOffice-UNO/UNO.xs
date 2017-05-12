/*************************************************************************
 *
 *  $RCSfile$
 *
 *  $Revision$
 *
 *  last change: $Author$ $Date$
 *
 *  The Contents of this file are made available subject to the terms of
 *  either of the following licenses
 *
 *         - GNU Lesser General Public License Version 2.1
 *         - Sun Industry Standards Source License Version 1.1
 *
 *  Sun Microsystems Inc., October, 2000
 *
 *  GNU Lesser General Public License Version 2.1
 *  =============================================
 *  Copyright 2000 by Sun Microsystems, Inc.
 *  901 San Antonio Road, Palo Alto, CA 94303, USA
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License version 2.1, as published by the Free Software Foundation.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston,
 *  MA  02111-1307  USA
 *
 *
 *  Sun Industry Standards Source License Version 1.1
 *  =================================================
 *  The contents of this file are subject to the Sun Industry Standards
 *  Source License Version 1.1 (the "License"); You may not use this file
 *  except in compliance with the License. You may obtain a copy of the
 *  License at http://www.openoffice.org/license.html.
 *
 *  Software provided under this License is provided on an "AS IS" basis,
 *  WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING,
 *  WITHOUT LIMITATION, WARRANTIES THAT THE SOFTWARE IS FREE OF DEFECTS,
 *  MERCHANTABLE, FIT FOR A PARTICULAR PURPOSE, OR NON-INFRINGING.
 *  See the License for the specific provisions governing your rights and
 *  obligations concerning the Software.
 *
 *  The Initial Developer of the Original Code is: Ralph Thomas
 *
 *   Copyright: 2000 by Sun Microsystems, Inc.
 *
 *   All Rights Reserved.
 *
 *   Contributor(s): Bustamam Harun
 *
 *
 ************************************************************************/

#define PERL_NO_GET_CONTEXT
#include "UNO.h"
#include "ppport.h"

#undef realloc

// UNO Runtime Instance
static PerlRT UNOInstance;

// helper functions
static void
UNOCroak(pTHX_ UNO_XAny any ) {
    SV *exc = AnyToSV(any);
    SV *errsv = get_sv("@", TRUE);
    sv_replace(errsv, exc);
    Perl_croak(aTHX_ Nullch);
}

static void
UNOCroak(pTHX_ ::com::sun::star::uno::Exception& e ) {
    UNOCroak(aTHX_ makeAny(e));
}

UNO::UNO() {
    ctx = NULL;
}

UNO::~UNO() {
    UNOInstance.prtInitialized = FALSE;
}

void
UNO::createServices() {
    UNOInstance.ssf = UNO_XSingleServiceFactory(
	UNOInstance.localCtx->getServiceManager()->createInstanceWithContext(
	    UNO_INVOCATION_OBJECT, UNOInstance.localCtx ), ::com::sun::star::uno::UNO_QUERY );

    if( ! UNOInstance.ssf.is() )
	throw ::com::sun::star::uno::RuntimeException(
	    ::rtl::OUString( RTL_CONSTASCII_USTRINGPARAM( "UNO: couldn't instantiate Single Service Manager" )),
		UNO_XInterface () );

    UNOInstance.typecvt = UNO_XTypeConverter(
	UNOInstance.localCtx->getServiceManager()->createInstanceWithContext(
	    UNO_TYPECONVERTER_OBJECT, UNOInstance.localCtx ), ::com::sun::star::uno::UNO_QUERY );

    if( ! UNOInstance.typecvt.is() )
	throw ::com::sun::star::uno::RuntimeException(
	    ::rtl::OUString( RTL_CONSTASCII_USTRINGPARAM( "UNO: couldn't instantiate typeconverter service" )),
		UNO_XInterface () );

    UNOInstance.reflection = UNO_XIdlReflection (
        UNOInstance.localCtx->getServiceManager()->createInstanceWithContext(
	    UNO_COREREFLECTION_OBJECT, UNOInstance.localCtx ), ::com::sun::star::uno::UNO_QUERY );

    if( ! UNOInstance.reflection.is() )
	throw ::com::sun::star::uno::RuntimeException(
	    ::rtl::OUString( RTL_CONSTASCII_USTRINGPARAM( "UNO: couldn't instantiate reflection service" )),
		UNO_XInterface () );
}

UNO_Any::UNO_Any(char *sname) {
    ::rtl::OUString soname = ::rtl::OUString::createFromAscii(sname);

    UNO_XAny tstruct;
    UNO_XIdlClass idlclass(UNOInstance.reflection->forName(soname), ::com::sun::star::uno::UNO_QUERY);
    if (! idlclass.is()) {
	croak("UNO: failed to create IdlClass");
    }

    idlclass->createObject(tstruct);
    pany = tstruct;
}

UNO_Struct::UNO_Struct() {
}

UNO_Struct::UNO_Struct(char *sname) : UNO_Any(sname) {
    UNO_SAny args(1);
    UNO_XInterface tif;

    args[0] <<= pany;
    tif = UNOInstance.ssf->createInstanceWithArguments(args);
    if ( ! tif.is() ) {
	croak("UNO: Proxy creation failed");
    }

    xinvoke = UNO_XInvocation2(tif, ::com::sun::star::uno::UNO_QUERY);

    if ( ! xinvoke.is() ) {
	croak("UNO: XInvocation2 failed to be created");
    }

    TypeString = strdup(sname);
}

UNO_Struct::UNO_Struct(UNO_XAny tany) {
    UNO_SAny args(1);
    UNO_XInterface tif;

    args[0] <<= tany;
    tif = UNOInstance.ssf->createInstanceWithArguments(args);
    if ( ! tif.is() ) {
	croak("UNO: Proxy creation failed");
    }

    xinvoke = UNO_XInvocation2(tif, ::com::sun::star::uno::UNO_QUERY);

    if ( ! xinvoke.is() ) {
	croak("UNO: XInvocation2 failed to be created");
    }

    pany = tany;
}

UNO_Struct::~UNO_Struct() {
}

void
UNO_Struct::set(char *mname, SV *value) {
    UNO_XAny aval;

    if ( ! xinvoke.is() ) {
	croak("UNO: Invalid XInvocation2 ref");
    }

    aval = SVToAny(value);

    ::rtl::OUString membername = ::rtl::OUString::createFromAscii(mname);
    if ( xinvoke->hasProperty(membername) ) {
	xinvoke->setValue( membername, aval );
    } else {
	croak("Member name: \"%s\" does not exists", mname);
    }
}

SV *
UNO_Struct::get(char *mname) {
    UNO_XAny aval;

    if ( ! xinvoke.is() ) {
	croak("UNO: Invalid XInvocation2 ref");
    }

    ::rtl::OUString membername = ::rtl::OUString::createFromAscii(mname);
    if ( xinvoke->hasProperty(membername) ) {
	aval = xinvoke->getValue( membername );
    } else {
	croak("Member name: \"%s\" does not exists", mname);
    }
    return AnyToSV(aval);
}

UNO_Interface *
UNO::createInitialComponentContext(char *iniFile) {
    UNOInstance.localCtx = cppu::defaultBootstrap_InitialComponentContext(
	::rtl::OUString::createFromAscii(iniFile) );
    UNOInstance.prtInitialized = TRUE;
    createServices();

    UNO_XAny tany;
    tany <<= UNOInstance.localCtx;

    ctx = new UNO_Interface(tany);
    return ctx;
}

UNO_Interface *
UNO::createInitialComponentContext() {
    UNOInstance.localCtx = cppu::defaultBootstrap_InitialComponentContext();
    UNOInstance.prtInitialized = TRUE;
    createServices();

    UNO_XAny tany;
    tany <<= UNOInstance.localCtx;

    ctx = new UNO_Interface(tany);
    return ctx;
}

UNO_Struct *
UNO::createIdlStruct(char *name) {
    return new UNO_Struct(name);
}

UNO_Interface::UNO_Interface() {
}

UNO_Interface::UNO_Interface(UNO_XAny thisif) {
    dTHX;
    UNO_SAny args(1);
    UNO_XInterface tif;

    // Check if ref is valid
    UNO_XInterface cif;
    thisif >>= cif;
    if ( ! cif.is() ) {
	croak("UNO: invalid interface ref");
    }

    args[0] <<= thisif;
    try {
        tif = UNOInstance.ssf->createInstanceWithArguments(args);
    } catch ( ::com::sun::star::uno::Exception& e ) {
	UNOCroak(aTHX_ e);
    }        
    if ( ! tif.is() ) {
	croak("UNO: Proxy creation failed");
    }

    xinvoke = UNO_XInvocation2(tif, ::com::sun::star::uno::UNO_QUERY);

    if ( ! xinvoke.is() ) {
	croak("UNO: XInvocation2 failed to be created");
    }

    pany = thisif;
}

SV *
UNO_Interface::invoke(char *method, UNO_SAny args) {
    dTHX;
    I32 i;

    ::rtl::OUString mstr = ::rtl::OUString::createFromAscii(method);
    if ( ! xinvoke.is() ) {
	croak("UNO: Invalid XInvocation2 ref");
    }

    if ( ! xinvoke->hasMethod(mstr) ) {
	croak("UNO: Method: \"%s\" is NOT defined", method);
    }

    UNO_SAny oargs;
    UNO_SShort oidx;
    UNO_XAny ret_val;

    try {
	ret_val = xinvoke->invoke(mstr, args, oidx, oargs);
    } catch ( ::com::sun::star::reflection::InvocationTargetException& e ) {
	UNOCroak(aTHX_ e.TargetException);
    } catch ( ::com::sun::star::lang::WrappedTargetRuntimeException& e ) {
	UNOCroak(aTHX_ e.TargetException);
    } catch ( ::com::sun::star::uno::Exception& e ) {
	UNOCroak(aTHX_ e);
    }

    SV *retval = Nullsv;
    if ( oargs.getLength() > 0 ) {
	AV *av;

	av = newAV();

	// Store return value
	SV *trv = AnyToSV(ret_val);
	av_store(av, 0, trv);

	// Convert output parameters
	av_extend(av, oargs.getLength()+1);
	for ( int i = 0; i < oargs.getLength(); i++ ) {
	    SV *tav = AnyToSV(UNOInstance.typecvt->convertTo(oargs[i], oargs[i].getValueType()));
	    av_store(av, i+1, tav);
	}
	retval = (SV *)av;
    } else {
	// Convert return value
	retval = AnyToSV(ret_val);
    }

    return retval;
}

void
UNO_Any::assignAny(UNO_XAny any) {
	pany <<= any;
}

UNO_XAny
UNO_Any::getAny() {
	return pany;
}

static void
UNOExit(pTHX_ void *pi) {
    // Clean up PerlRT
    ((PerlRT *)pi)->reflection.clear();
    ((PerlRT *)pi)->typecvt.clear();
    ((PerlRT *)pi)->ssf.clear();
    ((PerlRT *)pi)->localCtx.clear();
}

void
Bootstrap(pTHX) {
    dSP;

    UNOInstance.prtInitialized = 0;

    perl_atexit(UNOExit, (void *)&UNOInstance);
}

UNO_SAny
AVToSAny(AV *parr) {
    dTHX;
    UNO_SAny aany;

    if ( av_len(parr) >= 0 ) {
	aany.realloc(av_len(parr) + 1);
	for ( int i = 0; i <= av_len(parr); i++ ) {
	    aany[i] = SVToAny(*av_fetch(parr, i, FALSE));
	}
    }
    return aany;
}

UNO_XAny
HVToStruct(HV *hv) {
    dTHX;
    UNO_XAny a;

    SV *smagic = newSVpv(UNO_STRUCT_NAME_KEY, strlen(UNO_STRUCT_NAME_KEY));
    if ( hv_exists_ent(hv, smagic, 0) ) {
	char *key;
	I32 klen;
	SV *val;

	SV **pname = hv_fetch(hv, UNO_STRUCT_NAME_KEY, strlen(UNO_STRUCT_NAME_KEY), FALSE);
	char *cname = SvPVX(*pname);

	::rtl::OUString sname = ::rtl::OUString::createFromAscii(cname);

	UNO_XMaterialHolder mholder( UNOInstance.ssf, ::com::sun::star::uno::UNO_QUERY );
	if ( mholder.is( ) )
		a = mholder->getMaterial();

	// Iterate through hash
	hv_iterinit(hv);
	while (val = hv_iternextsv(hv, (char **) &key, &klen)) {
	    if ( strcmp(key, UNO_STRUCT_NAME_KEY) ) {
		UNO_XAny tany;

		tany = SVToAny(val);
	    }
	}
    }
    return a;
}

UNO_XAny
SVToAny(SV *svp) {
    dTHX;
    UNO_XAny a;

    SvGETMAGIC(svp);

    if ( !SvOK(svp) )
	return a;

    if ( SvROK(svp) ) {
	switch ( SvTYPE(SvRV(svp)) ) {
	    case SVt_PVAV: {
		AV *parr = (AV *)SvRV(svp);
		UNO_SAny aany = AVToSAny(parr);
		a <<= aany;

		break;
	    }

	    case SVt_PVHV: {
		HV *hv = (HV *)SvRV(svp);
		UNO_XAny aany = HVToStruct(hv);
		a <<= aany;

		break;
	    }

	    case SVt_RV:
	    case SVt_PVMG: {
		long otype;
		IV tmp = SvIV((SV*)SvRV(svp));
		UNO_Any *tptr = INT2PTR(UNO_Any *,tmp);

		UNO_XAny tany = tptr->getAny();

		switch (tany.getValueTypeClass()) {
		    case typelib_TypeClass_STRUCT: {
			UNO_XMaterialHolder mh(tptr->xinvoke, ::com::sun::star::uno::UNO_QUERY);
			if( mh.is() ) {
			    a = mh->getMaterial();
			} else {
			    croak("Error getting Material");
			}
			break;
		    }

		    case typelib_TypeClass_SEQUENCE:
		    case typelib_TypeClass_INTERFACE: {
			a <<= tany;
			break;
		    }

		    case typelib_TypeClass_BOOLEAN:
		    case typelib_TypeClass_LONG:
		    case typelib_TypeClass_HYPER: {
			a = tany;
			break;
		    }

		    default: {
			croak("Unsupported ref: %d", tany.getValueTypeClass());
			break;
		    }
		}

		break;
	    }
	}
    } else if ( SvNOK(svp) ) {
	a <<= (double) SvNVX(svp);
    } else if (SvIOK(svp) ) {
	a <<= (long) SvIVX(svp);
    } else if (SvPOK(svp) ) {
	// Extract String
	char *tstr = SvPVX(svp);
	::rtl::OUString ostr = ::rtl::OUString(tstr, SvCUR(svp), SvUTF8(svp) ? RTL_TEXTENCODING_UTF8 : RTL_TEXTENCODING_ISO_8859_1 );
	a <<= ostr;
    }

    return a;
}

AV *
SAnyToAV(UNO_SAny sa) {
    dTHX;
    AV *av;

    av = newAV();
    av_extend(av, sa.getLength());
    for ( int i = 0; i < sa.getLength(); i++ ) {
	SV *tav = AnyToSV(UNOInstance.typecvt->convertTo(sa[i], sa[i].getValueType()));
	av_store(av, i, tav);
    }
    return av;
}

SV *
AnyToSV(UNO_XAny a) {
    dTHX;
    SV *ret;

    ret = Nullsv;

    switch (a.getValueTypeClass()) {
	case typelib_TypeClass_VOID: {
	    ret = Nullsv;
	    break;
	}

	case typelib_TypeClass_CHAR: {
	    sal_Unicode c = *(sal_Unicode*)a.getValue();
	    ret = newSViv(c);
	    break;
	}

	case typelib_TypeClass_BOOLEAN: {
	    sal_Bool b;
	    a >>= b;
	    ret = b ? &PL_sv_yes : &PL_sv_no;
	    break;
	}

	case typelib_TypeClass_BYTE:
	case typelib_TypeClass_SHORT:
	case typelib_TypeClass_UNSIGNED_SHORT: 
	case typelib_TypeClass_LONG: {
	    long l;
	    a >>= l;
	    ret = newSViv(l);
	    break;
	}

	case typelib_TypeClass_UNSIGNED_LONG: { 
	    unsigned long l;
	    a >>= l;
	    ret = newSVuv(l);
	    break;
	} 

	case typelib_TypeClass_HYPER: {
	    sal_Int64 l;
	    a >>= l;
	    ret = newSViv(l);
	    break;
	}

	case typelib_TypeClass_UNSIGNED_HYPER: {
	    sal_uInt64 l;
	    a >>= l;
	    ret = newSVuv(l);
	    break;
	}

	case typelib_TypeClass_FLOAT: {
	    float f;
	    a >>= f;
	    ret = newSVnv(f);
	    break;
	}

	case typelib_TypeClass_DOUBLE: {
	    double d;
	    a >>= d;
	    ret = newSVnv(d);
	    break;
	}

	case typelib_TypeClass_STRING: {
	    ::rtl::OUString tmp_ostr;
	    a >>= tmp_ostr;

	    ::rtl::OString o = ::rtl::OUStringToOString(tmp_ostr, RTL_TEXTENCODING_UTF8);

	    ret = newSVpvn(o.getStr(), o.getLength());
	    SvUTF8_on(ret);
	    break;
	}

	case typelib_TypeClass_TYPE: {
	    ::com::sun::star::uno::Type t;
	    a >>= t;
	    ::rtl::OString o = ::rtl::OUStringToOString( t.getTypeName(), RTL_TEXTENCODING_ASCII_US );
	    ret = SvRV(newSVpv(o.getStr(), (com::sun::star::uno::TypeClass)t.getTypeClass()));
	    break;
	}

	case typelib_TypeClass_ANY: {
	    croak("Any2SV: ANY type not supported yet");
	    break;
	}

	case typelib_TypeClass_ENUM: {
	    croak("Any2SV: ENUM type not supported yet");
	    break;
	}

	case typelib_TypeClass_EXCEPTION: {
	    UNO_Struct *tret = new UNO_Struct(a);
	    SV *mret = sv_newmortal();
	    ret = newRV_inc(mret);
	    sv_setref_pv(ret, "OpenOffice::UNO::Exception", (void *)tret);
	    break;
	}

	case typelib_TypeClass_STRUCT: {
	    UNO_Struct *tret = new UNO_Struct(a);
	    SV *mret = sv_newmortal();
	    ret = newRV_inc(mret);
	    sv_setref_pv(ret, "OpenOffice::UNO::Struct", (void *)tret);
	    break;
	}

	case typelib_TypeClass_SEQUENCE: {
	    UNO_SAny sa;
	    UNOInstance.typecvt->convertTo(a, ::getCppuType(&sa)) >>= sa;
	    ret = newRV_noinc((SV *)SAnyToAV(sa));
	    break;
	}

	case typelib_TypeClass_INTERFACE: {
	    UNO_Interface *tret = new UNO_Interface(a);
	    SV *mret = sv_newmortal();
	    ret = newRV_inc(mret);
	    sv_setref_pv(ret, "OpenOffice::UNO::Interface", (void *)tret);
	    break;
	}

	default: {
	    croak("Any2SV: Error Unknown Any type");
	    ret = Nullsv;
	    break;
	}
    }
    return ret;
}

UNO_Boolean::UNO_Boolean() {
    sal_Bool b = sal_False;
    pany = UNO_XAny(&b, getBooleanCppuType());
    bvalue = sal_False;
}

UNO_Boolean::UNO_Boolean(SV *bval) {
    dTHX;
    sal_Bool b = (sal_Bool)SvTRUE(bval);
    pany = UNO_XAny(&b, getBooleanCppuType());
    bvalue = b;
}

UNO_Boolean::~UNO_Boolean() {
}

UNO_Int32::UNO_Int32() {
    sal_Int32 i = 0;
    pany = UNO_XAny(&i, getCppuType(&i));
    ivalue = 0;
}

UNO_Int32::UNO_Int32(SV *ival) {
    dTHX;
    sal_Int32 i = (sal_Int32)SvIV(ival);
    pany = UNO_XAny(&i, getCppuType(&i));
    ivalue = i;
}

UNO_Int32::~UNO_Int32() {
}

UNO_Int64::UNO_Int64() {
    sal_Int64 i = 0;
    pany = UNO_XAny(&i, getCppuType(&i));
    ivalue = 0;
}

UNO_Int64::UNO_Int64(SV *ival) {
    dTHX;
    sal_Int64 i = (sal_Int64)SvIV(ival);
    pany = UNO_XAny(&i, getCppuType(&i));
    ivalue = i;
}

UNO_Int64::~UNO_Int64() {
}

MODULE = OpenOffice::UNO     	PACKAGE = OpenOffice::UNO	PREFIX = UNO_

PROTOTYPES: DISABLE

BOOT:
    Bootstrap(aTHX);

UNO *
UNO::new(...)
CODE:
{
    RETVAL = new UNO();
}
OUTPUT:
    RETVAL

void
UNO::DESTROY(...)
CODE:
{
    delete(THIS);
}

UNO_Interface *
UNO::createInitialComponentContext(...)
CODE:
{
    if ( items == 1 ) {
	RETVAL = THIS->createInitialComponentContext();
    } else if ( items == 2 ) {
	char *iniFile;
	STRLEN len;

	iniFile = SvPV(ST(1), len);
	RETVAL = THIS->createInitialComponentContext(iniFile);
    }
}
OUTPUT:
    RETVAL

UNO_Struct *
UNO::createIdlStruct(...)
CODE:
{
    char *name;
    STRLEN len;

    name = SvPV(ST(1), len);
    UNO_Struct *tret = THIS->createIdlStruct(name);
    RETVAL = tret;
}
OUTPUT:
    RETVAL

MODULE = OpenOffice::UNO	PACKAGE = OpenOffice::UNO::Any	PREFIX = UNO_

UNO_Any *
UNO_Any::new(type, value)
    char *type
    SV *value
CODE:
{
    UNO_Any *any = new UNO_Any(type);
    UNO_XAny from = SVToAny(value);

    ::com::sun::star::uno::Type t = any->getAny().getValueType();
    try {
        any->assignAny(UNOInstance.typecvt->convertTo(from, t));
    } catch(::com::sun::star::uno::Exception& e) {
        UNOCroak(aTHX_ e);
    }

    RETVAL = any;
}
OUTPUT:
    RETVAL

MODULE = OpenOffice::UNO	PACKAGE = OpenOffice::UNO::Interface	PREFIX = UNO_

UNO_Interface *
UNO_Interface::new(...)
CODE:
{
    UNO_Interface *retval;
    
    retval = new UNO_Interface();

    RETVAL = retval;
}
OUTPUT:
    RETVAL

SV *
UNO_Interface::AUTOLOAD(...)
CODE:
{
    CV *method = get_cv("OpenOffice::UNO::Interface::AUTOLOAD", 0);

    I32 i;
    UNO_SAny args;

    if ( items > 1 ) {
	args.realloc(items-1);
	for ( i = 1; i < items; i++ ) {
	    UNO_XAny a = SVToAny(ST(i));
	    args[i-1] <<= a;
	}
    }

    RETVAL = THIS->invoke(SvPVX(method), args);
}
OUTPUT:
    RETVAL

void
UNO_Interface::DESTROY(...)
CODE:
{
    delete(THIS);
}

MODULE = OpenOffice::UNO	PACKAGE = OpenOffice::UNO::Struct	PREFIX = UNO_

UNO_Struct *
UNO_Struct::new(...)
CODE:
{
    UNO_Struct *ret;

    ret = (UNO_Struct *)NULL;
    if ( items == 2 ) {
	char *stype;
	STRLEN len;

	stype = SvPV(ST(1), len);
	ret = new UNO_Struct(stype);
    }
    RETVAL = ret;
}
OUTPUT:
    RETVAL

void
UNO_Struct::DESTROY(...)
CODE:
{
    delete(THIS);
}

SV *
UNO_Struct::AUTOLOAD(...)
CODE:
{
    CV *member = get_cv("OpenOffice::UNO::Struct::AUTOLOAD", 0);
    char *mname;

    mname = SvPVX(member);

    SV *ret;

    ret = Nullsv;
    // Distinguish between "set" and "get" accessor
    if ( items == 2 ) {	// If "set"
	THIS->set(mname, ST(1));
    } else {	// If "get"
	ret = THIS->get(mname);
    }

    RETVAL = ret;
}
OUTPUT:
    RETVAL

MODULE = OpenOffice::UNO	PACKAGE = OpenOffice::UNO::Boolean	PREFIX = UNO_

UNO_Boolean *
UNO_Boolean::new(...)
CODE:
{
    if ( items == 2 ) {
        RETVAL = new UNO_Boolean(ST(1));
    } else {
        RETVAL = new UNO_Boolean();
    }
}
OUTPUT:
    RETVAL

MODULE = OpenOffice::UNO	PACKAGE = OpenOffice::UNO::Int32	PREFIX = UNO_

UNO_Int32 *
UNO_Int32::new(...)
CODE:
{
    if ( items == 2 ) {
        RETVAL = new UNO_Int32(ST(1));
    } else {
        RETVAL = new UNO_Int32();
    }
}
OUTPUT:
    RETVAL

MODULE = OpenOffice::UNO	PACKAGE = OpenOffice::UNO::Int64	PREFIX = UNO_

UNO_Int64 *
UNO_Int64::new(...)
CODE:
{
    if ( items == 2 ) {
        RETVAL = new UNO_Int64(ST(1));
    } else {
        RETVAL = new UNO_Int64();
    }
}
OUTPUT:
    RETVAL
