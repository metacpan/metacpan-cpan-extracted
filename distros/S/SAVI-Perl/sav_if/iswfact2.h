/*
 * iswfact2.h (26-NOV-1999)
 *
 * This file is a part of the Sophos Anti-Virus Interface (SAVI)(tm).
 *
 * Copyright (C) 2002 Sophos Plc, Oxford, England.
 * All rights reserved.
 *
 * This source code is only intended as a supplement to the
 * SAVI(tm) Reference and related documentation for the library.
 *
 * Class factory interface file for SAVI2 onwards.
 */

#ifndef __ISWFACT2_H__
#define __ISWFACT2_H__

#include "savitype.h"                     /* Include Sophos basic types. */   

#ifdef __SOPHOS_WIN32__
#  include <unknwn.h>                     /* IUnknown interface. */
#  include <objbase.h>                    /* DllGetClassObject.  */
typedef IClassFactory ISweepClassFactory2;/* make sure cross platform  compatibility. */
#else
#  include "iswunk2.h"

class ISweepClassFactory2 : public ISweepUnknown2
{
public:
   virtual HRESULT SOPHOS_STDCALL CreateInstance( IUnknown* pUnkOuter, REFIID IIDObject, void** ppObject ) = 0;
   virtual HRESULT SOPHOS_STDCALL LockServer(SOPHOS_BOOL Lock) = 0;
};

#endif /* __SOPHOS_WIN32__ */

#endif   /* __ISWFACT2_H__ */

