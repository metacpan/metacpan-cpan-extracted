
#include "STAFServiceInterface.h"
#include "STAFIncludes.h"
#include "synchelper.h"
#include "perlglue.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct STAFProcPerlServiceDataST {
	PHolder *perl;
	STAFMutexSem_t mutex;
	SyncData *syncData;
} STAFProcPerlServiceData;

STAFRC_t ParseParameters(STAFServiceInfoLevel30 *pInfo, PHolder *perl_holder, unsigned int *maxLogs, long *maxLogSize, STAFString_t *pErrorBuffer);
STAFRC_t ReplaceChar(STAFString_t opr_str, char old, char newc);

STAFRC_t STAFServiceConstruct(STAFServiceHandle_t *pServiceHandle,
							  void *pServiceInfo, unsigned int infoLevel,
							  STAFString_t *pErrorBuffer)
{
	if (infoLevel != 30) return kSTAFInvalidAPILevel;
	
	STAFServiceInfoLevel30 *pInfo = static_cast<STAFServiceInfoLevel30 *>(pServiceInfo);
	unsigned int maxLogs = 5; // Defaults to keeping 5 PerlInterpreter logs
	long maxLogSize = 1048576; // Default size of each log is 1M
	STAFRC_t ret;
	
	STAFProcPerlServiceData *pData = (STAFProcPerlServiceData*)malloc(sizeof(STAFProcPerlServiceData));
	if (pData==NULL) {
		return kSTAFUnknownError;
	}
	SyncData *syncData = CreateSyncData();
	if (NULL == syncData) {
		free(pData);
		return kSTAFUnknownError;
	}
	pData->syncData = syncData;

	PHolder *perl_data = CreatePerl(syncData);
	if (perl_data==NULL) {
		free(pData);
		DestroySyncData(syncData);
		return kSTAFUnknownError;
	}

	pData->perl = perl_data;

	PopulatePerlHolder(perl_data, pInfo->name, pInfo->exec, pInfo->serviceType);

	// Walk through and verify the config options
	ret = ParseParameters(pInfo, perl_data, &maxLogs, &maxLogSize, pErrorBuffer);
	if (ret!=kSTAFOk) return ret;

	ret = RedirectPerlStdout(perl_data, pInfo->writeLocation, pInfo->name, maxLogs, maxLogSize, pErrorBuffer);
	if (ret!=kSTAFOk) {
		free(pData);
		DestroySyncData(syncData);
		DestroyPerl(perl_data);
		return ret;
	}
	ret = PreparePerlInterpreter(perl_data, pInfo->exec, pErrorBuffer);
	if (ret!=kSTAFOk) {
		free(pData);
		DestroySyncData(syncData);
		DestroyPerl(perl_data);
		return ret;
	}

	ret = STAFMutexSemConstruct(&(pData->mutex), NULL, NULL);
	if (ret!=kSTAFOk) {
		free(pData);
		DestroySyncData(syncData);
		Terminate(perl_data);
		DestroyPerl(perl_data);
		return ret;
	}
	*pServiceHandle=pData;
	return kSTAFOk;
}

STAFRC_t STAFServiceDestruct(STAFServiceHandle_t *serviceHandle,
							 void *pDestructInfo,
							 unsigned int destructLevel,
							 STAFString_t *pErrorBuffer)
{
	if (destructLevel != 0) return kSTAFInvalidAPILevel;
	
    STAFProcPerlServiceData *pData =
		static_cast<STAFProcPerlServiceData *>(*serviceHandle);
	
	STAFMutexSemDestruct(&(pData->mutex), NULL);
	DestroySyncData(pData->syncData);
	DestroyPerl(pData->perl);
	free(pData);

    *serviceHandle = 0;
	
    return kSTAFOk;
}

