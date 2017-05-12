/* -*- C -*- */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <howl.h>
#include <rendezvous/rendezvous.h>
#include <rendezvous/text_record.h>

#define MY_DEBUG 0
#if MY_DEBUG
#  define DS(x) (x)
#else
#  define DS(x)
#endif


static sw_string
status_text[] = {
    "success",
    "success", /* should be "Stopped", but in Howl 0.9.8 it seems to
		* tell me STOPPED when it should be STARTED. I Hate Software */
    "Name Collision",
    "Invalid"
};


static sw_result
publish_reply(  
    sw_rendezvous                 rendezvous,
    sw_rendezvous_publish_status  status,
    sw_rendezvous_publish_id      id,
    sw_opaque                     extra
    )
{
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    DS( warn( "publish reply: %s %x\n", status_text[status], extra) );

    XPUSHs( (SV*) extra );
    XPUSHs( sv_2mortal( newSVpv(status_text[status], 0) ) );
    PUTBACK;

    call_method("_publish_callback", G_DISCARD);

    return SW_OKAY;
}


MODULE = Net::Rendezvous::Publish::Backend::Howl		PACKAGE = Net::Rendezvous::Publish::Backend::Howl		

sw_rendezvous
init_rendezvous()
CODE:
{
    if (sw_rendezvous_init( &RETVAL ) != SW_OKAY) {
	croak("init failed");
    }
}
OUTPUT:
    RETVAL

sw_rendezvous_publish_id
xs_publish( self, object, name, type, domain, host, port, text_chunks )
sw_rendezvous self;
SV* object;
sw_const_string name;
sw_const_string type;
sw_const_string domain;
sw_const_string host;
sw_port port;
AV *text_chunks;
CODE:
{
    sw_rendezvous_publish_id id;
    sw_result result;
    sw_text_record text;
    int i;


    if ( sw_text_record_init( &text ) != SW_OKAY ) {
	croak("sw_text_record_init failed");
    }
    for (i = 0; i <= av_len(text_chunks); i++) {
	SV **chunk = av_fetch(text_chunks, i, 0);
        char *str = SvPV_nolen(*chunk);
	DS( warn("add_string %s\n", str) );
	if ( sw_text_record_add_string( text, str ) != SW_OKAY ) {
	    croak("sw_text_record_add_string failed");
	}
    }

    DS( warn("publish %s %s %d %x\n", name, type, port, object ) );
    
    if ((result = sw_rendezvous_publish( 
	     self, 0, name, type, *domain ? domain : NULL, *host ? host : NULL, port, 
	     sw_text_record_bytes(text), sw_text_record_len(text),
	     publish_reply, SvREFCNT_inc( object), &id 
	     )) != SW_OKAY)
    {
        /* sw_text_record_fina( &text ); */
	croak("publish failed: %d\n", result);
    }
    sw_text_record_fina( text ); 
    RETVAL = id;
}
OUTPUT: RETVAL

sw_result
sw_discovery_cancel(self, id)
	sw_rendezvous	self
	sw_rendezvous_publish_id	id

sw_result
sw_rendezvous_fina(self)
	sw_rendezvous	self

sw_salt
get_salt( session );
sw_rendezvous session;
CODE:
{
    if (sw_rendezvous_salt( session, &RETVAL ) != SW_OKAY) {
	croak("salt failed");
    }
}
OUTPUT: RETVAL

void
run_step( salt, time )
sw_salt salt;
sw_long time;
CODE:
    sw_salt_step( salt, &time );
