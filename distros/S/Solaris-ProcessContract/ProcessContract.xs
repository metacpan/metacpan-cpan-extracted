#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <errno.h>
#include <string.h>
#include <limits.h>
#include <stdio.h>

#include <sys/ctfs.h>
#include <sys/contract/process.h>
#include <libcontract.h>


MODULE = Solaris::ProcessContract  PACKAGE = Solaris::ProcessContract::XS

PROTOTYPES: DISABLE


# Expose process contract flags
int
_FLAGS()
ALIAS:
  CT_PR_INHERIT   = CT_PR_INHERIT
  CT_PR_NOORPHAN  = CT_PR_NOORPHAN
  CT_PR_PGRPONLY  = CT_PR_PGRPONLY
  CT_PR_REGENT    = CT_PR_REGENT
  CT_PR_ALLPARAM  = CT_PR_ALLPARAM
  CT_PR_EV_EMPTY  = CT_PR_EV_EMPTY
  CT_PR_EV_FORK   = CT_PR_EV_FORK
  CT_PR_EV_EXIT   = CT_PR_EV_EXIT
  CT_PR_EV_CORE   = CT_PR_EV_CORE
  CT_PR_EV_SIGNAL = CT_PR_EV_SIGNAL
  CT_PR_EV_HWERR  = CT_PR_EV_HWERR
  CT_PR_ALLEVENT  = CT_PR_ALLEVENT
  CT_PR_ALLFATAL  = CT_PR_ALLFATAL
CODE:
  RETVAL = ix;
OUTPUT:
  RETVAL


# Opens a new process contract template
int
_open_template_fd()
PREINIT:
  int fd;
CODE:
  fd = open64(CTFS_ROOT "/process/template", O_RDWR);
  if ( fd == -1 ) {
    croak( "failed to open process contract template: %s\n", strerror(errno) );
  }
  RETVAL = fd;
OUTPUT:
 RETVAL


# Opens the latest process contract
int
_open_latest_fd()
PREINIT:
  int fd;
CODE:
  fd = open64(CTFS_ROOT "/process/latest", O_RDONLY);
  if ( fd == -1 ) {
    croak( "failed to open latest process contract: %s\n", strerror(errno) );
  }
  RETVAL = fd;
OUTPUT:
 RETVAL


# Opens the control file for a contract
int
_open_control_fd(id)
  int id
PREINIT:
  int   fd;
  char  path[PATH_MAX];
CODE:
  snprintf(path, PATH_MAX, CTFS_ROOT "/all/%u/ctl", id);
  fd = open64(path, O_WRONLY);
  if ( fd == -1 ) {
    croak( "failed to open process contract %u: %s\n", id, strerror(errno) );
  }
  RETVAL = fd;
OUTPUT:
 RETVAL


# Close file descriptor
void
_close_fd(fd)
  int fd
CODE:
  close(fd);


# Activate a template
void
_activate_template(fd)
  int fd
CODE:
  errno = ct_tmpl_activate(fd);
  if ( errno ) {
    croak( "failed to activate process template: %s\n", strerror(errno) );
  }


# Clear a template
void
_clear_template(fd)
  int fd
CODE:
  errno = ct_tmpl_clear(fd);
  if ( errno ) {
    croak( "failed to clear template: %s\n", strerror(errno) );
  }


# Set parameters on a template
void
_set_template_parameters(fd, params)
  int           fd
  unsigned int  params
CODE:
  errno = ct_pr_tmpl_set_param(fd, params);
  if ( errno ) {
    croak( "failed to set template params: %s\n", strerror(errno) );
  }


# Get parameters from a template
unsigned int
_get_template_parameters(fd)
  int           fd
PREINIT:
  unsigned int  params;
CODE:
  errno = ct_pr_tmpl_get_param(fd, &params);
  if ( errno ) {
    croak( "failed to get template params: %s\n", strerror(errno) );
  }
  RETVAL = params;
OUTPUT:
  RETVAL


# Set informative events on a template
void
_set_template_informative_events(fd, events)
  int           fd
  unsigned int  events
CODE:
  errno = ct_tmpl_set_informative(fd, events);
  if ( errno ) {
    croak( "failed to set template informative events: %s\n", strerror(errno) );
  }


# Get informative events from a template
unsigned int
_get_template_informative_events(fd)
  int           fd
PREINIT:
  unsigned int  params;
CODE:
  errno = ct_tmpl_get_informative(fd, &params);
  if ( errno ) {
    croak( "failed to get template informative events: %s\n", strerror(errno) );
  }
  RETVAL = params;
OUTPUT:
  RETVAL


# Set fatal events on a template
void
_set_template_fatal_events(fd, events)
  int           fd
  unsigned int  events
CODE:
  errno = ct_pr_tmpl_set_fatal(fd, events);
  if ( errno ) {
    croak( "failed to set template fatal events: %s\n", strerror(errno) );
  }


# Get fatal events from a template
unsigned int
_get_template_fatal_events(fd)
  int           fd
PREINIT:
  unsigned int  params;
CODE:
  errno = ct_pr_tmpl_get_fatal(fd, &params);
  if ( errno ) {
    croak( "failed to get template fatal events: %s\n", strerror(errno) );
  }
  RETVAL = params;
OUTPUT:
  RETVAL


# Set critical events on a template
void
_set_template_critical_events(fd, events)
  int           fd
  unsigned int  events
CODE:
  errno = ct_tmpl_set_critical(fd, events);
  if ( errno ) {
    croak( "failed to set template critical events: %s\n", strerror(errno) );
  }


# Get critical events from a template
unsigned int
_get_template_critical_events(fd)
  int           fd
PREINIT:
  unsigned int  params;
CODE:
  errno = ct_tmpl_get_critical(fd, &params);
  if ( errno ) {
    croak( "failed to get template critical events: %s\n", strerror(errno) );
  }
  RETVAL = params;
OUTPUT:
  RETVAL


# Get contract id
int
_get_contract_id(fd)
  int     fd
PREINIT:
  int     ctid;
  void*   ct_stathdl_t;
CODE:
  errno = ct_status_read(fd, CTD_COMMON, &ct_stathdl_t);
  if ( errno ) {
    croak( "failed to get process contract status: %s\n", strerror(errno) );
  }
  ctid = ct_status_get_id(ct_stathdl_t);
  if ( ctid == -1 ) {
    croak( "failed to get process contract id: %s\n", strerror(errno) );
  }  
  ct_status_free(ct_stathdl_t);
  RETVAL = ctid;
OUTPUT:
  RETVAL


# Abandon a process contract
void
_abandon_contract(fd)
  int fd
CODE:
  errno = ct_ctl_abandon(fd);
  if ( errno ) {
    croak( "failed to abandon process contract: %s\n", strerror(errno) );
  }


# Adopt a process contract
void
_adopt_contract(fd)
  int fd
CODE:
  errno = ct_ctl_adopt(fd);
  if ( errno ) {
    croak( "failed to abandon process contract: %s\n", strerror(errno) );
  }

