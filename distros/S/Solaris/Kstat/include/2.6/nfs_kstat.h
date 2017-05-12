/* Hacked out of Solaris 2.6 nfs_clnt.h */

#define KNC_STRSIZE	128	/* From rpc/clnt.h */
#define NFS_CALLTYPES	3	/* From nfs/nfs_clnt.h */
#define SYS_NMLN	257	/* From limits.h */

/*
 * Read-only mntinfo statistics
 */
struct mntinfo_kstat {
	char		mik_proto[KNC_STRSIZE];
	uint32_t	mik_vers;
	uint_t		mik_flags;
	uint_t		mik_secmod;
	uint32_t	mik_curread;
	uint32_t	mik_curwrite;
	int		mik_retrans;
	struct {
		uint32_t srtt;
		uint32_t deviate;
		uint32_t rtxcur;
	} mik_timers[NFS_CALLTYPES+1];
	uint32_t	mik_noresponse;
	uint32_t	mik_failover;
	uint32_t	mik_remap;
	char		mik_curserver[SYS_NMLN];
};