STAFRC_t STAFServiceInit(STAFServiceHandle_t serviceHandle,
						 void *pInitInfo, unsigned int initLevel,
						 STAFString_t *pErrorBuffer)
{
	if (initLevel != 30) return kSTAFInvalidAPILevel;
	
    STAFProcPerlServiceData *pData =
		static_cast<STAFProcPerlServiceData *>(serviceHandle);
	STAFServiceInitLevel30 *pInfo =
		static_cast<STAFServiceInitLevel30 *>(pInitInfo);

	STAFRC_t ret = STAFMutexSemRequest(pData->mutex, -1, NULL);
	if (ret!=kSTAFOk)
		return ret;

	ret = InitService(pData->perl, pInfo->parms, pInfo->writeLocation, pErrorBuffer);
	
	if (STAFMutexSemRelease(pData->mutex, NULL) != kSTAFOk) {
		const char *msg = "Error in ServiceInit: could not aquire lock!";
		//fprintf(stderr, "%s\n", msg);
		STAFStringConstruct(pErrorBuffer, msg, strlen(msg), NULL);
		return kSTAFUnknownError;
	}

	return ret;
}

STAFRC_t STAFServiceTerm(STAFServiceHandle_t serviceHandle,
						 void *pTermInfo, unsigned int termLevel,
						 STAFString_t *pErrorBuffer)
{
	if (termLevel != 0) return kSTAFInvalidAPILevel;
	
    STAFProcPerlServiceData *pData =
		static_cast<STAFProcPerlServiceData *>(serviceHandle);

	STAFRC_t ret = STAFMutexSemRequest(pData->mutex, -1, NULL);
	if (ret!=kSTAFOk)
		return ret;

	ret = Terminate(pData->perl);
	
	if (STAFMutexSemRelease(pData->mutex, NULL) != kSTAFOk) {
		const char *msg = "Error in ServiceTerm: could not aquire lock!";
		//fprintf(stderr, "%s\n", msg);
		STAFStringConstruct(pErrorBuffer, msg, strlen(msg), NULL);
		return kSTAFUnknownError;
	}

	return ret;
}

STAFRC_t STAFServiceAcceptRequest(STAFServiceHandle_t serviceHandle,
								  void *pRequestInfo, unsigned int reqLevel,
								  STAFString_t *pResultBuffer)
{
	if (reqLevel != 30) return kSTAFInvalidAPILevel;

    STAFProcPerlServiceData *pData = static_cast<STAFProcPerlServiceData *>(serviceHandle);
	STAFServiceRequestLevel30 *pInfo = static_cast<STAFServiceRequestLevel30 *>(pRequestInfo);

	SingleSync *ss = GetSingleSync(pData->syncData, pInfo->requestNumber);
	if ( NULL == ss ) {
		const char *msg = "Error in AcceptRequest: received NULL as sync record";
		STAFStringConstruct(pResultBuffer, msg, strlen(msg), NULL);
		return kSTAFUnknownError;
	}
	
	STAFRC_t ret = STAFMutexSemRequest(pData->mutex, -1, NULL);
	if (ret!=kSTAFOk) {
		const char *msg = "Error in AcceptRequest: Failed to get mutex";
		STAFStringConstruct(pResultBuffer, msg, strlen(msg), NULL);
		return ret;
	}

	ret = ServeRequest(pData->perl, pInfo, pResultBuffer);

	if (STAFMutexSemRelease(pData->mutex, NULL) != kSTAFOk) {
		const char *msg = "Error in AcceptRequest: could not release lock!";
		STAFStringConstruct(pResultBuffer, msg, strlen(msg), NULL);
		ret = kSTAFUnknownError;
	}

	if (77==ret && NULL == *pResultBuffer) {
		// this is a delayed answer. wait for the real answer
		ret = WaitForSingleSync(ss, pResultBuffer);
	}
	ReleaseSingleSync(pData->syncData, ss);
	return ret;
}


