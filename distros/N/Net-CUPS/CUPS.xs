#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <cups/cups.h>
#if (CUPS_VERSION_MAJOR > 1) || (CUPS_VERSION_MINOR > 5)
#define HAVE_CUPS_1_6 1
#endif

/*#include <cups/backend.h>*/
#include <cups/http.h>
#ifdef HAVE_CUPS_1_6
 #include <cupsfilters/image.h>
#else
 #include <cups/image.h>
#endif
#include <cups/ipp.h>
#include <cups/ppd.h>
#include <cups/file.h>
#include <cups/dir.h>
#include <cups/language.h>
#include <cups/transcode.h>
#include <cups/adminutil.h>

#include "const-c.inc"
#include "packer.c"

#ifndef HAVE_CUPS_1_6
#define ippGetGroupTag(attr)  attr->group_tag
#define ippGetName(attr)      attr->name
#define ippGetValueTag(attr)  attr->value_tag
#define ippGetInteger(attr, element) attr->values[element].integer
#define ippGetString(attr, element, language) attr->values[element].string.text
#define ippGetStatusCode(ipp)  ipp->request.status.status_code
#define ippFirstAttribute(ipp) ipp->current = ipp->attrs
#define ippNextAttribute(ipp)  ipp->current = ipp->current->next
#endif

static SV *password_cb = (SV*) NULL;

const char *
password_cb_wrapper(const char *prompt)
{
	/* This variable will show up as unused on certain platforms. */
    STRLEN n_a;
    static char password[255] = { '\0' };

    if (! password_cb) 
        return NULL;

    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(prompt, 0)));
    PUTBACK;
    call_sv(password_cb, G_SCALAR);
    SPAGAIN;
    strncpy(password, POPpx, 254);

    PUTBACK;
    FREETMPS;
    LEAVE;

    return password;
}

cups_dest_t* cupsCloneDest(cups_dest_t* src) {
	int i;
	cups_dest_t *dst = malloc(sizeof(cups_dest_t));
	memcpy(dst, src, sizeof(cups_dest_t));
	if(src->name != NULL)
		dst->name = strdup(src->name);
	if(src->instance != NULL)
		dst->instance = strdup(src->instance);
	dst->options = malloc(src->num_options * sizeof(cups_option_t));
	for(i = 0; i < src->num_options; i++) {
		memcpy(&dst->options[i], &src->options[i], sizeof(cups_option_t));
		if(src->options[i].name != NULL)
			dst->options[i].name = strdup(src->options[i].name);
		if(src->options[i].value != NULL)
			dst->options[i].value = strdup(src->options[i].value);
	}
	return(dst);
}

MODULE = Net::CUPS		PACKAGE = Net::CUPS		

PROTOTYPES: DISABLE

INCLUDE: const-xs.inc

const char*
NETCUPS_getServer()
	CODE:
		RETVAL = cupsServer();
	OUTPUT:
		RETVAL

const char*
NETCUPS_getUsername()
	CODE:
		RETVAL = cupsUser();
	OUTPUT:
		RETVAL

void
NETCUPS_setServer( name )
		const char* name;
	CODE:
		cupsSetServer( name );

void
NETCUPS_setUsername( username )
		const char* username;
	CODE:
		cupsSetUser( username );

void
NETCUPS_setPasswordCB( callback )
		SV* callback;
	CODE:
		if( password_cb == (SV*) NULL )
		{
			password_cb = newSVsv( callback );
			cupsSetPasswordCB( password_cb_wrapper );
		}
		else
		{
			SvSetSV( password_cb, callback );
		}

const char*
NETCUPS_getPassword( prompt )
		const char* prompt;
	CODE:
		RETVAL = cupsGetPassword( prompt );
	OUTPUT:
		RETVAL

void
NETCUPS_getDestination( name )
		char* name;
	PPCODE:
		cups_dest_t * destinations = NULL;
		cups_dest_t * destination = NULL;
		int count = 0;
		SV* rv = NULL;
		count = cupsGetDests( &destinations );
		/* If we have a NULL for destination name, then we are going 
           to assume we want the default. */
		if( !strlen( name ) )
		{
			name = cupsGetDefault();
		}
		destination = cupsGetDest( name, NULL, count, destinations );
		rv = sv_newmortal();
		sv_setref_pv( rv, "Net::CUPS::Destination", destination );
		XPUSHs( rv );
		XSRETURN( 1 );

