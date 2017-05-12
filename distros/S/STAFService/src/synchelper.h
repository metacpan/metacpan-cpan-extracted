#ifndef __SYNC_HELPEER_H__
#define __SYNC_HELPEER_H__

#include "STAFIncludes.h"

typedef struct SyncData_t SyncData;
typedef struct SingleSync_t SingleSync;

SyncData *CreateSyncData();
SingleSync *GetSingleSync(SyncData *sd, unsigned int request_number);
void PostSingleSyncByID(SyncData *sd, unsigned int id, STAFRC_t rc, const char *err_str, unsigned int len);
STAFRC_t WaitForSingleSync(SingleSync *ss, STAFString_t *pErrorBuffer);
void ReleaseSingleSync(SyncData *sd, SingleSync *ss);
void DestroySyncData(SyncData *sd);

#endif
