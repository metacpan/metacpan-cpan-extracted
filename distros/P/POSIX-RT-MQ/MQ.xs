#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <mqueue.h>
#include <signal.h>
#include <unistd.h>

static char cvs_id[] = "$Id: MQ.xs,v 1.8 2003/01/27 10:43:11 ilja Exp $";

static int not_here(char *s)
{
    croak("POSIX::RT::MQ::%s not implemented on this architecture", s);
    return -1;
}

MODULE = POSIX::RT::MQ		PACKAGE = POSIX::RT::MQ
PROTOTYPES: ENABLE

int 
MQ_OPEN_MAX()
    PREINIT:
        int val=-1;
    CODE:
	errno = 0;
#ifdef  _SC_MQ_OPEN_MAX
        val = sysconf(_SC_MQ_OPEN_MAX);
#endif
	/* if errno is still 0 the limit is indeterminate */
        if (errno && val==-1) not_here("MQ_OPEN_MAX"); 
        RETVAL=val;
    OUTPUT:
        RETVAL

int 
MQ_PRIO_MAX()
    PREINIT:
        int val=-1;
    CODE:
	errno = 0;
#ifdef _SC_MQ_PRIO_MAX
        val = sysconf(_SC_MQ_PRIO_MAX);
#endif
	/* if errno is still 0 the limit is indeterminate */
        if (errno && val==-1) not_here("MQ_PRIO_MAX");
        RETVAL=val;
    OUTPUT:
        RETVAL



mqd_t 
mq_open(name,oflag,mode,attr=NULL)
        char*  name 
        int    oflag
        Mode_t mode
        SV*    attr
    PREINIT:
        mqd_t           mqdes;
        struct mq_attr* mqa_ptr = NULL;
        STRLEN          mqa_len;
    CODE:
        if (attr != NULL)
            mqa_ptr = (struct mq_attr*) SvPV(attr, mqa_len);
         /* check mqa_len ? */
        mqdes = mq_open(name, oflag, mode, mqa_ptr);
        if (mqdes == (mqd_t)-1) { XSRETURN_UNDEF; }
        RETVAL = mqdes;
    OUTPUT:
        RETVAL    

int
mq_close(mqdes)
        mqd_t mqdes
    CODE:
        if (mq_close(mqdes) == -1) { XSRETURN_UNDEF; }
        RETVAL = 1;
    OUTPUT:
        RETVAL    

int
mq_unlink(name)
        char* name 
    CODE:
        if (mq_unlink(name) == -1) { XSRETURN_UNDEF; }
        RETVAL = 1;
    OUTPUT:
        RETVAL    

SV*
mq_attr(mqdes, new_attr=NULL)
        mqd_t  mqdes
        SV*    new_attr;
    PREINIT:
        struct mq_attr  old_mqa;
        struct mq_attr* new_mqa_ptr;
        STRLEN          new_mqa_len;
    CODE:
        if (new_attr == NULL)
        {
            if (mq_getattr(mqdes, &old_mqa) == -1) { XSRETURN_UNDEF; }
        }
        else
        {
            new_mqa_ptr = (struct mq_attr*) SvPV(new_attr, new_mqa_len);
            /* check new_mqa_len ? */
            if (mq_setattr(mqdes, new_mqa_ptr, &old_mqa) == -1) { XSRETURN_UNDEF; }
        }
        RETVAL = newSVpvn((char*)&old_mqa, sizeof(old_mqa));
    OUTPUT:
        RETVAL
        
int 
mq_send(mqdes, msg, msg_prio)
        mqd_t  mqdes
        SV*    msg
        unsigned int msg_prio
    PREINIT:
        char*  msg_ptr;
        STRLEN msg_len;
    CODE:
        msg_ptr = SvPV(msg, msg_len);
        if (mq_send(mqdes, msg_ptr, msg_len, msg_prio) == -1) { XSRETURN_UNDEF; }
        RETVAL = 1;
    OUTPUT:
        RETVAL

void 
mq_receive(mqdes, msg_max_len)
        mqd_t        mqdes
        size_t       msg_max_len
    PREINIT:
        char*        msg_ptr;
        ssize_t      msg_len;
        unsigned int msg_prio;
    PPCODE:
        if ((msg_ptr = malloc(msg_max_len)) == NULL) { XSRETURN_EMPTY; }        
        msg_len = mq_receive(mqdes, msg_ptr, msg_max_len, &msg_prio);
        if (msg_len == -1)
        { 
            free(msg_ptr);
            XSRETURN_EMPTY;
        }
        XPUSHs(sv_2mortal(newSVpvn(msg_ptr, msg_len)));
        XPUSHs(sv_2mortal(newSVuv(msg_prio)));
        free(msg_ptr);

int 
mq_notify(mqdes, ...)
        mqd_t  mqdes
    PREINIT:
        struct sigevent  sigev;
        struct sigevent* sigevp = NULL;
    CODE:
        if (items > 1)
        {
            sigev.sigev_notify = SIGEV_SIGNAL;
            sigev.sigev_signo  = SvIV(ST(1));
            sigev.sigev_value.sival_int = 0;
            sigevp = &sigev;
        }
        if (mq_notify(mqdes, sigevp) == -1) { XSRETURN_UNDEF; }
        RETVAL = 1;
    OUTPUT:
        RETVAL


SV*
mq_attr_pack(mq_flags, mq_maxmsg, mq_msgsize, mq_curmsgs)
        long mq_flags
        long mq_maxmsg
        long mq_msgsize
        long mq_curmsgs 
    PREINIT:
        struct mq_attr mqa;
    CODE:
        mqa.mq_flags   = mq_flags;
        mqa.mq_maxmsg  = mq_maxmsg;
        mqa.mq_msgsize = mq_msgsize;
        mqa.mq_curmsgs = mq_curmsgs;
        RETVAL = newSVpvn((char*)&mqa, sizeof(mqa));
    OUTPUT:
        RETVAL

void
mq_attr_unpack(mqa)
        SV* mqa
    PREINIT:
        struct mq_attr* mqa_ptr;
        STRLEN          mqa_len;
    PPCODE:
        mqa_ptr = (struct mq_attr*) SvPV(mqa, mqa_len); 
        /* check mqa_len ? */
        XPUSHs(sv_2mortal(newSViv(mqa_ptr->mq_flags)));
        XPUSHs(sv_2mortal(newSViv(mqa_ptr->mq_maxmsg)));
        XPUSHs(sv_2mortal(newSViv(mqa_ptr->mq_msgsize)));
        XPUSHs(sv_2mortal(newSViv(mqa_ptr->mq_curmsgs)));