void
NETCUPS_getDestinations()
	PPCODE:
		cups_dest_t * destinations = NULL;
		int count = 0;
		int loop = 0;
		SV* rv = NULL;
		count = cupsGetDests( &destinations );
		for( loop = 0; loop < count; loop++ )
		{
			rv = sv_newmortal();
			/* FIXME cloning is probably not the best way to go at this.
			   It's at best a band aid for incorrect memory management
			   throughout this code base. Also there's a cupsCopyDest
			   function that seems to be doing the same as cupsCloneDest. */
			cups_dest_t *single = cupsCloneDest( &destinations[loop] );
			sv_setref_pv( rv, "Net::CUPS::Destination", single );
			XPUSHs( rv );
		}
		cupsFreeDests(count, destinations);
		XSRETURN( count );

ppd_file_t*
NETCUPS_getPPD( name )
		const char* name;
	INIT:
		const char* filename = NULL;
	CODE:
		filename = cupsGetPPD( name );
		RETVAL = ppdOpenFile( filename );
	OUTPUT:
		RETVAL

void
NETCUPS_requestData( request, resource, filename )
		ipp_t* request;
		const char* resource;
		const char* filename;
	PPCODE:
		http_t* http = NULL;
		ipp_t* response = NULL;
		const char* server = NULL;
		SV* rv = NULL;
		int port;
		server = cupsServer();
		port = ippPort();
		httpInitialize();
		http = httpConnect( server, port );
		if( strlen( filename ) == 0  )
			filename = NULL;
		response = cupsDoFileRequest( http, request, resource, filename );
		rv = sv_newmortal();
		sv_setref_pv( rv, "Net::CUPS::IPP", response );
		XPUSHs( rv );
		httpClose( http );
		XSRETURN( 1 );

void
NETCUPS_getPPDMakes() 
	http_t          *http;     /* HTTP object */
	ipp_t           *request;  /* IPP request object */
	ipp_t           *response; /* IPP response object */
	ipp_attribute_t *attr;     /* Current IPP attribute */
		
	PPCODE:
		SV* rv = NULL;	
		int count = 0;	
		cups_lang_t *language;
		language = cupsLangDefault();
		http = httpConnectEncrypt(cupsServer(), ippPort(), cupsEncryption()); 
		request =  ippNewRequest(CUPS_GET_PPDS);
		ippAddString(request, IPP_TAG_OPERATION, IPP_TAG_CHARSET,
					 "attributes-charset", NULL, "utf-8");
		ippAddString(request, IPP_TAG_OPERATION, IPP_TAG_LANGUAGE,
					 "attributes-natural-language", NULL, language->language);
		ippAddString(request, IPP_TAG_OPERATION, IPP_TAG_KEYWORD,
					 "requested-attributes", NULL, "ppd-make");

		response = cupsDoRequest(http, request, "/");

		if (response != NULL) {
			attr = ippFindAttribute(response, "ppd-make", IPP_TAG_TEXT); 
			rv = sv_newmortal();
			sv_setpv(rv, ippGetString(attr, 0, NULL));
			XPUSHs(rv);
			count++;

			while (attr != NULL) {
				attr = ippFindNextAttribute(response, "ppd-make", IPP_TAG_TEXT);
				if (attr == NULL) {
					break;
				}

				rv = sv_newmortal();
				sv_setpv(rv, ippGetString(attr, 0, NULL));
				XPUSHs(rv);
				count++;
			}			
	
		ippDelete(response);
		httpClose(http); 
	}
	else {
		XSRETURN ( 0 );
	}
	XSRETURN( count );


