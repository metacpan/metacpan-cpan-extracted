#ifndef INC_VXQUOTACTL_H
#define INC_VXQUOTACTL_H

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

int vx_quotactl(int cmd, char *mntpt, uid_t uid, void *addr);

#endif /* INC_VXQUOTACTL_H */
