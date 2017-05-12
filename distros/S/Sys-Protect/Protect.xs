#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

OP* sysprotect_op_deny(pTHX) {
  dSP;

  Perl_die(aTHX_ "Opcode denied: %s", PL_op_name[PL_op->op_type]);
  RETURN;
}

MODULE = Sys::Protect		PACKAGE = Sys::Protect

void
import(class)
     SV * class
     CODE: 
{
  int i;

  /* Deny anything that we don't know about at the time we made our
     list. */
  for (i = OP_CUSTOM; i < OP_max; ++i) {
    PL_ppaddr[i] = MEMBER_TO_FPTR(sysprotect_op_deny);
  }

  PL_ppaddr[OP_SYSCALL] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_BACKTICK] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_UMASK] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_SSELECT] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_DBMOPEN] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_DBMCLOSE] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_TRUNCATE] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_SOCKET] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_SOCKPAIR] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_SEND] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_RECV] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_FCNTL] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_IOCTL] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_BIND] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_CONNECT] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_LISTEN] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_FLOCK] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_ACCEPT] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_SHUTDOWN] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_GSOCKOPT] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_SSOCKOPT] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_GETSOCKNAME] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_GETPEERNAME] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_CHOWN] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_CHROOT] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_UNLINK] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_CHMOD] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_RENAME] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_LINK] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_SYMLINK] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_FORK] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_MKDIR] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_RMDIR] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_WAIT] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_WAITPID] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_EXEC] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_EXIT] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_SYSTEM] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_KILL] = MEMBER_TO_FPTR(sysprotect_op_deny);
  //? PL_ppaddr[OP_GETPPID] = MEMBER_TO_FPTR(sysprotect_op_deny);
  //? PL_ppaddr[OP_GETPGRP] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_GETPRIORITY] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_TMS] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_ALARM] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_SHMGET] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_SHMCTL] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_SHMREAD] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_MSGGET] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_MSGCTL] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_MSGSND] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_MSGRCV] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_SEMGET] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_SEMCTL] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_SEMOP] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_GPBYNAME] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_GPBYNUMBER] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_GPROTOENT] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_GHBYNAME] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_GHBYADDR] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_GHOSTENT] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_GNBYNAME] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_GNBYADDR] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_GNETENT] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_GPBYNAME] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_GPBYNUMBER] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_GPROTOENT] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_GSBYNAME] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_GSBYPORT] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_GSERVENT] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_SHOSTENT] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_SNETENT] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_SPROTOENT] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_SSERVENT] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_EHOSTENT] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_ENETENT] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_EPROTOENT] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_ESERVENT] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_GPWNAM] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_GPWUID] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_GPWENT] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_SPWENT] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_EPWENT] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_GGRNAM] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_GGRGID] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_GGRENT] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_SGRENT] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_EGRENT] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_GETLOGIN] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_SYSCALL] = MEMBER_TO_FPTR(sysprotect_op_deny);
  PL_ppaddr[OP_LOCK] = MEMBER_TO_FPTR(sysprotect_op_deny);
#ifdef OP_THREADSV
  PL_ppaddr[OP_THREADSV] = MEMBER_TO_FPTR(sysprotect_op_deny);
#endif
  PL_ppaddr[OP_DUMP] = MEMBER_TO_FPTR(sysprotect_op_deny);
}

