/*
 * isavi2.h (26-NOV-1999)
 *
 * This file is a part of the Sophos Anti-Virus Interface (SAVI)(tm).
 *
 * Copyright (C) 2002 Sophos Plc, Oxford, England.
 * All rights reserved.
 *
 * This source code is only intended as a supplement to the
 * SAVI(tm) Reference and related documentation for the library.
 *
 * Sophos ISavi2 declarations.
 */

#ifndef __ISAVI2_H__
#define __ISAVI2_H__

#include "savitype.h"   /* SAVI types */
#include "swerror2.h"   /* Savi2 error codes */
#include "iswfact2.h"   /* The class factory */
#include "swiid.h"      /* Interface identifiers */

#ifdef __SOPHOS_WIN32__
#  include <unknwn.h>   /* IUnknown interface */
#  define SAVI_IUNKNOWN IUnknown
#else    /* __SOPHOS_WIN32__ */
#  include "iswunk2.h"  /* ISweepUnknown interface */
#  define SAVI_IUNKNOWN ISweepUnknown2
#endif   /* __SOPHOS_WIN32__ */

/* Forward declarations */
class ISweepResults;
class ISweepError;
class IIDEDetails;
class IEngineConfig;
class ISweepNotify;

/* General purpose enumerator: */

template <class T> 
class IEnum : public SAVI_IUNKNOWN
/* This class provides access to a list of objects of type T. */
{
public:
   virtual HRESULT SOPHOS_STDCALL Next( SOPHOS_ULONG cElement, 
                                        T pElement[], 
                                        SOPHOS_ULONG *pcFetched ) = 0;
      /* Description:
            Copy the next cElements in pElement, which the caller must allocate.

         Parameters:
            cElement       The number of elements requested.
            pElement       A caller allocated buffer that can receive cElement entries.
            pcFetched      Pointer to a variable which will contain the actual number
                           of entries copied into pElement. Supply NULL if you don't
                           want this value.
         Return value:
            Success codes:
            SOPHOS_S_OK    The requested number of elements were copied into pElement.
            SOPHOS_S_FALSE Less than the requested number of elements were copied into pElement.

            Failure codes:
            SOPHOS_E_INVALIDARG   
                           An invalid pointer parameter was supplied.
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      
      */

   virtual HRESULT SOPHOS_STDCALL Skip( SOPHOS_ULONG cElement ) = 0;
      /* Description:
            Skip the next cElements.

         Parameters:
            cElement       The number of elements to skip.

         Return value:
            Success codes:
            SOPHOS_S_OK    The requested number of elements were skipped.
            SOPHOS_S_FALSE Less than the requested number of elements were skipped.

            Failure codes:
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      
      */

   virtual HRESULT SOPHOS_STDCALL Reset() = 0;                    
      /* Description:
            Reset the enumerator to the start of the list.

         Parameters:
            None.

         Return value:
            Success codes:
            SOPHOS_S_OK    The enumerator was reset successfully.

            Failure codes:
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      
      */

   virtual HRESULT SOPHOS_STDCALL Clone( IEnum<T> **ppEnum ) = 0;   
      /* Description:
            Take a copy of this enumerator in its current state.

         Parameters:
            ppEnum         A pointer which will point to the newly
                           cloned enumerator.

         Return value:
            Success codes:
            SOPHOS_S_OK    The enumerator was cloned successfully.

            Failure codes:
            SOPHOS_E_INVALIDARG   
                           An invalid pointer parameter was supplied.
            SOPHOS_E_OUTOFMEMORY  
                           Insufficient memory available to create the clone.
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      
      */
};

typedef IEnum<ISweepResults *> IEnumSweepResults;  /* List of sweep results. */
typedef IEnum<IIDEDetails *> IEnumIDEDetails;      /* List of IDE details. */
typedef IEnum<IEngineConfig *> IEnumEngineConfig;  /* List of sweep engine settings. */

/* Interface version 2 */

class ISavi2 : public SAVI_IUNKNOWN
{
public:
   virtual HRESULT SOPHOS_STDCALL Initialise() = 0;
   virtual HRESULT SOPHOS_STDCALL InitialiseWithMoniker( LPCOLESTR pApplicationMoniker ) = 0;
      /* Description:
            Initialise the sweep engine ready for use. Call this before using
            any other parts of the SAVI interface. The client must eventually
            call Terminate() to finish with the interface.

         Parameters:
            pApplicationMoniker  Some text to identify this instance of the SAVI 
                                 interface. The text appears on the sweep GUI and 
                                 is used to identify configuration settings as 
                                 specific to this instance of SAVI.
            
         Return value:
            Success codes:
            SOPHOS_S_OK    The interface was successfully initialised.
            SOPHOS_SAVI_ERROR_OLD_VIRUS_DATA
                           The interface was successfully initialised but the
                           internal virus data is beyond its useful life.
                           Sophos recommends that the virus engine be upgraded
                           to a newer version as soon as possible.
                           
            Failure codes:
            SOPHOS_SAVI_ERROR_ALREADY_INIT
                           The interface was already initialised.
            SOPHOS_SAVI_ERROR_SAV_NOT_INSTALLED
                           Sophos anti-virus software is not installed on this
                           computer.
            SOPHOS_SAVI_ERROR_INITIALISING                           
                           A non-specific initialisation error.
            SOPHOS_SAVI_ERROR_INIT_CONFIGURATION                             
                           An internal error occured initialising the engine
                           configuration.
            SOPHOS_SAVI_ERROR_MISSING_MAIN_VIRUS_DATA
                           The main body of virus data is missing.
            SOPHOS_SAVI_ERROR_CORRUPT
                           The virus data was corrupt.
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      
      */

   virtual HRESULT SOPHOS_STDCALL RegisterNotification( REFIID NotifyIID, 
                                                        void *pCallbackInterface, 
                                                        void *Token ) = 0;
      /* Description:
            Register a notification callback to be invoked during virus scans.
            The caller must create an object of the correct type and supply a pointer to it.
            At present only objects of type ISweepNotify and ISweepDiskChange are supported.
            Note that the object type and NotifyIID values must match.

         Parameters:
            NotifyIID      Identifies the type of the configuration data to be returned.
                           (see manual for a list of IIDs supported).
            pCallbackInterface      
                           A pointer to the callback object created by the caller
                           and register for callbacks.
                           Supply NULL to unregister a previously registered object.
            Token          This value will be passed to notification functions in the 
                           callback interface. It is not used within the SAVI interface.
                           Typically it is used to point to some data in the SAVI client
                           which the notification function needs to use. Supply NULL if this
                           value is not used.
                          
         Return value:
            
            Success codes:
            SOPHOS_S_OK    The callback object was successfully registered.

            Failure codes:
            SOPHOS_SAVI_ERROR_NOT_INITIALISED
                           Neither initialisation function has been called.
      	    SOPHOS_SAVI_ERROR_UPGRADE_FAILED
                           An attempt to upgrade the sweep engine failed and the SAVI
                           interface is temporarily unavailable.
            SOPHOS_E_INVALIDARG   
                           pCallbackInterface did not point to a valid memory location.
            SOPHOS_E_NOINTERFACE  
                           NotifyIID specified a notification object type not supported by
                           this version of SAVI.
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      */

