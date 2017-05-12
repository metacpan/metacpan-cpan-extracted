#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <utmp.h>

#ifdef _AIX
#define _HAVE_UT_HOST	1
#endif

#ifdef NOUTFUNCS
#include <stdlib.h>
#include <unistd.h>
#include <time.h>
#include <string.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>


#ifdef BSD
#define _NO_UT_ID
#define _NO_UT_TYPE
#define _NO_UT_PID
#define _HAVE_UT_HOST
#define ut_user ut_name
#endif

/*
   define these so it still works as documented :)
*/

#ifndef USER_PROCESS
#define EMPTY           0       /* No valid user accounting information.  */

#define RUN_LVL         1       /* The system's runlevel.  */
#define BOOT_TIME       2       /* Time of system boot.  */
#define NEW_TIME        3       /* Time after system clock changed.  */
#define OLD_TIME        4       /* Time when system clock changed.  */

#define INIT_PROCESS    5       /* Process spawned by the init process.  */
#define LOGIN_PROCESS   6       /* Session leader of a logged in user.  */
#define USER_PROCESS    7       /* Normal process.  */
#define DEAD_PROCESS    8       /* Terminated process.  */

#define ACCOUNTING      9
#endif

/*
    It is almost certain that if these are not defined the fields they are
    for are not present or this is BSD :)
*/


static int ut_fd = -1;

static char _ut_name[] = _PATH_UTMP;

void utmpname(char *filename)
{
   strcpy(_ut_name, filename);
}

void setutent(void)
{
    if (ut_fd < 0)
    {
       if ((ut_fd = open(_ut_name, O_RDONLY)) < 0) 
       {
            croak("Can't open %s",_ut_name);
        }
    }

    lseek(ut_fd, (off_t) 0, SEEK_SET);
}

void endutent(void)
{
    if (ut_fd > 0)
    {
        close(ut_fd);
    }

    ut_fd = -1;
}

struct utmp *getutent(void) 
{
    static struct utmp s_utmp;
    int readval;

    if (ut_fd < 0)
    {
        setutent();
    }

    if ((readval = read(ut_fd, &s_utmp, sizeof(s_utmp))) < sizeof(s_utmp))
    {
        if (readval == 0)
        {
            return NULL;
        }
        else if (readval < 0) 
        {
            croak("Error reading %s", _ut_name);
        } 
        else 
        {
            croak("Partial record in %s [%d bytes]", _ut_name, readval );
        }
    }
    return &s_utmp;
}

#endif


static double
constant(char *name, int len, int arg)
{
   errno = 0;
	if (strEQ(name, "ACCOUNTING")) 
   {
	    return ACCOUNTING;
	}
   else if (strEQ(name, "BOOT_TIME")) 
   {
	    return BOOT_TIME;
	}
   else if (strEQ(name, "DEAD_PROCESS")) 
   {
	    return DEAD_PROCESS;
	}
   else if (strEQ(name, "EMPTY")) 
   {
	    return EMPTY;
	}
   else if (strEQ(name, "INIT_PROCESS")) 
   {
	    return INIT_PROCESS;
	}
   else if (strEQ(name, "LOGIN_PROCESS")) 
   {
	    return LOGIN_PROCESS;
	}
   else if (strEQ(name, "NEW_TIME")) 
   {	
	    return NEW_TIME;
	}
   else if (strEQ(name, "OLD_TIME")) 
   {
	    return OLD_TIME;
	}
   else if (strEQ(name, "RUN_LVL")) 
   {	
	    return RUN_LVL;
	}
	if (strEQ(name, "USER_PROCESS")) 
   {
	    return USER_PROCESS;
	}
   else
   {
    errno = EINVAL;
    return 0;
   }

}


MODULE = Sys::Utmp		PACKAGE = Sys::Utmp		

PROTOTYPES: DISABLE


double
constant(sv,arg)
    PREINIT:
	STRLEN		len;
    INPUT:
	SV *		sv
	char *		s = SvPV(sv, len);
	int		arg
    CODE:
	RETVAL = constant(s,len,arg);
    OUTPUT:
	RETVAL



