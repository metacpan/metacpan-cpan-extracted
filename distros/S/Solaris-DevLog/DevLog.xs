/*
 * $Id: DevLog.xs,v 1.1 2002/02/11 21:51:47 bossert Exp $
 * Project:  Solaris::DevLog
 * File:     DevLog.pm
 * Author:   Greg Bossert <bossert@fuaim.com>, <greg@netzwert.ag>
 *
 * Copyright (c) 2002 Greg Bossert
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the same terms as Perl itself.
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/types.h>
#include <sys/stat.h>
#include <stropts.h>
#include <sys/strlog.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>

#include <sys/log.h>

#include <door.h>

/* With typemap, maps HvObject to a blessed HV */
typedef HV HvObject; 

void afstreams_door_server_proc(void *cookie, char *argp, size_t arg_size, door_desc_t *dp, size_t n_desc)
{
  door_return(NULL, 0, NULL, 0);
  return;
}

/* ######## start of XSUB code ######## */

MODULE = Solaris::DevLog		PACKAGE = Solaris::DevLog	

int
cleanup(self, stream_fd, door_fd)
        HV * self
        int stream_fd
        int door_fd
   CODE:
        if (stream_fd > 0) {
	  close(stream_fd);
	}
        if (door_fd > 0) {
	  door_revoke(door_fd);
	  close(door_fd);
	}

int
open_stream(self, path)
        HV * self
        char *path
    PREINIT:
	int stream_fd;
    CODE:
	stream_fd = open(path, O_RDONLY | O_NOCTTY | O_NONBLOCK);
	if (stream_fd == -1) {
	  croak("cannot open sun-stream %s (%s)\n", path, strerror(errno));
	}
	RETVAL = stream_fd;
    OUTPUT:
        RETVAL

int 
init_stream(self, stream_fd)
        HV * self
        int stream_fd
    PREINIT:
        struct strioctl ioc;
    CODE:
	memset(&ioc, 0, sizeof(ioc));
	ioc.ic_cmd = I_CONSLOG;
	if (ioctl(stream_fd, I_STR, &ioc) < 0) { 
	  close(stream_fd);
	  croak("cannot enable console logging on sun-stream (%s)\n", strerror(errno));
        }

int 
open_door(self, door_name)
        HV * self
        char *door_name
    PREINIT:
	int fd, door_fd;
	struct stat st;
    CODE:
	if (stat(door_name, &st) == -1) {
	  fd = creat(door_name, 0666);
	  if (fd == -1) {
	    croak("cannot create door file %s (%s)\n", door_name, strerror(errno));
	  }
	  close(fd);
	}
	fdetach(door_name);

	door_fd = door_create(afstreams_door_server_proc, NULL, 0);
	RETVAL = door_fd;

	if (door_fd == -1) {
	  croak("cannot initialize door server %s (%s)\n", door_name, strerror(errno));
	}

	if (fattach(door_fd, door_name) == -1) {
	  close(door_fd);
	  croak("cannot attach door to %s (%s)\n", door_name, strerror(errno));
	}
    OUTPUT:
        RETVAL

void
_getmsg(self,stream_fd,ctlhash)
        HV * self
        int stream_fd
        HV * ctlhash
    PREINIT:
        int flags;
        int res;
        struct log_ctl lc;
	char *ctlbuf;
	char *databuf;
	struct strbuf ctl, data;
        SV * sv_mid, * sv_sid, * sv_level, * sv_flags,
	  * sv_ltime, * sv_ttime, * sv_seq_no, * sv_pri;
    PPCODE:
	flags = 0;

	/* set up the control buffer */
	ctl.maxlen = ctl.len = sizeof(lc);
	ctl.buf = (char *) &lc;

	/* set up the data buffer */
	databuf = (char *)malloc(LOG_MAXPS);
	data.maxlen = LOG_MAXPS;
	data.len = 0;
	data.buf = databuf;

	res = getmsg(stream_fd, &ctl, &data, &flags);

	if ((res & MORECTL) == 0) {
	  if (res & MOREDATA) {
	    croak("getmsg: STREAMS device gave too long line\n");
	  }
	}
	else {
	  croak("getmsg: trying to return too much ctl data, res=%i %s\n", res, strerror(errno));
	}

        /* unpack the ctlbuf */
        sv_mid = newSViv(lc.mid);
        hv_store(ctlhash, "mid", 3, sv_mid, 0);
        sv_sid = newSViv(lc.sid);
        hv_store(ctlhash, "sid", 3, sv_sid, 0);
        sv_level = newSViv(lc.level);
        hv_store(ctlhash, "level", 5, sv_level, 0);
        sv_flags = newSViv(lc.flags);
        hv_store(ctlhash, "flags", 5, sv_flags, 0);
        sv_ltime = newSViv(lc.ltime);
        hv_store(ctlhash, "ltime", 5, sv_ltime, 0);
        sv_ttime = newSViv(lc.ttime);
        hv_store(ctlhash, "ttime", 5, sv_ttime, 0);
        sv_seq_no = newSViv(lc.seq_no);
        hv_store(ctlhash, "seq_no", 6, sv_seq_no, 0);
        sv_pri = newSViv(lc.pri);
        hv_store(ctlhash, "pri", 3, sv_pri, 0);

	XPUSHs(sv_2mortal(newSViv(res)));
	XPUSHs(sv_2mortal(newSVpvn(data.buf,data.len)));

	free (databuf);
