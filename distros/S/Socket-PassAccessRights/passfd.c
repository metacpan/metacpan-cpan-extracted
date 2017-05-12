/* passfd.c  -  BSD style file descriptor passing over unix domain sockets
 *
 * Copyright (c) 2000 Sampo Kellomaki <sampo@iki.fi>, All Rights Reserved.
 * This module may be copied under the same terms as the perl itself.
 *
 * See also:
 * recvmsg(2)
 * sendmsg(2)
 * Richard Stevens: Unix Network Programming, Prentice Hall, 1990; chapter 6.10
 * /usr/include/socketbits.h
 * /usr/include/sys/socket.h
 */

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/uio.h>
#include <errno.h>

/* I test here for __sun for lack of anything better, but I
 * mean Solaris 2.6. The idea of undefining SCM_RIGHTS is
 * to force the headers to behave BSD 4.3 way which I have
 * tested to work.
 *
 * In general, if you have compilation errors, you might consider
 * adding a test for your platform here.
 */
#if defined(__sun)
#undef SCM_RIGHTS
#endif

#ifdef SCM_RIGHTS

/* It seems various versions of glibc headers (i.e.
 * /usr/include/socketbits.h) miss one or more of these */

#ifndef CMSG_DATA
# define CMSG_DATA(cmsg) ((cmsg)->cmsg_data)
#endif

#ifndef CMSG_NXTHDR
# define CMSG_NXTHDR(mhdr, cmsg) __cmsg_nxthdr (mhdr, cmsg)
#endif

#ifndef CMSG_FIRSTHDR
# define CMSG_FIRSTHDR(mhdr) \
  ((size_t) (mhdr)->msg_controllen >= sizeof (struct cmsghdr)	       \
   ? (struct cmsghdr *) (mhdr)->msg_control : (struct cmsghdr *) NULL)
#endif

#ifndef CMSG_ALIGN
# define CMSG_ALIGN(len) (((len) + sizeof (size_t) - 1) \
			 & ~(sizeof (size_t) - 1))
#endif

#ifndef CMSG_SPACE
# define CMSG_SPACE(len) (CMSG_ALIGN (len) \
			 + CMSG_ALIGN (sizeof (struct cmsghdr)))
#endif

#ifndef CMSG_LEN
# define CMSG_LEN(len)   (CMSG_ALIGN (sizeof (struct cmsghdr)) + (len))
#endif

union fdmsg {
	struct cmsghdr h;
	char buf[CMSG_SPACE(sizeof(int))];
};
#endif

/* Tested to work on perl 5.005_03
 *   Linux-2.2.14 glibc-2.0.7 (libc.so.6) i586  BSD4.4
 *   Linux-2.0.38 glibc-2.0.7 (libc.so.6) i586  BSD4.4
 *   SunOS-5.6, gcc-2.7.2.3, Sparc BSD4.3
 * see also: linux/net/unix/af_unix.c
 */

int
sendfd(sock_fd, send_me_fd)
	int sock_fd;
	int send_me_fd;
{
	int ret = 0;
	struct iovec  iov[1];
	struct msghdr msg;
	
	iov[0].iov_base = &ret;  /* Don't send any data. Note: der Mouse
				  * <mouse@Rodents.Montreal.QC.CA> says
				  * that might work better if at least one
				  * byte is sent. */
	iov[0].iov_len  = 1;
	
	msg.msg_iov     = iov;
	msg.msg_iovlen  = 1;
	msg.msg_name    = 0;
	msg.msg_namelen = 0;

	{
#ifdef SCM_RIGHTS
		/* New BSD 4.4 way (ouch, why does this have to be
		 * so convoluted). */

		union  fdmsg  cmsg;
		struct cmsghdr* h;

		msg.msg_control = cmsg.buf;
		msg.msg_controllen = sizeof(union fdmsg);
		msg.msg_flags = 0;
		
		h = CMSG_FIRSTHDR(&msg);
		h->cmsg_len   = CMSG_LEN(sizeof(int));
		h->cmsg_level = SOL_SOCKET;
		h->cmsg_type  = SCM_RIGHTS;
		*((int*)CMSG_DATA(h)) = send_me_fd;
#else
		/* Old BSD 4.3 way. Not tested. */
		msg.msg_accrights = &send_me_fd;
		msg.msg_accrightslen = sizeof(send_me_fd);
#endif	

		if (sendmsg(sock_fd, &msg, 0) < 0) {
			ret = 0;
		} else {
			ret = 1;
		}
	}
	/*fprintf(stderr,"send %d %d %d %d\n",sock_fd, send_me_fd, ret, errno);*/
	return ret;
}

int
recvfd(sock_fd)
	int sock_fd;
{
	int count;
	int ret = 0;
	struct iovec  iov[1];
	struct msghdr msg;
	
	iov[0].iov_base = &ret;  /* don't receive any data */
	iov[0].iov_len  = 1;
	
	msg.msg_iov = iov;
	msg.msg_iovlen = 1;
	msg.msg_name = NULL;
	msg.msg_namelen = 0;

	{
#ifdef SCM_RIGHTS
		union fdmsg  cmsg;
		struct cmsghdr* h;

		msg.msg_control = cmsg.buf;
		msg.msg_controllen = sizeof(union fdmsg);
		msg.msg_flags = 0;
		
		h = CMSG_FIRSTHDR(&msg);
		h->cmsg_len   = CMSG_LEN(sizeof(int));
		h->cmsg_level = SOL_SOCKET;  /* Linux does not set these */
		h->cmsg_type  = SCM_RIGHTS;  /* upon return */
		*((int*)CMSG_DATA(h)) = -1;
		
		if ((count = recvmsg(sock_fd, &msg, 0)) < 0) {
			ret = 0;
		} else {
			h = CMSG_FIRSTHDR(&msg);   /* can realloc? */
			if (   h == NULL
			    || h->cmsg_len    != CMSG_LEN(sizeof(int))
			    || h->cmsg_level  != SOL_SOCKET
			    || h->cmsg_type   != SCM_RIGHTS ) {
				/* This should really never happen */
				if (h)
				  fprintf(stderr,
				    "%s:%d: protocol failure: %d %d %d\n",
				    __FILE__, __LINE__,
				    h->cmsg_len,
				    h->cmsg_level, h->cmsg_type);
				else
				  fprintf(stderr,
				    "%s:%d: protocol failure: NULL cmsghdr*\n",
				    __FILE__, __LINE__);
				ret = 0;
			} else {
				ret = *((int*)CMSG_DATA(h));
				/*fprintf(stderr, "recv ok %d\n", ret);*/
			}
		}
#else
		int receive_fd;
		msg.msg_accrights = &receive_fd;
		msg.msg_accrightslen = sizeof(receive_fd);

		if (recvmsg(sock_fd, &msg, 0) < 0) {
			ret = 0;
		} else {
			ret = receive_fd;
		}
#endif
	}
	
	/*fprintf(stderr, "recv %d %d %d %d\n",sock_fd, ret, errno, count);*/
	return ret;
}

/* EOF  -  passfd.c */
