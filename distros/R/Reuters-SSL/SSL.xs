#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ssl.h"

/*******************************/
/* Local Static Vars           */
/*******************************/
static SV *my_callback; /* Pointer To Function for Registered Callback */


/******************************/
/* local callback             */
/******************************/
/* this function is called from within the sslDispatchEvent - function automatically
   when there is an event in the queue to be processed. If the program has registered
   before a callback function back into the perl - program via the sslregsiterCallBack 
   then this callback
   function will be called with the translated structure to hash.
*/
static SSL_EVENT_RETCODE
my_callback_function(int Channel, SSL_EVENT_TYPE Event, SSL_EVENT_INFO* EventInfo, void *ClientEventTag)
{
	dSP;
	int count;
	int retval;
	HV * hImage = (HV*)NULL;
	ENTER;SAVETMPS;
	PUSHMARK(SP);
	if (hImage == (HV*)NULL)
		hImage = newHV();
	hv_clear(hImage);
	if (Event == SSL_ET_ITEM_IMAGE)
	{
		SSL_ITEM_IMAGE_TYPE  * item = (SSL_ITEM_IMAGE_TYPE *)EventInfo;
		hv_store(hImage,"ServiceName",11,newSVpv(item->ServiceName,strlen(item->ServiceName)),0);
		hv_store(hImage,"ItemName",8,newSVpv(item->ItemName,strlen(item->ItemName)),0);
		hv_store(hImage,"SequenceNum",11,newSViv(item->SequenceNum),0);
		hv_store(hImage,"PreviousName",12,newSVpv(item->PreviousName,strlen(item->PreviousName)),0);
		hv_store(hImage,"NextName",8,newSVpv(item->NextName,strlen(item->NextName)),0);
		hv_store(hImage,"GroupId",7,newSViv(item->GroupId),0);
		hv_store(hImage,"ItemState",8,newSViv(item->ItemState),0);
		hv_store(hImage,"StateInfoCode",13,newSViv(item->StateInfoCode),0);
		hv_store(hImage,"DataLength",10,newSViv(item->DataLength),0);
		hv_store(hImage,"Data",4,newSVpv(item->Data,item->DataLength),0);
	}
	if (Event == SSL_ET_ITEM_UPDATE)
	{
		SSL_ITEM_UPDATE_TYPE *item = (SSL_ITEM_UPDATE_TYPE*)EventInfo;
		hv_store(hImage,"ServiceName",11,newSVpv(item->ServiceName,strlen(item->ServiceName)),0);
		hv_store(hImage,"ItemName",8,newSVpv(item->ItemName,strlen(item->ItemName)),0);
		hv_store(hImage,"DataLength",10,newSViv(item->DataLength),0);
		hv_store(hImage,"Data",4,newSVpv(item->Data,item->DataLength),0);
	}
	if (Event == SSL_ET_SERVICE_INFO)
	{
		SSL_SERVICE_INFO_TYPE *item = (SSL_SERVICE_INFO_TYPE*)EventInfo;
		hv_store(hImage,"ServiceName",11,newSVpv(item->ServiceName,strlen(item->ServiceName)),0);
		hv_store(hImage,"ServiceStatus",13,newSViv((int)item->ServiceStatus),0);
	}
	if (Event == SSL_ET_ITEM_STATUS_STALE || Event == SSL_ET_ITEM_STATUS_OK 
		|| Event == SSL_ET_ITEM_STATUS_CLOSED || Event == SSL_ET_ITEM_STATUS_CLOSED_RECOVER
		|| Event == SSL_ET_ITEM_STATUS_INFO )
	{
		SSL_ITEM_STATUS_TYPE *item = (SSL_ITEM_STATUS_TYPE*)EventInfo;
		hv_store(hImage,"ServiceName",11,newSVpv(item->ServiceName,strlen(item->ServiceName)),0);
		hv_store(hImage,"ItemName",8,newSVpv(item->ItemName,strlen(item->ItemName)),0);
		hv_store(hImage,"StateInfoCode",13,newSViv(item->StateInfoCode),0);
		hv_store(hImage,"Text",4,newSVpv(item->Text,strlen(item->Text)),0);
	}
	if (Event == SSL_ET_INSERT_ACK || Event == SSL_ET_INSERT_NAK )
	{
		SSL_INSERT_RESPONSE_TYPE *item = (SSL_INSERT_RESPONSE_TYPE*)EventInfo;
		hv_store(hImage,"ServiceName",11,newSVpv(item->ServiceName,strlen(item->ServiceName)),0);
		hv_store(hImage,"InsertName",10,newSVpv(item->InsertName,strlen(item->InsertName)),0);
		hv_store(hImage,"DataLength",10,newSViv(item->DataLength),0);
		hv_store(hImage,"Data",4,newSVpv(item->Data,item->DataLength),0);
	}
	EXTEND (SP, 3);
	XPUSHs (sv_2mortal (newSViv (     Channel)));
	XPUSHs (sv_2mortal (newSViv (     Event  )));
	XPUSHs (sv_2mortal (newRV   ((SV*)hImage )));
	
	PUTBACK;
	count = perl_call_sv(my_callback, G_SCALAR);
	SPAGAIN;

	if ( count!= 1 )
		croak ("perl-my_callback returned more than one argument\n");
	retval = POPi;
	PUTBACK;
	FREETMPS;
	LEAVE;
	return retval;
}