   virtual HRESULT SOPHOS_STDCALL GetVirusEngineVersion( U32* pVersion,
                                                         LPOLESTR pVersionString,
                                                         U32 StringLength,
                                                         SYSTEMTIME* pVdataDate,
                                                         U32* pNumberOfDetectableViruses,
                                                         U32* pVersionEx,
                                                         REFIID DetailsIID,
                                                         void** ppDetailsList ) = 0;

      /* Description:
            Get the version number, text and date of the virus sweep engine, together
            with the number of different viruses that can be detected.
            Optionally an enumerator of additional virus identity files can be created.
            

         Parameters:
            pVersion       A pointer to a location for the version number. This can be NULL
                           if not required.
            pVersionString A pointer to a buffer for the version string. This can be NULL
                           if not required.
            StringLength   The size of the buffer allocatef for pVersionString IN CHARACTERS.
            pVdataDate     A pointer to a location for the date of the main virus data. This 
                           can be NULL if not required.
            pNumberOfDetectableViruses
                           A pointer to a location for the number of detectable viruses. 
                           This can be NULL if not required.
            pSubVersion    A pointer to a location for sub-version number.  Can be NULL if 
                           not required.
            DetailsIID     Identifies the type of the identity file details to be returned.
                           At present this must be SOPHOS_IID_ENUM_IDEDETAILS.
            ppDetailsList  A pointer to a pointer to the interface object created by this 
                           function. The object can be used by the client to enumerate 
                           objects of the class specified by the DetailsIID parameter. If 
                           there are none, an enumerator containing zero items is returned. 
                           When the client has finished with the enumerator object, it must 
                           call Release() on the object.
                           This parameter can be NULL if not required.
     
         Return value:

            Success codes:
            SOPHOS_S_OK    All requested information on current loaded virus engine retrieved.
            SOPHOS_SAVI_ERROR_OLD_VIRUS_DATA
                           The interface was successfully initialised but the internal
                           virus data is beyond its useful life. Sophos recommends that
                           the virus engine be upgraded to a newer version as soon as
                           possible.
                           NB if both SOPHOS_SAVI_ERROR_OLD_VIRUS_DATA and
                           SOPHOS_SAVI_ERROR_PARTIAL_INFORMATION are true then 
                           SOPHOS_SAVI_ERROR_OLD_VIRUS_DATA will be returned.

            SOPHOS_SAVI_ERROR_PARTIAL_INFORMATION
                           Some of the  requested information on current loaded virus engine
                           could not be retrieved .

            Failure codes:
            SOPHOS_SAVI_ERROR_NOT_INITIALISED
                           Neither initialisation function has been called.
      		SOPHOS_SAVI_ERROR_UPGRADE_FAILED
                           An attempt to upgrade the sweep engine failed and the SAVI
                           interface is temporarily unavailable.
            SOPHOS_E_INVALIDARG   
                           ppResults was non-NULL but did not point to a valid memory
                           location.
            SOPHOS_E_NOINTERFACE  
                           DetailsIID specified a details object type not supported by
                           this version of SAVI.
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      */

   virtual HRESULT SOPHOS_STDCALL Terminate() = 0;
      /* Description:
            Call this to finish using this interface and release the virus sweep engine.
            
         Parameters:
            none.

         Return value:

            Success codes:
            SOPHOS_S_OK    Termination was successful.

            Failure codes:
            SOPHOS_SAVI_ERROR_NOT_INITIALISED
                           Neither initialisation function has been called.
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      */

   virtual HRESULT SOPHOS_STDCALL SetConfigDefaults() = 0;
      /* Description:
            Set all sweep engine configurations to their default values.
            
         Parameters:
            none.

         Return value:

            Success codes:
            SOPHOS_S_OK    Default values were restored successfully.

            Failure codes:
            SOPHOS_SAVI_ERROR_NOT_INITIALISED
                           Neither initialisation function has been called.
      		SOPHOS_SAVI_ERROR_UPGRADE_FAILED
                           An attempt to upgrade the sweep engine failed and the SAVI
                           interface is temporarily unavailable.
            SOPHOS_SAVI_ERROR_INIT_CONFIGURATION                             
                           An internal error occured initialising the engine configuration.
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      */

   virtual HRESULT SOPHOS_STDCALL ReadConfig() = 0;
      /* Description:
            Not implemented in current versions of SAVI. 
            
         Parameters:
            none.

         Return value:

            Failure codes:
            SOPHOS_SAVI_ERROR_NOT_SUPPORTED
                           Function not supported.
      */

   virtual HRESULT SOPHOS_STDCALL WriteConfig() = 0;
      /* Description:
            Not implemented in current versions of SAVI. 
            
         Parameters:
            none.

         Return value:

            Failure codes:
            SOPHOS_SAVI_ERROR_NOT_SUPPORTED
                           Function not supported.
      */

   virtual HRESULT SOPHOS_STDCALL GetConfigEnumerator( REFIID ConfigIID, void **ppConfigs ) = 0;
      /* Description:
            Get an enumerator object which will enumerate the configuration values and types
            supported by this interface.

         Parameters:
            ConfigIID      Identifies the type of the configuration data to be returned.
                           At present this must be SOPHOS_IID_ENUM_ENGINECONFIG.
            ppResults      A pointer to a pointer to an IEnumEngineConfigs object which
                           will be created by this function. When the caller has finished 
                           with the object,  it must call Release() on the object.
     
         Return value:
            
            Success codes:
            SOPHOS_S_OK    The enumerator object was obtained successfully.

            Failure codes:
            SOPHOS_SAVI_ERROR_NOT_INITIALISED
                           Neither initialisation function has been called.
      		SOPHOS_SAVI_ERROR_UPGRADE_FAILED
                           An attempt to upgrade the sweep engine failed and the SAVI
                           interface is temporarily unavailable.
            SOPHOS_E_INVALIDARG   
                           ppCOnfigs was non-NULL but did not point to a valid memory
                           location.
            SOPHOS_E_NOINTERFACE  
                           ConfigIID specified a configuration object type not supported by
                           this version of SAVI.
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      */

   virtual HRESULT SOPHOS_STDCALL SetConfigValue( LPCOLESTR pValueName,
                                                  U32 Type,
                                                  LPCOLESTR pData ) = 0;
      /* Description:
            Set the value of a specific sweep engine configuration parameter.
            
         Parameters:
            pValueName     The name of the configuration parameter. 
            Type           The type of the parameter, one of the SOPHOS_TYPE_* constants.
            pData          The value of the parameter, which is always encoded as text.                        

            Valid parameter names and types can be obtained using the configuration 
            parameter enumerator obtained by calling GetConfigEnumerator()

         Return value:

            Success codes:
            SOPHOS_S_OK    The parameter value was set correctly.

            Failure codes:
            SOPHOS_SAVI_ERROR_NOT_INITIALISED
                           Neither initialisation function has been called.
      		SOPHOS_SAVI_ERROR_UPGRADE_FAILED
                           An attempt to upgrade the sweep engine failed and the SAVI
                           interface is temporarily unavailable.
            SOPHOS_SAVI_ERROR_INVALID_CONFIG_NAME
                           The combination of parameter name and type was not valid.
            SOPHOS_ERROR_INVALID_PARAMETER
                           In error occured storing the value supplied.
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      */

