
#include "synchelper.h"
#include <stdio.h>
#include <stdlib.h>

typedef unsigned int uint;

struct SingleSync_t {
	// the place of this record in the SingleSync's array
    uint request_number;
	// If free, then point to the next free.
	// (or to NULL, if this is the last free record)
	// if in hash, point to the next record in the same bucket
    struct SingleSync_t *next;
	// Event - for waiting and posting the result
    STAFEventSem_t event;
	// The following two parameters are used for passing the results
	// from the worker thread to the requesting thread
	STAFString_t resultBuffer;
	STAFRC_t return_code;
};

struct SyncData_t {
	// Pointer to the first free record. NULL if no record is free.
    SingleSync *first_free;
	// Holds a list of records
    SingleSync **list;
	// how long the list was malloced
    uint list_created;
	// how many items are used in the list
    uint list_occupied;
	// mutex protecting the list. every reading or writing should use this.
    STAFMutexSem_t mutex;
};

void DestroySyncData(SyncData *sd) {
	SingleSync *ss = sd->first_free;
	while (ss != NULL) {
		SingleSync *tmp = ss;
		ss = ss->next;
		free(tmp);
	}
    for (unsigned int ix=0; ix<sd->list_created; ix++) {
        SingleSync *ss = sd->list[ix];
		while (ss != NULL) {
			STAFEventSemDestruct(&(ss->event), NULL);
			SingleSync *tmp = ss;
			ss = ss->next;
			free(tmp);
		}
    }
    free(sd->list);
    STAFMutexSemDestruct(&(sd->mutex), NULL);
    free(sd);
}

void ReleaseSingleSync(SyncData *sd, SingleSync *ss) {
    STAFRC_t ret = STAFMutexSemRequest(sd->mutex, -1, NULL);
	if (ret != kSTAFOk) {
		fprintf(stderr, "ReleaseSingleSync: Warning - failed to request sem\n");
	}
	uint hashed = ss->request_number % sd->list_created;
	if (sd->list[hashed] == ss) {
		sd->list[hashed] = ss->next;
	} else {
		SingleSync *t = sd->list[hashed];
		uint counter = 0;
		while (t!= NULL) {
			if (t->next == ss) {
				t->next = ss->next;
				break;
			}
			t = t->next;
			if ( counter > sd->list_occupied ) {
				fprintf(stderr, "ReleaseSingleSync: Warning - searching for more slots then exists?\n");
				fprintf(stderr, "Counter %d, Occupid %d, Request %d\n", counter, sd->list_occupied, ss->request_number);
				return;
			}
			counter++;
		}
	}
	if (ss->resultBuffer != NULL) {
		fprintf(stderr, "Warning: STAF::DelayedAnswer() was called for request number %d\n", ss->request_number);
		fprintf(stderr, "   But the data was released without being used.\n");
		fprintf(stderr, "   Please check that you use the currect requestNumber\n");
		fprintf(stderr, "   (and probably now you have a client that will wait forever...)\n");
		STAFStringDestruct(&(ss->resultBuffer) , NULL);
		ss->resultBuffer = NULL;
	}
	ss->request_number = 0;
    ss->next = sd->first_free;
    sd->first_free = ss;
    ret = STAFMutexSemRelease(sd->mutex, NULL);
	if (ret != kSTAFOk) {
		fprintf(stderr, "ReleaseSingleSync: Warning - failed to release sem\n");
	}
}

STAFRC_t WaitForSingleSync(SingleSync *ss, STAFString_t *pErrorBuffer) {
	STAFRC_t ret;
    ret = STAFEventSemWait(ss->event, STAF_EVENT_SEM_INDEFINITE_WAIT, NULL);
	if (ret!=kSTAFOk) {
		fprintf(stderr, "WaitForSingleSync: Warning - failed while waiting to event\n");
		return NULL;
	}
    ret = STAFEventSemReset(ss->event, NULL);
	if (ret!=kSTAFOk) {
		fprintf(stderr, "WaitForSingleSync: Warning - failed while reseting event\n");
		return NULL;
	}
	*pErrorBuffer = ss->resultBuffer;
	STAFRC_t rc = ss->return_code;
	ss->return_code = 0;
	ss->resultBuffer = NULL;
	return rc;
}

SingleSync *_GetSyncById(SyncData *sd, uint request_number) {
    SingleSync *ss = NULL;
	STAFRC_t ret;
    ret = STAFMutexSemRequest(sd->mutex, -1, NULL);
	if (ret!=kSTAFOk) {
		fprintf(stderr, "_GetSyncById: Warning - failed to request sem\n");
		return NULL;
	}
	uint hashed = request_number % sd->list_created;
	ss = sd->list[hashed];
	while (( ss != NULL ) && ( ss->request_number != request_number )) {
		ss = ss->next;
	}
	
    ret = STAFMutexSemRelease(sd->mutex, NULL);
	if (ret!=kSTAFOk) {
		fprintf(stderr, "_GetSyncById: Warning - failed to release sem\n");
	}
    return ss;
}

