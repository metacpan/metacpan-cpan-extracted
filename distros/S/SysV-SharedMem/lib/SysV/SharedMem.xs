#if defined linux
#	ifndef _GNU_SOURCE
#		define _GNU_SOURCE
#	endif
#	define GNU_STRERROR_R
#endif

#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/shm.h>

#define PERL_NO_GET_CONTEXT
#define PERL_REENTR_API 1
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#ifndef MIN
#	define MIN(a, b) ((a) < (b) ? (a) : (b))
#endif

#ifndef SvPV_free
#	define SvPV_free(arg) sv_setpvn_mg(arg, NULL, 0);
#endif

#if PERL_VERSION >= 14
#define find_magic(var) mg_findext(var, PERL_MAGIC_ext, &svsh_table)
#define check_magic(magic, var) (magic = find_magic(var))
#define unmagic(var) sv_unmagicext(var, PERL_MAGIC_ext, (MGVTBL*)&svsh_table)
#else
#define find_magic(var) mg_find(var, PERL_MAGIC_ext)
#define SVSH_MAGIC_NUMBER 0x7368
#define check_magic(magic, var) (magic = find_magic(var) && magic->mg_private == SVSH_MAGIC_NUMBER)
#define unmagic(var) sv_unmagic(var, PERL_MAGIC_ext)
#endif

#ifndef SV_CHECK_THINKFIRST_COW_DROP
#define SV_CHECK_THINKFIRST_COW_DROP(sv) SV_CHECK_THINKFIRST(sv)
#endif

struct svsh_info {
	int shmid;
	void* real_address;
	void* fake_address;
	size_t real_length;
	size_t fake_length;
#ifdef USE_ITHREADS
	perl_mutex count_mutex;
	int count;
#endif
};

static size_t page_size() {
	static size_t pagesize = 0;
	if (pagesize == 0) {
		pagesize = sysconf(_SC_PAGESIZE);
	}
	return pagesize;
}

#define die_sys(format) Perl_croak(aTHX_ format, strerror(errno))

static void real_croak_sv(pTHX_ SV* value) {
	dSP;
	PUSHMARK(SP);
	XPUSHs(value);
	PUTBACK;
	call_pv("Carp::croak", G_VOID | G_DISCARD);
}

#define croak_sys(format) real_croak_sv(aTHX_ sv_2mortal(newSVpvf(format, strerror(errno))))

static void reset_var(SV* var, struct svsh_info* info) {
	SvPVX(var) = info->fake_address;
	SvLEN(var) = 0;
	SvCUR(var) = info->fake_length;
	SvPOK_only(var);
}

static void svsh_fixup(pTHX_ SV* var, struct svsh_info* info, const char* string, STRLEN len) {
	if (ckWARN(WARN_SUBSTR)) {
		Perl_warn(aTHX_ "Writing directly to shared memory is not recommended");
		if (SvCUR(var) > info->fake_length)
			Perl_warn(aTHX_ "Truncating new value to size of the shared memory segment");
	}

	if (string && len)
		Copy(string, info->fake_address, MIN(len, info->fake_length), char);
	SV_CHECK_THINKFIRST_COW_DROP(var);
	if (SvROK(var))
		sv_unref_flags(var, SV_IMMEDIATE_UNREF);
	if (SvPOK(var))
		SvPV_free(var);
	reset_var(var, info);
}

static int svsh_write(pTHX_ SV* var, MAGIC* magic) {
	struct svsh_info* info = (struct svsh_info*) magic->mg_ptr;
	if (!SvOK(var))
		svsh_fixup(aTHX_ var, info, NULL, 0);
	else if (!SvPOK(var)) {
		STRLEN len;
		const char* string = SvPV(var, len);
		svsh_fixup(aTHX_ var, info, string, len);
	}
	else if (SvPVX(var) != info->fake_address)
		svsh_fixup(aTHX_ var, info, SvPVX(var), SvCUR(var));
	return 0;
}

static int svsh_clear(pTHX_ SV* var, MAGIC* magic) {
	Perl_die(aTHX_ "Can't clear a shared memory segment");
	return 0;
}