   virtual HRESULT SOPHOS_STDCALL GetConfigValue( LPCOLESTR pValueName,
                                                  U32 Type,
                                                  U32 MaxSize,
                                                  LPOLESTR pData,
                                                  U32* pSize ) = 0;
      /* Description:
            Get the value of a specific sweep engine configuration parameter.
            
         Parameters:
            pValueName     The name of the configuration parameter. 
            Type           The type of the parameter, one of the SOPHOS_TYPE_* constants.
            MaxSize        The number of characters allocated by the caller for the value.
            pData          Pointer to a buffer of length MaxSize which will receive the value.
                           Supply NULL if you do not require this value.
            pSize          This location receives the total length of the config value 
                           INCLUDING TERMINATOR, in characters.

         Return value:

            Success codes:
            SOPHOS_S_OK    The buffer supplied was big enough and the name was copied into it.
                           
            Failure codes:
            SOPHOS_SAVI_ERROR_BUFFER_TOO_SMALL
                           The buffer supplied by the user was not big enough.
            SOPHOS_SAVI_ERROR_NOT_INITIALISED
                           Neither initialisation function has been called.
      		SOPHOS_SAVI_ERROR_UPGRADE_FAILED
                           An attempt to upgrade the sweep engine failed and the SAVI
                           interface is temporarily unavailable.
            SOPHOS_SAVI_ERROR_INVALID_CONFIG_NAME
                           The combination of parameter name and type was not valid.
            SOPHOS_ERROR_INVALID_PARAMETER
                           In error occured storing the value supplied.
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      */

   virtual HRESULT SOPHOS_STDCALL SweepFile( LPCOLESTR pFileName, 
                                             REFIID ResultsIID, 
                                             void **ppResults ) = 0;
      /* Description:
            Sweep a file for viruses. 

         Parameters:
            pFileName      The name of the file to sweep.
            ResultsIID     Identifies the type of the results to be returned.
                           At present this must be SOPHOS_IID_ENUM_SWEEPRESULTS.
            ppResults      A pointer to a pointer to an IEnumSweepResults object which
                           will be created by this function. The object can be used
                           by the caller to enumerate any viruses found in the file.
                           If there are no viruses, an enumerator containing zero items
                           is returned. When the caller has finished with the object, 
                           it must call Release() on the object.
                           This parameter may be supplied as NULL, in which case no sweep
                           results object is created.
     
         Return value:
            Note that there are multiple success codes so it is recommended that callers
            use the SUCCEEDED() macro to test for successful completion of this function.
            
            Success codes:
            SOPHOS_S_OK    The file was successfully swept and contained no viruses.
            SOPHOS_SAVI_ERROR_VIRUSPRESENT
                           The file was successfully swept and contained one or more viruses.
            SOPHOS_SAVI_ERROR_OLD_VIRUS_DATA
                           The file was successfully swept but the internal virus data is 
                           beyond its useful life. Sophos recommends that the virus engine be 
                           upgraded to a newer version as soon as possible.

            Failure codes:
            SOPHOS_SAVI_ERROR_NOT_INITIALISED
                           Neither initialisation function has been called.
      		SOPHOS_SAVI_ERROR_UPGRADE_FAILED
                           An attempt to upgrade the sweep engine failed and the SAVI
                           interface is temporarily unavailable.
            SOPHOS_E_INVALIDARG   
                           ppResults was non-NULL but did not point to a valid memory
                           location.
            SOPHOS_E_NOINTERFACE  
                           ResultsIID specified a results object type not supported by
                           this version of SAVI.
            RPC_E_WRONG_THREAD
                           A callback was installed using RegisterNotification() on a 
                           different thread to the current one. Both calls must be on the
                           same thread.
            SOPHOS_SAVI_ERROR_IC_INCOMPATIBLE_VERSION
                           The version of intercheck installed is not compatible with
                           this version of SAVI.
            SOPHOS_SAVI_ERROR_IC_ACCESS_DENIED
                           The calling process does not have sufficient rights to disable 
                           the InterCheck client.
            SOPHOS_SAVI_ERROR_IC_SCAN_PREVENTED
                           The InterCheck client could not be disabled.    
            SOPHOS_SAVI_ERROR_SWEEPFAILURE
                           The sweep engine could not sweep the file.
                           Call GetLastError() for more information.
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      */

   virtual HRESULT SOPHOS_STDCALL DisinfectFile( LPCOLESTR pFileName, 
                                                 REFIID ResultsIID, 
                                                 void **ppResults ) = 0;
      /* Description:
            Attempt to disinfect a file which contains a virus, then sweep the file to
            see if it contains any viruses after the attempt.

         Parameters:
            pFileName      The name of the file to sweep.
            ResultsIID     Identifies the type of the results to be returned.
                           At present this must be SOPHOS_IID_ENUM_SWEEPRESULTS.
            ppResults      A pointer to a pointer to an IEnumSweepResults object which
                           will be created by this function. The object can be used
                           by the caller to enumerate any viruses found in the file after
                           the disinfectinon attempt. If there are no viruses, an enumerator 
                           containing zero items is returned. 
                           When the caller has finished with the object, 
                           it must call Release() on the object.
                           This parameter may be supplied as NULL, in which case no sweep
                           results object is created.
     
         Return value:

            Success codes:
            Note that there are multiple success codes so it is recommended that callers
            use the SUCCEEDED() macro to test for successful completion of this function.
            
            SOPHOS_S_OK    The infected file was successfully disinfected
            SOPHOS_SAVI_ERROR_OLD_VIRUS_DATA
                           The infected file was successfully disinfected but the internal 
                           virus data is beyond its useful life. Sophos recommends that the 
                           virus engine be upgraded to a newer version as soon as possible.

            Failure codes:
            SOPHOS_SAVI_ERROR_DISINFECTION_UNAVAILABLE
                           The file could not be disinfected. Either it initially contained
                           no virus, or the virus could not be removed.
            SOPHOS_SAVI_ERROR_DISINFECTION_FAILED
                           The virus could not be removed, the disinfection attempt failed.
            SOPHOS_SAVI_ERROR_NOT_INITIALISED
                           Neither initialisation function has been called.
      		SOPHOS_SAVI_ERROR_UPGRADE_FAILED
                           An attempt to upgrade the sweep engine failed and the SAVI
                           interface is temporarily unavailable.
            SOPHOS_E_INVALIDARG   
                           ppResults was non-NULL but did not point to a valid memory
                           location.
            SOPHOS_E_NOINTERFACE  
                           ResultsIID specified a results object type not supported by
                           this version of SAVI.
            RPC_E_WRONG_THREAD
                           A callback was installed using RegisterNotification() on a 
                           different thread to the current one. Both calls must be on the
                           same thread.
            SOPHOS_SAVI_ERROR_IC_INCOMPATIBLE_VERSION
                           The version of intercheck installed is not compatible with
                           this version of SAVI.
            SOPHOS_SAVI_ERROR_IC_ACCESS_DENIED
                           The calling process does not have sufficient rights to disable 
                           the InterCheck client.
            SOPHOS_SAVI_ERROR_IC_SCAN_PREVENTED
                           The InterCheck client could not be disabled.    
            SOPHOS_SAVI_ERROR_SWEEPFAILURE
                           The sweep engine could not sweep the file.
                           Call GetLastError() for more information.
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      */

