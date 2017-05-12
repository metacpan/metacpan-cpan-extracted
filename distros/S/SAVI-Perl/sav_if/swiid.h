/*
 * swiid.h
 *
 * This file is a part of the Sophos Anti-Virus Interface (SAVI)(tm).
 *
 * Copyright (C) 2002-2004 Sophos Plc, Oxford, England.
 * All rights reserved.
 *
 * This source code is only intended as a supplement to the
 * SAVI(tm) Reference and related documentation for the library.
 *
 * SAVI class and interface ID definitions.
 */

#ifndef __SWIID_DOT_H__
#define __SWIID_DOT_H__

#include "compute.h"
#include "savitype.h"
#ifndef __SOPHOS_WIN32__
# include "substcom.h"
#endif

/*          */
/* Classes. */
/*          */

/*          
 * Generic SAVI class identifier 
 */          
DEFINE_GUID(SOPHOS_CLASSID_SAVI, 0x91c4c540, 0x9fdd, 0x11d2, 0xaf, 0xaa, 0x00, 0x10, 0x5a, 0x30, 0x5a, 0x2b);
   /* {91C4C540-9FDD-11d2-AFAA-00105A305A2B} */

/*
 * For backward compatibility
 */
#define   SOPHOS_CLSID_SAVI              0x10000000
#define   SOPHOS_CLSID_SWAPI             SOPHOS_CLSID_SAVI

#define   SOPHOS_CLSID_SAVI2             SOPHOS_CLASSID_SAVI


/*             */
/* Interfaces. */
/*             */

/*
 * SAVI 1 only
 */
#define   SOPHOS_IID_UNKNOWN             0x00000000   
#define   SOPHOS_IID_CLASSFACTORY        0x00000001
#define   SOPHOS_IID_SWAPI_0_00          0x10000000
#define   SOPHOS_IID_SAVI1               SOPHOS_IID_SWAPI_0_00

/* 
 * SAVI 2 only
 */
#define   SOPHOS_IID_UNKNOWN2            IID_IUnknown          /* Use Windows' definition. */
#define   SOPHOS_IID_CLASSFACTORY2       IID_IClassFactory     /* Use Windows' definition. */
DEFINE_GUID(SOPHOS_IID_SAVI2, 0x2d12c871, 0x7ac, 0x11d3, 0xbe, 0x8d, 0x0, 0x10, 0x5a, 0x30, 0x5d, 0x2f);
   /* {2D12C871-07AC-11d3-BE8D-00105A305D2F} */

/* 
 * SAVI 3 only
 */
DEFINE_GUID(SOPHOS_IID_SAVI3, 0xff4e3eaa, 0x9380, 0x4a82, 0x82, 0x85, 0x2f, 0x17, 0xf2, 0xda, 0x8c, 0xfa);
   /* {FF4E3EAA-9380-4a82-8285-2F17F2DA8CFA} */

/*
 * Sophos internal.
 */
DEFINE_GUID(SOPHOS_IID_SWEEPRESULTS, 0x91c4c542, 0x9fdd, 0x11d2, 0xaf, 0xaa, 0x00, 0x10, 0x5a, 0x30, 0x5a, 0x2b);
   /* {91C4C542-9FDD-11d2-AFAA-00105A305A2B} */

DEFINE_GUID(SOPHOS_IID_ENUM_SWEEPRESULTS, 0x3a2fcc2, 0xa0a8, 0x11d2, 0xaf, 0xac, 0x00, 0x10, 0x5a, 0x30, 0x5a, 0x2b);
   /* {03A2FCC2-A0A8-11d2-AFAC-00105A305A2B} */

DEFINE_GUID(SOPHOS_IID_SWEEPERROR, 0x12d7b270, 0xc65f, 0x11d2, 0xaf, 0xcf, 0x00, 0x10, 0x5a, 0x30, 0x5a, 0x2b);
   /* {12D7B270-C65F-11d2-AFCF-00105A305A2B} */

DEFINE_GUID(SOPHOS_IID_IDEDETAILS, 0xbf8ea561, 0x7a7, 0x11d3, 0xbe, 0x8d, 0x0, 0x10, 0x5a, 0x30, 0x5d, 0x2f);
   /* {BF8EA561-07A7-11d3-BE8D-00105A305D2F} */

