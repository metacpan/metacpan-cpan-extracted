/*
 * isavi3.h
 *
 * This file is a part of the Sophos Anti-Virus Interface (SAVI)(tm).
 *
 * Copyright (C) 2002-2004 Sophos Plc, Oxford, England.
 * All rights reserved.
 *
 * This source code is only intended as a supplement to the
 * SAVI(tm) Reference and related documentation for the library.
 *
 * Sophos ISavi3 declarations.
 */

#ifndef __ISAVI3_H__
#define __ISAVI3_H__

#include "isavi2.h"

/* Interface version 3 */

class ISavi3 : public ISavi2
{
public:
   virtual HRESULT SOPHOS_STDCALL SweepBuffer( LPCOLESTR pBuffName, 
                                               U32 buffSize, 
                                               U08 *pBuff, 
                                               REFIID ResultsIID, 
                                               void **ppResults ) = 0;
      /* Description:
            Sweep a buffer for viruses. 

         Parameters:
            pBuffName      The name of the buffer to sweep.
            buffSize       The size in bytes of the buffer to sweep.
            pBuff          Pointer to the buffer to sweep.
            ResultsIID     Identifies the type of the results to be returned.
                           At present this must be SOPHOS_IID_ENUM_SWEEPRESULTS.
            ppResults      A pointer to a pointer to an IEnumSweepResults object which
                           will be created by this function. The object can be used
                           by the caller to enumerate any viruses found in the buffer.
                           If there are no viruses, an enumerator containing zero items
                           is returned. When the caller has finished with the object, 
                           it must call Release() on the object.
                           This parameter may be supplied as NULL, in which case no sweep
                           results object is created.
     
         Return value:
            Note that there are multiple success codes so it is recommended that callers
            use the SUCCEEDED() macro to test for successful completion of this function.
            
            Success codes:
            SOPHOS_S_OK    The buffer was successfully swept and contained no viruses.
            SOPHOS_SAVI_ERROR_VIRUSPRESENT
                           The buffer was successfully swept and contained one or more viruses.
            SOPHOS_SAVI_ERROR_OLD_VIRUS_DATA
                           The buffer was successfully swept but the internal virus data is 
                           beyond its useful life. Sophos recommends that the virus engine is 
                           upgraded to a newer version as soon as possible.

            Failure codes:
            SOPHOS_SAVI_ERROR_NOT_INITIALISED
                           Neither initialisation function has been called.
      		SOPHOS_SAVI_ERROR_UPGRADE_FAILED
                           An attempt to upgrade the sweep engine failed and the SAVI
                           interface is temporarily unavailable.
            SOPHOS_E_INVALIDARG   
                           ppResults was non-NULL but did not point to a valid memory location.
            SOPHOS_E_NOINTERFACE  
                           ResultsIID specified a results object type not supported by this 
                           version of SAVI.
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
                           The sweep engine could not sweep the buffer.
                           Call GetLastError() for more information.
            SOPHOS_E_UNEXPECTED   
                           An unexpected error. 
            Win32 platforms may also return other HRESULT values.
      */

