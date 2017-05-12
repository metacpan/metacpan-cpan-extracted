#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <unistd.h>     /* _POSIX, _SC_* */

#if !defined(_POSIX_SEMAPHORES)
#  error "POSIX::RT::Semaphore requires _POSIX_SEMAPHORES support."
#endif

#include <semaphore.h>
#include <limits.h>     /* _POSIX_SEM_* */
#include <errno.h>      /* ENOSYS */

#ifdef HAVE_SEM_TIMEDWAIT
#  include <time.h>
#endif


#ifdef HAS_MMAP
#  include <sys/mman.h>
#  if defined(MAP_ANON) && !defined(MAP_ANONYMOUS)
#    define MAP_ANONYMOUS     MAP_ANON
#  endif
#  ifndef MAP_ANONYMOUS
#    include <fcntl.h> /* open(..., O_RDWR) */
#  endif
#  ifndef MAP_HASSEMAPHORE
#    define MAP_HASSEMAPHORE  0
#  endif
#  ifndef MAP_FAILED
#    define MAP_FAILED        ((void *)-1)
#  endif
#endif



typedef int SysRet;

typedef struct PSem_C {
  sem_t* sem;
  char * name;
} * POSIX__RT__Semaphore___base;
typedef POSIX__RT__Semaphore___base POSIX__RT__Semaphore__Named;
typedef POSIX__RT__Semaphore___base POSIX__RT__Semaphore__Unnamed;

/* _alloc_sem()
 * 
 * Return a new sem_t in shared memory (maybe), or NULL (_not_ SEM_FAILED)
 * on failure.
 */
static sem_t *
_alloc_sem(void) {
	sem_t *sem = NULL;
#ifdef HAS_MMAP
	int fd = -1;
	int prot_flags = PROT_READ|PROT_WRITE;
	int map_flags = MAP_SHARED|MAP_HASSEMAPHORE;

#  ifdef MAP_ANONYMOUS
	map_flags |= MAP_ANONYMOUS;
	sem = (sem_t *)mmap(NULL, sizeof(sem_t), prot_flags, map_flags, fd, 0);
#  else
	if ((fd = open("/dev/zero", O_RDWR)) != -1) {
		sem = (sem_t *)mmap(NULL, sizeof(sem_t), prot_flags, map_flags, fd, 0);
		close(fd);
	}
#  endif /* MAP_ANONYMOUS */
#else
	Newz(0, sem, 1, sem_t);
#endif /* HAS_MMAP */

	return sem;
}

/* _dealloc_sem
 *
 * Free a sem_t we allocated.
 */
static void
_dealloc_sem(sem_t *sem)
{
#ifdef HAS_MMAP
	munmap((void *)sem, sizeof(sem_t));
#else
	Safefree(sem);
#endif
}

static int
function_not_implemented(void)
{
  errno = ENOSYS;
  return -1;
}

#define sem_valid(sem)     ((sem) && (sem) != SEM_FAILED)

#define PRECOND_valid_psem(fname, psem)                   \
  do {                                                    \
    if (!psem || !sem_valid(psem->sem))                   \
        croak(fname "() method called on invalid psem");  \
  } while (0)


MODULE = POSIX::RT::Semaphore  PACKAGE = POSIX::RT::Semaphore  PREFIX = psem_
PROTOTYPES: DISABLE

BOOT:
{
	char * const pkgs[] = {
		"POSIX::RT::Semaphore::Named::ISA",
		"POSIX::RT::Semaphore::Unnamed::ISA",
	};
	HV *stash;
	int i;

	for (i = 0; i < sizeof(pkgs)/sizeof(*pkgs); i++) {
		AV *isa;
		isa = get_av(pkgs[i], TRUE);
		av_push(isa, newSVpv("POSIX::RT::Semaphore::_base", 0));
	}

	stash = gv_stashpvn("POSIX::RT::Semaphore", 20, TRUE);

	newCONSTSUB(stash, "SIZEOF_SEM_T", newSViv(sizeof(sem_t)));
#ifdef _POSIX_SEM_VALUE_MAX
	newCONSTSUB(stash, "SEM_VALUE_MAX", newSViv(_POSIX_SEM_VALUE_MAX));
#endif
#ifdef _SC_SEM_VALUE_MAX
	newCONSTSUB(stash, "_SC_SEM_VALUE_MAX", newSViv(_POSIX_SEM_VALUE_MAX));
#endif
#ifdef _POSIX_SEM_NSEMS_MAX
	newCONSTSUB(stash, "SEM_NSEMS_MAX", newSViv(_POSIX_SEM_NSEMS_MAX));
#endif
#ifdef _SC_SEM_NSEMS_MAX
	newCONSTSUB(stash, "_SC_SEM_NSEMS_MAX", newSViv(_POSIX_SEM_NSEMS_MAX));
#endif
#ifdef SEM_NAME_LEN
	newCONSTSUB(stash, "SEM_NAME_LEN", newSViv(SEM_NAME_LEN));
#endif
#ifdef SEM_NAME_MAX
	newCONSTSUB(stash, "SEM_NAME_MAX", newSViv(SEM_NAME_MAX));
#endif
}

SysRet
psem_unlink(pkg = "POSIX::RT::Semaphore", path)
	char*             pkg
	char*             path

	CODE:
