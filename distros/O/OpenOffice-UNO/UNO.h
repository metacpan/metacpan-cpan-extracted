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

#ifndef _PERLUNO_H_
#define _PERLUNO_H_

#ifdef bool
#undef bool
#include <iostream.h>
#endif

#include <com/sun/star/connection/ConnectionSetupException.hpp>
#include <com/sun/star/lang/XMultiComponentFactory.hpp>
#include <com/sun/star/lang/XSingleServiceFactory.hpp>
#include <com/sun/star/lang/XMultiServiceFactory.hpp>
#include <com/sun/star/reflection/XIdlReflection.hpp>
#include <com/sun/star/beans/XMaterialHolder.hpp>
#include <com/sun/star/script/XTypeConverter.hpp>
#include <com/sun/star/uno/XComponentContext.hpp>
#include <com/sun/star/reflection/XIdlClass.hpp>
#include <com/sun/star/lang/WrappedTargetRuntimeException.hpp>
#include <com/sun/star/uno/RuntimeException.hpp>
#include <com/sun/star/beans/XIntrospection.hpp>
#include <com/sun/star/script/XInvocation2.hpp>
#include <com/sun/star/lang/XTypeProvider.hpp>
#include <com/sun/star/lang/XServiceInfo.hpp>
#include <com/sun/star/uno/XInterface.hpp>
#include <com/sun/star/uno/Reference.h>
#include <typelib/typedescription.hxx>
#include <cppuhelper/bootstrap.hxx>

#include <com/sun/star/uno/Any.hxx>

#include <rtl/strbuf.hxx>
#include <rtl/ustrbuf.hxx>

#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef __cplusplus
};
#endif

#define UNO_INVOCATION_OBJECT ::rtl::OUString( RTL_CONSTASCII_USTRINGPARAM( "com.sun.star.script.Invocation" ))
#define UNO_TYPECONVERTER_OBJECT ::rtl::OUString( RTL_CONSTASCII_USTRINGPARAM( "com.sun.star.script.Converter" ))
#define UNO_COREREFLECTION_OBJECT ::rtl::OUString( RTL_CONSTASCII_USTRINGPARAM( "com.sun.star.reflection.CoreReflection" ))

#define UNO_STRUCT_NAME_KEY "UNOStructName"

typedef ::com::sun::star::uno::Reference< ::com::sun::star::uno::XComponentContext > UNO_XComponentContext;	
typedef ::com::sun::star::uno::Reference< ::com::sun::star::lang::XMultiComponentFactory > UNO_XMultiComponentFactory;
typedef ::com::sun::star::uno::Reference< ::com::sun::star::lang::XMultiServiceFactory > UNO_XMultiServiceFactory;
//typedef ::com::sun::star::lang::XMultiComponentFactory UNO_XMultiComponentFactory;
typedef ::com::sun::star::uno::Reference< ::com::sun::star::uno::XInterface > UNO_XInterface;
typedef ::com::sun::star::uno::Reference< ::com::sun::star::lang::XSingleServiceFactory > UNO_XSingleServiceFactory;
typedef ::com::sun::star::uno::Reference< ::com::sun::star::script::XTypeConverter > UNO_XTypeConverter;
typedef ::com::sun::star::uno::Any UNO_XAny;
typedef ::com::sun::star::uno::Sequence< ::com::sun::star::uno::Any > UNO_SAny;
typedef ::com::sun::star::uno::Sequence< short > UNO_SShort;
typedef ::com::sun::star::uno::Reference< ::com::sun::star::lang::XServiceInfo > UNO_XServiceInfo;
typedef ::com::sun::star::uno::Reference< ::com::sun::star::lang::XTypeProvider > UNO_XTypeProvider;
typedef ::com::sun::star::uno::Reference< ::com::sun::star::script::XInvocation2 > UNO_XInvocation2;
typedef ::com::sun::star::uno::Reference< ::com::sun::star::beans::XMaterialHolder > UNO_XMaterialHolder;
typedef ::com::sun::star::uno::Reference< ::com::sun::star::reflection::XIdlClass > UNO_XIdlClass;
typedef ::com::sun::star::uno::Reference< ::com::sun::star::reflection::XIdlReflection > UNO_XIdlReflection;


typedef struct _PerlRT {
	bool prtInitialized;
	UNO_XComponentContext localCtx;
	UNO_XSingleServiceFactory ssf;
	UNO_XTypeConverter typecvt;
	UNO_XIdlReflection reflection;
} PerlRT;

class UNO_Any {
public:
	UNO_Any() {};
	UNO_Any(char *stype);
	~UNO_Any() {};
	UNO_XAny getAny();
	void assignAny(UNO_XAny any);

	UNO_XInvocation2 xinvoke;

protected:
	UNO_XAny pany;
};

class UNO_Struct : UNO_Any {
public:
	UNO_Struct();
	UNO_Struct(char *stype);
	UNO_Struct(UNO_XAny tinterface);
	~UNO_Struct();

	void set(char *mname, SV *value);
	SV *get(char *mname);

private:
	char *TypeString;
};

class UNO_Interface : UNO_Any {
public:
	UNO_Interface();
	UNO_Interface(UNO_XAny targetInterface);
	~UNO_Interface() {};

	SV * invoke(char *method, UNO_SAny args);
};

class UNO_Util {
public:
	UNO_Util() {};
	~UNO_Util() {};
};

class UNO {
public:
    UNO();
    ~UNO();

    UNO_Interface *createInitialComponentContext();
    UNO_Interface *createInitialComponentContext(char *iniFile);
    UNO_Struct *createIdlStruct(char *name);

private:
    void createServices();

    UNO_Interface *ctx;
};

class UNO_Boolean : UNO_Any {
public:
    UNO_Boolean();
    UNO_Boolean(SV *val);
    ~UNO_Boolean();

private:
    sal_Bool bvalue;
};

class UNO_Int32 : UNO_Any {
public:
    UNO_Int32();
    UNO_Int32(SV *val);
    ~UNO_Int32();

private:
    sal_Int32 ivalue;
};

class UNO_Int64 : UNO_Any {
public:
    UNO_Int64();
    UNO_Int64(SV *val);
    ~UNO_Int64();

private:
    sal_Int64 ivalue;
};

// Function Prototype
UNO_SAny AVToSAny(AV *av);
UNO_XAny HVToStruct(HV *hv);
UNO_XAny SVToAny(SV *svp);
SV *AnyToSV(UNO_XAny a);
AV *SAnyToAV(UNO_SAny sa);
SV *AnyToSV(UNO_XAny a);
AV *SAnyToAV(UNO_SAny sa);

#endif /* _PERLUNO_H_ */
