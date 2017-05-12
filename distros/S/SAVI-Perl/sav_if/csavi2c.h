/*
 * csavi2c.h (26-NOV-1999)
 *
 * This file is a part of the Sophos Anti-Virus Interface (SAVI)(tm).
 *
 * Copyright (C) 2002 Sophos Plc, Oxford, England.
 * All rights reserved.
 *
 * This source code is only intended as a supplement to the
 * SAVI(tm) Reference and related documentation for the library.
 *
 * Sophos CISavi2 declarations.
 */

#ifndef __CSAVI2C_DOT_H__
#define __CSAVI2C_DOT_H__

/* ----- */

#include "savitype.h"
#include "swerror2.h"
#include "swiid.h"

/* ----- */

#define CISWEEPUNKNOWN2VTBL \
  HRESULT      (SOPHOS_STDCALL_PUBLIC_PTR QueryInterface)(void *object, REFIID IIDObject, void **ppObject); \
  SOPHOS_ULONG (SOPHOS_STDCALL_PUBLIC_PTR AddRef)(void *object); \
  SOPHOS_ULONG (SOPHOS_STDCALL_PUBLIC_PTR Release)(void *object)

typedef struct _CISweepUnknown2Vtbl
{
  CISWEEPUNKNOWN2VTBL;
} CISweepUnknownVtbl;

typedef struct _CISweepUnknown2
{
  CISweepUnknownVtbl *pVtbl;
} CISweepUnknown2;

typedef struct _CISweepClassFactory2Vtbl
{
  CISWEEPUNKNOWN2VTBL;
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR CreateInstance)(void *object, void *pUnkOuter, REFIID IIDObject, void **ppObject);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR LockServer)(void *object, SOPHOS_BOOL Lock);
} CISweepClassFactory2Vtbl;

typedef struct _CISweepClassFactory2
{
  CISweepClassFactory2Vtbl *pVtbl;
} CISweepClassFactory2;

#define CISAVI2VTBL \
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR Initialise)(void *object); \
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR InitialiseWithMoniker)(void *object, LPCOLESTR pApplicationMoniker); \
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR RegisterNotification)(void *object, REFIID NotifyIID, void *pCallbackInterface, void *pToken); \
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR GetVirusEngineVersion)(void *object, U32 *pVersion, LPOLESTR pVersionString, U32 StringLength, SYSTEMTIME *pVdataDate, U32 *pNumberOfDetectableViruses, U32 *pVersionEx, REFIID DetailsIID, void **ppDetailsList); \
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR Terminate)(void *object); \
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR SetConfigDefaults)(void *object); \
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR ReadConfig)(void *object); \
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR WriteConfig)(void *object); \
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR GetConfigEnumerator)(void *object, REFIID ConfigIID, void **ppConfigs); \
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR SetConfigValue)(void *object, LPCOLESTR pValueName, U32 Type, LPCOLESTR pData); \
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR GetConfigValue)(void *object, LPCOLESTR pValueName, U32 Type, U32 MaxSize, LPOLESTR pData, U32 *pSize); \
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR SweepFile)(void *object, LPCOLESTR pFileName, REFIID ResultsIID, void **ppResults); \
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR DisinfectFile)(void *object, LPCOLESTR pFileName, REFIID ResultsIID, void **ppResults); \
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR SweepLogicalSector)(void *object, LPCOLESTR pDriveName, U32 Reserved, U32 SectorNumber, REFIID ResultsIID, void **ppResults); \
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR SweepPhysicalSector)(void *object, LPCOLESTR pDriveName, U32 Head, U32 Cylinder, U32 Sector, REFIID ResultsIID, void **ppResults); \
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR DisinfectLogicalSector)(void *object, LPCOLESTR pDriveName, U32 Reserved, U32 SectorNumber, REFIID ResultsIID, void **ppResults); \
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR DisinfectPhysicalSector)(void *object, LPCOLESTR pDriveName, U32 Head, U32 Cylinder, U32 Sector, REFIID ResultsIID, void **ppResults); \
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR SweepMemory)(void *object, REFIID ResultsIID, void **ppResults); \
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR Disinfect)(void *object, REFIID ToDisinfectIID, void *pToDisinfect)

typedef struct _CISavi2Vtbl
{
  CISWEEPUNKNOWN2VTBL;
  CISAVI2VTBL;
} CISavi2Vtbl;

typedef struct _CISavi2
{
  CISavi2Vtbl *pVtbl;
} CISavi2;

typedef struct _CISweepResultsVtbl
{
  CISWEEPUNKNOWN2VTBL;
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR IsDisinfectable)(void *object, U32 *pIsDisinfectable);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR GetVirusType)(void *object, U32 *pVirusType);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR GetVirusName)(void *object, U32 ArraySize, LPOLESTR pVirusName, U32 *pVirusNameLength);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR GetLocationInformation)(void *object, U32 ArraySize, LPOLESTR pLocation, U32 *pLocationNameLength);
} CISweepResultsVtbl;

typedef struct _CISweepResults
{
  CISweepResultsVtbl *pVtbl;
} CISweepResults;

