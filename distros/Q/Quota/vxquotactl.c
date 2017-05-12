/* vxquotactl.c 
 *
 * vx_quotactl() provides a quotactl() style call for the VERITAS File
 * System (VxFS).  It has only been tested on Solaris 2.6.
 *
 * This code is mostly the result of a service order placed with Sun,
 * which in turn resulted in them bugging VERITAS.  It was released
 * with no copyright notice with the following warning:
 *
 *   As promised, below is a C program that would provide a similiar 
 *   functionality as "quotactl" for you.  Veritas has tested it and it 
 *   works well, but bear in mind that it may go away without notice. 
 * 
 *   Just to clear this - there will not be any support from us on this
 *   and it is absolutely upto customer to work with it or not.
 *
 * BUGS:
 *
 * Does not compile with gcc 2.7.2.3, and quite likely other versions.  It
 * does compile fine with Sun Workshop C 4.2.
 *
 * AUTHOR (sort of):
 *
 * Mike Gerdts, gerdts@cae.wisc.edu
 */

#include "include/vxquotactl.h"
#include <fcntl.h>
#include <sys/types.h>
#include <sys/vfs.h>
#include <sys/fs/vxio.h>
#include <sys/fs/vx_solaris.h>
#include <sys/fs/vx_machdep.h>
#include <sys/fs/vx_ioctl.h>
#include <sys/fs/vx_layout.h>
#include <sys/fs/vx_aioctl.h>
#include <sys/fs/vx_quota.h>

int
vx_quotactl(int cmd, char *mntpt, uid_t uid, void *addr)
{
	int			fd;
	struct vx_quotctl	quotabuf;
	struct vx_genioctl	genbuf;

	fd = open(mntpt, O_RDONLY);
	if (fd < 0) {
		return -1;
	}

	genbuf.ioc_cmd = VX_QUOTACTL;
	genbuf.ioc_up = &quotabuf;

	quotabuf.cmd = cmd;
	quotabuf.uid = uid;
	quotabuf.addr = addr;

	if (ioctl(fd, VX_ADMIN_IOCTL, &genbuf) < 0) {
		close(fd);
		return -1;
	}

	close(fd);
	return 0;
}
