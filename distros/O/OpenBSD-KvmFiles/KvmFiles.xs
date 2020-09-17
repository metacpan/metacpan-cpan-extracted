#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <fcntl.h>
#include <kvm.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#define _KERNEL /* for DTYPE_VNODE */
#include <sys/file.h>
#undef _KERNEL
#include <sys/pipe.h>
#include <sys/eventvar.h>


MODULE = OpenBSD::KvmFiles		PACKAGE = OpenBSD::KvmFiles		
PROTOTYPES: ENABLE

int
_fd_per_process(int pid)
	INIT:
		struct kinfo_file* ret;
		int c;
		kvm_t * kd;
	CODE:
		kd = kvm_open(NULL, NULL, NULL, KVM_NO_FILES, NULL);
		ret = kvm_getfiles(kd, KERN_FILE_BYPID , pid, 1, &c);
		kvm_close(kd);
		RETVAL = c;
	OUTPUT:
		RETVAL

AV*
_fd_info_per_process(int pid)
	INIT:
		struct kinfo_file* kf;
		int i,c;
		kvm_t * kd;
		char buf[64];
	CODE:
		RETVAL = newAV();
		sv_2mortal((SV*)RETVAL);
		kd = kvm_open(NULL, NULL, NULL, KVM_NO_FILES, NULL);
		kf = kvm_getfiles(kd, KERN_FILE_BYPID , pid, sizeof(*kf), &c);
		for (i = 0; i < c; i++) {
			HV* hash = newHV();
			hv_store(hash, "type", strlen("type"), newSVnv(kf[i].f_type), 0);
			hv_store(hash, "usecount", strlen("usecount"), newSVnv(kf[i].f_usecount), 0);
			hv_store(hash, "read_bytes", strlen("read_bytes"), newSVnv(kf[i].f_rbytes), 0);
			hv_store(hash, "write_bytes", strlen("write_bytes"), newSVnv(kf[i].f_wbytes), 0);


			hv_store(hash, "uid", 3, newSVnv(kf[i].f_uid), 0);
			hv_store(hash, "gid", 3, newSVnv(kf[i].f_gid), 0);
			hv_store(hash, "pid", 3, newSVnv(kf[i].p_pid), 0);

			switch ( kf[i].f_type ) {
				case DTYPE_VNODE: /* file */
					hv_store(hash, "path", strlen("path"), newSVpvf("%s", kf[i].f_mntonname), 0);
					break;
				case DTYPE_SOCKET: /* communications endpoint */
					hv_store(hash, "rtable", strlen("rtable"), newSVnv(kf[i].inp_rtableid), 0);
					break;
				case DTYPE_PIPE: /* pipe */
					// pipe_state
					snprintf( buf, 4, "%s%s%s"
					             , (kf->pipe_state & PIPE_WANTR) ? "R" : ""
					             , (kf->pipe_state & PIPE_WANTW) ? "W" : ""
					             , (kf->pipe_state & PIPE_EOF) ? "E" : "");
					hv_store(hash, "state", strlen("state"),  newSVpvf("%s", buf), 0);
					break;
				case DTYPE_KQUEUE: /* event queue */
					hv_store(hash, "state", strlen("state")
					        , newSVpvf("%s%s", (kf->kq_state & KQ_SEL) ? "S" : "", (kf->kq_state & KQ_SLEEP) ? "W" : "")
					        , 0);
				case DTYPE_DMABUF: /* DMA buffer (for DRM) */
				default:
					break;
			}
			av_push(RETVAL, newRV_noinc((SV*)hash));
		}
		kvm_close(kd);
	OUTPUT:
		RETVAL