void PostSingleSyncByID(SyncData *sd, unsigned int id, STAFRC_t rc, const char *err_str, unsigned int len) {
	STAFRC_t ret;
    SingleSync *ss = _GetSyncById(sd, id);
    if (NULL == ss) {
		fprintf(stderr, "Error: can not find waiting request whose number is %d\n", id);
		fprintf(stderr, "   Please check that you use the currect requestNumber\n");
		fprintf(stderr, "   (and probably now you have a client that will wait forever...)\n");
        return;
	}
	STAFStringConstruct(&(ss->resultBuffer), err_str, len, NULL);
	ss->return_code = rc;
    ret = STAFEventSemPost(ss->event, NULL);
	if (ret!=kSTAFOk) {
		fprintf(stderr, "PostSingleSyncByID: Warning - failed to post event\n");
	}
}

uint _ExtendSyncTable(SyncData *sd) {
	uint ix;
	uint new_base = sd->list_created * 2;
	SingleSync **list = (SingleSync**)malloc(sizeof(SingleSync*) * new_base);
	if (NULL == list) {
		fprintf(stderr, "Failed to malloc memory for new SyncTable\n");
		return 0;
	}
	for (ix=0; ix < new_base; ix++) {
		list[ix] = NULL;
	}
	for (ix=0; ix<sd->list_created; ix++) {
		SingleSync *ss = sd->list[ix];
		while (ss != NULL) {
			SingleSync *next = ss->next;
			uint hashed = ss->request_number % new_base;
			ss->next = list[hashed];
			list[hashed] = ss;
			ss = next;
		}
	}
	free(sd->list);
	sd->list = list;
	sd->list_created = new_base;
	return 1;
}

SingleSync *_CreateNewSingleSync(SyncData *sd) {
    SingleSync *ss = NULL;
    if (sd->list_created <= sd->list_occupied) {
        // if there is no place for a new record - need to expend the array
		if (1 != _ExtendSyncTable(sd)) {
			return NULL;
		}
    }
    
    // now we know that there is enough space for a new record. so lets create it.
    ss = (SingleSync*)malloc(sizeof(SingleSync));
    if (NULL == ss) {
		fprintf(stderr, "GetSingleSync: Warning - failed malloc memory\n");		
        return NULL;
    }
    STAFRC_t ret = STAFEventSemConstruct(&(ss->event), NULL, NULL);
	if (ret!=kSTAFOk) {
		fprintf(stderr, "GetSingleSync: Warning - failed to construct ss sem\n");
        free(ss);
		return NULL;
    }
	return ss;
}

SingleSync *GetSingleSync(SyncData *sd, uint request_number) {
    SingleSync *ss = NULL;
	STAFRC_t ret = STAFMutexSemRequest(sd->mutex, -1, NULL);
	if (ret!=kSTAFOk) {
		fprintf(stderr, "GetSingleSync: Warning - failed to request sem\n");
		return NULL;
	}
    if (NULL != sd->first_free) {
        ss = sd->first_free;
        sd->first_free = ss->next;
    } else {
		ss = _CreateNewSingleSync(sd);
		if (NULL == ss) {
			ret = STAFMutexSemRelease(sd->mutex, NULL);
			if (ret != kSTAFOk) {
				fprintf(stderr, "GetSingleSync: Warning - failed release sem on failed ss construct\n");
			}
			return NULL;
		}
		sd->list_occupied++;
	}

	uint hashed = request_number % sd->list_created;
    ss->request_number = request_number;
	ss->resultBuffer = NULL;
	ss->return_code = 0;
    ss->next = sd->list[hashed];
	sd->list[hashed] = ss;
    
    ret = STAFMutexSemRelease(sd->mutex, NULL);
	if (ret != kSTAFOk) {
		fprintf(stderr, "GetSingleSync: Warning - failed release sem\n");
	}
    return ss;
}

SyncData *CreateSyncData() {
    STAFRC_t ret;
    SyncData *ds = (SyncData*)malloc(sizeof(SyncData));
    if (NULL == ds) {
		fprintf(stderr, "CreateSyncData: Warning - failed malloc main data structure\n");
		return NULL;
	}
    ds->list = (SingleSync**)malloc(sizeof(SingleSync*)*10);
    if (NULL == ds->list) {
		fprintf(stderr, "CreateSyncData: Warning - failed malloc hash table\n");
        free(ds);
        return NULL;
    }
    ds->list_created = 10;
    ds->list_occupied = 0;
    ds->first_free = NULL;
	for (uint ix=0; ix<ds->list_created; ix++) {
		ds->list[ix] = NULL;
	}
    ret = STAFMutexSemConstruct(&(ds->mutex), NULL, NULL);
    if (ret!=kSTAFOk) {
		fprintf(stderr, "CreateSyncData: Warning - failed to construct main sem\n");
        free(ds->list);
        free(ds);
        return NULL;
    }
    return ds;
}
