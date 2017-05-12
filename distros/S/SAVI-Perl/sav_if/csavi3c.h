/*
 * csavi3c.h (9-JAN-2002)
 *
 * This file is a part of the Sophos Anti-Virus Interface (SAVI)(tm).
 *
 * Copyright (C) 2002 Sophos Plc, Oxford, England.
 * All rights reserved.
 *
 * This source code is only intended as a supplement to the
 * SAVI(tm) Reference and related documentation for the library.
 *
 * Sophos CISavi3 declarations.
 */

#ifndef __CSAVI3C_DOT_H__
#define __CSAVI3C_DOT_H__

#include "csavi2c.h"

typedef struct _CISavi3Vtbl
{
  CISWEEPUNKNOWN2VTBL;
  CISAVI2VTBL;
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR SweepBuffer)(void *object, LPCOLESTR pBuffName, U32 buffSize, U08 *pBuff, REFIID ResultsIID, void **ppResults);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR SweepHandle)(void *object, LPCOLESTR pHandleName, SOPHOS_FD fileHandle, REFIID ResultsIID, void **ppResults);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR SweepStream)(void *object, LPCOLESTR pStreamName, REFIID StreamIID, void *pStream, REFIID ResultsIID, void **ppResults);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR DisinfectBuffer)(void *object, LPCOLESTR pBuffName, U32 buffSize, U08 *pBuff, REFIID ResultsIID, void **ppResults);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR DisinfectHandle)(void *object, LPCOLESTR pHandleName, SOPHOS_FD fileHandle, REFIID ResultsIID, void **ppResults);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR DisinfectStream)(void *object, LPCOLESTR pStreamName, REFIID StreamIID, void *pStream, REFIID ResultsIID, void **ppResults);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR LoadVirusData)(void *object);
} CISavi3Vtbl;

typedef struct _CISavi3
{
  CISavi3Vtbl *pVtbl;
} CISavi3;

typedef struct _CISaviStreamVtbl
{
  CISWEEPUNKNOWN2VTBL;
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR ReadStream)(void *object, void *lpvBuffer, U32 count, U32 *bytesRead);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR WriteStream)(void *object, const void *lpvBuffer, U32 count, U32 *bytesWritten);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR SeekStream)(void *object, S32 lOffset, U32 uOrigin, U32 *newPosition);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR GetLength)(void *object, U32 *length);
} CISaviStreamVtbl;

typedef struct _CISaviStream
{
  CISaviStreamVtbl *pVtbl;
} CISaviStream;


/*
 * Sophos CIChangeNotify declarations.
 */
typedef struct _CIChangeNotifyVtbl
{
  CISWEEPUNKNOWN2VTBL;
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR OnChange)(void *object, void *token);
} CIChangeNotifyVtbl;

typedef struct _CIChangeNotify
{
  CIChangeNotifyVtbl *pVtbl;
  IID                 typeCode;
  U32                 refCount;
} CIChangeNotify;

typedef struct _CIVersionChecksumVtbl
{
  CISWEEPUNKNOWN2VTBL;
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR GetType)(void *object, U32 *pType);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR GetValue)(void *object, U32 *pValue);
} CIVersionChecksumVtbl;

typedef struct _CIVersionChecksum
{
  CIVersionChecksumVtbl *pVtbl;
} CIVersionChecksum;

typedef struct _CIEnumVersionChecksumVtbl
{
  CISWEEPUNKNOWN2VTBL;
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR Next)(void *object, SOPHOS_ULONG cElement, void *pElement[], SOPHOS_ULONG *pcFetched);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR Skip)(void *object, SOPHOS_ULONG cElement);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR Reset)(void *object);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR Clone)(void *object, void **ppEnum);
} CIEnumVersionChecksumVtbl;

typedef struct _CIEnumVersionChecksum
{
  CIEnumVersionChecksumVtbl *pVtbl;
} CIEnumVersionChecksum;


/* 
 * Interface definition for CISeverityNotify.
 */
typedef struct _CISeverityNotifyVtbl
{
  CISWEEPUNKNOWN2VTBL;
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR OnSevereError)(void *object, void *token, HRESULT ErrorCode, U32 Severity);
} CISeverityNotifyVtbl;

typedef struct _CISeverityNotify
{
  CISeverityNotifyVtbl *pVtbl;
  IID                   typeCode;
  U32                   refCount;
} CISeverityNotify;


#endif /* __CSAVI3C_DOT_H__ */