void
getutent(self)
SV *self
   PPCODE:
     static AV *ut;
     static HV *meth_stash;
     static IV ut_tv;
     static IV _ut_pid;
     static IV _ut_type; 
     static SV *ut_ref;
     static char *_ut_id;
     static struct utmp *utent;
     static char ut_host[sizeof(utent->ut_host)];


     SV *sv_ut_user;
     SV *sv_ut_id;
     SV *sv_ut_line;
     SV *sv_ut_pid;
     SV *sv_ut_type;
     SV *sv_ut_host;
     SV *sv_ut_tv;

     if(!SvROK(self)) 
        croak("Must be called as an object method");


     utent = getutent();

     if ( utent )
     {
#ifdef _NO_UT_ID
       _ut_id = "";
#else
       _ut_id = utent->ut_id;
#endif
#ifdef _NO_UT_TYPE
       _ut_type = 7;
#else
       _ut_type = utent->ut_type;
#endif
#ifdef _NO_UT_PID
       _ut_pid = -1; 
#else
       _ut_pid = utent->ut_pid;
#endif
#ifdef _HAVE_UT_TV
       ut_tv = (IV)utent->ut_tv.tv_sec;
#else
       ut_tv = (IV)utent->ut_time;
#endif
#ifdef _HAVE_UT_HOST
       strncpy(ut_host, utent->ut_host,sizeof(utent->ut_host));
#else
       strncpy(ut_host, "",1);
#endif


       sv_ut_user = newSVpv(utent->ut_user,0);
       sv_ut_id   = newSVpv(_ut_id,0);
       sv_ut_line = newSVpv(utent->ut_line,0);
       sv_ut_pid  = newSViv(_ut_pid);
       sv_ut_type = newSViv(_ut_type);
       sv_ut_host = newSVpv(ut_host,0);
       sv_ut_tv   = newSViv(ut_tv);


       SvTAINTED_on(sv_ut_user);
       SvTAINTED_on(sv_ut_host); 

       if ( GIMME_V == G_ARRAY )
       {
         sv_ut_user = sv_2mortal(sv_ut_user);
         sv_ut_id   = sv_2mortal(sv_ut_id);
         sv_ut_line = sv_2mortal(sv_ut_line);
         sv_ut_pid  = sv_2mortal(sv_ut_pid);
         sv_ut_type = sv_2mortal(sv_ut_type);
         sv_ut_host = sv_2mortal(sv_ut_host);
         sv_ut_tv   = sv_2mortal(sv_ut_tv);

         XPUSHs(sv_ut_user);
         XPUSHs(sv_ut_id);
         XPUSHs(sv_ut_line);
         XPUSHs(sv_ut_pid);
         XPUSHs(sv_ut_type);
         XPUSHs(sv_ut_host);
         XPUSHs(sv_ut_tv);

       }
       else if ( GIMME_V == G_SCALAR )
       {
         ut = newAV();
         av_push(ut,sv_ut_user);
         av_push(ut,sv_ut_id);
         av_push(ut,sv_ut_line);
         av_push(ut,sv_ut_pid);
         av_push(ut,sv_ut_type);
         av_push(ut,sv_ut_host);
         av_push(ut,sv_ut_tv);

         meth_stash = gv_stashpv("Sys::Utmp::Utent",1);
         ut_ref = newRV_noinc((SV *)ut);
         sv_bless(ut_ref, meth_stash);
         XPUSHs(sv_2mortal(ut_ref));
       }
       else
       {
          XSRETURN_EMPTY;
       }
     }
     else
     {
        XSRETURN_EMPTY;
     }



void
setutent(self)
SV *self
   PPCODE:

    if(!SvROK(self)) 
        croak("Must be called as an object method");

    setutent();

void
endutent(self)
SV *self
   PPCODE:

    if(!SvROK(self)) 
        croak("Must be called as an object method");
    endutent();

void
utmpname(self, filename)
SV *self
SV *filename
   PPCODE:
     char *ff;

    if(!SvROK(self)) 
        croak("Must be called as an object method");

     ff = SvPV(filename,PL_na);
     utmpname(ff);

void
DESTROY(self)
SV *self
   PPCODE:

    if(!SvROK(self)) 
        croak("Must be called as an object method");

     endutent();