STAFRC_t STAFServiceGetLevelBounds(unsigned int levelID,
                                   unsigned int *minimum,
                                   unsigned int *maximum)
{
    switch (levelID)
    {
        case kServiceInfo:
        {
            *minimum = 30;
            *maximum = 30;
            break;
        }
        case kServiceInit:
        {
            *minimum = 30;
            *maximum = 30;
            break;
        }
        case kServiceAcceptRequest:
        {
            *minimum = 30;
            *maximum = 30;
            break;
        }
        case kServiceTerm:
        case kServiceDestruct:
        {
            *minimum = 0;
            *maximum = 0;
            break;
        }
        default:
        {
            return kSTAFInvalidAPILevel;
        }
    }

    return kSTAFOk;
}

// Helper Functions

int STAFStringCompare(STAFString_t str1, STAFString_t str2) {
	unsigned int result;
	STAFStringIsEqualTo(str1, str2, kSTAFStringCaseInsensitive, &result, NULL);
	if (result==0)
		return 1;
	return 0;
}

STAFRC_t ParseParameters(STAFServiceInfoLevel30 *pInfo, PHolder *perl_holder, unsigned int *maxLogs, long *maxLogSize, STAFString_t *pErrorBuffer) {

	STAFString_t MaxLogsSizeString;
	STAFString_t MaxLogsString;
	STAFString_t UseLibString;
	STAFRC_t ret = kSTAFOk;

	STAFStringConstruct(&MaxLogsSizeString, "MAXLOGSIZE", 10, NULL);
	STAFStringConstruct(&MaxLogsString, "MAXLOGS", 7, NULL);
	STAFStringConstruct(&UseLibString, "USELIB", 6, NULL);

    for (unsigned int i = 0; i < pInfo->numOptions; ++i)
    {
		STAFString_t optionValue = pInfo->pOptionValue[i];
		STAFString_t upperOptionName = pInfo->pOptionName[i];

        if (STAFStringCompare(upperOptionName, MaxLogsString)==0)
        {
            // Check to make sure it is an integer value > 0
			STAFRC_t ret1 = STAFStringToUInt(optionValue, maxLogs, 10, NULL);
			if (ret1 != kSTAFOk) {
				const char *msg = "Error: MAXLOGS value is incorrect!";
				STAFStringConstruct(pErrorBuffer, msg, strlen(msg), NULL);
				ret = kSTAFServiceConfigurationError;
				break;
			}

        }
        else if (STAFStringCompare(upperOptionName, MaxLogsSizeString)==0)
        {
            // Check to make sure it is an integer value > 0
			unsigned int maxLogSizeTmp;
			STAFRC_t ret1 = STAFStringToUInt(optionValue, &maxLogSizeTmp, 10, NULL);
			if (ret1 != kSTAFOk) {
				const char *msg = "Error: MAXLOGSIZE value is incorrect!";
				STAFStringConstruct(pErrorBuffer, msg, strlen(msg), NULL);
				ret = kSTAFServiceConfigurationError;
				break;
			} else
				*maxLogSize = maxLogSizeTmp;
		}
        else if (STAFStringCompare(upperOptionName, UseLibString)==0)
        {
			perl_uselib(perl_holder, optionValue);
        }
        else
        {
			STAFStringConstructCopy(pErrorBuffer, upperOptionName, NULL);
            ret = kSTAFServiceConfigurationError;
			break;
        }
	}
	STAFStringDestruct(&MaxLogsSizeString , NULL);
	STAFStringDestruct(&MaxLogsString , NULL);
	STAFStringDestruct(&UseLibString , NULL);
    return ret;
}

STAFRC_t ReplaceChar(STAFString_t opr_str, char old, char newc) {
	STAFString_t old_t, newc_t;
	char tmp[2];
	tmp[1] = 0;
	tmp[0] = old;
	STAFStringConstruct(&old_t, tmp, 1, NULL);
	tmp[0] = newc;
	STAFStringConstruct(&newc_t, tmp, 1, NULL);
	STAFRC_t ret = STAFStringReplace(opr_str, old_t, newc_t, NULL);
	STAFStringDestruct(&old_t, NULL);
	STAFStringDestruct(&newc_t, NULL);
	return ret;
}