   virtual HRESULT SOPHOS_STDCALL SweepLogicalSector( LPCOLESTR pDriveName,
                                                      U32 Reserved,
                                                      U32 SectorNumber,
                                                      REFIID ResultsIID,
                                                      void **ppResults ) = 0;
      /* Description:
            Sweeps a logical disk sector for viruses. At present SAVI can address
            2^32 sectors. This implies that SAVI can scan sectors on disks with
            512 Bytes/Sector up to (2^32)*(2^9) or approximately 2 TeraBytes.

         Parameters:
            pDriveName     The name of the disk drive to sweep. This is platform dependant.
                           On Win32 use a string formatted as follows:
                              \\.\A: (where A is the drive letter).
                           On UNIX use a string formatted as follows:
                              /dev/<device name>

            Reserved       This value is reserved - it must be 0.
            SectorNumber   The sector number you wish to scan (zero based)

            ResultsIID     Identifies the type of the results to be returned.
                           At present this must be SOPHOS_IID_ENUM_SWEEPRESULTS.

            ppResults      A pointer to a pointer to an IEnumSweepResults object which
                           will be created by this function. The object can be used
                           by the caller to enumerate any viruses found on the disk sector.
                           If there are no viruses, an enumerator containing zero items
                           is returned. When the caller has finished with the object, 
                           it must call Release() on the object.
                           This parameter may be supplied as NULL, in which case no sweep
                           results object is created.
     
         Return value:
            Note that there are multiple success codes so it is recommended that callers
            use the SOPHOS_SUCCEEDED() macro to test for successful completion of this function.
            
            Success codes:
            SOPHOS_S_OK    The sector was successfully swept and contained no viruses.
            SOPHOS_SAVI_ERROR_VIRUSPRESENT
                           The sector was successfully swept and contained one or more viruses.
            SOPHOS_SAVI_ERROR_OLD_VIRUS_DATA
                           The sector was successfully swept but the internal virus data is 
                           beyond its useful life. Sophos recommends that the virus engine be 
                           upgraded to a newer version as soon as possible.
            
            Failure codes:
            SOPHOS_SAVI_ERROR_NOT_INITIALISED
                           Neither initialisation function has been called.
      		SOPHOS_SAVI_ERROR_UPGRADE_FAILED
                           An attempt to upgrade the sweep engine failed and the SAVI
                           interface is temporarily unavailable.
            SOPHOS_E_INVALIDARG   
                           Either an invalid drive name was supplied or ppResults was 
                           non-NULL but did not point to a valid memory location.
            SOPHOS_E_NOINTERFACE  
                           ResultsIID specified a results object type not supported by
                           this version of SAVI.
            RPC_E_WRONG_THREAD
                           A callback was installed using RegisterNotification() on a 
                           different thread to the current one. Both calls must be on the
                           same thread.
            SOPHOS_SAVI_ERROR_IC_INCOMPATIBLE_VERSION
                           The version of intercheck installed is not compatible with
                           this version of SAVI.
            SOPHOS_SAVI_ERROR_IC_ACCESS_DENIED
                           The calling process does not have sufficient rights to disable 
                           the InterCheck client.
            SOPHOS_SAVI_ERROR_IC_SCAN_PREVENTED
                           The InterCheck client could not be disabled.    
            SOPHOS_SAVI_ERROR_SWEEPFAILURE
                           The sweep engine could not sweep the sector.
                           Call GetLastError() for more information.
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      */

   virtual HRESULT SOPHOS_STDCALL SweepPhysicalSector( LPCOLESTR pDriveName,
                                                       U32 Head,
                                                       U32 Cylinder,
                                                       U32 Sector,
                                                       REFIID ResultsIID,
                                                       void **ppResults ) = 0;
      /* Description:
            Sweeps a physical disk sector for viruses.

         Parameters:
            pDriveName     The name of the disk drive to sweep. This is platform dependant.
                           On Win32 use a string formatted as follows:
                              either -  \\.PHYSICALDRIVEx where x is the physical driver number
                                        (0 for the first fixed disk).
                              or     -  \\.\A: (where A is the drive letter).

                           On UNIX use a string formatted as follows:
                              /dev/<device name>

            Head           The zero based index to the physical disk head
            Cylinder       The zero based index to the physical disk cylinder
            Sector         The ONE based index to the physical disk sector

            ResultsIID     Identifies the type of the results to be returned.
                           At present this must be SOPHOS_IID_ENUM_SWEEPRESULTS.
            ppResults      A pointer to a pointer to an IEnumSweepResults object which
                           will be created by this function. The object can be used
                           by the caller to enumerate any viruses found on the disk sector.
                           If there are no viruses, an enumerator containing zero items
                           is returned. When the caller has finished with the object, 
                           it must call Release() on the object.
                           This parameter may be supplied as NULL, in which case no sweep
                           results object is created.
     
         Return value:
            Note that there are multiple success codes so it is recommended that callers
            use the SOPHOS_SUCCEEDED() macro to test for successful completion of this function.
            
            Success codes:
            SOPHOS_S_OK    The sector was successfully swept and contained no viruses.
            SOPHOS_SAVI_ERROR_VIRUSPRESENT
                           The sector was successfully swept and contained one or more viruses.
            SOPHOS_SAVI_ERROR_OLD_VIRUS_DATA
                           The sector was successfully swept but the internal virus data is 
                           beyond its useful life. Sophos recommends that the virus engine be 
                           upgraded to a newer version as soon as possible.

            Failure codes:
            SOPHOS_SAVI_ERROR_NOT_INITIALISED
                           Neither initialisation function has been called.
      		SOPHOS_SAVI_ERROR_UPGRADE_FAILED
                           An attempt to upgrade the sweep engine failed and the SAVI
                           interface is temporarily unavailable.
            SOPHOS_E_INVALIDARG   
                           Either an invalid drive name was supplied or ppResults was 
                           non-NULL but did not point to a valid memory location.
            SOPHOS_E_NOINTERFACE  
                           ResultsIID specified a results object type not supported by
                           this version of SAVI.
            RPC_E_WRONG_THREAD
                           A callback was installed using RegisterNotification() on a 
                           different thread to the current one. Both calls must be on the
                           same thread.
            SOPHOS_SAVI_ERROR_IC_INCOMPATIBLE_VERSION
                           The version of intercheck installed is not compatible with
                           this version of SAVI.
            SOPHOS_SAVI_ERROR_IC_ACCESS_DENIED
                           The calling process does not have sufficient rights to disable 
                           the InterCheck client.
            SOPHOS_SAVI_ERROR_IC_SCAN_PREVENTED
                           The InterCheck client could not be disabled.    
            SOPHOS_SAVI_ERROR_SWEEPFAILURE
                           The sweep engine could not sweep the sector.
                           Call GetLastError() for more information.
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      */