void
NETCUPS_getAllPPDs ()
	http_t          *http;     /* HTTP object */
	ipp_t           *request;  /* IPP request object */
	ipp_t           *response; /* IPP response object */
	ipp_attribute_t *attr;     /* Current IPP attribute */

	PPCODE:
		SV* rv = NULL;	
		int count = 0;	
		cups_lang_t *language;
		language = cupsLangDefault();
		http = httpConnectEncrypt(cupsServer(), ippPort(), cupsEncryption()); 
		request =  ippNewRequest(CUPS_GET_PPDS);
		ippAddString(request, IPP_TAG_OPERATION, IPP_TAG_CHARSET,
					 "attributes-charset", NULL, "utf-8");
		ippAddString(request, IPP_TAG_OPERATION, IPP_TAG_LANGUAGE,
					 "attributes-natural-language", NULL, language->language);
		ippAddString(request, IPP_TAG_OPERATION, IPP_TAG_KEYWORD,
					 "requested-attributes", NULL, "ppd-make-and-model");
		response = cupsDoRequest(http, request, "/");
	
		if (response != NULL) {
			attr = ippFindAttribute(response, 
									"ppd-make-and-model", 
									IPP_TAG_TEXT); 
			rv = sv_newmortal();
			sv_setpv(rv, ippGetString(attr, 0, NULL));
			XPUSHs(rv);
			count++;
			while (attr != NULL) {
				attr = ippFindNextAttribute(response, 
											"ppd-make-and-model", 
											IPP_TAG_TEXT);
				if (attr == NULL) {
					break;
				}
				rv = sv_newmortal();
				sv_setpv(rv, ippGetString(attr, 0, NULL));
				XPUSHs(rv);
				count++;
			}			

			ippDelete(response);
			httpClose(http); 
		}	
		else {
			XSRETURN ( 0 );
		}
	XSRETURN( count );

void
NETCUPS_deleteDestination( destination );
	const char* destination;

	PPCODE:
		ipp_t *request;
		http_t *http;
		char uri[HTTP_MAX_URI]; 	
	
		httpAssembleURIf(HTTP_URI_CODING_ALL, uri, sizeof(uri), "ipp", NULL,
						 cupsServer(), 0, "/printers/%s", destination);
		http = httpConnectEncrypt(cupsServer(), ippPort(), cupsEncryption());
		request = ippNewRequest(CUPS_DELETE_PRINTER);
		ippAddString(request, IPP_TAG_OPERATION, IPP_TAG_URI, "printer-uri",
					 NULL, uri);
		ippDelete(cupsDoRequest(http, request, "/admin/"));

void 
NETCUPS_addDestination(name, location, printer_info, ppd_name, device_uri);
	const char* name;
	const char* location;
	const char* printer_info;
	const char* ppd_name;
	const char* device_uri;

	PPCODE:
		http_t *http = NULL;     /* HTTP object */
		ipp_t *request = NULL;  /* IPP request object */
		char uri[HTTP_MAX_URI];	/* Job URI */
		
		http = httpConnectEncrypt(cupsServer(), ippPort(), cupsEncryption());
		
		request = ippNewRequest(CUPS_ADD_PRINTER);

		httpAssembleURIf(HTTP_URI_CODING_ALL, uri, sizeof(uri), "ipp", NULL,
						 cupsServer(), 0, "/printers/%s", name);
		ippAddString(request, IPP_TAG_OPERATION, IPP_TAG_URI, "printer-uri",
					 NULL, uri);
		ippAddString(request, IPP_TAG_PRINTER, IPP_TAG_TEXT, "printer-location",
					 NULL, location);
		ippAddString(request, IPP_TAG_PRINTER, IPP_TAG_TEXT, "printer-info",
					 NULL, printer_info );
		ippAddString(request, IPP_TAG_PRINTER, IPP_TAG_NAME, "ppd-name",
					 NULL, ppd_name);
		strncpy(uri, device_uri, sizeof(uri)); 
		ippAddString(request, IPP_TAG_PRINTER, IPP_TAG_URI, "device-uri",
					 NULL, uri);
		ippAddBoolean(request, IPP_TAG_PRINTER, "printer-is-accepting-jobs", 1);
		ippAddInteger(request, IPP_TAG_PRINTER, IPP_TAG_ENUM, "printer-state",
					  IPP_PRINTER_IDLE);
		ippDelete(cupsDoRequest(http, request, "/admin/"));