   virtual HRESULT SOPHOS_STDCALL SweepHandle( LPCOLESTR pHandleName, 
                                               SOPHOS_FD fileHandle, 
                                               REFIID ResultsIID, 
                                               void **ppResults ) = 0;
      /* Description:
            Sweep a file for viruses via a file handle. 

         Parameters:
            pHandleName    The name of the file handle to sweep.
            fileHandle     File handle to sweep.
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
                           beyond its useful life. Sophos recommends that the virus engine is 
                           upgraded to a newer version as soon as possible.

            Failure codes:
            SOPHOS_SAVI_ERROR_NOT_INITIALISED
                           Neither initialisation function has been called.
      		SOPHOS_SAVI_ERROR_UPGRADE_FAILED
                           An attempt to upgrade the sweep engine failed and the SAVI
                           interface is temporarily unavailable.
            SOPHOS_E_INVALIDARG   
                           ppResults was non-NULL but did not point to a valid memory location.
            SOPHOS_E_NOINTERFACE  
                           ResultsIID specified a results object type not supported by this 
                           version of SAVI.
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
   
   virtual HRESULT SOPHOS_STDCALL SweepStream( LPCOLESTR pStreamName, 
                                               REFIID StreamIID,  
                                               void *pStream, 
                                               REFIID ResultsIID, 
                                               void **ppResults ) = 0;
      /* Description:
            Sweep a stream for viruses. 

         Parameters:
            pStreamName    The name of the stream to sweep.
            StreamIID      Identifies the type of the pStream interface pointer.
                           At present this must be SOPHOS_IID_SAVISTREAM.
            pStream        Pointer to the implemented stream interface.
            ResultsIID     Identifies the type of the results to be returned.
                           At present this must be SOPHOS_IID_ENUM_SWEEPRESULTS.
            ppResults      A pointer to a pointer to an IEnumSweepResults object which
                           will be created by this function. The object can be used
                           by the caller to enumerate any viruses found in the stream.
                           If there are no viruses, an enumerator containing zero items
                           is returned. When the caller has finished with the object, 
                           it must call Release() on the object.
                           This parameter may be supplied as NULL, in which case no sweep
                           results object is created.
     
         Return value:
            Note that there are multiple success codes so it is recommended that callers
            use the SUCCEEDED() macro to test for successful completion of this function.
            
            Success codes:
            SOPHOS_S_OK    The stream was successfully swept and contained no viruses.
            SOPHOS_SAVI_ERROR_VIRUSPRESENT
                           The stream was successfully swept and contained one or more viruses.
            SOPHOS_SAVI_ERROR_OLD_VIRUS_DATA
                           The stream was successfully swept but the internal virus data is 
                           beyond its useful life. Sophos recommends that the virus engine is 
                           upgraded to a newer version as soon as possible.

            Failure codes:
            SOPHOS_SAVI_ERROR_NOT_INITIALISED
                           Neither initialisation function has been called.
      		SOPHOS_SAVI_ERROR_UPGRADE_FAILED
                           An attempt to upgrade the sweep engine failed and the SAVI
                           interface is temporarily unavailable.
            SOPHOS_E_INVALIDARG   
                           ppResults was non-NULL but did not point to a valid memory location.
            SOPHOS_E_NOINTERFACE  
                           ResultsIID specified a results object type not supported by this 
                           version of SAVI.
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
                           The sweep engine could not sweep the stream.
                           Call GetLastError() for more information.
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      */
   
   virtual HRESULT SOPHOS_STDCALL DisinfectBuffer( LPCOLESTR pBuffName, 
                                                   U32 buffSize, 
                                                   U08 *pBuff, 
                                                   REFIID ResultsIID, 
                                                   void **ppResults ) = 0;
      /* Description:
            Attempt to disinfect a buffer which contains a virus, then sweep the buffer to
            see if it contains any viruses after the attempt.

         Parameters:
            pBuffName      The name of the buffer to sweep.
            buffSize       The size in bytes of the buffer to sweep.
            pBuff          Pointer to the buffer to sweep.
            ResultsIID     Identifies the type of the results to be returned.
                           At present this must be SOPHOS_IID_ENUM_SWEEPRESULTS.
            ppResults      A pointer to a pointer to an IEnumSweepResults object which
                           will be created by this function. The object can be used
                           by the caller to enumerate any viruses found in the buffer after
                           the disinfectinon attempt. If there are no viruses, an enumerator 
                           containing zero items is returned. 
                           When the caller has finished with the object, 
                           it must call Release() on the object.
                           This parameter may be supplied as NULL, in which case no sweep
                           results object is created.
     
         Return value:
            Note that there are multiple success codes so it is recommended that callers
            use the SUCCEEDED() macro to test for successful completion of this function.
            
            Success codes:
            SOPHOS_S_OK    The infected buffer was successfully disinfected
            SOPHOS_SAVI_ERROR_OLD_VIRUS_DATA
                           The infected buffer was successfully disinfected but the internal 
                           virus data is beyond its useful life. Sophos recommends that the 
                           virus engine is upgraded to a newer version as soon as possible.

            Failure codes:
            SOPHOS_SAVI_ERROR_DISINFECTION_UNAVAILABLE
                           The buffer could not be disinfected. Either it initially contained
                           no virus, or the virus could not be removed.
            SOPHOS_SAVI_ERROR_DISINFECTION_FAILED
                           The virus could not be removed, the disinfection attempt failed.
            SOPHOS_SAVI_ERROR_NOT_INITIALISED
                           Neither initialisation function has been called.
      		SOPHOS_SAVI_ERROR_UPGRADE_FAILED
                           An attempt to upgrade the sweep engine failed and the SAVI
                           interface is temporarily unavailable.
            SOPHOS_E_INVALIDARG   
                           ppResults was non-NULL but did not point to a valid memory location.
            SOPHOS_E_NOINTERFACE  
                           ResultsIID specified a results object type not supported by this 
                           version of SAVI.
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
                           The sweep engine could not sweep the buffer.
                           Call GetLastError() for more information.
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      */
   