   virtual HRESULT SOPHOS_STDCALL DisinfectLogicalSector( LPCOLESTR pDriveName,
                                                          U32 Reserved,
                                                          U32 SectorNumber,
                                                          REFIID ResultsIID,
                                                          void **ppResults ) = 0;
      /* Description:
            Attempt to disinfect a logical disk sector, then sweep the sector to
            see if it contains any viruses after the attempt. At present SAVI can
            address 2^32 sectors. This implies that SAVI can scan sectors on disks
            with 512 Bytes/Sector up to (2^32)*(2^9) or approximately 2 TeraBytes.

         Parameters:
            pDriveName     The name of the disk drive to sweep. This is platform dependant.
                           On Win32 use a string formatted as follows:
                              \\.\A: (where A is the drive letter).
                           On UNIX use a string formatted as follows:
                              /dev/<device name>
            Reserved       This value is reserved - it must be 0.
            SectorNumber   The sector number you wish to scan (zero based)

            ResultsIID     Identifies the type of the results to be returned.
                           At present this must be SOPHOS_IID_ENUM_SWEEPRESULTS.
            
            ppResults      A pointer to a pointer to an IEnumSweepResults object which
                           will be created by this function. The object can be used
                           by the caller to enumerate any viruses found on the disk sector
                           after the disinfection attempt.
                           If there are no viruses, an enumerator containing zero items
                           is returned. When the caller has finished with the object, 
                           it must call Release() on the object.
                           This parameter may be supplied as NULL, in which case no sweep
                           results object is created.
     
         Return value:
            Note that there are multiple success codes so it is recommended that callers
            use the SOPHOS_SUCCEEDED() macro to test for successful completion of this function.

            Success codes:
            SOPHOS_S_OK    The infected sector was successfully disinfected
            SOPHOS_SAVI_ERROR_OLD_VIRUS_DATA
                           The infected sector was successfully disinfected but the internal 
                           virus data is beyond its useful life. Sophos recommends that the 
                           virus engine be upgraded to a newer version as soon as possible.

            Failure codes:
            SOPHOS_SAVI_ERROR_DISINFECTION_UNAVAILABLE
                           The sector could not be disinfected. Either it initially contained
                           no virus, or the virus could not be removed.
            SOPHOS_SAVI_ERROR_DISINFECTION_FAILED
                           The virus could not be removed, the disinfection attempt failed.
            SOPHOS_SAVI_ERROR_NOT_INITIALISED
                           Neither initialisation function has been called.
      		SOPHOS_SAVI_ERROR_UPGRADE_FAILED
                           An attempt to upgrade the sweep engine failed and the SAVI
                           interface is temporarily unavailable.
            SOPHOS_E_INVALIDARG   
                           Either an invalid drive name was supplied or ppResults was 
                           non-NULL but did not point to a valid memory location.
            SOPHOS_E_NOINTERFACE  
                           ResultsIID specified a results object type not supported by
                           this version of SAVI.
            RPC_E_WRONG_THREAD
                           A callback was installed using RegisterNotification() on a 
                           different thread to the current one. Both calls must be on the
                           same thread.
            SOPHOS_SAVI_ERROR_IC_INCOMPATIBLE_VERSION
                           The version of intercheck installed is not compatible with
                           this version of SAVI.
            SOPHOS_SAVI_ERROR_IC_ACCESS_DENIED
                           The calling process does not have sufficient rights to disable 
                           the InterCheck client.
            SOPHOS_SAVI_ERROR_IC_SCAN_PREVENTED
                           The InterCheck client could not be disabled.    
            SOPHOS_SAVI_ERROR_SWEEPFAILURE
                           The sweep engine could not sweep the sector.
                           Call GetLastError() for more information.
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      */

   virtual HRESULT SOPHOS_STDCALL DisinfectPhysicalSector( LPCOLESTR pDriveName,
                                                           U32 Head,
                                                           U32 Cylinder,
                                                           U32 Sector,
                                                           REFIID ResultsIID,
                                                           void **ppResults ) = 0;
      /* Description:
            Attempt to disinfect a physical disk sector, then sweep the sector to
            see if it contains any viruses after the attempt.

         Parameters:
            pDriveName     The name of the disk drive to sweep. This is platform dependant.
                           On Win32 use a string formatted as follows:
                              either -  \\.PHYSICALDRIVEx where x is the physical driver number
                                        (0 for the first fixed disk).
                              or     -  \\.\A: (where A is the drive letter).

            Head           The zero based index to the physical disk head
            Cylinder       The zero based index to the physical disk cylinder
            Sector         The ONE based index to the physical disk sector

            ResultsIID     Identifies the type of the results to be returned.
                           At present this must be SOPHOS_IID_ENUM_SWEEPRESULTS.
            ppResults      A pointer to a pointer to an IEnumSweepResults object which
                           will be created by this function. The object can be used
                           by the caller to enumerate any viruses found on the disk sector.
                           If there are no viruses, an enumerator containing zero items
                           is returned. When the caller has finished with the object, 
                           it must call Release() on the object.
                           This parameter may be supplied as NULL, in which case no sweep
                           results object is created.
     
         Return value:
            Note that there are multiple success codes so it is recommended that callers
            use the SOPHOS_SUCCEEDED() macro to test for successful completion of this function.
            
            Success codes:
            SOPHOS_S_OK    The infected sector was successfully disinfected.
            SOPHOS_SAVI_ERROR_OLD_VIRUS_DATA
                           The infected sector was successfully disinfected but the internal 
                           virus data is beyond its useful life. Sophos recommends that the 
                           virus engine be upgraded to a newer version as soon as possible.

            Failure codes:
            SOPHOS_SAVI_ERROR_NOT_INITIALISED
                           Neither initialisation function has been called.
      		SOPHOS_SAVI_ERROR_UPGRADE_FAILED
                           An attempt to upgrade the sweep engine failed and the SAVI
                           interface is temporarily unavailable.
            SOPHOS_E_INVALIDARG   
                           Either an invalid drive name was supplied or ppResults was 
                           non-NULL but did not point to a valid memory location.
            SOPHOS_E_NOINTERFACE  
                           ResultsIID specified a results object type not supported by
                           this version of SAVI.
            RPC_E_WRONG_THREAD
                           A callback was installed using RegisterNotification() on a 
                           different thread to the current one. Both calls must be on the
                           same thread.
            SOPHOS_SAVI_ERROR_IC_INCOMPATIBLE_VERSION
                           The version of intercheck installed is not compatible with
                           this version of SAVI.
            SOPHOS_SAVI_ERROR_IC_ACCESS_DENIED
                           The calling process does not have sufficient rights to disable 
                           the InterCheck client.
            SOPHOS_SAVI_ERROR_IC_SCAN_PREVENTED
                           The InterCheck client could not be disabled.    
            SOPHOS_SAVI_ERROR_SWEEPFAILURE
                           The sweep engine could not sweep the sector.
                           Call GetLastError() for more information.
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      */


