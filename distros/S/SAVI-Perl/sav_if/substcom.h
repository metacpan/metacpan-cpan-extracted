/*
 * substcom.h (06-MAR-2003)
 *
 * This file is a part of the Sophos Anti-Virus Interface (SAVI)(tm).
 *
 * Copyright (C) 2003 Sophos Plc, Oxford, England.
 * All rights reserved.
 *
 * This source code is only intended as a supplement to the
 * SAVI(tm) Reference and related documentation for the library.
 *
 * COM-like definitions for non Win32 platforms 
 */

#ifndef __SUBSTCOM_DOT_H__
#define __SUBSTCOM_DOT_H__

/*
 * The SAVI_INTERFACE_CPP symbol specifies whether C or C++ SAVI APIs are
 * used in C++ source files.  The default for NetWare is to use the C++
 * interface from C++ source files.  For the other platforms the default 
 * is the C interface.  If it becomes necessary to change the default 
 * behaviour for a particular source file then the symbol can be explicitly
 * defined before including swiid.h.  If SAVI_INTERFACE_CPP is defined to 
 * be 0 then the C SAVI interface will be used in C++ source files. If 
 * SAVI_INTERFACE_CPP is defined to be non-zero then the C++ interface
 * will be used. 
 * (For Win32 the C++ SAVI interface is ALWAYS assumed in C++ source files 
 *  and this cannot be changed by defining SAVI_INTERFACE_CPP as 0).
 */
#ifndef SAVI_INTERFACE_CPP
# if defined( __cplusplus ) && ( defined( __SOPHOS_NW__ ) )
#  define SAVI_INTERFACE_CPP 1
# else
#  define SAVI_INTERFACE_CPP 0
# endif /* __cplusplus */
#endif /* SAVI_INTERFACE_CPP */

#ifndef SAVI_EXTERN_DEC
#ifdef __cplusplus
#define SAVI_EXTERN_DEC   extern "C"
#define SAVI_EXTERN_DEF   extern "C"
#else
#define SAVI_EXTERN_DEC   extern
#define SAVI_EXTERN_DEF
#endif /* __cplusplus */
#endif /* EXTERN_DEC */

 /*
  * Define GUIDs and associated macros when not on Windows platform
  */
typedef struct _GUID
{
   U32   Data1;
   U16   Data2;
   U16   Data3;
   U08   Data4[8];
} GUID;

typedef GUID IID;

#ifndef _REFGUID_DEFINED
#define _REFGUID_DEFINED
#if ( SAVI_INTERFACE_CPP != 0 )
#define REFGUID const GUID &
#else
typedef const GUID * REFGUID;
#endif /* SAVI_INTERFACE_CPP */
#endif /* _REFGUID_DEFINED */

#ifndef _REFIID_DEFINED
#define _REFIID_DEFINED
#if ( SAVI_INTERFACE_CPP != 0 )
#define REFIID const IID &
#else
typedef const IID *   REFIID;
#endif /* SAVI_INTERFACE_CPP */
#endif /* _REFIID_DEFINED */

#ifndef _REFCLSID_DEFINED
#define _REFCLSID_DEFINED
#if ( SAVI_INTERFACE_CPP != 0 )
#define REFCLSID const IID &
#else
typedef const IID * REFCLSID;
#endif /* SAVI_INTERFACE_CPP */
#endif /* _REFCLSID_DEFINED */

# ifndef INITGUID
#  define DEFINE_GUID(name, l, w1, w2, b1, b2, b3, b4, b5, b6, b7, b8) \
      SAVI_EXTERN_DEC const GUID name
# else /* INITGUID */
#  define DEFINE_GUID(name, l, w1, w2, b1, b2, b3, b4, b5, b6, b7, b8) \
      SAVI_EXTERN_DEF const GUID name = { l, w1, w2, { b1, b2,  b3,  b4,  b5,  b6,  b7,  b8 } }
# endif /* INITGUID */

#define IsEqualIID(riid1, riid2) IsEqualGUID(riid1, riid2)
#define IsEqualCLSID(rclsid1, rclsid2) IsEqualGUID(rclsid1, rclsid2)

