#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <string.h> /* for memmove() mostly */
#include <errno.h> /* errno values */
#include <poll.h>
#include <sys/time.h>
#include <time.h>
#include "alloc.h"
#include "poexs.h"

/*#define XS_LOOP_DEBUG*/

#if defined(MEM_DEBUG) || defined(XS_LOOP_DEBUG)
/* sizes that should require re-allocation of the arrays */
#define START_FD_ALLOC 5
#define START_LOOKUP_ALLOC 10
#else
/* more than we need on average */
#define START_FD_ALLOC 50
#define START_LOOKUP_ALLOC 100
#endif

#define LOOP_CHECK_INITIALIZED() if (lp_fds == NULL) croak("POE::XS::Loop::Poll hasn't been initialized correctly");

#ifdef XS_LOOP_TRACE
#define lp_tracing_enabled() 1
#else
#define lp_tracing_enabled() 0
#endif

#define lpm_loop_resume_time_watcher(self, next_time) lp_loop_resume_time_watcher(next_time)
#define lpm_loop_reset_time_watcher(self, next_time) lp_loop_reset_time_watcher(next_time)
#define lpm_loop_watch_filehandle(self, handle, mode) lp_loop_watch_filehandle(handle, mode)
#define lpm_loop_ignore_filehandle(self, handle, mode) lp_loop_ignore_filehandle(handle, mode)
#define lpm_loop_pause_filehandle(self, handle, mode) lp_loop_ignore_filehandle(handle, mode)
#define lpm_loop_resume_filehandle(self, handle, mode) lp_loop_watch_filehandle(handle, mode)

/* no ops */
#define lp_loop_attach_uidestroy(kernel)
#define lp_loop_halt(kernel)

/* the next time-based event to be dispatched */
static double lp_next_time;

/* poll fd structures, lp_fd_count are in use, lp_fd_alloc are available */
static struct pollfd *lp_fds;
static int lp_fd_count;
static int lp_fd_alloc;

/* lookup table to translate fd numbers to an index in lp_fds
   if the entry in lp_fd_lookup is -1 then no entry is allocated */
static int *lp_fd_lookup;
static int lp_fd_lookup_alloc;

#ifdef XS_LOOP_TRACE
/* when we started working, used only for tracing */
static double lp_start_time;
#endif

/* functions should be static, hopefully the compiler will inline them
   into the XS code */

static void
lp_loop_initialize(SV *kernel) {
  int i;

  poe_initialize();

  POE_TRACE_CALL(("<cl> loop_initialize()"));

  lp_next_time = 0;

  lp_fd_alloc = START_FD_ALLOC;
  lp_fd_count = 0;
  lp_fds = mymalloc(sizeof(*lp_fds) * START_FD_ALLOC);

  lp_fd_lookup_alloc = START_LOOKUP_ALLOC;
  lp_fd_lookup = mymalloc(sizeof(*lp_fd_lookup) * START_LOOKUP_ALLOC);
  for (i = 0; i < lp_fd_lookup_alloc; ++i)
    lp_fd_lookup[i] = -1;

#ifdef XS_LOOP_TRACE
  lp_start_time = poe_timeh();
#endif
}

static void
lp_loop_finalize(SV *kernel) {
  POE_TRACE_CALL(("<cl> loop_finalize()"));

#ifdef XS_LOOP_TRACE
  if (lp_fd_count) {
    int i;
    POE_TRACE_FILE(("LOOP HANDLE LEAK"));
    for (i = 0; i < lp_fd_count; ++i) {
      POE_TRACE_FILE(("Index %d: fd %d mask %x", i, lp_fds[i].fd, lp_fds[i].events));
    }
  }
#endif

  myfree(lp_fds);
  lp_fds = NULL;
  lp_fd_count = 0;
  lp_fd_alloc = 0;
  myfree(lp_fd_lookup);
  lp_fd_lookup = NULL;
  lp_fd_lookup_alloc = 0;
}

static int
_get_file_entry(int fd) {
  if (fd < 0 || fd > lp_fd_lookup_alloc)
    return -1;

  return lp_fd_lookup[fd];
}

/*
  expand the fd lookup table so that we can store the given fd in it
*/
static void
_expand_fd_lookup(int fd) {
  int i;
  int new_alloc = lp_fd_lookup_alloc * 2;
  if (fd >= new_alloc)
    new_alloc = fd + 1;

  lp_fd_lookup = myrealloc(lp_fd_lookup, sizeof(*lp_fd_lookup) * new_alloc);
  for (i = lp_fd_lookup_alloc; i < new_alloc; ++i)
    lp_fd_lookup[i] = -1;
  lp_fd_lookup_alloc = new_alloc;
}

static void
_expand_fds(void) {
  int new_alloc = lp_fd_alloc * 2;
  lp_fds = myrealloc(lp_fds, sizeof(*lp_fds) * new_alloc);
  lp_fd_alloc = new_alloc;
}

