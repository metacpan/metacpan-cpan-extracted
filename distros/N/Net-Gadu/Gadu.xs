/*
 * Net::Gadu 
 * 
 * Copyright (C) 2002-2006 Marcin Krzy¿anowski
 * http://hakore.com/
 * 
 * This program is free software; you can redistribute it and/or modify 
 * it under the terms of the GNU Lesser General Public License as published by 
 * the Free Software Foundation; either version 2 of the License, or 
 * (at your option) any later version. 
 * 
 * This program is distributed in the hope that it will be useful, 
 * but WITHOUT ANY WARRANTY; without even the implied warranty of 
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
 * GNU General Public License for more details. 
 * 
 * You should have received a copy of the GNU Lesser General Public License 
 * along with this program; if not, write to the Free Software 
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA 
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <libgadu.h>
#include <sys/types.h>
#include <arpa/inet.h>


typedef struct gg_session *Sgg_session;
typedef struct gg_http	*Sgg_http;

MODULE = Net::Gadu		PACKAGE = Net::Gadu

int
gg_ping(sess)
    Sgg_session	sess


int
gg_check_event(sess)
	Sgg_session	sess;
    PREINIT:
	int	ret = 0;
	fd_set rd, wr;
	struct timeval	tv;
    CODE:
	if (sess)
	{
	    
	     FD_ZERO(&rd);
	     FD_ZERO(&wr);
	     
	     if ((sess->state != GG_STATE_ERROR) && (sess->state != GG_STATE_DONE) && (sess->state != GG_STATE_IDLE))
	     {
    		    if ((sess->check & GG_CHECK_READ))
			FD_SET(sess->fd, &rd);

		    if ((sess->check & GG_CHECK_WRITE))
			FD_SET(sess->fd, &wr);
	     }

	     if (sess->state == GG_STATE_IDLE)
	     {
		    ret = 0;
	     }

	    tv.tv_sec = 1;
	    tv.tv_usec = 0;
		
	    if (select(sess->fd + 1, &rd, &wr, NULL, &tv) != -1) 
	    {
		if (sess->state != GG_STATE_IDLE && (FD_ISSET(sess->fd, &rd) || FD_ISSET(sess->fd, &wr)))
    		{
	    	    ret = 1;
		}
	    }
	     
	     
	}

	RETVAL = ret;
    OUTPUT:
	RETVAL


SV *
gg_get_event(sess)
	Sgg_session	sess;
    PROTOTYPE: $
    PREINIT:
	int i;
	gg_pubdir50_t r;
	struct gg_event *event;
	HV	* results;
    INIT:
	results = (HV *)sv_2mortal((SV *)newHV());
    CODE:

	if ((sess) && 
	    (sess->status != GG_STATUS_NOT_AVAIL) &&
	    (sess->status != GG_STATUS_NOT_AVAIL_DESCR)) 
	    {
	    
	    event = gg_watch_fd(sess);
	    if (!event)
	    {
	    	hv_store(results,"type",4,newSVnv(GG_EVENT_DISCONNECT),0);
	    }
	    else 
	    {

    	    hv_store(results,"type",4,newSVnv(event->type),0);
	    switch (event->type) {
		case GG_EVENT_MSG:
		    hv_store(results,"msgclass",8,newSVnv(event->event.msg.msgclass),0);
		    hv_store(results,"sender",6,newSVnv(event->event.msg.sender),0);
		    hv_store(results,"message",7,newSVpv(event->event.msg.message,0),0);
		    break;
		case GG_EVENT_ACK:
		    hv_store(results,"recipient",strlen("recipient"),newSVnv(event->event.ack.recipient),0);
		    hv_store(results,"status",strlen("status"),newSVnv(event->event.ack.status),0);
		    hv_store(results,"seq",strlen("seq"),newSVnv(event->event.ack.seq),0);
		    break;
		case GG_EVENT_STATUS:
		    hv_store(results,"uin",strlen("uin"),newSVnv(event->event.status.uin),0);
		    hv_store(results,"status",strlen("status"),newSVnv(event->event.status.status),0);
		    hv_store(results,"descr",strlen("descr"),newSVpv(event->event.status.descr ? event->event.status.descr : "",0),0);
		    break;
		case GG_EVENT_STATUS60:
		    hv_store(results,"uin",strlen("uin"),newSVnv(event->event.status60.uin),0);
		    hv_store(results,"status",strlen("status"),newSVnv(event->event.status60.status),0);
		    hv_store(results,"descr",strlen("descr"),newSVpv(event->event.status60.descr ? event->event.status60.descr : "",0),0);
		    break;
		case GG_EVENT_NOTIFY:
		    hv_store(results,"uin",strlen("uin"),newSVnv(event->event.notify->uin),0);
		    hv_store(results,"status",strlen("status"),newSVnv(event->event.notify->status),0);
		    break;
		case GG_EVENT_NOTIFY_DESCR:
		    hv_store(results,"uin",strlen("uin"),newSVnv(event->event.notify->uin),0);
		    hv_store(results,"status",strlen("status"),newSVnv(event->event.notify->status),0);
		    hv_store(results,"descr",strlen("descr"),newSVpv(event->event.notify_descr.descr ? event->event.notify_descr.descr : "",0),0);
		    break;
		case GG_EVENT_NOTIFY60:
		    for (i = 0; event->event.notify60[i].uin; i++)
		    {
			hv_store(results,"uin",3,newSVnv(event->event.notify60[i].uin),0);
			hv_store(results,"status",6,newSVnv(event->event.notify60[i].status),0);
			hv_store(results,"descr",5,newSVpv(event->event.notify60[i].descr ? event->event.notify60[0].descr : "",0),0);
		    }
		    break;
		case GG_EVENT_PUBDIR50_SEARCH_REPLY:
		    {
			HV *foundlist;
			HV *details;
			unsigned int i,count;
			r = event->event.pubdir50;
			count = gg_pubdir50_count(r);
			
			foundlist = (HV *)sv_2mortal((SV *)newHV());
			for  (i=0;i<count;i++)
			{
			    const char *uin = gg_pubdir50_get(r,i,GG_PUBDIR50_UIN);
			    const char *first_name = gg_pubdir50_get(r,i,GG_PUBDIR50_FIRSTNAME);
			    const char *last_name = gg_pubdir50_get(r,i,GG_PUBDIR50_LASTNAME);
			    const char *nickname = gg_pubdir50_get(r,i,GG_PUBDIR50_NICKNAME);
			    const char *born = gg_pubdir50_get(r,i,GG_PUBDIR50_BIRTHYEAR);
			    const char *gender = gg_pubdir50_get(r,i,GG_PUBDIR50_GENDER);
			    const char *city = gg_pubdir50_get(r,i,GG_PUBDIR50_CITY);
			    const char *status = gg_pubdir50_get(r,i,GG_PUBDIR50_STATUS);

			    details = (HV *)sv_2mortal((SV *)newHV());
			    
			    hv_store(details,"uin",3,newSVpv(uin,0),0);
			    hv_store(details,"first_name",10,newSVpv(first_name ? first_name : "",0),0);
			    hv_store(details,"last_name",9,newSVpv(last_name ? last_name : "",0),0);
			    hv_store(details,"nickname",8,newSVpv(nickname ? nickname : "",0),0);
			    hv_store(details,"born",4,newSVpv(born ? born : "",0),0);
			    hv_store(details,"gender",6,newSVpv(gender ? gender : "",0),0);
			    hv_store(details,"status",6,newSVpv(status ? status : "",0),0);

			    hv_store(foundlist,uin,strlen(uin),newRV((SV *)details),0);
			}
			
			hv_store(results,"results",7,newRV((SV *)foundlist),0);
		    }
		    break;
	    }
	    }
	    gg_free_event(event);
	    }
	    RETVAL = newRV((SV *)results);
    OUTPUT:
	RETVAL
    

SV *
gg_search(sess,uin,nickname,first_name,last_name,city,gender,active)
    Sgg_session	sess;
    char 	*uin;
    char	*nickname
    char	*first_name
    char	*last_name
    char	*city
    char	*gender
    int		active
    PROTOTYPE: $$$$$$$$$
    INIT:
	AV	* results;
	gg_pubdir50_t r;
    CODE:
	r = gg_pubdir50_new(GG_PUBDIR50_SEARCH_REQUEST);

	if (uin && strlen(uin) > 0)
	    gg_pubdir50_add(r,GG_PUBDIR50_UIN,uin);

	if (nickname && strlen(nickname) > 0)
	    gg_pubdir50_add(r,GG_PUBDIR50_NICKNAME,nickname);

	if (first_name && strlen(first_name) > 0)
	    gg_pubdir50_add(r,GG_PUBDIR50_FIRSTNAME,first_name);

	if (last_name && strlen(last_name) > 0)
	    gg_pubdir50_add(r,GG_PUBDIR50_LASTNAME,last_name);

	if (city && strlen(city) > 0)
	    gg_pubdir50_add(r,GG_PUBDIR50_CITY,city);

	if (active)
	    gg_pubdir50_add(r,GG_PUBDIR50_ACTIVE,GG_PUBDIR50_ACTIVE_TRUE);

	if (gender && strlen(gender) > 0)
	    gg_pubdir50_add(r,GG_PUBDIR50_GENDER,gender);

	
	gg_pubdir50(sess,r);
	gg_pubdir50_free(r);

int
gg_send_message(sess,msgclass,recipient,message)
    Sgg_session	sess
    int	msgclass
    uin_t recipient
    const unsigned char	* message
    PROTOTYPE: $$$$




Sgg_session 
gg_login(uin,password,async,server_addr,initial_status)
    uin_t	uin
    char 	*password
    int 	async
    char	*server_addr
    int		initial_status
    PROTOTYPE: $$$$$
    INIT:
	struct gg_login_params p;
    CODE:
	/* gg_debug_level = 255; */
	
	memset(&p, 0, sizeof(p));
	p.uin = uin;
	p.password = password;
	p.async = async;
	p.status = initial_status;
	p.has_audio = 0;
	p.image_size = 255;
	
	if (!strcmp(server_addr,"0.0.0.0"))
	{
	    p.server_addr = inet_addr(server_addr);
	}
	
	RETVAL = gg_login(&p);
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Sgg_session", (void*)RETVAL);



int
gg_change_status(sess,status)
    Sgg_session	sess
    int status



int
gg_change_status_descr(sess,status,descr)
    Sgg_session sess
    int status
    const unsigned char * descr


int gg_notify(sess)
    Sgg_session sess
    PROTOTYPE: $
    INIT:
	int ret;
    CODE:
        ret = gg_notify(sess, NULL, 0);
	RETVAL = ret;
    

int
gg_add_notify(sess, uin)
    Sgg_session sess
    uin_t	uin
    PROTOTYPE: $$



int
gg_remove_notify(sess, uin)
    Sgg_session sess
    uin_t	uin
    PROTOTYPE: $$
    

void
gg_logoff(sess)
    Sgg_session	sess
    


void
gg_free_session(sess)
    Sgg_session sess