   virtual HRESULT SOPHOS_STDCALL DisinfectHandle( LPCOLESTR pHandleName, 
                                                   SOPHOS_FD fileHandle, 
                                                   REFIID ResultsIID, 
                                                   void **ppResults ) = 0;
      /* Description:
            Attempt to disinfect a file which contains a virus via a file handle, then 
            sweep the file to see if it contains any viruses after the attempt.

         Parameters:
            pHandleName    The name of the file handle to sweep.
            fileHandle     File handle to sweep.
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
            Note that there are multiple success codes so it is recommended that callers
            use the SUCCEEDED() macro to test for successful completion of this function.
            
            Success codes:
            SOPHOS_S_OK    The infected file was successfully disinfected
            SOPHOS_SAVI_ERROR_OLD_VIRUS_DATA
                           The infected file was successfully disinfected but the internal 
                           virus data is beyond its useful life. Sophos recommends that the 
                           virus engine is upgraded to a newer version as soon as possible.

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
                           ppResults was non-NULL but did not point to a valid memory location.
            SOPHOS_E_NOINTERFACE  
                           ResultsIID specified a results object type not supported by this 
                           version of SAVI.
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

   virtual HRESULT SOPHOS_STDCALL DisinfectStream( LPCOLESTR pStreamName, 
                                                   REFIID StreamIID,  void *pStream, 
                                                   REFIID ResultsIID, void **ppResults ) = 0;
      /* Description:
            Attempt to disinfect a stream which contains a virus, then sweep the stream to
            see if it contains any viruses after the attempt.

         Parameters:
            pStreamName    The name of the stream to disinfect.
            StreamIID      Identifies the type of the pStream interface pointer.
                           At present this must be SOPHOS_IID_SAVISTREAM.
            pStream        Pointer to the implemented stream interface.
            ResultsIID     Identifies the type of the results to be returned.
                           At present this must be SOPHOS_IID_ENUM_SWEEPRESULTS.
            ppResults      A pointer to a pointer to an IEnumSweepResults object which
                           will be created by this function. The object can be used
                           by the caller to enumerate any viruses found in the stream after
                           the disinfectinon attempt. If there are no viruses, an enumerator 
                           containing zero items is returned. 
                           When the caller has finished with the object, 
                           it must call Release() on the object.
                           This parameter may be supplied as NULL, in which case no sweep
                           results object is created.
     
         Return value:
            Note that there are multiple success codes so it is recommended that callers
            use the SUCCEEDED() macro to test for successful completion of this function.
            
            Success codes:
            SOPHOS_S_OK    The infected stream was successfully disinfected.
            SOPHOS_SAVI_ERROR_OLD_VIRUS_DATA
                           The infected stream was successfully disinfected but the internal 
                           virus data is beyond its useful life. Sophos recommends that the 
                           virus engine is upgraded to a newer version as soon as possible.

            Failure codes:
            SOPHOS_SAVI_ERROR_DISINFECTION_UNAVAILABLE
                           The stream could not be disinfected. Either it initially contained
                           no virus, or the virus could not be removed.
            SOPHOS_SAVI_ERROR_DISINFECTION_FAILED
                           The virus could not be removed, the disinfection attempt failed.
            SOPHOS_SAVI_ERROR_NOT_INITIALISED
                           Neither initialisation function has been called.
      		SOPHOS_SAVI_ERROR_UPGRADE_FAILED
                           An attempt to upgrade the sweep engine failed and the SAVI
                           interface is temporarily unavailable.
            SOPHOS_E_INVALIDARG   
                           ppResults was non-NULL but did not point to a valid memory location.
            SOPHOS_E_NOINTERFACE  
                           ResultsIID specified a results object type not supported by this 
                           version of SAVI.
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
                           The sweep engine could not sweep the stream.
                           Call GetLastError() for more information.
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      */