static int
_make_file_entry(int fd) {
  int entry;

  if (fd < 0)
    return -1;

  if (fd >= lp_fd_lookup_alloc)
    _expand_fd_lookup(fd);

  entry = lp_fd_lookup[fd];
  if (entry == -1) {
    if (lp_fd_count == lp_fd_alloc)
      _expand_fds();

    entry = lp_fd_count++;
    lp_fd_lookup[fd] = entry;
    lp_fds[entry].fd = fd;
    lp_fds[entry].events = 0;
    lp_fds[entry].revents = 0;

    return entry;
  }
  else {
    return entry;
  }
}

static void
_release_file_entry(int fd) {
  int entry = _get_file_entry(fd);

  if (entry < 0)
    croak("Attempt to remove a non-existent poll entry");

  fd = lp_fds[entry].fd;
  lp_fd_lookup[fd] = -1;

  if (entry != lp_fd_count-1) {
    /* move the last entry into place */
    lp_fds[entry] = lp_fds[lp_fd_count-1];
    lp_fd_lookup[lp_fds[entry].fd] = entry;
  }

  --lp_fd_count;
}

static int
_poll_from_poe_mode(int mode) {
  switch (mode) {
  case MODE_RD:
    return POLLIN;

  case MODE_WR:
    return POLLOUT;

  case MODE_EX:
    return POLLPRI;

  default:
    croak("Unknown filehandle watch mode %d", mode);
  }  
}

#ifdef XS_LOOP_TRACE

static const char *
poll_mode_names(int mask) {
  switch (mask) {
  case 0:
  case POLLIN:
    return "POLLIN";

  case POLLOUT:
    return "POLLOUT";

  case POLLPRI:
    return "POLLPRI";

  case POLLIN | POLLOUT:
    return "POLLIN | POLLOUT";

  case POLLIN | POLLPRI:
    return "POLLIN | POLLPRI";

  case POLLOUT | POLLPRI:
    return "POLLOUT | POLLPRI";

  case POLLOUT | POLLIN | POLLPRI:
    return "POLLOUT | POLLIN | POLLPRI";

  case POLLNVAL:
    return "POLLNVAL";

  default:
    return "Unknown";
  }
}

#endif

static void
lp_loop_do_timeslice(SV *kernel) {
  double delay = 3600;
  int count;
  double now;
  int save_errno;

  LOOP_CHECK_INITIALIZED();

  POE_TRACE_CALL(("<cl> loop_do_timeslice()"));

  poe_test_if_kernel_idle(kernel);

  now = poe_timeh();
  if (lp_next_time) {
    delay = lp_next_time - now;
    if (delay > 3600)
      delay = 3600;
  }
  if (delay < 0)
    delay = 0;

#ifdef XS_LOOP_TRACE

  {
    int i;
    SV *trace_sv = newSVpv("<fh> ,---- XS POLL FDS IN ----\n", 0);
    for (i = 0; i < lp_fd_count; ++i) {
      sv_catpvf(trace_sv, "<fh> | Index %2d fd %3d mask %x (%s)\n", i, lp_fds[i].fd, lp_fds[i].events, poll_mode_names(lp_fds[i].events));
    }
    sv_catpv(trace_sv, "<fh> `-------------------------");
    /*POE_TRACE_FILE(("<fh>  Delay %f\n", delay));*/
    POE_TRACE_FILE((POE_SV_FORMAT, trace_sv));
    SvREFCNT_dec(trace_sv);
  }
  POE_TRACE_EVENT(("<ev> Kernel::run() iterating (XS) now(%.4f) timeout(%.4f)"
    " then(%.4f)\n", now - lp_start_time, delay, (now - lp_start_time) + delay));

#endif  

  count = poll(lp_fds, lp_fd_count, (int)(delay * 1000));
  save_errno = errno;

#ifdef XS_LOOP_TRACE
  if (poe_tracing_files()) {
    int i;
    SV *trace_sv = newSVpvf("<fh> poll() => %d (%d)\n", count, save_errno);

    sv_catpvf(trace_sv, "<fh> /---- XS POLL FDS OUT ----\n");
    for (i = 0; i < lp_fd_count; ++i) {
      if (lp_fds[i].revents) {
        sv_catpvf(trace_sv, "<fh> | Index %2d fd %d mask %x (%s)\n", i, 
          lp_fds[i].fd, lp_fds[i].revents, poll_mode_names(lp_fds[i].revents));
      }
    }
    sv_catpv(trace_sv, "<fh> `-------------------------");
    POE_TRACE_FILE((POE_SV_FORMAT, trace_sv));
    SvREFCNT_dec(trace_sv);
  }
#endif

  /* POE::Loop::Select puts this after the event dispatch, but as the
     comment there notes, it's not really idle time when it includes
     the event dispatch processing, so I've moved it here */
  POE_STAT_ADD(kernel, "idle_seconds", poe_timeh()-now);

  errno = save_errno;
  if (count < 0) {
    if (errno != EINPROGRESS &&
	errno != EWOULDBLOCK &&
	errno != EINTR) {
      /* pass $! for auto-magical text description of errno */
      poe_trap("<fh> poll error: " POE_SV_FORMAT " (%d)", get_sv("!", 0), errno);
    }
  }
  else if (count) {
    int mode;
    int i;
    int *fds[3] = { NULL };
    int counts[3] = { 0, 0, 0 };
    int masks[3];

    fds[0] = mymalloc(sizeof(int) * lp_fd_count * 3);
    fds[1] = fds[0] + lp_fd_count;
    fds[2] = fds[1] + lp_fd_count;
    for (mode = MODE_RD; mode <= MODE_EX; ++mode) {
      masks[mode] = _poll_from_poe_mode(mode);
    }

    /* build an array of fds for each event */
    for (i = 0; i < lp_fd_count; ++i) {
      if (lp_fds[i].revents) {
	int revents = lp_fds[i].revents;
	for (mode = MODE_RD; mode <= MODE_EX; ++mode) {
	  if ((lp_fds[i].events & masks[mode])
	      && revents & (masks[mode] | POLLHUP | POLLERR | POLLNVAL)) {
	    fds[mode][counts[mode]++] = lp_fds[i].fd;
	  }
	}
      }
    }

    for (mode = MODE_RD; mode <= MODE_EX; ++mode) {
      if (counts[mode])
	poe_enqueue_data_ready(kernel, mode, fds[mode], counts[mode]);
    }
    myfree(fds[0]);
  }
  else {
    POE_TRACE_FILE(("<fh> poll timed out"));
  }

  poe_data_ev_dispatch_due(kernel);
}

