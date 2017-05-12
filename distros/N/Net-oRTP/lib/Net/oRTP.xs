/*

	Net::oRTP: Real-time Transport Protocol (rfc3550)

	Nicholas Humfrey
	University of Southampton
	njh@ecs.soton.ac.uk
	
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <sys/types.h>
#include <ortp/ortp.h>



#ifndef rtp_get_markbit
#define rtp_get_markbit(mp)			((rtp_header_t*)((mp)->b_rptr))->markbit
#endif

#ifndef rtp_get_seqnumber
#define rtp_get_seqnumber(mp)		((rtp_header_t*)((mp)->b_rptr))->seq_number
#endif

#ifndef rtp_get_timestamp
#define rtp_get_timestamp(mp)		((rtp_header_t*)((mp)->b_rptr))->timestamp
#endif

#ifndef rtp_get_ssrc
#define rtp_get_ssrc(mp)			((rtp_header_t*)((mp)->b_rptr))->ssrc
#endif

#ifndef rtp_get_payload_type
#define rtp_get_payload_type(mp)	((rtp_header_t*)((mp)->b_rptr))->paytype
#endif



MODULE = Net::oRTP	PACKAGE = Net::oRTP


## Library initialisation
void
ortp_initialize()
  CODE:
	ortp_set_log_level_mask( ORTP_WARNING|ORTP_ERROR|ORTP_FATAL );
	ortp_init();
	ortp_scheduler_init();

void
ortp_shutdown()
  CODE:
	ortp_exit();




## Session Stuff
RtpSession*
rtp_session_new(mode)
	int mode
  CODE:
  	RETVAL=rtp_session_new(mode);
  	rtp_session_signal_connect(RETVAL,"ssrc_changed",(RtpCallback)rtp_session_reset,0);
  OUTPUT:
	RETVAL
	
	
void
rtp_session_set_scheduling_mode(session,yesno)
	RtpSession*	session
	int			yesno
	
void
rtp_session_set_blocking_mode(session,yesno)
	RtpSession*	session
	int			yesno

int
rtp_session_set_local_addr(session,addr,port)
	RtpSession*	session
	const char*	addr
	int			port

int
rtp_session_get_local_port(session)
	RtpSession* session
	
int
rtp_session_set_remote_addr(session,addr,port)
	RtpSession*	session
	const char*	addr
	int			port

void
rtp_session_set_jitter_compensation(session,milisec)
	RtpSession*	session
	int			milisec

int
rtp_session_get_jitter_compensation(session)
	RtpSession*	session
  CODE:
	RETVAL = session->rtp.jittctl.jitt_comp;
  OUTPUT:
	RETVAL
	

void
rtp_session_enable_adaptive_jitter_compensation(session,val)
	RtpSession*	session
	int			val

int
rtp_session_adaptive_jitter_compensation_enabled(session)
	RtpSession*	session
  CODE:
	RETVAL = rtp_session_adaptive_jitter_compensation_enabled( session );
  OUTPUT:
	RETVAL


void
rtp_session_set_ssrc(session,ssrc)
	RtpSession*	session
	int			ssrc
	
int
rtp_session_get_send_ssrc(session)
	RtpSession*	session
  CODE:
	RETVAL = session->send_ssrc;
  OUTPUT:
	RETVAL

void
rtp_session_set_seq_number(session,seq)
	RtpSession*	session
	int			seq

int
rtp_session_get_send_seq_number(session)
	RtpSession*	session
  CODE:
	RETVAL = session->rtp.snd_seq;
  OUTPUT:
	RETVAL

int
rtp_session_set_send_payload_type(session,pt)
	RtpSession*	session
	int			pt

int
rtp_session_get_send_payload_type(session)
	RtpSession*	session

int
rtp_session_get_recv_payload_type(session)
	RtpSession*	session
	
int
rtp_session_set_recv_payload_type(session,pt)
	RtpSession*	session
	int			pt

int
rtp_session_send_with_ts(session,sv,userts)
	RtpSession*	session
	SV*			sv
	int			userts
  PREINIT:
	STRLEN len = 0;
	const char * ptr = NULL;
  CODE:
  	ptr = SvPV( sv, len );
  	RETVAL = rtp_session_send_with_ts( session, ptr, len, userts );
  OUTPUT:
	RETVAL


SV*
rtp_session_recv_with_ts(session,wanted,userts)
	RtpSession*	session
	int			wanted
	int			userts
  PREINIT:
  	char* buffer = malloc( wanted );
  	char* ptr = buffer;
  	int buf_len = wanted;
  	int buf_used=0, bytes=0;
  	int have_more=1;
  CODE:
	while (have_more) {
		bytes = rtp_session_recv_with_ts(session,ptr,buf_len-buf_used,userts,&have_more);
		if (bytes<=0) break;
		buf_used += bytes;
		
		// Allocate some more memory
		if (have_more) {
			buffer = realloc( buffer, buf_len + wanted );
			buf_len += wanted;
			ptr = buffer + buf_used;
		}
	}
	
	if (bytes<=0) {
 		RETVAL = &PL_sv_undef;
  	} else {
		RETVAL = newSVpvn( buffer, buf_used );
  	}
  	
  	free( buffer );
  OUTPUT:
	RETVAL


void
rtp_session_flush_sockets(session)
	RtpSession*	session
	
void
rtp_session_release_sockets(session)
	RtpSession*	session
	
void
rtp_session_reset(session)
	RtpSession*	session

	
void
rtp_session_destroy(session)
	RtpSession*	session



mblk_t*
rtp_session_recvm_with_ts(session,user_ts)
	RtpSession*	session
	int			user_ts


void
rtp_set_markbit(mp,value)
	mblk_t* mp
	int     value
  CODE:
    rtp_set_markbit( mp, value );


void
rtp_set_seqnumber(mp,value)
	mblk_t* mp
	int     value
  CODE:
    rtp_set_seqnumber( mp, value );


void
rtp_set_timestamp(mp,value)
	mblk_t* mp
	int     value
  CODE:
    rtp_set_timestamp( mp, value );


void
rtp_set_ssrc(mp,value)
	mblk_t* mp
	int     value
  CODE:
    rtp_set_ssrc( mp, value );


void
rtp_set_payload_type(mp,value)
	mblk_t* mp
	int     value
  CODE:
    rtp_set_payload_type( mp, value );



int
rtp_get_markbit(mp)
	mblk_t* mp
  CODE:
	RETVAL = rtp_get_markbit(mp);
  OUTPUT:
	RETVAL

int
rtp_get_seqnumber(mp)
	mblk_t* mp
  CODE:
	RETVAL = rtp_get_seqnumber(mp);
  OUTPUT:
	RETVAL


int
rtp_get_timestamp(mp)
	mblk_t* mp
  CODE:
	RETVAL = rtp_get_timestamp(mp);
  OUTPUT:
	RETVAL

int
rtp_get_ssrc(mp)
	mblk_t* mp
  CODE:
	RETVAL = rtp_get_ssrc(mp);
  OUTPUT:
	RETVAL

int
rtp_get_payload_type(mp)
	mblk_t* mp
  CODE:
	RETVAL = rtp_get_payload_type(mp);
  OUTPUT:
	RETVAL