#ifdef HAVE_SEM_UNLINK
	RETVAL = sem_unlink(path);
#else
	# older versions of Cygwin
	RETVAL = function_not_implemented();
#endif

	OUTPUT:
	RETVAL

MODULE = POSIX::RT::Semaphore PACKAGE = POSIX::RT::Semaphore::_base  PREFIX = psem_
PROTOTYPES: DISABLE

void
psem_DESTROY(self)
	POSIX::RT::Semaphore::_base    self

	CODE:
	if (self->name) {
		if (sem_valid(self->sem))
			(void)sem_close(self->sem);
		Safefree(self->name);
	} else {
		if (sem_valid(self->sem))
			_dealloc_sem(self->sem);
	}
	Safefree(self);

SysRet
psem_wait(self)
	POSIX::RT::Semaphore::_base    self

	CODE:
	PRECOND_valid_psem("wait", self);
	RETVAL = sem_wait(self->sem);

	OUTPUT:
	RETVAL

SysRet
psem_trywait(self) 
	POSIX::RT::Semaphore::_base    self

	CODE:
	PRECOND_valid_psem("trywait", self);
	RETVAL = sem_trywait(self->sem);

	OUTPUT:
	RETVAL

SysRet
psem_timedwait(self, timeout)
	POSIX::RT::Semaphore::_base    self
	NV                             timeout

	PREINIT:
#ifdef HAVE_SEM_TIMEDWAIT
	struct timespec ts;
#endif

	CODE:
	PRECOND_valid_psem("timedwait", self);
#ifdef HAVE_SEM_TIMEDWAIT
	if (timeout < 0.0)
		timeout = 0.0;
	ts.tv_sec  = (long)timeout;
	timeout -= (NV)ts.tv_sec;
	ts.tv_nsec = (long)(timeout * 1000000000.0);
	RETVAL = sem_timedwait(self->sem, (const struct timespec *)&ts);
#else
	RETVAL = function_not_implemented();
#endif

	OUTPUT:
	RETVAL

SysRet
psem_post(self)
	POSIX::RT::Semaphore::_base    self

	CODE:
	PRECOND_valid_psem("post", self);
	RETVAL = sem_post(self->sem);

	OUTPUT:
	RETVAL

int
psem_getvalue(self)
	POSIX::RT::Semaphore::_base    self

	CODE:
	# RETVAL is an int, _not_ a SysRet, since we preserve -1
	PRECOND_valid_psem("getvalue", self);
	if (sem_getvalue(self->sem, &RETVAL) != 0) {
		XSRETURN_UNDEF;
	}

	OUTPUT:
	RETVAL

 ## Obsolecent ##
char*
psem_name(self)
	POSIX::RT::Semaphore::_base    self

	CODE:
	PRECOND_valid_psem("name", self);
	RETVAL = self->name;

	OUTPUT:
	RETVAL


MODULE = POSIX::RT::Semaphore PACKAGE = POSIX::RT::Semaphore::Unnamed  PREFIX = psem_
PROTOTYPES: DISABLE

POSIX::RT::Semaphore::Unnamed
psem_init(pkg = "POSIX::RT::Semaphore::Unnamed", pshared = 0, value = 1)
	char*               pkg
	int                 pshared
	unsigned            value

	CODE:
	Newz(0, RETVAL, 1, struct PSem_C);
	RETVAL->sem = _alloc_sem();
	if (NULL == RETVAL->sem) {
		Safefree(RETVAL);
		croak("sem_init: failed to allocate semaphore");
	}
	if (sem_init(RETVAL->sem, pshared, value) == -1) {
		_dealloc_sem(RETVAL->sem);
		Safefree(RETVAL);
		RETVAL = NULL;
	}
	#warn("xs.sem_init 0x%x (sem: 0x%x)\n", RETVAL, RETVAL->sem);

	OUTPUT:
	RETVAL

SysRet
psem_destroy(self)
	POSIX::RT::Semaphore::Unnamed    self

	CODE:
	PRECOND_valid_psem("destroy", self);
	if (0 == (RETVAL = sem_destroy(self->sem))) {
		_dealloc_sem(self->sem);
		self->sem = NULL;
	}

	OUTPUT:
	RETVAL


MODULE = POSIX::RT::Semaphore PACKAGE = POSIX::RT::Semaphore::Named  PREFIX = psem_
PROTOTYPES: DISABLE

POSIX::RT::Semaphore::Named
psem_open(pkg = "POSIX::RT::Semaphore::Named", name, flags = 0, mode = 0666, value = 1)
	char*               pkg
	char*               name
	int                 flags
	Mode_t              mode
	unsigned            value

	PREINIT:
	sem_t*              sem;

	CODE:
	sem = sem_open(name, flags, mode, value);
	if (SEM_FAILED == sem) {
		XSRETURN_UNDEF;
	}

	Newz(0, RETVAL, 1, struct PSem_C);
	RETVAL->sem = sem;
	RETVAL->name = savepv(name);
	#warn("xs.sem_open 0x%x (sem: 0x%x)\n", RETVAL, RETVAL->sem);

	OUTPUT:
	RETVAL

SysRet
psem_close(self)
	POSIX::RT::Semaphore::Named    self

	CODE:
	PRECOND_valid_psem("close", self);
	RETVAL = sem_close(self->sem);
	self->sem = NULL;

	OUTPUT:
	RETVAL