#if ( SAVI_INTERFACE_CPP != 0 )

/* InlineIsEqualGUID will be used (instead of IsEqualGUID) if __INLINE_ISEQUAL_GUID is defined.
 * This will make IsEqualGUID faster (and the code fatter).
 */
SOPHOS_INL_KW int InlineIsEqualGUID(REFGUID rguid1, REFGUID rguid2)
{
   return (
      ((unsigned long *) &rguid1)[0] == ((unsigned long *) &rguid2)[0] &&
      ((unsigned long *) &rguid1)[1] == ((unsigned long *) &rguid2)[1] &&
      ((unsigned long *) &rguid1)[2] == ((unsigned long *) &rguid2)[2] &&
      ((unsigned long *) &rguid1)[3] == ((unsigned long *) &rguid2)[3]);
}

SOPHOS_INL_KW int IsEqualGUID(REFGUID rguid1, REFGUID rguid2)
{
    return !memcmp(&rguid1, &rguid2, sizeof(GUID));
}

#else /* SAVI_INTERFACE_CPP */

/* InlineIsEqualGUID will be used (instead of IsEqualGUID) if __INLINE_ISEQUAL_GUID is defined.
 * This will make IsEqualGUID faster etc.
 */
#define InlineIsEqualGUID(rguid1, rguid2)  \
        (((unsigned long *) rguid1)[0] == ((unsigned long *) rguid2)[0] &&   \
        ((unsigned long *) rguid1)[1] == ((unsigned long *) rguid2)[1] &&    \
        ((unsigned long *) rguid1)[2] == ((unsigned long *) rguid2)[2] &&    \
        ((unsigned long *) rguid1)[3] == ((unsigned long *) rguid2)[3])

 /*
  * Define comparison utilities.
  */
# define IsEqualGUID(a,b)                       \
   ( ((a)!=NULL && (b)!=NULL)   &&             \
     ( ((a) == (b)) ||                         \
       ((a)->Data1 == (b)->Data1 &&            \
        (a)->Data2 == (b)->Data2 &&            \
        (a)->Data3 == (b)->Data3 &&            \
        memcmp((a)->Data4, (b)->Data4, 8)==0) )\
   )

#endif /* SAVI_INTERFACE_CPP */

#ifdef __INLINE_ISEQUAL_GUID
#undef IsEqualGUID
#define IsEqualGUID(rguid1, rguid2) InlineIsEqualGUID(rguid1, rguid2)
#endif /* __INLINE_ISEQUAL_GUID */

#if ( SAVI_INTERFACE_CPP != 0 )
SOPHOS_INL_KW int operator==(REFGUID guidOne, REFGUID guidOther)
{
    return IsEqualGUID(guidOne,guidOther);
}

SOPHOS_INL_KW int operator!=(REFGUID guidOne, REFGUID guidOther)
{
    return !(guidOne == guidOther);
}
#endif /* SAVI_INTERFACE_CPP */

#define IUnknown  ISweepUnknown2

/*
 * Define IID_IUnknown and IID_IClassFactory to the same values as Microsoft
 */
DEFINE_GUID(IID_IUnknown,       0x00000000, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);
DEFINE_GUID(IID_IClassFactory,  0x00000001, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

#ifdef __SOPHOS_NW__
#define CLSCTX_ALL  0
# ifdef __cplusplus
  extern "C" {
# endif  /* __cplusplus */
 HRESULT SAVICoCreateInstance( REFCLSID rclsid, void* pUnkOuter, unsigned int dwClsContext, REFIID riid, void** ppv );
 HRESULT SAVICoInitialize( void* pvReserved );
 void SAVICoUninitialize();
# ifdef __cplusplus
  }
# endif  /* __cplusplus */
# define CoCreateInstance SAVICoCreateInstance
# define CoInitialize     SAVICoInitialize
# define CoUninitialize   SAVICoUninitialize
#endif /* __SOPHOS_NW__ */

#endif /* __SUBSTCOM_DOT_H__ */