   virtual HRESULT SOPHOS_STDCALL LoadVirusData() = 0;
      /* Description:
            Load virus descriptions from virus data files.
            Default virus data file name and locations may be overridden using values 
            specified in config items.

         Return value:
            Note that there are multiple success codes so it is recommended that callers 
            use the SUCCEEDED() macro to test for successful completion of this function.
            
            Success codes:
            SOPHOS_S_OK    The virus data was successfully loaded
            SOPHOS_SAVI_ERROR_OLD_VIRUS_DATA
                           The virus data was successfully loaded but it is beyond its 
                           useful life. Sophos recomends that the virus engine is upgraded 
                           to a newer version as soon as possible.

            Failure codes:
            SOPHOS_SAVI_ERROR_MISSING_MAIN_VIRUS_DATA
                           The main body of virus data is missing.
            SOPHOS_SAVI_ERROR_CORRUPT
                           The virus data was corrupt.
            SOPHOS_SAVI_ERROR_INITIALISING                           
                           A non-specific initialisation error.
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      */
};


/*
 * An object of this class must implemented by a SAVI client wishing to use
 * either the ISavi3::SweepStream() or ISavi3::DisinfectStream() functions.
 */
class ISaviStream : public SAVI_IUNKNOWN
{
public:
   virtual HRESULT SOPHOS_STDCALL ReadStream( void *lpvBuffer, U32 count, U32 *bytesRead ) = 0;
      /* Description:
            Copy the number of bytes specified in count from the SaviStream to the given buffer.
         
         Parameters:
            lpvBuffer      Pointer to the buffer that will receive the copied data.
            count          Number of bytes to copy into lpvBuffer.
            bytesRead      Pointer to a value to receive the number of bytes successfully read.
         
         Return value:
            
            Success codes:
            SOPHOS_S_OK    The read operation completed successfully.
            
            Failure codes:
            SOPHOS_E_INVALIDARG   
                           One of the passed parameters held an invalid value.
            SOPHOS_SAVI_ERROR_STREAM_READ_FAIL
                           A general code used to describe a failed read attempt.
      */

   virtual HRESULT SOPHOS_STDCALL WriteStream( const void *lpvBuffer, U32 count, U32 *bytesWritten ) = 0;
      /* Description:
            Copy the number of bytes specified in count from the given buffer to the SaviStream.
         
         Parameters:
            lpvBuffer      Pointer to the buffer that contains the data to copy.
            count          Number of bytes to copy from lpvBuffer.
            bytesWritten   Pointer to a value to take the number of bytes successfully written.
         
         Return value:
            
            Success codes:
            SOPHOS_S_OK    The write operation completed successfully.
            
            Failure codes:
            SOPHOS_E_INVALIDARG   
                           One of the passed parameters held an invalid value.
            SOPHOS_SAVI_ERROR_STREAM_WRITE_FAIL
                           A general code used to describe a failed write attempt.
      */