   virtual HRESULT SOPHOS_STDCALL SweepMemory( REFIID ResultsIID, void **ppResults ) = 0;
      /* Description:
            Sweeps memory for viruses. This facility is not supported on all platforms.

         Parameters:
            ResultsIID     Identifies the type of the results to be returned.
                           At present this must be SOPHOS_IID_ENUM_SWEEPRESULTS.
            ppResults      A pointer to a pointer to an IEnumSweepResults object which
                           will be created by this function. The object can be used
                           by the caller to enumerate any viruses found in memory.
                           If there are no viruses, an enumerator containing zero items
                           is returned. When the caller has finished with the object, 
                           it must call Release() on the object.
                           This parameter may be supplied as NULL, in which case no sweep
                           results object is created.
     
         Return value:
            Note that there are multiple success codes so it is recommended that callers
            use the SUCCEEDED() macro to test for successful completion of this function.
            
            Success codes:
            SOPHOS_S_OK    Memory was successfully swept and contained no viruses.
            SOPHOS_SAVI_ERROR_VIRUSPRESENT
                           Memory was successfully swept and contained one or more viruses.
            SOPHOS_SAVI_ERROR_OLD_VIRUS_DATA
                           Memory was successfully swept but the internal virus data is 
                           beyond its useful life. Sophos recommends that the virus engine be 
                           upgraded to a newer version as soon as possible.
            
            Failure codes:
            SOPHOS_SAVI_ERROR_NOT_INITIALISED
                           Neither initialisation function has been called.
      		SOPHOS_SAVI_ERROR_UPGRADE_FAILED
                           An attempt to upgrade the sweep engine failed and the SAVI
                           interface is temporarily unavailable.
            SOPHOS_E_INVALIDARG   
                           ppResults was non-NULL but did not point to a valid memory
                           location.
            SOPHOS_E_NOINTERFACE  
                           ResultsIID specified a results object type not supported by
                           this version of SAVI.
            RPC_E_WRONG_THREAD
                           A callback was installed using RegisterNotification() on a 
                           different thread to the current one. Both calls must be on the
                           same thread.
            SOPHOS_SAVI_ERROR_IC_INCOMPATIBLE_VERSION
                           The version of intercheck installed is not compatible with
                           this version of SAVI.
            SOPHOS_SAVI_ERROR_IC_ACCESS_DENIED
                           The calling process does not have sufficient rights to disable 
                           the InterCheck client.
            SOPHOS_SAVI_ERROR_IC_SCAN_PREVENTED
                           The InterCheck client could not be disabled.    
            SOPHOS_SAVI_ERROR_SWEEPFAILURE
                           The sweep engine could not sweep memory.
                           Call GetLastError() for more information.
            SOPHOS_SAVI_ERROR_NOT_SUPPORTED
                           Memory sweeping is not supported on this platform.
            SOPHOS_SAVI_ERROR_COULD_NOT_OPEN
                           An error occured scanning memory.
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      */

   virtual HRESULT SOPHOS_STDCALL Disinfect( REFIID ToDisinfectIID, void *pToDisinfect ) = 0;
      /* Description:
            Attempt to disinfect a particular virus. This member function uses
            the results of a previous sweep to identify viruses to disinfect.

         Parameters:
            ToDisinfectIID Identifies the type of the results supplied, which were returned
                           by a previous call to one of the SweepXxxx() methods.
                           At present this must be SOPHOS_IID_SWEEPRESULTS.
            pToDisinfect   Points to a SweepResults object identifying the virus to disinfect.
     
         Return value:
            Success codes:
            SOPHOS_S_OK    The infected object was successfully disinfected

            Failure codes:
            SOPHOS_SAVI_ERROR_DISINFECTION_UNAVAILABLE
                           The virus could not be removed.
            SOPHOS_SAVI_ERROR_DISINFECTION_FAILED
                           The disinfection attempt failed.
            SOPHOS_SAVI_ERROR_NOT_INITIALISED
                           Neither initialisation function has been called.
      		SOPHOS_SAVI_ERROR_UPGRADE_FAILED
                           An attempt to upgrade the sweep engine failed and the SAVI
                           interface is temporarily unavailable.
            SOPHOS_E_INVALIDARG   
                           Either an invalid drive name or file fname was supplied or 
                           ppResults was non-NULL but did not point to a valid memory
                           location.
            SOPHOS_E_NOINTERFACE  
                           ResultsIID specified a results object type not supported by
                           this version of SAVI.
            RPC_E_WRONG_THREAD
                           A callback was installed using RegisterNotification() on a 
                           different thread to the current one. Both calls must be on the
                           same thread.
            SOPHOS_SAVI_ERROR_IC_INCOMPATIBLE_VERSION
                           The version of intercheck installed is not compatible with
                           this version of SAVI.
            SOPHOS_SAVI_ERROR_IC_ACCESS_DENIED
                           The calling process does not have sufficient rights to disable 
                           the InterCheck client.
            SOPHOS_SAVI_ERROR_IC_SCAN_PREVENTED
                           The InterCheck client could not be disabled.    
            SOPHOS_SAVI_ERROR_SWEEPFAILURE
                           The sweep engine could not sweep the sector or file.
                           Call GetLastError() for more information.
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      */
};

class IIDEDetails : public SAVI_IUNKNOWN
/* This class holds information for a single identity file. */
{
public:

   virtual HRESULT SOPHOS_STDCALL GetName( U32 ArraySize, 
                                           LPOLESTR pIDEName, 
                                           U32* pIDENameLength ) = 0;
      /* Description:
            Get the name of the identity file.
   
         Parameters:
            ArraySize      The total size of the buffer supplied to receive the name, IN
                           CHARACTERS.
            pIDEName       A pointer to the buffer which will receive the name.
                           NULL may be supplied if this value is not required.
            pIDENameLength This location receives the total length of the IDE name 
                           INCLUDING TERMINATOR, in characters.

         Return value:
            
            Success codes:
            SOPHOS_S_OK    The buffer suppled was big enough and the name was copied into it.
                           
            Failure codes:
            SOPHOS_SAVI_ERROR_BUFFER_TOO_SMALL
                           The buffer supplied by the user was not big enough.
            SOPHOS_E_INVALIDARG   
                           A pointer parameter did not point to a valid memory location.
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      */

   virtual HRESULT SOPHOS_STDCALL GetType( U32 *pType ) = 0;
      /* Description:
            Get the type of the virus identity file. The type can be:
               SOPHOS_TYPE_IDE         A file in "IDE" format
               SOPHOS_TYPE_UPD         A file in "UPD" format
               SOPHOS_TYPE_VDL         A file in "VDL" format
               SOPHOS_TYPE_UNKNOWN

         Parameters:
            pType          A pointer to a location which will receive the type code of
                           the identity file.

         Return value:
            
            Success codes:
            SOPHOS_S_OK    The type code was copied into the location supplied.
                           
            Failure codes:
            SOPHOS_E_INVALIDARG   
                           The parameter did not point to a valid memory location.
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      */

   
   virtual HRESULT SOPHOS_STDCALL GetState( U32 *pState ) = 0;
      /* Description:
            Get the state of the virus identity file.

         Parameters:
            pState         A pointer to a location which will receive the state code of
                           the identity file. The state can be:
               SOPHOS_IDE_VDL_SUCCESS        The file loaded correctly
               SOPHOS_IDE_VDL_FAILED         The file failed to load
               SOPHOS_IDE_VDL_OLD_WARNING    The file loaded but is out of date

         Return value:
            
            Success codes:
            SOPHOS_S_OK    The state was copied into the location supplied.
                           
            Failure codes:
            SOPHOS_E_INVALIDARG   
                           The parameter did not point to a valid memory location.
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      */

   virtual HRESULT SOPHOS_STDCALL GetDate( SYSTEMTIME* pDate ) = 0;
      /* Description:
            Get the date of the virus identity file.

         Parameters:
            pDate          A pointer to a location which will receive the date of the 
                           identity file.

         Return value:
            
            Success codes:
            SOPHOS_S_OK    The date was copied into the location supplied.
                           
            Failure codes:
            SOPHOS_E_INVALIDARG   
                           The parameter did not point to a valid memory location.
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      */

};