void
NETCUPS_getPPDFileName(ppdfilename);
	const char* ppdfilename;

	PPCODE:
		http_t          *http;     /* HTTP object */
		ipp_t           *request;  /* IPP request object */
		ipp_t           *response; /* IPP response object */
		ipp_attribute_t *attr;     /* Current IPP attribute */
		int i = 0;
		char* tmpppd;
		char test[1024];	
		SV* rv = NULL;

		http = httpConnectEncrypt(cupsServer(), ippPort(), cupsEncryption()); 
	
		request = ippNewRequest(CUPS_GET_PPDS);	

		ippAddString(request, IPP_TAG_OPERATION, IPP_TAG_CHARSET,
					 "attributes-charset", NULL, "utf-8");
		ippAddString(request, IPP_TAG_OPERATION, IPP_TAG_LANGUAGE,
					 "attributes-natural-language", NULL, "en");	

		response = cupsDoRequest(http, request, "/");

		if (response != NULL) {
			attr = ippFindAttribute(response, "ppd-name", IPP_TAG_NAME );
			while ((attr != NULL) && (i < 1)) {
				tmpppd = ippGetString(attr, 0, NULL);	
				attr = ippFindNextAttribute(response, 
											"ppd-make", 
											IPP_TAG_TEXT);
				attr = ippFindNextAttribute(response, 
											"ppd-make-and-model", 
											IPP_TAG_TEXT);
				if (strcmp(ippGetString(attr, 0, NULL), ppdfilename) == 0 ) {
					/* return tmpppd; */
					strcpy(test, tmpppd);	
					break;	
				}
				attr = ippFindNextAttribute(response, "ppd-name", IPP_TAG_NAME);	
			}
		}
		ippDelete(response); 
		httpClose(http);
		rv = sv_newmortal();  
		sv_setpv( rv, test); 
		XPUSHs( rv );

MODULE = Net::CUPS      PACKAGE = Net::CUPS::Destination

PROTOTYPES: DISABLE

INCLUDE: const-xs.inc

void
NETCUPS_getDeviceAttribute( device, attribute, attribute_type )
	const char* device;
	const char* attribute;
	int attribute_type;

	PPCODE: 
		http_t *http = NULL;			/* HTTP object */
		ipp_t *request = NULL; 		/* IPP request */
		ipp_t *response = NULL;			/* IPP response */
		ipp_attribute_t *attr = NULL;	/* IPP attribute */
		SV* rv = NULL; 
		char *description = NULL;

		http = httpConnectEncrypt( cupsServer(), ippPort(), cupsEncryption() );

		if (http == NULL) {
			perror ("Unable to connect to server");
			/* return (1); */
		}

		request = ippNewRequest (CUPS_GET_PRINTERS);
 
		if ((response = cupsDoRequest (http, request, "/")) != NULL) {
			attr = ippFindNextAttribute(response, "printer-name", IPP_TAG_NAME);

			while (attr != NULL) {
				if (strcmp(ippGetString(attr, 0, NULL), device) == 0) { 
					attr = ippFindNextAttribute( response, 
												 attribute, 
												 attribute_type);
					rv = sv_newmortal();  
					sv_setpv( rv, ippGetString(attr, 0, NULL)); 
					XPUSHs( rv );
					break;	
				}					
				attr = ippFindNextAttribute( response, 
											 "printer-name", 
											 IPP_TAG_NAME);
				if (attr == NULL) {
					break;
				}   
			}
		}
		ippDelete( response ); 
		httpClose( http );   	 
		XSRETURN( 1 );

int
NETCUPS_addOption( self, name, value )
		cups_dest_t* self;
		const char* name;
		const char* value;
	CODE:
		int num_options;
		num_options =
			cupsAddOption( name, value, self->num_options, &self->options );
		self->num_options = num_options;
		RETVAL = num_options;
	OUTPUT:
		RETVAL

int
NETCUPS_cancelJob( self, jobid )
		const char* self;
		int jobid;
	CODE:
		RETVAL = cupsCancelJob( self, jobid );
	OUTPUT:
		RETVAL

int
NETCUPS_freeDestination( self )
		cups_dest_t* self;
	CODE:
		/* If we use the following function, then we will get errors */
		/* about double frees.                                       */
		/*cupsFreeDests( 1, self );                                  */
		if( self->instance )
			free( self->instance );
		cupsFreeOptions( self->num_options, self->options );
		/* I am working under the assumption that the actual 'cups_dest_t */
		/* will be freed when perl does its garbage collection.           */
		/* I really need to research it more.                             */
		RETVAL = 1;
	OUTPUT:
		RETVAL

