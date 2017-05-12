#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "tclink.c"

MODULE = Net::TCLink		PACKAGE = Net::TCLink

void *
TCLinkCreate()

void 
TCLinkPushParam(handle, name, value)
	void * handle
	char * name
	char * value

void 
TCLinkSend(handle)
	void * handle

char *
TCLinkGetEntireResponse(handle,buf)
	void * handle
	char * buf
	CODE:
		TCLinkGetEntireResponse(handle,buf,strlen(buf));
		RETVAL = buf;
	OUTPUT:
		RETVAL

void 
TCLinkDestroy(handle)
	void * handle

