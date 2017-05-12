/*
 * savierr.h (29-JAN-2002)
 *
 * This file is a part of the Sophos Anti-Virus Interface (SAVI)(tm).
 *
 * Copyright (C) 2002 Sophos Plc, Oxford, England.
 * All rights reserved.
 *
 * This source code is only intended as a supplement to the
 * SAVI(tm) Reference and related documentation for the library.
 *
 * SAVI error code definitions.
 */

#ifndef __SAVIERR_DOT_H__
#define __SAVIERR_DOT_H__

#include "savitype.h"   

#ifdef __SOPHOS_WIN32__

/* Windows standard error codes: */
#include <winerror.h>

/* On win32 we have aliases for the Windows definitions, to remain COM-compliant: */
#define SOPHOS_S_OK                    S_OK
#define SOPHOS_S_FALSE                 S_FALSE
#define SOPHOS_E_NOINTERFACE           E_NOINTERFACE
#define SOPHOS_CLASS_E_NOAGGREGATION   CLASS_E_NOAGGREGATION
#define SOPHOS_E_UNEXPECTED            E_UNEXPECTED
#define SOPHOS_E_OUTOFMEMORY           E_OUTOFMEMORY
#define SOPHOS_E_INVALIDARG            E_INVALIDARG
#define SOPHOS_E_NOTIMPL               E_NOTIMPL
#define SOPHOS_E_OUT_OF_DISK           STG_E_MEDIUMFULL
#define SOPHOS_RPC_E_WRONG_THREAD      RPC_E_WRONG_THREAD
#define SOPHOS_MAKE_HRESULT(sev,fac,code) (MAKE_HRESULT(sev,fac,code) | (1<<29))
#define SOPHOS_SEVERITY_SUCCESS        SEVERITY_SUCCESS
#define SOPHOS_SEVERITY_ERROR          SEVERITY_ERROR
#define SOPHOS_FACILITY_ITF            FACILITY_ITF
#define SOPHOS_SUCCEEDED(Status)       SUCCEEDED(Status)
#define SOPHOS_FAILED(Status)          FAILED(Status)
#define SOPHOS_CODE(Status)            HRESULT_CODE(Status)
#define SOPHOS_FACILITY(Status)        HRESULT_FACILITY(Status)
#define SOPHOS_SEVERITY(Status)        HRESULT_SEVERITY(Status)

#else    /* __SOPHOS_WIN32__ */

/* Supply some error codes analogous to Windows error codes: */
/* For IUnknown: */
#define SOPHOS_S_OK                    ((HRESULT)0x00000000L)
#define SOPHOS_S_FALSE                 ((HRESULT)0x00000001L)
#define SOPHOS_E_NOINTERFACE           ((HRESULT)0x80004002L)
/* For IClassFactory: */
#define SOPHOS_CLASS_E_NOAGGREGATION   ((HRESULT)0x80040110L)
#define SOPHOS_E_UNEXPECTED            ((HRESULT)0x8000FFFFL)
#define SOPHOS_E_OUTOFMEMORY           ((HRESULT)0x8007000EL)
#define SOPHOS_E_INVALIDARG            ((HRESULT)0x80070057L)
#define SOPHOS_E_NOTIMPL               ((HRESULT)0x80004001L)
#define SOPHOS_E_OUT_OF_DISK           ((HRESULT)0x80030070L)
#define SOPHOS_RPC_E_WRONG_THREAD      ((HRESULT)0x8001010EL)


/* Macros for defining error codes: */
#define SOPHOS_MAKE_HRESULT(sev,fac,code) \
    ((HRESULT) (((U32)(sev)<<31) | ((U32)(fac)<<16) | ((U32)(code))) )
#define SOPHOS_SEVERITY_SUCCESS    0
#define SOPHOS_SEVERITY_ERROR      1

#define SOPHOS_FACILITY_ITF        4

/* Macros for testing error results: */
#define SOPHOS_SUCCEEDED(Status)  ((HRESULT)(Status) >= 0)
#define SOPHOS_FAILED(Status)     ((HRESULT)(Status) < 0)
#define SOPHOS_CODE(Status)       ((HRESULT)(Status) & 0xFFFF)
#define SOPHOS_FACILITY(Status)   ((((HRESULT)(Status)) >> 16) & 0x1FFF)
#define SOPHOS_SEVERITY(Status)   ((((HRESULT)(Status)) >> 31) & 0x1)

#endif   /* __SOPHOS_WIN32__ */

/* Sophos-specific error messages: */

