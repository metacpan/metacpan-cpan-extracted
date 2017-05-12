
#ifndef __PERLGLUE_H__
#define __PERLGLUE_H__

#include "STAFServiceInterface.h"
#include "synchelper.h"

typedef struct PerlHolder PHolder;

PHolder *CreatePerl(SyncData *syncData);
void PopulatePerlHolder(PHolder *holder, STAFString_t service_name, STAFString_t library_name, STAFServiceType_t serviceType);
STAFRC_t RedirectPerlStdout(PHolder *holder, STAFString_t WriteLocation, STAFString_t ServiceName, unsigned int maxlogs, long maxlogsize, STAFString_t *pErrorBuffer);
STAFRC_t PreparePerlInterpreter(PHolder *holder, STAFString_t library_name, STAFString_t *pErrorBuffer);
void perl_uselib(PHolder *holder, STAFString_t path);

STAFRC_t InitService(PHolder *holder, STAFString_t parms, STAFString_t writeLocation, STAFString_t *pErrorBuffer);
STAFRC_t ServeRequest(PHolder *holder, struct STAFServiceRequestLevel30 *request, STAFString_t *pResultBuffer);
STAFRC_t Terminate(PHolder *holder);
STAFRC_t DestroyPerl(PHolder *holder);

#endif
