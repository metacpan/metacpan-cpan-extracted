/*
 * iswunk2.h (26-NOV-1999)
 *
 * This file is a part of the Sophos Anti-Virus Interface (SAVI)(tm).
 *
 * Copyright (C) 1997,2000 Sophos Plc, Oxford, England.
 * All rights reserved.
 *
 * This source code is only intended as a supplement to the
 * SAVI(tm) Reference and related documentation for the library.
 *
 * Sophos ISweepUnknown declaration
 */

#ifndef __ISWUNK2_H__
#define __ISWUNK2_H__

#include "savitype.h"

/* Check that we aren't trying to mix SAVI1 and SAVI2 interfaces: */
#ifdef _SOPHOS_SAVI1
#  error Attempting to mix SAVI1 and SAVI2 include files. Include only isavi2.h for SAVI2.
#endif
#define _SOPHOS_SAVI2

class ISweepUnknown2
{
public:
   virtual HRESULT SOPHOS_STDCALL QueryInterface(REFIID IID, void** ppObject ) = 0;
   virtual SOPHOS_ULONG SOPHOS_STDCALL AddRef() = 0;
   virtual SOPHOS_ULONG SOPHOS_STDCALL Release() = 0;
};

#endif   /*__ISWUNK2_H__ */