DEFINE_GUID(SOPHOS_IID_ENUM_IDEDETAILS, 0x3a2fcc3, 0xa0a8, 0x11d2, 0xaf, 0xac, 0x00, 0x10, 0x5a, 0x30, 0x5a, 0x2b);
   /* {03A2FCC3-A0A8-11d2-AFAC-00105A305A2B} */

DEFINE_GUID(SOPHOS_IID_SWEEPNOTIFY, 0x3a2fcc0, 0xa0a8, 0x11d2, 0xaf, 0xac, 0x00, 0x10, 0x5a, 0x30, 0x5a, 0x2b);
   /* {03A2FCC0-A0A8-11d2-AFAC-00105A305A2B} */

DEFINE_GUID(SOPHOS_IID_SWEEPNOTIFY2, 0x179fe890, 0x59, 0x11d6, 0x95, 0x28, 0xaa, 0x0, 0x4, 0x0, 0x12, 0x4);
   /* {179FE890-0059-11d6-9528-AA0004001204} */

DEFINE_GUID(SOPHOS_IID_SWEEPDISKCHANGE, 0x2a6e01c6, 0x72df, 0x4469, 0x9b, 0x37, 0x1b, 0xa, 0x3b, 0xe4, 0x2b, 0xa6);
   /* {2A6E01C6-72DF-4469-9B37-1B0A3BE42BA6} */

DEFINE_GUID(SOPHOS_IID_ENGINECONFIG, 0x3a2fcc1, 0xa0a8, 0x11d2, 0xaf, 0xac, 0x00, 0x10, 0x5a, 0x30, 0x5a, 0x2b);
   /* {03A2FCC1-A0A8-11d2-AFAC-00105A305A2B} */

DEFINE_GUID(SOPHOS_IID_ENUM_ENGINECONFIG, 0x3a2fcc4, 0xa0a8, 0x11d2, 0xaf, 0xac, 0x00, 0x10, 0x5a, 0x30, 0x5a, 0x2b);
   /* {03A2FCC4-A0A8-11d2-AFAC-00105A305A2B} */

DEFINE_GUID(SOPHOS_IID_GENERIC_LIST_HEAD, 0x2110ac80, 0xf999, 0x11d2, 0xbe, 0x88, 0x0, 0x10, 0x5a, 0x30, 0x5d, 0x2f);
   /* {2110AC80-F999-11d2-BE88-00105A305D2F} */

DEFINE_GUID(SOPHOS_IID_GENERIC_LIST_ITEM, 0x858c4ee0, 0xf999, 0x11d2, 0xbe, 0x88, 0x0, 0x10, 0x5a, 0x30, 0x5d, 0x2f);
   /* {858C4EE0-F999-11d2-BE88-00105A305D2F} */

DEFINE_GUID(SOPHOS_IID_SAVISTREAM, 0x341c886d, 0x7558, 0x47ea, 0xb5, 0x77, 0x85, 0xe4, 0x7f, 0xeb, 0xb7, 0xc7);
   /* {341C886D-7558-47ea-B577-85E47FEBB7C7} */
   
DEFINE_GUID(SOPHOS_IID_CHANGENOTIFY, 0xe5c2e464, 0xe2fa, 0x4725, 0xa0, 0x80, 0x1c, 0x78, 0x0, 0x20, 0xdf, 0x33);
   /* {E5C2E464-E2FA-4725-A080-1C780020DF33} */

DEFINE_GUID(SOPHOS_IID_CHECKSUM, 0x27471914, 0xddc0, 0x488a, 0x90, 0xfc, 0x96, 0xe3, 0x51, 0x61, 0x73, 0xdb);
   /* {27471914-DDC0-488a-90FC-96E3516173DB} */

DEFINE_GUID(SOPHOS_IID_ENUM_CHECKSUM, 0x3fa56829, 0xbd91, 0x4c39, 0xa5, 0x6d, 0xe1, 0xe9, 0x4a, 0x76, 0xed, 0x32);
   /* {3FA56829-BD91-4c39-A56D-E1E94A76ED32} */

DEFINE_GUID(SOPHOS_IID_SEVERITYNOTIFY, 0xfd112c86, 0x3b28, 0x460e, 0x8a, 0xb4, 0x1, 0x61, 0x77, 0xba, 0x48, 0x2d);
   /* {FD112C86-3B28-460e-8AB4-016177BA482D} */

#endif   /* __SWIID_DOT_H__ */