/* Introduced for SAVI2 and onwards */
#define SOPHOS_SAVI_ERROR_INITIALISING SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x200)
                        /* DLL failed to intialise. */

#define SOPHOS_SAVI_ERROR_TERMINATING SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x201)
                        /* Error while unloading. */

#define SOPHOS_SAVI_ERROR_SWEEPFAILURE SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x202)
                        /* The virus scan failed. */

#define SOPHOS_SAVI_ERROR_VIRUSPRESENT SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_SUCCESS, SOPHOS_FACILITY_ITF, 0x203)
                        /* A virus was detected. */

#define SOPHOS_SAVI_ERROR_NOT_INITIALISED SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x204)
                        /* Attempt to use virus engine without initialising it. */

#define SOPHOS_SAVI_ERROR_IC_INCOMPATIBLE_VERSION SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x205)
                        /* The installed version of SAV is running an     */
                        /* incompatible version of the InterCheck client. */

#define SOPHOS_SAVI_ERROR_IC_ACCESS_DENIED SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x206)
                        /* The process does not have sufficient rights */
                        /* to disable the InterCheck client.           */

#define SOPHOS_SAVI_ERROR_IC_SCAN_PREVENTED SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x207)
                        /* The InterCheck client could not be disabled.  */
                        /* The request to scan the file has been denied. */

#define SOPHOS_SAVI_ERROR_DISINFECTION_FAILED SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x208)
                        /* The disinfection failed. */

#define SOPHOS_SAVI_ERROR_DISINFECTION_UNAVAILABLE SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x209)
                        /* Disinfection was attempted on an uninfected file */
                        /* or the virus could not be removed.               */

#define SOPHOS_SAVI_ERROR_UPGRADE_FAILED SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x20A)
                        /* An attempted upgrade to the virus engine failed. */

#define SOPHOS_SAVI_ERROR_SAV_NOT_INSTALLED SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x20B)
                        /* Sophos Anti Virus has been removed from this machine. */
                        
#define SOPHOS_SAVI_ERROR_INVALID_CONFIG_NAME SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x20C)
                        /* Attempt to get/set SAVI configuration with incorrect name. */

#define SOPHOS_SAVI_ERROR_INVALID_CONFIG_TYPE SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x20D)
                        /* Attempt to get/set SAVI configuration with incorrect type. */

#define SOPHOS_SAVI_ERROR_INIT_CONFIGURATION SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x20E)
                        /* Could not configure SAVI. */

#define SOPHOS_SAVI_ERROR_NOT_SUPPORTED SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x20F)
                        /* File format not supported (scanning) or SAVI function not implementated. */

#define SOPHOS_SAVI_ERROR_COULD_NOT_OPEN SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x210)
                        /* File couldn't be accessed. */

#define SOPHOS_SAVI_ERROR_FILE_COMPRESSED SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x211)
                        /* File was compressed, but no virus was found on the outer level. */

#define SOPHOS_SAVI_ERROR_FILE_ENCRYPTED SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x212)
                        /* File was encrypted. */

#define SOPHOS_SAVI_ERROR_INFORMATION_NOT_AVAILABLE SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x213)
                        /* Additional virus location is unavailable. */

#define SOPHOS_SAVI_ERROR_ALREADY_INIT SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x214)
                        /* Attempt to initialise when already initialised. */

#define SOPHOS_SAVI_ERROR_STUB SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x215)
                        /* Attempt to use a stub library. */

#define SOPHOS_SAVI_ERROR_BUFFER_TOO_SMALL SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x216)
                        /* Buffer supplied was too small. */

#define SOPHOS_SAVI_CBCK_CONTINUE_THIS SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_SUCCESS, SOPHOS_FACILITY_ITF, 0x217)
                        /* Returned from a callback function to continue with the current file. */

#define SOPHOS_SAVI_CBCK_CONTINUE_NEXT SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_SUCCESS, SOPHOS_FACILITY_ITF, 0x218)
                        /* Returned from a callback function to skip to the next file. */

#define SOPHOS_SAVI_CBCK_STOP SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_SUCCESS, SOPHOS_FACILITY_ITF, 0x219)
                        /* Returned from a callback function to stop the current operation. */

#define SOPHOS_SAVI_ERROR_CORRUPT SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x21A)
                        /* Sweep could not proceed, the file was corrupted. */

#define SOPHOS_SAVI_ERROR_REENTRANCY SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x21B)
                        /* An attempt to re-enter SAVI from a callback notification was detected. */
 