typedef struct _CIIDEDetailsVtbl
{
  CISWEEPUNKNOWN2VTBL;
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR GetName)(void *object, U32 ArraySize, LPOLESTR pIDEName, U32 *pIDENameLength);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR GetType)(void *object, U32 *pType);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR GetState)(void *object, U32 *pState);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR GetDate)(void *object, SYSTEMTIME *pDate);
} CIIDEDetailsVtbl;

typedef struct _CIIDEDetails
{
  CIIDEDetailsVtbl *pVtbl;
} CIIDEDetails;

typedef struct _CIEngineConfigVtbl
{
  CISWEEPUNKNOWN2VTBL;
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR GetName)(void *object, U32 ArraySize, LPOLESTR pName, U32 *pNameLength);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR GetType)(void *object, U32 *pType);
} CIEngineConfigVtbl;

typedef struct _CIEngineConfig
{
  CIEngineConfigVtbl *pVtbl;
} CIEngineConfig;

typedef struct _CISweepErrorVtbl
{
  CISWEEPUNKNOWN2VTBL;
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR GetLocationInformation)(void *object, U32 ArraySize, LPOLESTR pLocation, U32* pLocationNameLength);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR GetErrorCode)(void *object, HRESULT *ErrorCode);
} CISweepErrorVtbl;

typedef struct _CISweepError
{
  CISweepErrorVtbl *pVtbl;
} CISweepError;

typedef struct _CISweepNotifyVtbl
{
  CISWEEPUNKNOWN2VTBL;
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR OnFileFound)(void *object, void *token, LPCOLESTR pName);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR OnVirusFound)(void *object, void *token, REFIID ResultsIID, void *pResults);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR OnErrorFound)(void *object, void *token, REFIID ErrorIID, void *pError);
} CISweepNotifyVtbl;

typedef struct _CISweepNotify
{
  CISweepNotifyVtbl *pVtbl;
  IID                typeCode;
  U32                refCount;
} CISweepNotify;

typedef struct _CISweepNotify2Vtbl
{
  CISWEEPUNKNOWN2VTBL;
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR OnFileFound)(void *object, void *token, LPCOLESTR pName);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR OnVirusFound)(void *object, void *token, REFIID ResultsIID, void *pResults);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR OnErrorFound)(void *object, void *token, REFIID ErrorIID, void *pError);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR OkToContinue)(void *object, void *token, U16 Activity, U32 Extent, LPCOLESTR pTarget);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR OnClassification)(void *object, void *token, U32 Classifn);
} CISweepNotify2Vtbl;

typedef struct _CISweepNotify2
{
  CISweepNotify2Vtbl *pVtbl;
  IID                typeCode;
  U32                refCount;
} CISweepNotify2;

typedef struct _CISweepDiskChangeVtbl
{
  CISWEEPUNKNOWN2VTBL;
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR OnDiskChange)(void *object, void *token, LPCOLESTR pFileName, U32 partNumber, U32 timesRound);
} CISweepDiskChangeVtbl;

typedef struct _CISweepDiskChange
{
  CISweepDiskChangeVtbl *pVtbl;
  IID                    typeCode;
  U32                    refCount;
} CISweepDiskChange;

typedef struct _CIEnumSweepResultsVtbl
{
  CISWEEPUNKNOWN2VTBL;
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR Next)(void *object, SOPHOS_ULONG cElement, void *pElement[], SOPHOS_ULONG *pcFetched);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR Skip)(void *object, SOPHOS_ULONG cElement);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR Reset)(void *object);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR Clone)(void *object, void **ppEnum);
} CIEnumSweepResultsVtbl;

typedef struct _CIEnumSweepResults
{
  CIEnumSweepResultsVtbl *pVtbl;
} CIEnumSweepResults;

typedef struct _CIEnumIDEDetailsVtbl
{
  CISWEEPUNKNOWN2VTBL;
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR Next)(void *object, SOPHOS_ULONG cElement, void *pElement[], SOPHOS_ULONG *pcFetched);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR Skip)(void *object, SOPHOS_ULONG cElement);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR Reset)(void *object);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR Clone)(void *object, void **ppEnum);
} CIEnumIDEDetailsVtbl;

typedef struct _CIEnumIDEDetails
{
  CIEnumIDEDetailsVtbl *pVtbl;
} CIEnumIDEDetails;

typedef struct _CIEnumEngineConfigVtbl
{
  CISWEEPUNKNOWN2VTBL;
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR Next)(void *object, SOPHOS_ULONG cElement, void *pElement[], SOPHOS_ULONG *pcFetched);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR Skip)(void *object, SOPHOS_ULONG cElement);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR Reset)(void *object);
  HRESULT (SOPHOS_STDCALL_PUBLIC_PTR Clone)(void *object, void **ppEnum);
} CIEnumEngineConfigVtbl;

typedef struct _CIEnumEngineConfig
{
  CIEnumEngineConfigVtbl *pVtbl;
} CIEnumEngineConfig;

#if !defined( __SOPHOS_WIN32__ ) && !defined( __SOPHOS_NW__ )
#ifdef __cplusplus
extern "C"
{
#endif /* __cplusplus */
  HRESULT SOPHOS_EXPORTC DllGetClassObject(REFCLSID CLSIDObject, REFIID IIDObject, void **ppObject);
#ifdef __cplusplus
}
#endif /* __cplusplus */
#endif /* ! __SOPHOS_WIN32__ */

#endif /* __CSAVI2C_DOT_H__ */