static int svsh_free(pTHX_ SV* var, MAGIC* magic) {
	struct svsh_info* info = (struct svsh_info*) magic->mg_ptr;
#ifdef USE_ITHREADS
	MUTEX_LOCK(&info->count_mutex);
	if (--info->count == 0) {
		if (shmdt(info->real_address) == -1)
			die_sys("Could not detach shared memory segment: %s");
		MUTEX_UNLOCK(&info->count_mutex);
		MUTEX_DESTROY(&info->count_mutex);
		PerlMemShared_free(info);
	}
	else {
		MUTEX_UNLOCK(&info->count_mutex);
	}
#else
	if (shmdt(info->real_address) == -1)
		die_sys("Could not detach shared memory segment: %s");
	PerlMemShared_free(info);
#endif 
	SvREADONLY_off(var);
	SvPVX(var) = NULL;
	SvCUR(var) = 0;
	SvOK_off(var);
	return 0;
}

#ifdef USE_ITHREADS
static int svsh_dup(pTHX_ MAGIC* magic, CLONE_PARAMS* param) {
	struct svsh_info* info = (struct svsh_info*) magic->mg_ptr;
	MUTEX_LOCK(&info->count_mutex);
	assert(info->count);
	++info->count;
	MUTEX_UNLOCK(&info->count_mutex);
	return 0;
}
#else
#define svsh_dup 0
#endif

#ifdef MGf_LOCAL
static int svsh_local(pTHX_ SV* var, MAGIC* magic) {
	Perl_croak(aTHX_ "Can't localize shared memory segment");
}
#define svsh_local_tail , svsh_local
#else
#define svsh_local_tail
#endif
static const MGVTBL svsh_table  = { 0, svsh_write,  0, svsh_clear, svsh_free,  0, svsh_dup svsh_local_tail };

static void check_new_variable(pTHX_ SV* var) {
	if (SvTYPE(var) > SVt_PVMG && SvTYPE(var) != SVt_PVLV)
		Perl_croak(aTHX_ "Trying to attach to a nonscalar!\n");
	SV_CHECK_THINKFIRST_COW_DROP(var);
	if (SvREADONLY(var))
		Perl_croak(aTHX_ "%s", PL_no_modify);
	if (SvMAGICAL(var) && find_magic(var))
		unmagic(var);
	if (SvROK(var))
		sv_unref_flags(var, SV_IMMEDIATE_UNREF);
	if (SvNIOK(var))
		SvNIOK_off(var);
	if (SvPOK(var)) 
		SvPV_free(var);
	SvUPGRADE(var, SVt_PVMG);
}

static void* do_mapping(pTHX_ int id, int flags) {
	void* address = shmat(id, NULL, flags);
	if (address == (void*)-1)
		croak_sys("Could not attach: %s");
	return address;
}

static void _my_shmctl(pTHX_ int id, int op, struct shmid_ds* buffer, const char* format) {
	int ret = shmctl(id, op, buffer);
	if (ret != 0)
		die_sys(format);
}

#define my_shmctl(id, op, buffer, format) _my_shmctl(aTHX_ id, op, buffer, format)
static struct svsh_info* S_initialize_svsh_info(pTHX_ int shmid, void* address, size_t length, ptrdiff_t correction) {
	struct svsh_info* magical = PerlMemShared_malloc(sizeof *magical);
	if (length == 0) {
		struct shmid_ds buffer;
		my_shmctl(shmid, IPC_STAT, &buffer, "Could not establish size of shared memory segment: %s");
		length = buffer.shm_segsz;
	}
	magical->shmid        = shmid;
	magical->real_address = address;
	magical->fake_address = (char*)address + correction;
	magical->real_length  = length + correction;
	magical->fake_length  = length;
#ifdef USE_ITHREADS
	MUTEX_INIT(&magical->count_mutex);
	magical->count = 1;
#endif
	return magical;
}
#define initialize_svsh_info(shmid, address, length, correction) S_initialize_svsh_info(aTHX_ shmid, address, length, correction)

static void add_magic(pTHX_ SV* var, struct svsh_info* magical, int writable) {
	MAGIC* magic = sv_magicext(var, NULL, PERL_MAGIC_ext, &svsh_table, (const char*) magical, 0);
#ifdef SVSH_MAGIC_NUMBER
	magic->mg_private = SVSH_MAGIC_NUMBER;
#endif
#ifdef MGf_LOCAL
	magic->mg_flags |= MGf_LOCAL;
#endif
#ifdef USE_ITHREADS
	magic->mg_flags |= MGf_DUP;
#endif
	if (!writable)
		SvREADONLY_on(var);
}

