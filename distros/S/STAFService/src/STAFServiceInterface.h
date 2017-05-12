/*****************************************************************************/
/* Software Testing Automation Framework (STAF)                              */
/* (C) Copyright IBM Corp. 2001                                              */
/*                                                                           */
/* This software is licensed under the Common Public License (CPL) V1.0.     */
/*****************************************************************************/

#ifndef STAF_ServiceInterface 
#define STAF_ServiceInterface

//#include "STAF.h"
//#include "STAFString.h"
#include "STAFIncludes.h"

/*********************************************************************/
/* This header defines the interface by which STAF communicates with */
/* external services.  Before calling the service directly, STAF     */
/* will call STAFServiceGetLevelBounds to determine which structure  */
/* levels the service supports.  Currently, STAF supports the        */
/* following data structure levels:                                  */
/*                                                                   */
/*    ServiceInfo     - 30                                           */
/*    ServiceInit     - 30                                           */
/*    ServiceRequest  - 30                                           */
/*    ServiceTerm     - 0                                            */
/*    ServiceDestruct - 0                                            */
/*                                                                   */
/* In the cases where STAF only supports structure level 0, a NULL   */
/* pointer is passed into the service for the structure pointer.     */
/*********************************************************************/

#ifdef __cplusplus
extern "C" {
#endif

typedef unsigned int STAFRequestNumber_t;
typedef unsigned int STAFTrustLevel_t;
typedef void * STAFServiceHandle_t;

enum STAFServiceLevelID { kServiceInfo = 0, kServiceInit = 1,
                          kServiceAcceptRequest = 2, kServiceTerm = 3,
                          kServiceDestruct = 4 };

typedef enum
{
    kSTAFServiceTypeUnknown       = 0,  // Unknown service type
    kSTAFServiceTypeService       = 1,  // Regular service
    kSTAFServiceTypeServiceLoader = 2,  // Service Loader Service
    kSTAFServiceTypeAuthenticator = 3   // Authenticator Service
} STAFServiceType_t;

/**********************************************************************/
/* STAF passes in this structure on a STAFServiceConstruct call. The  */
/* data members have the following meanings:                          */
/*                                                                    */
/*   name          - The name of the service                          */
/*   exec          - The name of the executable that implements the   */
/*                   service (This is used by proxy services that     */
/*                   provide support for services in other languages. */
/*                   For example, this might be the Java class name   */
/*                   that implements the service of the name of the   */
/*                   Rexx script that implements the service. This    */
/*                   value has no meaning for C/C++ services and may  */
/*                   be ignored or used for any other purpose the     */
/*                   service desires.                                 */
/*   writeLocation - This specifies a directory in which STAF is      */
/*                   allowed to write.                                */
/*   serviceType   - This specifies the type of service (e.g. regular */
/*                   service, service loader service, authenticator   */
/*                   service)                                         */
/*   numOptions    - This specifies how many options were specified   */
/*                   for this service in the STAF.cfg file            */
/*   pOptionName   - This is an array of "numOptions" STAFString_t's  */
/*                   which contain the names of the options specified */
/*                   in the STAF.cfg file                             */
/*   pOptionValue  - This is an array of "numOptions" STAFString_t's  */
/*                   which contain the values of the options          */
/*                   specified in the STAF.cfg file                   */
/**********************************************************************/
struct STAFServiceInfoLevel30
{
    STAFString_t name;
    STAFString_t exec;
    STAFString_t writeLocation;
    STAFServiceType_t serviceType;
    unsigned int numOptions;
    STAFString_t *pOptionName;
    STAFString_t *pOptionValue;
};


/*********************************************************************/
/* STAF passes in this structure on a STAFServiceInit call.  The     */
/* data members have the following meanings:                         */
/*                                                                   */
/*   parms         - The parameters specified for this service in    */
/*                   the STAF.cfg file                               */
/*   writeLocation - This specifies a directory in which STAF is     */
/*                   allowed to write.                               */
/*********************************************************************/
struct STAFServiceInitLevel30
{
    STAFString_t parms;
    STAFString_t writeLocation;
};


/*********************************************************************/
/* STAF passes in this structure on a STAFServiceAcceptRequest call. */
/* The data members have the following meanings:                     */
/*                                                                   */
/*   stafInstanceUUID - The UUID of the instance of STAF that        */
/*                      submitted the request                        */
/*   machine          - The logical interface identifier for the     */
/*                      machine from which the request originated    */
/*                      (if tcp interface, it's the long host name)  */
/*   machineNickname  - The machine nickname of the machine from     */
/*                      which the request originated                 */
/*   handleName       - The registered name of the STAF handle       */
/*   handle           - The STAF Handle of the requesting process    */
/*   trustLevel       - The trust level of the requesting process    */
/*   isLocalRequest   - Is the request from the local system         */
/*   diagEnabled      - Indicates if diagnostics are enabled or not  */
/*                      1=Enabled, 0=Disabled                        */
/*   request          - The actual request string                    */
/*   requestNumber    - The request number of the service request    */
/*   user             - If the STAF Handle of the requesting process */
/*                      is authenticated, this is the                */
/*                      user (authenticator://userIdentifier) or     */
/*                      "none://anonymous" if the handle is not      */
/*                      authenticated.                               */
/*   endpoint         - The endpoint from which the request          */
/*                      originated in the following format:          */
/*                        interface://logicalInterfaceID[@port]      */
/*   physicalInterfaceID - The physical interface identifier for the */
/*                      machine from which the request originated    */
/*                      (if tcp interface, it's the long host name)  */
/*********************************************************************/
struct STAFServiceRequestLevel30
{
    STAFString_t        stafInstanceUUID;
    STAFString_t        machine;
    STAFString_t        machineNickname;
    STAFString_t        handleName;
    STAFHandle_t        handle;
    unsigned int        trustLevel;
    unsigned int        isLocalRequest;
    unsigned int        diagEnabled;
    STAFString_t        request;
    STAFRequestNumber_t requestNumber;
    STAFString_t        user;
    STAFString_t        endpoint;
    STAFString_t        physicalInterfaceID;
};


/*********************************************************************/
/* STAFServiceGetLevelBounds - This function is called to determine  */
/*                             what data structure levels a service  */
/*                             supports.                             */
/*                                                                   */
/* Accepts: (IN)  The data structure ID (one of the enumeration      */
/*                  values in STAFServiceLevelID)                    */
/*          (OUT) A pointer to the minimum structure level supported */
/*          (OUT) A pointer to the maximum structure level supported */
/*                                                                   */
/* Returns:  kSTAFOk, if successful                                  */
/*********************************************************************/
STAFRC_t STAFServiceGetLevelBounds(unsigned int levelID,
                                   unsigned int *minimum,
                                   unsigned int *maximum);


/*********************************************************************/
/* STAFServiceConstruct - This function is called to construct a     */
/*                        service.                                   */
/*                                                                   */
/* Accepts: (OUT) A Pointer to the service's handle (this is used in */
/*                  all subsequent calls by STAF)                    */
/*          (IN)  A pointer to a ServiceInfo data structure          */
/*          (IN)  The level of the ServiceInfo data structure        */
/*          (OUT) A pointer to an error string (this should only be  */
/*                  set, and will only be freed by STAF, if the      */
/*                  service returns a non-zero return code)          */
/*                                                                   */
/* Returns:  kSTAFOk, if successful                                  */
/*********************************************************************/
STAFRC_t STAFServiceConstruct(STAFServiceHandle_t *pServiceHandle,
                              void *pServiceInfo, unsigned int infoLevel,
                              STAFString_t *pErrorBuffer);


/*********************************************************************/
/* STAFServiceInit - This function is called to initialize a         */
/*                   service.                                        */
/*                                                                   */
/* Accepts: (IN)  The service's handle (obtained from                */
/*                  STAFServiceConstruct)                            */
/*          (IN)  A pointer to a ServiceInit data structure          */
/*          (IN)  The level of the ServiceInit data structure        */
/*          (OUT) A pointer to an error string (this should only be  */
/*                  set, and will only be freed by STAF, if the      */
/*                  service returns a non-zero return code)          */
/*                                                                   */
/* Returns:  kSTAFOk, if successful                                  */
/*********************************************************************/
STAFRC_t STAFServiceInit(STAFServiceHandle_t serviceHandle,
                         void *pInitInfo, unsigned int initLevel,
                         STAFString_t *pErrorBuffer);


/*********************************************************************/
/* STAFServiceAcceptRequest - This function is called to have the    */
/*                            service handle a request.              */
/*                                                                   */
/* Accepts: (IN)  The service's handle (obtained from                */
/*                  STAFServiceConstruct)                            */
/*          (IN)  A pointer to a ServiceRequest data structure       */
/*          (IN)  The level of the ServiceRequest data structure     */
/*          (OUT) A pointer to the request's result buffer (this     */
/*                  should also be set, even if it is an empty       */
/*                  string, as STAF will always try to destruct this */
/*                  string)                                          */
/*                                                                   */
/* Returns: The return code of the request (this should one of the   */
/*          return codes defined in STAFError.h or be 4000+)         */
/*********************************************************************/
STAFRC_t STAFServiceAcceptRequest(STAFServiceHandle_t serviceHandle,
                                  void *pRequestInfo, unsigned int reqLevel,
                                  STAFString_t *pResultBuffer);


/*********************************************************************/
/* STAFServiceTerm - This function is called to terminate a service. */
/*                                                                   */
/* Accepts: (IN)  The service's handle (obtained from                */
/*                  STAFServiceConstruct)                            */
/*          (IN)  A pointer to a ServiceTerm data structure          */
/*          (IN)  The level of the ServiceTerm data structure        */
/*          (OUT) A pointer to an error string (this should only be  */
/*                  set, and will only be freed by STAF, if the      */
/*                  service returns a non-zero return code)          */
/*                                                                   */
/* Returns:  kSTAFOk, if successful                                  */
/*********************************************************************/
STAFRC_t STAFServiceTerm(STAFServiceHandle_t serviceHandle,
                         void *pTermInfo, unsigned int termLevel,
                         STAFString_t *pErrorBuffer);


/*********************************************************************/
/* STAFServiceDestruct - This function is called to destruct a       */
/*                       service.                                    */
/*                                                                   */
/* Accepts: (IN)  The service's handle (obtained from                */
/*                  STAFServiceConstruct)                            */
/*          (IN)  A pointer to a ServiceDestruct data structure      */
/*          (IN)  The level of the ServiceDestruct data structure    */
/*          (OUT) A pointer to an error string (this should only be  */
/*                  set, and will only be freed by STAF, if the      */
/*                  service returns a non-zero return code)          */
/*                                                                   */
/* Returns:  0, if successful                                        */
/*          >0, if unsuccessful (this should be one of the errors    */
/*              defined in STAFError.h or be 4000+)                  */
/*********************************************************************/
STAFRC_t STAFServiceDestruct(STAFServiceHandle_t *serviceHandle,
                             void *pDestructInfo,
                             unsigned int destructLevel,
                             STAFString_t *pErrorBuffer);


/***********************************/
/* Define typedefs for use by STAF */
/***********************************/

typedef STAFRC_t (*STAFServiceGetLevelBounds_t)(unsigned int levelID,
    unsigned int *minimum, unsigned int *maximum);

typedef STAFRC_t (*STAFServiceConstruct_t)(
    STAFServiceHandle_t *pServiceHandle, void *pServiceInfo,
    unsigned int infoLevel, STAFString_t *pErrorBuffer);

typedef STAFRC_t (*STAFServiceInit_t)(STAFServiceHandle_t serviceHandle,
    void *pInitInfo, unsigned int initLevel, STAFString_t *pErrorBuffer);

typedef STAFRC_t (*STAFServiceAcceptRequest_t)(
    STAFServiceHandle_t serviceHandle, void *pRequestInfo,
    unsigned int reqLevel, STAFString_t *pResultBuffer);

typedef STAFRC_t (*STAFServiceTerm_t)(STAFServiceHandle_t serviceHandle,
    void *pTermInfo, unsigned int termLevel, STAFString_t *pErrorBuffer);

typedef STAFRC_t (*STAFServiceDestruct_t)(
    STAFServiceHandle_t *serviceHandle, void *pDestructInfo,
    unsigned int destructLevel, STAFString_t *pErrorBuffer);

#ifdef __cplusplus
}
#endif

#endif