static void
lp_loop_run(SV *kernel) {
  LOOP_CHECK_INITIALIZED();

  POE_TRACE_CALL(("<cl> loop_run()"));
  while (poe_data_ses_count(kernel)) {
    lp_loop_do_timeslice(kernel);
  }
}

static void
lp_loop_resume_time_watcher(double next_time) {
  LOOP_CHECK_INITIALIZED();

  POE_TRACE_CALL(("<cl> loop_resume_time_watcher(%.3f) %.3f from now",
	  next_time, next_time - poe_timeh()));
  lp_next_time = next_time;
}

static void
lp_loop_reset_time_watcher(double next_time) {
  LOOP_CHECK_INITIALIZED();

  POE_TRACE_CALL(("<cl> loop_reset_time_watcher(%.3f) %.3f from now", 
	  next_time, next_time - poe_timeh()));
  lp_next_time = next_time;
}

static void
lp_loop_pause_time_watcher(SV *kernel) {
  LOOP_CHECK_INITIALIZED();

  POE_TRACE_CALL(("<cl> loop_pause_time_watcher()"));
  lp_next_time = 0;
}

static void
lp_loop_watch_filehandle(PerlIO *handle, int mode) {
  int fd = PerlIO_fileno(handle);
  int entry = _make_file_entry(fd);

  LOOP_CHECK_INITIALIZED();

  POE_TRACE_CALL(("<cl> loop_watch_filehandle(%d, %d %s)", 
		  fd, mode, poe_mode_names(mode)));

  lp_fds[entry].events |= _poll_from_poe_mode(mode);
}

static void
lp_loop_ignore_filehandle(PerlIO *handle, int mode) {
  int fd = PerlIO_fileno(handle);
  int entry = _get_file_entry(fd);

  LOOP_CHECK_INITIALIZED();

  POE_TRACE_CALL(("<cl> loop_ignore_filehandle(%d, %d %s)", 
		  fd, mode, poe_mode_names(mode)));

  if (entry >= 0) {
    lp_fds[entry].events &= ~_poll_from_poe_mode(mode);

    if (lp_fds[entry].events == 0) {
      _release_file_entry(fd);
    }
  }
}

MODULE = POE::XS::Loop::Poll  PACKAGE = POE::Kernel PREFIX = lp_

PROTOTYPES: DISABLE

void
lp_loop_initialize(kernel)
  SV *kernel

void
lp_loop_finalize(kernel)
  SV *kernel

void
lp_loop_do_timeslice(kernel)
  SV *kernel

void
lp_loop_run(kernel)
  SV *kernel

void
lp_loop_halt(kernel)

void
lp_loop_pause_time_watcher(kernel)
  SV *kernel

void
lp_loop_attach_uidestroy(kernel)

MODULE = POE::XS::Loop::Poll  PACKAGE = POE::Kernel PREFIX = lpm_

void
lpm_loop_resume_time_watcher(self, next_time)
  double next_time

void
lpm_loop_reset_time_watcher(self, next_time);
  double next_time

void
lpm_loop_watch_filehandle(self, fh, mode)
  PerlIO *fh
  int mode

void
lpm_loop_ignore_filehandle(self, fh, mode)
  PerlIO *fh
  int mode

void
lpm_loop_pause_filehandle(self, fh, mode)
  PerlIO *fh
  int mode

void
lpm_loop_resume_filehandle(self, fh, mode)
  PerlIO *fh
  int mode

MODULE = POE::XS::Loop::Poll  PACKAGE = POE::XS::Loop::Poll PREFIX = lp_

int
lp_tracing_enabled()

