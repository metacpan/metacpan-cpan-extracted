/* Copyright (c) 2000 Sampo Kellomaki <sampo@iki.fi>, All Rights Reserved.
 * This module may be copied under the same terms as the perl itself.
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "passfd.c"

MODULE = Socket::PassAccessRights	PACKAGE = Socket::PassAccessRights

int
sendfd(sock_fd,send_me_fd)
	int sock_fd
	int send_me_fd

int
recvfd(sock_fd)
	int sock_fd