char*
NETCUPS_getDestinationName( self )
		cups_dest_t *self;
	CODE:
		RETVAL = self->name;
	OUTPUT:
		RETVAL

const char*
NETCUPS_getDestinationOptionValue( self, option )
		cups_dest_t *self;
		char* option;
	CODE:
		RETVAL = cupsGetOption( option, self->num_options, self->options );
	OUTPUT:
		RETVAL

void
NETCUPS_getDestinationOptions( self )
		cups_dest_t* self
	INIT:
		int count = 0;
		int loop = 0;
		SV* rv = NULL;
		cups_option_t* options = NULL;
	PPCODE:
		count = self->num_options;
		options = self->options;

		for( loop = 0; loop < count; loop++ )
		{
			rv = newSV(0);
			sv_setpv( rv, options[loop].name );
			XPUSHs( rv );
		}
		XSRETURN( count );

SV*
NETCUPS_getJob( dest, jobid )
		const char* dest;
		int jobid;
	CODE:
		int loop = 0;
		int count = 0;
		HV* hv = NULL;
		cups_job_t* jobs = NULL;
		char *tstate = NULL;
		RETVAL = &PL_sv_undef;
		count = cupsGetJobs( &jobs, dest, 0, -1 );
		for( loop = 0; loop < count; loop++ )
		{
			if( jobs[loop].id == jobid )
			{
				hv = newHV();

				hv_store( hv, "completed_time",
						  strlen( "completed_time" ),
						  newSVnv( jobs[loop].completed_time ), 
						  0 );

				hv_store( hv, "creation_time",
						  strlen( "creation_time" ),
						  newSVnv( jobs[loop].creation_time ), 
						  0 );

				hv_store( hv, "dest",
						  strlen( "dest" ),
						  newSVpv( jobs[loop].dest, 
								   strlen( jobs[loop].dest ) ), 0 );

				hv_store( hv, "format",
						  strlen( "format" ),
						  newSVpv( jobs[loop].format, 
								   strlen( jobs[loop].format ) ), 0 );

				hv_store( hv, "id",
						  strlen( "id" ),
						  newSViv( jobs[loop].id ), 0 );

				hv_store( hv, "priority",
						  strlen( "priority" ),
						  newSViv( jobs[loop].priority ), 0 );

				hv_store( hv, "processing_time",
						  strlen( "processing_time" ),
						  newSVnv( jobs[loop].processing_time ), 0 );

				hv_store( hv, "size",
						  strlen( "size" ),
						  newSViv( jobs[loop].size ), 0 );

				hv_store( hv, "state",
						  strlen( "state" ),
						  newSViv( jobs[loop].state ), 0 );

				hv_store( hv, "title",
						  strlen( "title" ),
						  newSVpv( jobs[loop].title, 
								   strlen( jobs[loop].title ) ), 0 );

				hv_store( hv, "user",
						  strlen( "user" ),
						  newSVpv( jobs[loop].user, 
								   strlen( jobs[loop].user ) ), 0 );

				switch( jobs[loop].state ) 
				{
					case IPP_JOB_PENDING:
					{
							tstate = "pending";
							break;
					}
					case IPP_JOB_HELD:
					{
							tstate = "held";
							break;
					}
					case IPP_JOB_PROCESSING:
					{
							tstate = "processing";
							break;
					}
					case IPP_JOB_STOPPED:
					{
							tstate = "stopped";
							break;
					}
					/* CANCELLED is not a TYPO! (Well, it is, but it
 					   is not my fault! */
					case IPP_JOB_CANCELLED:
					{
							tstate = "canceled";
							break;
					}
					case IPP_JOB_ABORTED: 
					{
							tstate = "aborted";
							break;
					}
					case IPP_JOB_COMPLETED: 
					{
							tstate = "completed";
							break;
					}
					default: 
					{
							tstate = "unknown";
							break;
					}
				}

				hv_store( hv, "state_text",
						  strlen( "state_text" ),
						  newSVpv( tstate, 
								   strlen( tstate ) ), 0 );

				RETVAL = newRV((SV*)hv);
			}
		}
	OUTPUT:
		RETVAL

