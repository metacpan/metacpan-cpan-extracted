#include        "EXTERN.h"
#include        "perl.h"
#include        "XSUB.h"

#include        "isc-dhcp/result.h"
#include        "omapip/omapip.h"
#include	"dhcpctl.h"

#include 	<stdio.h>
#include	<netinet/in.h>
#include        <sys/socket.h>
#include        <sys/time.h>

#include        <assert.h>

#include "DHCPCTL-TP.h"  /* define TP_* constants */

#ifndef XS_DEBUG
#define XS_DEBUG 1
#endif
#if XS_DEBUG
#define DEBUG(x) fprintf x
#else
#define DEBUG(x)
#endif

#define IS_SUCCESS(err) ((err) == ISC_R_SUCCESS)
#define DHCP_PORT 7911
#define MODID DHCP_PORT  /* Might as well make it something recognizable */

/* Set the Perl variable $DHCPCTL::STATUS to
 * have a numeric value of (status) 
 * and a string value of (isc_result_totext(status))
 */
static void set_status(isc_result_t status) 
{
	SV *STATUS = get_sv("DHCPCTL::STATUS", 1);
        (void)SvUPGRADE(STATUS,SVt_PVNV);
        sv_setpv(STATUS,isc_result_totext(status));
	SvIVX(STATUS) = status;
	SvIOK_on(STATUS);

}
static void clear_status(void)  { set_status(ISC_R_SUCCESS); }

typedef struct s_callback {
  CV* perl_func;
  SV* data;
} CALLBACK, *CALLBACKp;

/* Never tested */
void 
handle_perl_callbacks(dhcpctl_handle object, dhcpctl_status status, void * cb)
{
  CV *perl_callback = ((CALLBACK *)cb)->perl_func;
  SV *perl_data = ((CALLBACK *)cb)->data;
  dSP;
  SV *object_deref = newSViv(0);
  SV *object_arg   = newRV_inc(object_deref);

  sv_setref_pv(object_arg, Nullch, (void*)object);
  DEBUG((stderr, "handle_perl_callbacks!\n"));

  ENTER ;
  SAVETMPS ;

  PUSHMARK(SP);
  XPUSHs(sv_2mortal(object_arg));
  XPUSHs(sv_2mortal(newSViv(status)));
  XPUSHs(perl_data);
  PUTBACK;

  call_sv((SV *)perl_callback, G_VOID|G_DISCARD);

  FREETMPS ;
  LEAVE ;
}

#include "const-c.inc"

MODULE  = Net::DHCP::Control	PACKAGE = Net::DHCP::Control
PROTOTYPES: DISABLE

void initialize()

  CODE:
    DEBUG((stderr, "debugging on\n"));
    dhcpctl_initialize();



dhcpctl_handle *
new_authenticator(name, algorithm, secret)
	char *name
	char *algorithm
	char *secret

	PREINIT:
	isc_result_t status;

	CODE:
	    clear_status();
            New(MODID, RETVAL, 1, dhcpctl_handle); 
	    *RETVAL = dhcpctl_null_handle;

	    status = dhcpctl_new_authenticator (RETVAL, name, algorithm, 
		secret, strlen(secret)+1);

	    if (status != ISC_R_SUCCESS) {
		set_status(status);
	        DEBUG ((stderr, "authenticator failed (%s)\n", isc_result_totext(status)));
	        Safefree(RETVAL);
	        RETVAL = NULL;
	    } 
            DEBUG((stderr, "secret = %p\n", secret));

	OUTPUT: RETVAL


dhcpctl_handle *
connect(host, port=7911, authenticator=NULL)
    char *		host
    int 		port
    dhcpctl_handle *    authenticator

    PREINIT:
	isc_result_t		status;
	
    CODE:
        DEBUG ((stderr, "connect(host=%s, port=%u, auth=%p)\n", 
		host, port, authenticator));
        clear_status();
        New(MODID, RETVAL, 1, dhcpctl_handle); 
	*RETVAL = dhcpctl_null_handle;

	DEBUG ((stderr, "Connecting to %s : %d\n", host, port));

	if (RETVAL != NULL) {
	    if (port == 0) port = DHCP_PORT;
	    status = dhcpctl_connect (RETVAL, host, port, 
	             authenticator ? *authenticator : dhcpctl_null_handle );
    	    set_status(status);
	    if (status != ISC_R_SUCCESS) {
	        DEBUG ((stderr, "connect failed (%s)\n", isc_result_totext(status)));
	        Safefree(RETVAL);
	        RETVAL = NULL;
	        DEBUG((stderr, "connect failed OK\n"));
	    }
	}

    OUTPUT: RETVAL


dhcpctl_handle *
new_object(connection, type)
	dhcpctl_handle * connection
	char * type

    PREINIT:
	isc_result_t		status;
	
	CODE:
        clear_status();
        New(MODID, RETVAL, 1, dhcpctl_handle); 

	DEBUG ((stderr, "Creating object of type '%s'\n", type));

	if (RETVAL != NULL) {
	    *RETVAL = dhcpctl_null_handle;
	    status = dhcpctl_new_object (RETVAL, *connection, type);
            set_status(status);

	    if (status != ISC_R_SUCCESS) {
	        DEBUG ((stderr, "Creation of '%s' failed (%s)\n", type, isc_result_totext(status)));
	        Safefree(RETVAL);
	        RETVAL = NULL;
	    }
	}

    OUTPUT: RETVAL



