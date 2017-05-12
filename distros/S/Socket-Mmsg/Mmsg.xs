#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <netinet/ip.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
	
	void sendmultimsg(PerlIO* psock, SV *msg_array_ref) {

		int i, retval, buf_len, sockfd, msg_count;
		struct mmsghdr *msgs;
		struct iovec *iovecs;
		SV *del_link, *buf_link, *from_link;
		AV *msg, *msg_array;
		struct timespec timeout;

		sockfd = PerlIO_fileno(psock);
		msg_array = (AV*)SvRV(msg_array_ref);
		msg_count = av_len(msg_array) + 1;

	// Allocate memory
		Newxz( msgs, msg_count, struct mmsghdr);
		Newxz( iovecs, msg_count, struct iovec);

		// Fill msgs
		for (i = 0; i < msg_count; i++) {

			msg = (AV*)SvRV(*av_fetch(msg_array, i, 0));

			// sockaddr
				from_link = *av_fetch(msg, 0, 0);

				msgs[i].msg_hdr.msg_name = (struct sockaddr_in*)SvPV_nolen(from_link);
				msgs[i].msg_hdr.msg_namelen = sizeof(struct sockaddr_in);

			// buffer
				buf_link = *av_fetch(msg, 1, 0);
				buf_len = sv_len(buf_link);

				iovecs[i].iov_base         = (char*)SvPV(buf_link,buf_len);
				iovecs[i].iov_len          = buf_len;
				msgs[i].msg_hdr.msg_iov    = &iovecs[i];
				msgs[i].msg_hdr.msg_iovlen = 1;
		}

		retval = sendmmsg(sockfd, msgs, msg_count, 0);

		if (retval == -1) {
			perror("sendmultimsg()");
		}else{
			// Delete sended msg
			for (i = 0; i < retval; i++) {
				SvREFCNT_dec(av_shift(msg_array));
			}

		dXSARGS;
		sp = mark;
		XPUSHs(sv_2mortal(newSViv(retval)));
		PUTBACK;
		}
		// Free memory
		Safefree(iovecs);
		Safefree(msgs);
	}

	void recvmultimsg(PerlIO* psock, int msg_count, int msg_len, float tspec) {

	int i, retval, mem_blk_pointer, sockfd;
	struct mmsghdr * msgs;
	struct iovec * iovecs;
	struct sockaddr_in * src_addr;
	char **bufs, *mem_blk;
	struct timespec timeout;
	AV *result, *pack;
	SV *pack_ref, *result_ref;

	sockfd = PerlIO_fileno(psock);

	// Allocate memory
		Newxz( src_addr, msg_count, struct sockaddr_in);	// For sockaddr struct
		Newxz( iovecs, msg_count, struct iovec);		// For iovec sttruct
		Newxz( msgs, msg_count, struct mmsghdr);		// For mmsghdr struct

	// For data
		Newxz( bufs, msg_count, char *);
		Newxz( mem_blk, ( msg_count*msg_len ), char );
		mem_blk_pointer = 0;
		for (i = 0; i < msg_count; i++) {
			bufs[i] = &mem_blk[mem_blk_pointer];
			mem_blk_pointer += msg_len;
		}

	// Filling struct mmsghdr
		for (i = 0; i < msg_count; i++) {
			iovecs[i].iov_base         = bufs[i];
			iovecs[i].iov_len          = msg_len;

			msgs[i].msg_hdr.msg_iov    = &iovecs[i];
			msgs[i].msg_hdr.msg_iovlen = 1;

			msgs[i].msg_hdr.msg_name = &src_addr[i];
			msgs[i].msg_hdr.msg_namelen = sizeof(src_addr[i]);
		}

		// timeout struct
			timeout.tv_sec = (time_t) tspec;
			timeout.tv_nsec = (long) ((tspec - (double) timeout.tv_sec) * 1000000000.0);

		// Recv
			retval = recvmmsg(sockfd, msgs, msg_count, MSG_WAITFORONE, &timeout);

		if (retval == -1) {
			perror("recvmmsg()");
		}else{

			// Gen result array
			result = newAV();

			for (i = 0; i < retval; i++) {
				pack = newAV();

				av_push(pack, newSVpv(msgs[i].msg_hdr.msg_name, msgs[i].msg_hdr.msg_namelen));	// sockaddr_in
				av_push(pack, newSVpv(bufs[i],msgs[i].msg_len));				// bufer

				pack_ref = newRV_noinc((SV *)pack);
				av_push(result, pack_ref);
			}

			result_ref = newRV_noinc((SV *)result);
			sv_2mortal(result_ref);

			dXSARGS;
			sp = mark;
			XPUSHs(result_ref);
			PUTBACK;
		}

		// Free memory
		Safefree(mem_blk);
		Safefree(src_addr);
		Safefree(iovecs);
		Safefree(msgs);
		Safefree(bufs);

	}

MODULE = Socket::Mmsg	PACKAGE = Socket::Mmsg

PROTOTYPES: DISABLE


void
sendmmsg (psock, msg_array_ref)
	PerlIO *	psock
	SV *	msg_array_ref
	PPCODE:
	sendmultimsg(psock, msg_array_ref);
	return;

void
recvmmsg (psock, msg_count, msg_len, tspec)
	PerlIO *	psock
	int	msg_count
	int	msg_len
	float	tspec
	PPCODE:
	recvmultimsg(psock, msg_count, msg_len, tspec);
	return;