void
NETCUPS_getJobs( dest, whose, scope )
		const char* dest;
		int whose;
		int scope;
	PPCODE:
		int loop = 0;
		int count = 0;
		SV* rv = NULL;
		cups_job_t* jobs = NULL;
		count = cupsGetJobs( &jobs, dest, whose, scope );
		for( loop = 0; loop < count; loop++ )
		{
			rv = newSV(0);
			sv_setiv( rv, jobs[loop].id );
			XPUSHs( rv );
		}
		XSRETURN( count );

const char*
NETCUPS_getError()
	CODE:
		RETVAL = cupsLastErrorString();
	OUTPUT:
		RETVAL

int
NETCUPS_printFile( self, filename, title )
		cups_dest_t* self;
		const char* filename;
		const char* title;
	CODE:
		RETVAL = cupsPrintFile( self->name,
								filename,
								title,
								self->num_options,
								self->options );
	OUTPUT:
		RETVAL


MODULE = Net::CUPS      PACKAGE = Net::CUPS::PPD

PROTOTYPES: DISABLE

INCLUDE: const-xs.inc

int
NETCUPS_freePPD( ppd )
		ppd_file_t *ppd;
	CODE:
		ppdClose( ppd );
		RETVAL = 1;
	OUTPUT:
		RETVAL

HV*
NETCUPS_getFirstOption( ppd )
		ppd_file_t *ppd;
	INIT:
		ppd_option_t *option;
	CODE:
		option = ppdFirstOption( ppd );
		RETVAL = hash_ppd_option_t( option );
                if (RETVAL == 0)
		  XSRETURN_UNDEF;
	OUTPUT:
		RETVAL

HV*
NETCUPS_getNextOption( ppd )
		ppd_file_t *ppd;
	INIT:
		ppd_option_t *option;
	CODE:
		option = ppdNextOption( ppd );
		RETVAL = hash_ppd_option_t( option );
                if (RETVAL == 0)
		  XSRETURN_UNDEF;
	OUTPUT:
		RETVAL

HV*
NETCUPS_getOption( ppd, keyword )
		ppd_file_t *ppd;
		const char* keyword;
	INIT:
		ppd_option_t *option;
	CODE:
		option = ppdFindOption( ppd, keyword );
		RETVAL = hash_ppd_option_t( option );
                if (RETVAL == 0)
		  XSRETURN_UNDEF;
	OUTPUT:
		RETVAL

int
NETCUPS_getPageLength( ppd, size )
		ppd_file_t *ppd;
		const char* size;
	CODE:
		RETVAL = ppdPageLength( ppd, size );
	OUTPUT:
		RETVAL

HV*
NETCUPS_getPageSize( ppd, size )
		ppd_file_t *ppd;
		const char* size;
	INIT:
		ppd_size_t* page_size;
		HV* hv;
	CODE:
		page_size = ppdPageSize( ppd, size );
		hv = newHV();

		if( page_size != NULL )
		{
			hv_store( hv, "bottom",
					  strlen( "bottom" ),
					  newSViv( page_size->bottom ), 0 );

			hv_store( hv, "left",
					  strlen( "left" ),
					  newSViv( page_size->left ), 0 );

			hv_store( hv, "length",
					  strlen( "length" ),
					  newSViv( page_size->length ), 0 );

			hv_store( hv, "marked",
					  strlen( "marked" ),
					  newSViv( page_size->marked ), 0 );

			hv_store( hv, "name",
					  strlen( "name" ),
					  newSVpv( page_size->name, PPD_MAX_NAME ), 0 );

			hv_store( hv, "right",
					  strlen( "right" ),
					  newSViv( page_size->right ), 0 );

			hv_store( hv, "top",
					  strlen( "top" ),
					  newSViv( page_size->top ), 0 );

			hv_store( hv, "width",
					  strlen( "width" ),
					  newSViv( page_size->width ), 0 );
		}
		RETVAL = hv;
	OUTPUT:
		RETVAL

int
NETCUPS_getPageWidth( ppd, size )
		ppd_file_t *ppd;
		const char* size;
	CODE:
		RETVAL = ppdPageWidth( ppd, size );
	OUTPUT:
		RETVAL


int
NETCUPS_isMarked( ppd, option, choice )
		ppd_file_t *ppd;
		const char* option;
		const char* choice;
	CODE:
		RETVAL = ppdIsMarked( ppd, option, choice );
	OUTPUT:
		RETVAL