   virtual HRESULT SOPHOS_STDCALL SeekStream( S32 lOffset, U32 uOrigin, U32 *newPosition ) = 0;
      /* Description:
            Set the SaviStream seek pointer to the number of bytes specified by lOffset from
            the position of uOrigin.
         
         Parameters:
            lOffset        Number of bytes to move the seek pointer relative to uOrigin.
            uOrigin        One of the SAVISTREAM_SEEK_XXX values defined in savitype.h. 
                           Specifies whether lOffset is relative to the start of the stream,
                           the end of the stream or the current position of the seek pointer.
            newPosition    Pointer to a value that should receive the new seek pointer.
         
         Return value:
            
            Success codes:
            SOPHOS_S_OK    The seek operation completed successfully.
            
            Failure codes:
            SOPHOS_E_INVALIDARG   
                           One of the passed parameters held an invalid value.
            SOPHOS_SAVI_ERROR_STREAM_SEEK_FAIL
                           A general code used to describe a failed seek attempt.
      */

   virtual HRESULT SOPHOS_STDCALL GetLength( U32 *length ) = 0;
      /* Description:
            Obtain the length of the stream in bytes.
         
         Parameters:
            length         Pointer to a value to receive the length of the stream.
            
         Return value:
            
            Success codes:
            SOPHOS_S_OK    The length of the stream was obtained successfully.
            
            Failure codes:
            SOPHOS_E_INVALIDARG   
                           The parameter held an invalid value.
            SOPHOS_SAVI_ERROR_STREAM_GETLENGTH_FAIL
                           A general code used to describe a failed attempt to obtain
                           the length of the stream.
      */
};


/* 
 * Sophos IChangeNotify declarations. 
 */
class IChangeNotify : public SAVI_IUNKNOWN
/* This class is implemented by a SAVI client wishing to set up a callback. */
{
public:
   virtual HRESULT SOPHOS_STDCALL OnChange( void *Token ) = 0;
      /* Description:
            This function is invoked whenever virus data or a binary component has changed.
            The return value is ignored by SAVI so any return value is acceptable.
   
         Parameters:
            Token    The user value supplied to RegisterNotification in the SAVI interface.

         Return value:
            SOPHOS_S_OK
      */
};

class IVersionChecksum : public SAVI_IUNKNOWN
/* This class holds checksum information. */
{
public:
   virtual HRESULT SOPHOS_STDCALL GetType( U32 *pType ) = 0;
      /* Description:
            Get the type of the checksum. The type can be:
               SOPHOS_TYPE_VDATA       Virus data
               SOPHOS_TYPE_BINARY      Binary

         Parameters:
            pType          A pointer to a location which will receive the type code of
                           the checksum.

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

   
   virtual HRESULT SOPHOS_STDCALL GetValue( U32 *pValue ) = 0;
      /* Description:
            Get the checksum value.

         Parameters:
            pValue         A pointer to a location which will receive the checksum.

         Return value:
            
            Success codes:
            SOPHOS_S_OK    The value was copied into the location supplied.
                           
            Failure codes:
            SOPHOS_E_INVALIDARG   
                           The parameter did not point to a valid memory location.
            SOPHOS_E_UNEXPECTED   
                           An unexpected error.
            Win32 platforms may also return other HRESULT values.
      */
};

/* 
 * List of Version checksum objects.
 * Obtained by passing SOPHOS_IID_ENUM_CHECKSUM to GetVirusEngineVersion().
 */
typedef IEnum<IVersionChecksum *> IEnumVersionChecksum;      


/*
 * Interface definition for ISeverityNotify.
 */
class ISeverityNotify : public SAVI_IUNKNOWN
{
public:
   virtual HRESULT SOPHOS_STDCALL OnSevereError( void *Token, HRESULT ErrorCode, U32 Severity ) = 0;
      /* Description:
            This function is invoked whenever a severe error occurs during a SAVI method call.
            The return value is ignored by SAVI so any return value is acceptable.
   
         Parameters:
            Token     The user value supplied to RegisterNotification in the SAVI interface.
            ErrorCode The error that has occured.
            Severity  The severity of the error which will be one of the defined error severity values.

         Return value:
            SOPHOS_S_OK
      */
};

#endif   /*__ISAVI3_H__ */