MODULE = Reuters::SSL		PACKAGE = Reuters::SSL		

BOOT:
my_callback = newSVsv (&PL_sv_undef);


int
sslInit()
	CODE:
	RETVAL = sslInit(SSL_VERSION_NO);
	OUTPUT:
	RETVAL

int
sslSnkMount(UserName)
	char *UserName;
	CODE:
	RETVAL = sslSnkMount(UserName);
	OUTPUT:
	RETVAL

int
sslDismount(Channel)
	int Channel;
	CODE:
	RETVAL = sslDismount(Channel);

int
sslSnkOpen(Channel, ServiceName, ItemName, ... )
	int Channel;
	char *ServiceName;
	char *ItemName;
	PREINIT:
	SSL_SINK_OPEN_OPTION OptionValue = 2;
	CODE:
	if ( items > 3 )
	  OptionValue = (SSL_SINK_OPEN_OPTION)SvIV(ST(3));
	RETVAL = sslSnkOpen(Channel, ServiceName, ItemName, NULL, SSL_SOO_REQUEST_TYPE, &OptionValue, NULL);
	OUTPUT:
	RETVAL

int 
sslRegisterCallBack(Channel, EventType, Callback)
	int Channel;
	int EventType;
	SV* Callback;
	CODE:
	sv_setsv (my_callback, Callback);
	EventType = SSL_EC_DEFAULT_HANDLER;
	RETVAL = sslRegisterClassCallBack(Channel, (SSL_EVENT_TYPE) EventType, my_callback_function, NULL);
	OUTPUT:
	RETVAL

int
sslSnkClose(Channel, ServiceName, ItemName)
	int Channel;
	char *ServiceName;
	char *ItemName;
	CODE:
	RETVAL = sslSnkClose(Channel, ServiceName, ItemName);
	OUTPUT:
	RETVAL

int
sslDispatchEvent(Channel, maxEvents)
	int Channel;
	int maxEvents;
	PREINIT:
	fd_set readfs;
	struct timeval timeout;
	CODE:
	timeout.tv_sec = 0;
	timeout.tv_usec = 0;
	FD_ZERO(&readfs);
	if (Channel != -1)
		FD_SET(Channel, &readfs);
	select(FD_SETSIZE, &readfs,NULL,NULL,&timeout);
	RETVAL = sslDispatchEvent(Channel, maxEvents);
	OUTPUT:
	RETVAL

int
sslGetProperty(Channel, OptionCode)
	int Channel;
	int OptionCode;
	PREINIT:
	int optionValue;
	int* optionPointer;
	int retval;
	PPCODE:
	optionPointer = &optionValue;
	retval = sslGetProperty(Channel, (SSL_OPTION_CODE)OptionCode, optionPointer);
	EXTEND(SP, 2);
	PUSHs(sv_2mortal(newSViv(retval)));
	PUSHs(sv_2mortal(newSViv(optionValue)));

char *
sslGetErrorText(Channel)
	int Channel;
	CODE:
	RETVAL = sslGetErrorText(Channel);
	OUTPUT:
	RETVAL

int
sslPostEvent(Channel, EventType, pEventInfo)
	int Channel;
	int EventType;
	SV* pEventInfo;
	PREINIT:
	SSL_INSERT_TYPE item;
	HV * EventInfo;
	STRLEN len;
	CODE:
	if ( SvTYPE( SvRV( pEventInfo ) ) != SVt_PVHV )
	{
		croak ("Argument #3 not of type reference to hash for EventInfo!\n");
	}
	EventInfo = (HV*)SvRV(pEventInfo);
	item.Data =        (char*)SvPV(*hv_fetch(EventInfo,"Data"       , 4,0),len);
	item.ServiceName = (char*)SvPV(*hv_fetch(EventInfo,"ServiceName",11,0),len);
	item.InsertName  = (char*)SvPV(*hv_fetch(EventInfo,"InsertName" ,10,0),len);
	item.InsertTag = NULL;
	item.DataLength =         SvIV(*hv_fetch(EventInfo,"DataLength", 10,0));
	RETVAL = sslPostEvent(Channel, (SSL_EVENT_TYPE)EventType, (SSL_EVENT_INFO*)&item);
	OUTPUT:
	RETVAL

int
sslErrorLog(LogFileName, LogFileSize)
	char *LogFileName;
	int LogFileSize;
	CODE:
	RETVAL = sslErrorLog(LogFileName, LogFileSize);
	OUTPUT:
	RETVAL