#define SOPHOS_SAVI_ERROR_CALLBACK SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x21C)
                        /* An error was encountered in the SAVI client's callback function. */

#define SOPHOS_SAVI_ERROR_PARTIAL_INFORMATION SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_SUCCESS, SOPHOS_FACILITY_ITF, 0x21D)
                        /* A call requesting several pieces of information did not return them all. */

#define SOPHOS_SAVI_ERROR_OLD_VIRUS_DATA SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_SUCCESS, SOPHOS_FACILITY_ITF, 0x21E)
                        /* The main body of virus data is out of date. */

#define SOPHOS_SAVI_ERROR_INVALID_TMP SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_SUCCESS, SOPHOS_FACILITY_ITF, 0x21F)
                        /* No valid temporary directory found. */

#define SOPHOS_SAVI_ERROR_MISSING_MAIN_VIRUS_DATA SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x220)
                        /* The main body of virus data is missing. */

#define SOPHOS_SAVI_INFO_IC_ACTIVE SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_SUCCESS, SOPHOS_FACILITY_ITF, 0x221)
                        /* The InterCheck client is active, and could not be disabled. */

#define SOPHOS_SAVI_ERROR_VIRUS_DATA_INVALID_VER SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x222)
                        /* The virus data main body has an invalid version. */

#define SOPHOS_SAVI_ERROR_MUST_REINIT SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x223)
                        /* SAVI must be reinitialised - the virus engine has a version */
                        /* higher than the running version of SAVI supports.           */

#define SOPHOS_SAVI_ERROR_CANNOT_SET_OPTION SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_SUCCESS, SOPHOS_FACILITY_ITF, 0x224)
                        /* Cannot set option value - the virus engine will not permit */
                        /* its value to be changed, as this option is immutable.      */

#define SOPHOS_SAVI_ERROR_PART_VOL SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x225)
                        /* The file passed for scanning represented part of a multi */
                        /* volume archive. The file cannot be scanned.              */

/* Introduced for SAVI3 and onwards */
#define SOPHOS_SAVI_CBCK_DEFAULT SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_SUCCESS, SOPHOS_FACILITY_ITF, 0x226)
                        /* Returned from a callback function to request default processing. */

#define SOPHOS_SAVI_INFO_OPT_GRP_INVAL_RTN SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_SUCCESS, SOPHOS_FACILITY_ITF, 0x227)
                        /* Returned if GetConfigValue() is called for a grouped engine setting.   */
                        /* This informational error code means that no meaning can be assigned to */
                        /* any value returned as the "value read" for the passed setting name.    */
             
#define SOPHOS_SAVI_ERROR_VDLD_ACTIVITY SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x228)
                        /* Operation failed due to incompatible pending / ongoing activity on */
                        /* Virus data.  (E.g. attempt to scan file while updating VDL data or */
                        /* attempt to update VDL data while scan in progress).                */

#define SOPHOS_SAVI_ERROR_STREAM_READ_FAIL SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x229)
                        /* For ISaviStream implementation: ReadStream failed. */

#define SOPHOS_SAVI_ERROR_STREAM_WRITE_FAIL SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x22A)
                        /* For ISaviStream implementation: WriteStream failed. */

#define SOPHOS_SAVI_ERROR_STREAM_SEEK_FAIL SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x22B)
                        /* For ISaviStream implementation: SeekStream failed. */

#define SOPHOS_SAVI_ERROR_STREAM_GETLENGTH_FAIL SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x22C)
                        /* For ISaviStream implementation: GetLength failed. */

#define SOPHOS_SAVI_ERROR_MISSING_VDL_PART SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x22D)
                        /* One of the files in a split-virus data set could not be located. */

#define SOPHOS_SAVI_WARNING_MISSING_VDL_PART SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_SUCCESS, SOPHOS_FACILITY_ITF, 0x22E)
                        /* "Warning-only" version of the previous error code. */

#define SOPHOS_SAVI_ERROR_VDL_CHECKSUM SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x22F)
                        /* One of the files in a split-virus data set has the wrong checksum. */

#define SOPHOS_SAVI_WARNING_VDL_CHECKSUM SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_SUCCESS, SOPHOS_FACILITY_ITF, 0x230)
                        /* "Warning-only" version of the previous error code. */

#define SOPHOS_SAVI_ERROR_SCAN_ABORTED SOPHOS_MAKE_HRESULT(SOPHOS_SEVERITY_ERROR, SOPHOS_FACILITY_ITF, 0x231)
                        /* Scan aborted by SAVI "AutoStop". */


#endif   /*__SAVIERR_DOT_H__*/