class ISweepResults : public SAVI_IUNKNOWN
/* This class represents a single sweep engine result. */
{
public:
   virtual HRESULT SOPHOS_STDCALL IsDisinfectable( U32* pIsDisinfectable ) = 0;
      /* Description:
            See whether the virus can be disinfected.
   
         Parameters:
            pIsDisinfectable
                           A pointer to a location which will receive a non-zero value
                           only if the virus can be disinfected.

         Return value:
            
            Success codes:
            SOPHOS_S_OK           
                           
            Failure codes:
            SOPHOS_E_INVALIDARG   
                           The parameter did not point to a valid memory location.
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      */

   virtual HRESULT SOPHOS_STDCALL GetVirusType( U32* pVirusType ) = 0;
      /* Description:
            Get the type of the virus.

         Parameters:
            pVirusType
                           A pointer to a location which will receive a type code. This is
                           one of:  SOPHOS_NO_VIRUS, SOPHOS_VIRUS, SOPHOS_VIRUS_IDENTITY, 
                           or SOPHOS_VIRUS_PATTERN

         Return value:
            
            Success codes:
            SOPHOS_S_OK           
                           
            Failure codes:
            SOPHOS_E_INVALIDARG   
                           The parameter did not point to a valid memory location.
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      */

   virtual HRESULT SOPHOS_STDCALL GetVirusName( U32 ArraySize,
                                                LPOLESTR pVirusName, 
                                                U32* pVirusNameLength ) = 0;
      /* Description:
            Get the name of the virus
   
         Parameters:
            ArraySize      The total size of the buffer supplied to receive the name, IN
                           CHARACTERS.
            pVirusName     A pointer to the buffer which will receive the name.
                           NULL may be supplied if this value is not required.
            pVirusNameLength 
                           This location receives the total length of the IDE name 
                           INCLUDING TERMINATOR, in characters.

         Return value:
            
            Success codes:
            SOPHOS_S_OK    The buffer suppled was big enough and the name was copied into it.
                           
            Failure codes:
            SOPHOS_SAVI_ERROR_BUFFER_TOO_SMALL
                           The buffer supplied by the user was not big enough.
            SOPHOS_E_INVALIDARG   
                           A pointer parameter did not point to a valid memory location.
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      */

   virtual HRESULT SOPHOS_STDCALL GetLocationInformation( U32 ArraySize,
                                                          LPOLESTR pLocation,
                                                          U32* pLocationNameLength ) = 0;
      /* Description:
            Get the location of the virus.
   
         Parameters:
            ArraySize      The total size of the buffer supplied to receive the name, IN
                           CHARACTERS.
            pLocation      A pointer to the buffer which will receive the location text.
                           NULL may be supplied if this value is not required.
            pLocationNameLength 
                           This location receives the total length of the IDE name 
                           INCLUDING TERMINATOR, in characters.

         Return value:
            
            Success codes:
            SOPHOS_S_OK    The buffer suppled was big enough and the name was copied into it.
                           
            Failure codes:
            SOPHOS_SAVI_ERROR_BUFFER_TOO_SMALL
                           The buffer supplied by the user was not big enough.
            SOPHOS_E_INVALIDARG   
                           A pointer parameter did not point to a valid memory location.
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      */
};

class IEngineConfig : public SAVI_IUNKNOWN
/* This class represents a single sweep engine setting. */
{
public:
   virtual HRESULT SOPHOS_STDCALL GetName( U32 ArraySize, 
                                           LPOLESTR pName, 
                                           U32 *pNameLength ) = 0;
      /* Description:
            Get the name of the configuration parameter.
   
         Parameters:
            ArraySize      The total size of the buffer supplied to receive the name, IN
                           CHARACTERS.
            pName          A pointer to the buffer which will receive the name.
                           NULL may be supplied if this value is not required.
            pNameLength    This location receives the total length of the IDE name 
                           INCLUDING TERMINATOR, in characters.

         Return value:
            
            Success codes:
            SOPHOS_S_OK    The buffer suppled was big enough and the name was copied into it.
                           
            Failure codes:
            SOPHOS_SAVI_ERROR_BUFFER_TOO_SMALL
                           The buffer supplied by the user was not big enough.
            SOPHOS_E_INVALIDARG
                           A pointer parameter did not point to a valid memory location.
            SOPHOS_E_UNEXPECTED
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      */
   virtual HRESULT SOPHOS_STDCALL GetType( U32 *pType ) = 0;
      /* Description:
            Get the type of the configuration parameter.
   
         Parameters:
            pType          A pointer to a location which will receive the type of
                           the configuration parameter. This is one of the
                           SOPHOS_TYPE_* constants.

         Return value:
            
            Success codes:
            SOPHOS_S_OK    Type obtained successfully.       

            Failure codes:
            SOPHOS_E_INVALIDARG   
                           The parameter did not point to a valid memory location.
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      */
};

class ISweepError : public SAVI_IUNKNOWN
/* This class represents an error encountered during a sweep. */
{
public:
   virtual HRESULT SOPHOS_STDCALL GetLocationInformation( U32 ArraySize,
                                                          LPOLESTR pLocation,
                                                          U32* pLocationNameLength ) = 0;
      /* Description:
            Get the location of the virus.
   
         Parameters:
            ArraySize      The total size of the buffer supplied to receive the name, IN
                           CHARACTERS.
            pLocation      A pointer to the buffer which will receive the location text.
                           NULL may be supplied if this value is not required.
            pLocationNameLength 
                           This location receives the total length of the IDE name 
                           INCLUDING TERMINATOR, in characters.

         Return value:
            
            Success codes:
            SOPHOS_S_OK    The buffer suppled was big enough and the name was copied into it.
                           
            Failure codes:
            SOPHOS_SAVI_ERROR_BUFFER_TOO_SMALL
                           The buffer supplied by the user was not big enough.
            SOPHOS_E_INVALIDARG   
                           A pointer parameter did not point to a valid memory location.
            SOPHOS_E_UNEXPECTED  
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      */

   virtual HRESULT SOPHOS_STDCALL GetErrorCode( HRESULT *ErrorCode ) = 0;
      /* Description:
            Get the type of error that occured.
   
         Parameters:
            ErrorCode      This location receives the error code. At present the following
                           errors are possible:
                              SOPHOS_SAVI_ERROR_FILE_ENCRYPTED
                                 The file was encrypted.
                              SOPHOS_SAVI_ERROR_CORRUPT
                                 The file was corrupted.
                              SOPHOS_SAVI_ERROR_NOT_SUPPORTED
                                 The file format was not supported.
                              SOPHOS_SAVI_ERROR_COULD_NOT_OPEN
                                 The file could not be opened.
                           NB in the future other codes may be added.

         Return value:
            Success codes:
            SOPHOS_S_OK    Code obtained successfully.       
                           
            Failure codes:
            SOPHOS_E_INVALIDARG   
                           A pointer parameter did not point to a valid memory location.
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      */
};