static struct svsh_info* get_svsh_magic(pTHX_ SV* var, const char* funcname) {
	MAGIC* magic;
	if (!SvMAGICAL(var) || !check_magic(magic, var))
		Perl_croak(aTHX_ "Could not %s: this variable is not a shared memory segment", funcname);
	return (struct svsh_info*) magic->mg_ptr;
}

#define SET_HASH(key, value) hv_store(hash, key, sizeof key - 1, newSViv(value), 0)

#define get_shmid(var, description) get_svsh_magic(aTHX_ var, description)->shmid

MODULE = SysV::SharedMem				PACKAGE = SysV::SharedMem

PROTOTYPES: DISABLED

void
_shmat(var, shmid, offset, length, flags)
	SV* var;
	int shmid;
	ssize_t offset;
	size_t length;
	int flags;
	PREINIT:
		ptrdiff_t correction;
		void* address;
		struct svsh_info* magical;
	CODE:
		check_new_variable(aTHX_ var);
		
		correction = offset % page_size();
		address = do_mapping(aTHX_ shmid, flags);
		
		magical = initialize_svsh_info(shmid, address, length, correction);
		reset_var(var, magical);
		add_magic(aTHX_ var, magical, 1);

SV*
shared_stat(var)
	SV* var;
	PREINIT:
		int shmid;
		struct shmid_ds buffer;
		HV* hash;
	CODE:
		my_shmctl(get_shmid(var, "shared_stat"), IPC_STAT, &buffer, "Could not shared_stat: %s");
		
		hash = newHV();
		
		SET_HASH("uid", buffer.shm_perm.uid);
		SET_HASH("gid", buffer.shm_perm.gid);
		SET_HASH("cuid", buffer.shm_perm.cuid);
		SET_HASH("cgid", buffer.shm_perm.cgid);
		SET_HASH("mode", buffer.shm_perm.mode);

		SET_HASH("segsz", buffer.shm_segsz);
		SET_HASH("lpid", buffer.shm_lpid);
		SET_HASH("cpid", buffer.shm_cpid);
		SET_HASH("nattch", buffer.shm_nattch);
		SET_HASH("atime", buffer.shm_atime);
		SET_HASH("dtime", buffer.shm_dtime);
		SET_HASH("ctime", buffer.shm_ctime);

		RETVAL = newRV_noinc((SV*)hash);
	OUTPUT:
		RETVAL

void
shared_chown(var, uid, gid = &PL_sv_undef)
	SV* var;
	IV uid;
	SV* gid;
	PREINIT:
	int shmid;
	struct shmid_ds buffer;
	CODE:
		shmid = get_shmid(var, "shared_chown");
		my_shmctl(shmid, IPC_STAT, &buffer, "Could not shared_chown: %s");
		buffer.shm_perm.uid = uid;
		if (SvOK(gid))
			buffer.shm_perm.gid = SvIV(gid);
		my_shmctl(shmid, IPC_SET, &buffer, "Could not shared_chown: %s");

void
shared_chmod(var, mode)
	SV* var;
	int mode;
	PREINIT:
	int shmid;
	struct shmid_ds buffer;
	CODE:
		shmid = get_shmid(var, "shared_chmod");
		my_shmctl(shmid, IPC_STAT, &buffer, "Could not shared_chmod: %s");
		buffer.shm_perm.mode = (buffer.shm_perm.mode & ~0777) | (mode & 0777);
		my_shmctl(shmid, IPC_SET, &buffer, "Could not shared_chmod: %s");

void
shared_remove(var)
	SV* var;
	PREINIT:
	int shmid;
	CODE:
		my_shmctl(get_shmid(var, "shared_remove"), IPC_RMID, NULL, "Could not shared_remove: %s");

void
shared_detach(var)
	SV* var;
	CODE:
		get_svsh_magic(aTHX_ var, "shared_detach");
		unmagic(var);

IV
shared_identifier(var)
	SV* var;
	CODE:
		RETVAL = get_shmid(var, "shared_identifier");
	OUTPUT:
		RETVAL