int
NETCUPS_markDefaults( ppd )
		ppd_file_t *ppd;
	CODE:
		ppdMarkDefaults( ppd );
		RETVAL = 1;
	OUTPUT:
		RETVAL

int
NETCUPS_markOption( ppd, option, choice )
		ppd_file_t *ppd;
		const char* option;
		const char* choice;
	CODE:
		RETVAL = ppdMarkOption( ppd, option, choice );
	OUTPUT:
		RETVAL

MODULE = Net::CUPS      PACKAGE = Net::CUPS::IPP

PROTOTYPES: DISABLE

INCLUDE: const-xs.inc

int
NETCUPS_freeIPP( ipp )
		ipp_t* ipp;
	CODE:
		ippDelete( ipp );
		RETVAL = 1;
	OUTPUT:
		RETVAL

int
NETCUPS_addString( ipp, group, type, name, charset, value )
		ipp_t* ipp;
		ipp_tag_t group;
		ipp_tag_t type;
		const char* name;
		const char* charset;
		const char* value;
	CODE:
		ipp_attribute_t* attribute = NULL;
		attribute = ippAddString( ipp, group, type, name, charset, value );
		RETVAL = 1;
	OUTPUT:
		RETVAL


void
NETCUPS_getAttributes( ipp )
		ipp_t* ipp;
	PPCODE:
		SV* rv = NULL;
		int count = 0;
		ipp_attribute_t* attr = NULL;
		for (attr = ippFirstAttribute(ipp); attr != NULL; attr = ippNextAttribute(ipp))
		{
			while (attr != NULL && ippGetGroupTag(attr) != IPP_TAG_JOB)
 		       attr = ippNextAttribute(ipp);

			if (attr == NULL)
				break;
			rv = sv_newmortal();
			sv_setpv( rv, ippGetName(attr) );
			XPUSHs( rv );
			count++;
		}
		XSRETURN( count );

void 
NETCUPS_getAttributeValue( ipp, name )
		ipp_t* ipp;
		const char* name;
	PPCODE:
		SV* rv = NULL;
		int count = 0;
		ipp_attribute_t* attr = NULL;
		for (attr = ippFirstAttribute(ipp); attr != NULL; attr = ippNextAttribute(ipp))
		{
			while (attr != NULL && ippGetGroupTag(attr) != IPP_TAG_JOB)
 		       attr = ippNextAttribute(ipp);

			if (attr == NULL)
				break;

			if( !strcmp( ippGetName(attr), name ) )
			{
				rv = sv_newmortal();
				if( ( ippGetValueTag(attr) == IPP_TAG_INTEGER ) ||
					( ippGetValueTag(attr) == IPP_TAG_ENUM ) )
				{
					/* We have a number with any luck ... */
					sv_setiv( rv, ippGetInteger(attr, 0) );
				}
				else
				{
					/* We have a string ... maybe ... try to set it. */
					sv_setpv( rv, ippGetString(attr, 0, NULL) );
				}

				XPUSHs( rv );
				count++;
				break;
			}
		}
		XSRETURN( count );

int 
NETCUPS_getPort()
	CODE:
		RETVAL = ippPort();
	OUTPUT:
		RETVAL

size_t
NETCUPS_getSize( ipp )
		ipp_t* ipp;
	CODE:
		RETVAL = ippLength( ipp );
	OUTPUT:
		RETVAL

void
NETCUPS_newIPP()
	PPCODE:
		ipp_t * ipp = NULL;
		SV* rv = NULL;
		ipp = ippNew();
		rv = sv_newmortal();
		sv_setref_pv( rv, "Net::CUPS::IPP", ipp );
		XPUSHs( rv );
		XSRETURN( 1 );

void
NETCUPS_newIPPRequest( op )
		ipp_op_t op;
	PPCODE:
		ipp_t * ipp = NULL;
		SV* rv = NULL;
		ipp = ippNewRequest( op );
		rv = sv_newmortal();
		sv_setref_pv( rv, "Net::CUPS::IPP", ipp );
		XPUSHs( rv );
		XSRETURN( 1 );

int
NETCUPS_setPort( port )
		int port;
	CODE:
		ippSetPort( port );
		RETVAL = ippPort();
	OUTPUT:
		RETVAL