unsigned
set_value(object, name, value, type=TP_UNSPECIFIED)
	dhcpctl_handle * object
	char * name
	SV * value
	TYPE type;

	CODE:

          clear_status();

	  if (type == TP_UNSPECIFIED) { /* try to guess the type */
	    if (value == NULL || !SvANY(value)) {  /* undef */
	      value = newSVpvn("", 0);
	      type = TP_STRING;
	    } else if (SvPOK(value)) {
	      type = TP_STRING;
	    } else if (SvIOK(value)) {
	      /* This test is dumb */
	      type = SvIV(value) < 0 ? TP_INT : TP_UINT;
	    }  else {
	      croak("set_value can't figure out the type of this datum");
            }
            DEBUG((stderr, "set-value: inferred type = %u\n", type));
	  }

          switch (type) {
	    unsigned len, u;
	    int i;
	    char *s;
	    case TP_STRING:
	      s = SvPV(value, len);
	      assert(s[len] == '\0');
	      RETVAL = dhcpctl_set_string_value(*object, s, name);
	      break;
	    case TP_INT:
	    case TP_UINT:
	      RETVAL = dhcpctl_set_int_value(*object, SvIV(value), name);
	      break;
	    case TP_BOOL:
	      RETVAL = dhcpctl_set_boolean_value(*object, SvIV(value) ? 1 : 0, name);
	      break;
	    default:
	      croak("Unknown data type (%u) in set_value", type);
	      break;
          }
	  
	set_status(RETVAL);
	RETVAL = IS_SUCCESS(RETVAL);
	OUTPUT: RETVAL



SV *
get_value(object, name, type=TP_UNSPECIFIED)
	dhcpctl_handle * object
	char * name
	TYPE type;

	PREINIT:
  	  isc_result_t status;
	  dhcpctl_data_string value = NULL;
	
	CODE:
          clear_status();
	  RETVAL = NULL;

          status = dhcpctl_get_value(&value, *object, name);
 	  set_status(status);
	  DEBUG((stderr, "value = %p; value->len = %d\n", value, value ? value->len : -1));
	  if (IS_SUCCESS(status)) {
            if (type == TP_UNSPECIFIED) {  /* This won't always work */
              if (value->len == 1) 
	        type = TP_BOOL;
              else if (value->len == 4)
                type = TP_INT; /* ... or a string of length 4 */
              else 
	        type = TP_STRING;
            }

	    switch(type) {
	    case TP_INT:
  	      RETVAL = newSViv(*(int *) value->value );
	      break;
	    case TP_BOOL:
	    case TP_UINT:
  	      RETVAL = newSVuv(*(unsigned int *) value->value );
	      break;
	    case TP_STRING:
	      if (value->value)
  	        RETVAL = newSVpvn(value->value, value->len);
	      else 
  	        RETVAL = 0;
	      break;
	    default:
	      croak("Unknown data type (%u) in get_value", type);
	      break;
            }	
	  }
	  
	OUTPUT: RETVAL



unsigned
open_object(object, connection, flags=0)
	dhcpctl_handle * object
	dhcpctl_handle * connection
	int flags

	CODE:
        clear_status();
	RETVAL = dhcpctl_open_object(*object, *connection, flags);
	set_status(RETVAL);
	RETVAL = IS_SUCCESS(RETVAL);

	OUTPUT: RETVAL


unsigned
object_update(handle, object)
	dhcpctl_handle * handle
	dhcpctl_handle * object

	CODE:
	clear_status();
	RETVAL = dhcpctl_object_update(*handle, *object);
	set_status(RETVAL);
	RETVAL = IS_SUCCESS(RETVAL);

	OUTPUT: RETVAL

	



unsigned
wait_for_completion(object) 
	dhcpctl_handle * object

	PREINIT:
	  isc_result_t waitstat = ISC_R_SUCCESS;
	  isc_result_t stat;

	CODE:
          clear_status();
	  stat = dhcpctl_wait_for_completion(*object, &waitstat);
    	DEBUG((stderr, "stat=%d, waitstat=%d\n", stat, waitstat));
	  set_status(IS_SUCCESS(stat) ? waitstat : stat);
	  RETVAL = IS_SUCCESS(stat) && IS_SUCCESS(waitstat);

	OUTPUT: RETVAL

unsigned 
set_callback(object, perl_callback, data)
	dhcpctl_handle * object
	CV * perl_callback
	SV * data

	PREINIT:
	  CALLBACKp cb;
	  isc_result_t status;

	CODE:
	  RETVAL = 0;
	  New(MODID, cb, 1, CALLBACK);
	  if (cb) {
  	    DEBUG((stderr, "cb constructed\n"));
	    cb->perl_func = perl_callback;
	    cb->data = data;
	    RETVAL = dhcpctl_set_callback(*object, (void *)cb, handle_perl_callbacks);
	    set_status(RETVAL);
  	    DEBUG((stderr, "set callback: %d\n", RETVAL));
	    RETVAL = IS_SUCCESS(RETVAL);
	  }

	OUTPUT: RETVAL
	

void 
deallocate(object)
	dhcpctl_handle * object

	CODE:
	    if (object) {
                omapi_object_dereference(object, MDL);	
	    }

char *
errtext(err)
	isc_result_t err;

	CODE:
	    RETVAL = (char * )isc_result_totext(err);
	OUTPUT: RETVAL

unsigned
is_success(err)
	isc_result_t err

	CODE: 
	  RETVAL = IS_SUCCESS(err);

	OUTPUT: RETVAL

void
ss(stat)
	int stat

	CODE:
	  set_status(stat);

INCLUDE: const-xs.inc
	