class ISweepNotify : public SAVI_IUNKNOWN
/* This class is implemented by a SAVI client wishing to set up a callback. */
{
public:
   virtual HRESULT SOPHOS_STDCALL OnFileFound( void *Token, LPCOLESTR Name ) = 0;
      /* Description:
            This function is invoked whenever a new file or sub-file is about to be swept.
            The return value indicates whether the file will be swept for viruses or not.
   
         Parameters:
            Token    The user value supplied to RegisterNotification in the SAVI interface.
            Name     The full name and path of the file which is about to be swept.

         Return value:
            SOPHOS_SAVI_CBCK_CONTINUE_THIS  
                     Go ahead and sweep the current file or sub-file for viruses.
            SOPHOS_SAVI_CBCK_CONTINUE_NEXT
                     Do not sweep the current file or sub-file, continue to the next one.
            SOPHOS_SAVI_CBCK_STOP
                     Do not sweep the current file or any others.
      */

   virtual HRESULT SOPHOS_STDCALL OnVirusFound( void *token, 
                                                REFIID ResultsIID, 
                                                void *pResults ) = 0;
      /* Description:
            This function is invoked whenever a virus is found within a file or sub-file.
            The return value indicates whether sweeping will proceed to the next file or not.

         Parameters:
            Token    The user value supplied to RegisterNotification in the SAVI interface.
            Name     The full name and path of the file which is about to be swept.
            ResultsIID     
                     Identifies the type of the results object supplied.
                     At present this is always SOPHOS_IID_SWEEPRESULTS.
                     In the future, other types may be supplied.
            pResults      
                     A pointer to a ISweepResults object which describes the virus found.
                     The type of the object is indicated by the value of ResultsIID.
                     The life of the object is controlled by SAVI so the object's Release()
                     function should not be called within this function unless AddRef() is 
                     also called.

         Return value:
            SOPHOS_SAVI_CBCK_CONTINUE_THIS  
                     Continue to sweep within current file or sub-file for further viruses.
            SOPHOS_SAVI_CBCK_CONTINUE_NEXT
                     Stop sweeping the current file, continue to the next one. This is the usual 
                     return code.
            SOPHOS_SAVI_CBCK_STOP
                     Do no further sweeping.
      */

   virtual HRESULT SOPHOS_STDCALL OnErrorFound( void *Token, 
                                                REFIID ErrorIID, 
                                                void *pError ) = 0;
      /* Description:
            This function is invoked whenever a problem is encountered sweeping a file for 
            viruses.
            The return value indicates whether sweeping will proceed to the next file or not.

         Parameters:
            Token    The user value supplied to RegisterNotification in the SAVI interface.
            Name     The full name and path of the file which is about to be swept.
            ErrorIID Identifies the type of the error object supplied.
                     At present this is always SOPHOS_IID_SWEEPERROR.
                     In the future, other types may be supplied.
            pError   A pointer to a the ISweepError object which describes the error 
                     encountered. The type of the object is indicated by the value of 
                     ErrorIID.
                     The life of the object is controlled by SAVI so the object's Release()
                     function should not be called within this function unless AddRef() is 
                     also called.

         Return value:
            SOPHOS_SAVI_CBCK_CONTINUE_THIS  
                     Attempt to ignore the error and continue to sweep within current file.
            SOPHOS_SAVI_CBCK_CONTINUE_NEXT
                     Stop sweeping the current file, continue to the next one.
            SOPHOS_SAVI_CBCK_STOP
                     Do no further sweeping.
      */
};

class ISweepNotify2 : public ISweepNotify
/* This class is implemented by a SAVI client wishing to set up a callback.
   It includes all of the functions of the ISweepNotify interface.
*/
{
public:
   virtual HRESULT SOPHOS_STDCALL OkToContinue( void *Token, 
                                                U16 Activity, 
                                                U32 Extent, 
                                                LPCOLESTR pTarget ) = 0;
      /* Description:
            This function is invoked in order to give the SAVI client a chance to interrupt
            scanning of the current object.  This can be most useful when scanning a file
            which is using up large amounts of resources - whether processing time, memory / 
            disc space or whatever.
            The return value indicates whether SAVI should carry on processing this file, 
            process the next file (in an archive) or halt.
   
         Parameters:
            Token    The user value supplied to RegisterNotification in the SAVI interface.
            activity A code which indicates why SAVI has invoked the callback function.  
                     This will be one of :
                     SAVI_ACTVTY_CLASSIF - SAVI is matching file contents against virus patterns
                     SAVI_ACTVTY_NEXTFILE - SAVI has found another sub-file in the file being scanned
                     SAVI_ACTVTY_DECOMPR - SAVI is expanding a compressed file or sub-file
            extent   A number which indicates how much of the activity has taken place
            pTarget  The name of the file or sub-file currently being processed

         Return value:
            SOPHOS_SAVI_CBCK_CONTINUE_THIS  
                     Carry on sweeping the current file or sub-file for viruses.
            SOPHOS_SAVI_CBCK_CONTINUE_NEXT
                     Stop sweeping the current file or sub-file, continue to the next one.
            SOPHOS_SAVI_CBCK_STOP
                     Stop sweeping the current file or any others.
      */

   virtual HRESULT SOPHOS_STDCALL OnClassification( void *Token, U32 Classifn ) = 0;
      /* Description:
            This function is invoked whenever a file or sub-file has been identified as
            one of the file types recognised by SAVI.
            The return value indicates whether sweeping will proceed to the next file or not.

         Parameters:
            Token    The user value supplied to RegisterNotification in the SAVI interface.
            Classifn A numeric value indicating the file classification type (see savitype.h)

         Return value:
            SOPHOS_SAVI_CBCK_CONTINUE_THIS  
                     Continue to sweep within current file or sub-file for further viruses.
            SOPHOS_SAVI_CBCK_CONTINUE_NEXT
                     Stop sweeping the current file, continue to the next one. This is the usual 
                     return code.
            SOPHOS_SAVI_CBCK_STOP
                     Do no further sweeping.
      */

};


class ISweepDiskChange : public SAVI_IUNKNOWN
/* This class is implemented by a SAVI client wishing to 
   be notified of disk changes during VDL loading
*/
{
public:
  virtual HRESULT SOPHOS_STDCALL OnDiskChange( void *Token, 
                                               LPCOLESTR pFileName, 
                                               U32 partNumber, 
                                               U32 timesRound ) = 0;
      /* Description:
            This function is invoked whenever a new section of VDL is required, usually this
            is caused by the data being spread across more than one disk, but may be caused
            by the data being spread across more than one file in the same directory. The 
            client should check that the requested file is not actually present before 
            prompting the user.
            The return value indicates whether the client has found the next section 
            successfully or not.

         Parameters:
            Token      The user value supplied to RegisterNotification in the SAVI interface.
            pFileName  The filename of the next part of the VDL data that is being requested
            partNumber The part number being requested.
            timesRound Counter to indicate the number of times this part has been requested,
                       zero for the first time. This allows clients to display a different
                       message to prompt the user on subsequent calls.

         Return value:
            SOPHOS_S_OK
                       Part located, attempt to continue loading VDL.
            SOPHOS_S_FALSE
                       Could not locate requested part, abort loading VDL.
      */
};

#endif   /*__ISAVI2_H__ */
