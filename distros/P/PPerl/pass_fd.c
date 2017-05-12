/* code lifted from Stevens' APUE */

#include	<errno.h>		/* for definition of errno */
#include	<stdarg.h>		/* ANSI C header file */
#include	<sys/types.h>
#include	<sys/socket.h>
#include	<sys/uio.h>
#include	<string.h>
#include        <unistd.h>
#include	"pass_fd.h"

#if VARIANT_SVR4

int
s_pipe(int fd[2])
{
    return( pipe(fd) );
}

#elif defined(VARIANT_43BSD) || defined(VARIANT_44BSD)

int
s_pipe(int fd[2])
{
    return( socketpair(AF_UNIX, SOCK_STREAM, 0, fd) );
}

#else

#error "Couldn't guess variant"

#endif


#if VARIANT_43BSD

int
send_fd(int clifd, int fd)
{
    struct iovec  iov[1];
    struct msghdr msg;
    char   buf[2];

    iov[0].iov_base = buf;
    iov[0].iov_len  = 2;
    msg.msg_iov     = iov;
    msg.msg_iovlen  = 1;
    msg.msg_name    = NULL;
    msg.msg_namelen = 0;

    if (fd < 0) {
	msg.msg_accrights    = NULL;
	msg.msg_accrightslen = 0;
	buf[1] = -fd;
	if (buf[1] == 0)
	    buf[1] = 1;
    } 
    else {
	msg.msg_accrights    = (caddr_t) &fd;
	msg.msg_accrightslen = sizeof(int);
	buf[1] = 0;
    }
    buf[0] = 0;

    if (sendmsg(clifd, &msg, 0) != 2)
	return(-1);
    
    return(0);
}

int
recv_fd(int servfd)
{
    int newfd, nread, status;
    char *ptr, buf[2];
    struct iovec  iov[1];
    struct msghdr msg;

    iov[0].iov_base = buf;
    iov[0].iov_len  = 2;
    msg.msg_iov     = iov;
    msg.msg_iovlen  = 1;
    msg.msg_name    = NULL;
    msg.msg_namelen = 0;
    msg.msg_accrights = (caddr_t) &newfd;
    msg.msg_accrightslen = sizeof(int);
    
    if ( (nread = recvmsg(servfd, &msg, 0)) <= 0)
	return(-1);
    
    return(newfd);/* descriptor, or -status */
}

#else 

struct cmessage {
    struct cmsghdr cmsg;
    int fd;
};

int
send_fd(int over, int this)
{
    struct iovec iov[1];
    struct msghdr msg;
    struct cmessage cm;
    char sendbuf[] = "";

    iov[0].iov_base = (char *)&sendbuf;
    iov[0].iov_len = sizeof(sendbuf);
    
    cm.cmsg.cmsg_type  = SCM_RIGHTS;
    cm.cmsg.cmsg_level = SOL_SOCKET;
    cm.cmsg.cmsg_len = sizeof(struct cmessage);
    cm.fd = this;

    msg.msg_iov = iov;
    msg.msg_iovlen = 1;
    msg.msg_name = NULL;
    msg.msg_namelen = 0;
    msg.msg_control = (caddr_t)&cm;
    msg.msg_controllen = sizeof(struct cmessage);
    msg.msg_flags = 0;

    if (sendmsg(over, &msg, 0) < 0)
	return -1;
    return 0;
}

int 
recv_fd(int over)
{
    struct iovec iov[1];
    struct msghdr msg;
    struct cmessage cm;
    ssize_t got;
    char recbuf;

    /* in examples this was >1 but this causes too much to be read,
     * causing sync issues */

    iov[0].iov_base = &recbuf;
    iov[0].iov_len = 1;

    bzero((char *)&cm, sizeof(cm));
    bzero((char *)&msg, sizeof(msg));

    msg.msg_iov = iov;
    msg.msg_iovlen = 1;
    msg.msg_name = NULL;
    msg.msg_namelen = 0;
    msg.msg_control = (caddr_t)&cm;
    msg.msg_controllen = sizeof(struct cmessage);
    msg.msg_flags = 0;

    if ((got = recvmsg(over, &msg, 0)) < 0)
	return -1;

    if (cm.cmsg.cmsg_type != SCM_RIGHTS)
	return -1;

    return cm.fd;
}

#endif
