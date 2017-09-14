#define PERL_constant_NOTFOUND	1
#define PERL_constant_NOTDEF	2
#define PERL_constant_ISIV	3
#define PERL_constant_ISNO	4
#define PERL_constant_ISNV	5
#define PERL_constant_ISPV	6
#define PERL_constant_ISPVN	7
#define PERL_constant_ISSV	8
#define PERL_constant_ISUNDEF	9
#define PERL_constant_ISUV	10
#define PERL_constant_ISYES	11

#ifndef NVTYPE
typedef double NV; /* 5.6 and later define NVTYPE, and typedef NV to it.  */
#endif
#ifndef aTHX_
#define aTHX_ /* 5.6 or later define this for threading support.  */
#endif
#ifndef pTHX_
#define pTHX_ /* 5.6 or later define this for threading support.  */
#endif

static int
constant_6 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     FP_NAN O_EXEC O_RDWR O_SYNC */
  /* Offset 3 gives the best switch position.  */
  switch (name[3]) {
  case 'D':
    if (memEQ(name, "O_RDWR", 6)) {
    /*                  ^        */
#ifdef O_RDWR
      *iv_return = O_RDWR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "FP_NAN", 6)) {
    /*                  ^        */
#ifdef FP_NAN
      *iv_return = FP_NAN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "O_EXEC", 6)) {
    /*                  ^        */
#ifdef O_EXEC
      *iv_return = O_EXEC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Y':
    if (memEQ(name, "O_SYNC", 6)) {
    /*                  ^        */
#ifdef O_SYNC
      *iv_return = O_SYNC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_7 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     FP_ZERO F_DUPFD F_GETFD F_GETFL F_GETLK F_RDLCK F_SETFD F_SETFL F_SETLK
     F_UNLCK F_WRLCK O_CREAT O_DSYNC O_RSYNC O_TRUNC RUN_LVL */
  /* Offset 2 gives the best switch position.  */
  switch (name[2]) {
  case 'C':
    if (memEQ(name, "O_CREAT", 7)) {
    /*                 ^          */
#ifdef O_CREAT
      *iv_return = O_CREAT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "F_DUPFD", 7)) {
    /*                 ^          */
#ifdef F_DUPFD
      *iv_return = F_DUPFD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "O_DSYNC", 7)) {
    /*                 ^          */
#ifdef O_DSYNC
      *iv_return = O_DSYNC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "F_GETFD", 7)) {
    /*                 ^          */
#ifdef F_GETFD
      *iv_return = F_GETFD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "F_GETFL", 7)) {
    /*                 ^          */
#ifdef F_GETFL
      *iv_return = F_GETFL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "F_GETLK", 7)) {
    /*                 ^          */
#ifdef F_GETLK
      *iv_return = F_GETLK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "RUN_LVL", 7)) {
    /*                 ^          */
#ifdef RUN_LVL
      *iv_return = RUN_LVL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "F_RDLCK", 7)) {
    /*                 ^          */
#ifdef F_RDLCK
      *iv_return = F_RDLCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "O_RSYNC", 7)) {
    /*                 ^          */
#ifdef O_RSYNC
      *iv_return = O_RSYNC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "F_SETFD", 7)) {
    /*                 ^          */
#ifdef F_SETFD
      *iv_return = F_SETFD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "F_SETFL", 7)) {
    /*                 ^          */
#ifdef F_SETFL
      *iv_return = F_SETFL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "F_SETLK", 7)) {
    /*                 ^          */
#ifdef F_SETLK
      *iv_return = F_SETLK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "O_TRUNC", 7)) {
    /*                 ^          */
#ifdef O_TRUNC
      *iv_return = O_TRUNC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "F_UNLCK", 7)) {
    /*                 ^          */
#ifdef F_UNLCK
      *iv_return = F_UNLCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'W':
    if (memEQ(name, "F_WRLCK", 7)) {
    /*                 ^          */
#ifdef F_WRLCK
      *iv_return = F_WRLCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "FP_ZERO", 7)) {
    /*                 ^          */
#ifdef FP_ZERO
      *iv_return = FP_ZERO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_8 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     AT_FDCWD F_GETOWN F_SETLKW F_SETOWN NEW_TIME OLD_TIME O_APPEND O_NOCTTY
     O_RDONLY O_SEARCH O_WRONLY RTLD_NOW SEEK_CUR SEEK_END SEEK_SET _CS_PATH */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case 'A':
    if (memEQ(name, "_CS_PATH", 8)) {
    /*                    ^        */
#ifdef _CS_PATH
      *iv_return = _CS_PATH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "AT_FDCWD", 8)) {
    /*                    ^        */
#ifdef AT_FDCWD
      *iv_return = AT_FDCWD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SEEK_CUR", 8)) {
    /*                    ^        */
#ifdef SEEK_CUR
      *iv_return = SEEK_CUR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "O_APPEND", 8)) {
    /*                    ^        */
#ifdef O_APPEND
      *iv_return = O_APPEND;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SEEK_END", 8)) {
    /*                    ^        */
#ifdef SEEK_END
      *iv_return = SEEK_END;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "NEW_TIME", 8)) {
    /*                    ^        */
#ifdef NEW_TIME
      *iv_return = NEW_TIME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "OLD_TIME", 8)) {
    /*                    ^        */
#ifdef OLD_TIME
      *iv_return = OLD_TIME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "F_SETLKW", 8)) {
    /*                    ^        */
#ifdef F_SETLKW
      *iv_return = F_SETLKW;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "O_RDONLY", 8)) {
    /*                    ^        */
#ifdef O_RDONLY
      *iv_return = O_RDONLY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "O_WRONLY", 8)) {
    /*                    ^        */
#ifdef O_WRONLY
      *iv_return = O_WRONLY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "RTLD_NOW", 8)) {
    /*                    ^        */
#ifdef RTLD_NOW
      *iv_return = RTLD_NOW;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "F_GETOWN", 8)) {
    /*                    ^        */
#ifdef F_GETOWN
      *iv_return = F_GETOWN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "F_SETOWN", 8)) {
    /*                    ^        */
#ifdef F_SETOWN
      *iv_return = F_SETOWN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "O_SEARCH", 8)) {
    /*                    ^        */
#ifdef O_SEARCH
      *iv_return = O_SEARCH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "SEEK_SET", 8)) {
    /*                    ^        */
#ifdef SEEK_SET
      *iv_return = SEEK_SET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "O_NOCTTY", 8)) {
    /*                    ^        */
#ifdef O_NOCTTY
      *iv_return = O_NOCTTY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_9 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     BOOT_TIME FP_NORMAL O_ACCMODE O_CLOEXEC O_TMPFILE RTLD_LAZY UTIME_NOW */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case 'A':
    if (memEQ(name, "FP_NORMAL", 9)) {
    /*                      ^       */
#ifdef FP_NORMAL
      *iv_return = FP_NORMAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "O_ACCMODE", 9)) {
    /*                      ^       */
#ifdef O_ACCMODE
      *iv_return = O_ACCMODE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "O_CLOEXEC", 9)) {
    /*                      ^       */
#ifdef O_CLOEXEC
      *iv_return = O_CLOEXEC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "O_TMPFILE", 9)) {
    /*                      ^       */
#ifdef O_TMPFILE
      *iv_return = O_TMPFILE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "BOOT_TIME", 9)) {
    /*                      ^       */
#ifdef BOOT_TIME
      *iv_return = BOOT_TIME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "UTIME_NOW", 9)) {
    /*                      ^       */
#ifdef UTIME_NOW
      *iv_return = UTIME_NOW;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Z':
    if (memEQ(name, "RTLD_LAZY", 9)) {
    /*                      ^       */
#ifdef RTLD_LAZY
      *iv_return = RTLD_LAZY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_10 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     AT_EACCESS FD_CLOEXEC FNM_PERIOD O_NOFOLLOW O_NONBLOCK O_TTY_INIT
     RTLD_LOCAL UTIME_OMIT */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case 'C':
    if (memEQ(name, "RTLD_LOCAL", 10)) {
    /*                      ^         */
#ifdef RTLD_LOCAL
      *iv_return = RTLD_LOCAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "AT_EACCESS", 10)) {
    /*                      ^         */
#ifdef AT_EACCESS
      *iv_return = AT_EACCESS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "FNM_PERIOD", 10)) {
    /*                      ^         */
#ifdef FNM_PERIOD
      *iv_return = FNM_PERIOD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "O_NOFOLLOW", 10)) {
    /*                      ^         */
#ifdef O_NOFOLLOW
      *iv_return = O_NOFOLLOW;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "UTIME_OMIT", 10)) {
    /*                      ^         */
#ifdef UTIME_OMIT
      *iv_return = UTIME_OMIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "O_TTY_INIT", 10)) {
    /*                      ^         */
#ifdef O_TTY_INIT
      *iv_return = O_TTY_INIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "O_NONBLOCK", 10)) {
    /*                      ^         */
#ifdef O_NONBLOCK
      *iv_return = O_NONBLOCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "FD_CLOEXEC", 10)) {
    /*                      ^         */
#ifdef FD_CLOEXEC
      *iv_return = FD_CLOEXEC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_11 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     FNM_NOMATCH FP_INFINITE ITIMER_PROF ITIMER_REAL O_DIRECTORY RTLD_GLOBAL */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'B':
    if (memEQ(name, "RTLD_GLOBAL", 11)) {
    /*                       ^         */
#ifdef RTLD_GLOBAL
      *iv_return = RTLD_GLOBAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "ITIMER_REAL", 11)) {
    /*                       ^         */
#ifdef ITIMER_REAL
      *iv_return = ITIMER_REAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "FP_INFINITE", 11)) {
    /*                       ^         */
#ifdef FP_INFINITE
      *iv_return = FP_INFINITE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "O_DIRECTORY", 11)) {
    /*                       ^         */
#ifdef O_DIRECTORY
      *iv_return = O_DIRECTORY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "ITIMER_PROF", 11)) {
    /*                       ^         */
#ifdef ITIMER_PROF
      *iv_return = ITIMER_PROF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "FNM_NOMATCH", 11)) {
    /*                       ^         */
#ifdef FNM_NOMATCH
      *iv_return = FNM_NOMATCH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_12 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     AT_REMOVEDIR CLOCK_UPTIME DEAD_PROCESS FNM_CASEFOLD FNM_NOESCAPE
     FNM_PATHNAME FP_SUBNORMAL INIT_PROCESS USER_PROCESS */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case 'E':
    if (memEQ(name, "FNM_NOESCAPE", 12)) {
    /*                     ^            */
#ifdef FNM_NOESCAPE
      *iv_return = FNM_NOESCAPE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "FP_SUBNORMAL", 12)) {
    /*                     ^            */
#ifdef FP_SUBNORMAL
      *iv_return = FP_SUBNORMAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "AT_REMOVEDIR", 12)) {
    /*                     ^            */
#ifdef AT_REMOVEDIR
      *iv_return = AT_REMOVEDIR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "DEAD_PROCESS", 12)) {
    /*                     ^            */
#ifdef DEAD_PROCESS
      *iv_return = DEAD_PROCESS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "INIT_PROCESS", 12)) {
    /*                     ^            */
#ifdef INIT_PROCESS
      *iv_return = INIT_PROCESS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "USER_PROCESS", 12)) {
    /*                     ^            */
#ifdef USER_PROCESS
      *iv_return = USER_PROCESS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "FNM_CASEFOLD", 12)) {
    /*                     ^            */
#ifdef FNM_CASEFOLD
      *iv_return = FNM_CASEFOLD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "FNM_PATHNAME", 12)) {
    /*                     ^            */
#ifdef FNM_PATHNAME
      *iv_return = FNM_PATHNAME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "CLOCK_UPTIME", 12)) {
    /*                     ^            */
#ifdef CLOCK_UPTIME
      *iv_return = CLOCK_UPTIME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_13 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     AT_EMPTY_PATH CLOCK_HIGHRES FNM_FILE_NAME LOGIN_PROCESS TIMER_ABSTIME */
  /* Offset 1 gives the best switch position.  */
  switch (name[1]) {
  case 'I':
    if (memEQ(name, "TIMER_ABSTIME", 13)) {
    /*                ^                  */
#ifdef TIMER_ABSTIME
      *iv_return = TIMER_ABSTIME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "CLOCK_HIGHRES", 13)) {
    /*                ^                  */
#ifdef CLOCK_HIGHRES
      *iv_return = CLOCK_HIGHRES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "FNM_FILE_NAME", 13)) {
    /*                ^                  */
#ifdef FNM_FILE_NAME
      *iv_return = FNM_FILE_NAME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "LOGIN_PROCESS", 13)) {
    /*                ^                  */
#ifdef LOGIN_PROCESS
      *iv_return = LOGIN_PROCESS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "AT_EMPTY_PATH", 13)) {
    /*                ^                  */
#ifdef AT_EMPTY_PATH
      *iv_return = AT_EMPTY_PATH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_14 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CLOCK_BOOTTIME CLOCK_REALTIME CLOCK_SOFTTIME ITIMER_VIRTUAL */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'A':
    if (memEQ(name, "CLOCK_REALTIME", 14)) {
    /*                       ^            */
#ifdef CLOCK_REALTIME
      *iv_return = CLOCK_REALTIME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "CLOCK_SOFTTIME", 14)) {
    /*                       ^            */
#ifdef CLOCK_SOFTTIME
      *iv_return = CLOCK_SOFTTIME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "ITIMER_VIRTUAL", 14)) {
    /*                       ^            */
#ifdef ITIMER_VIRTUAL
      *iv_return = ITIMER_VIRTUAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "CLOCK_BOOTTIME", 14)) {
    /*                       ^            */
#ifdef CLOCK_BOOTTIME
      *iv_return = CLOCK_BOOTTIME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_15 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     AT_NO_AUTOMOUNT CLOCK_MONOTONIC FNM_LEADING_DIR F_DUPFD_CLOEXEC */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'K':
    if (memEQ(name, "CLOCK_MONOTONIC", 15)) {
    /*                   ^                 */
#ifdef CLOCK_MONOTONIC
      *iv_return = CLOCK_MONOTONIC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "FNM_LEADING_DIR", 15)) {
    /*                   ^                 */
#ifdef FNM_LEADING_DIR
      *iv_return = FNM_LEADING_DIR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "AT_NO_AUTOMOUNT", 15)) {
    /*                   ^                 */
#ifdef AT_NO_AUTOMOUNT
      *iv_return = AT_NO_AUTOMOUNT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "F_DUPFD_CLOEXEC", 15)) {
    /*                   ^                 */
#ifdef F_DUPFD_CLOEXEC
      *iv_return = F_DUPFD_CLOEXEC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_17 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     AT_SYMLINK_FOLLOW CLOCK_UPTIME_FAST POSIX_FADV_NORMAL POSIX_FADV_RANDOM */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case 'L':
    if (memEQ(name, "POSIX_FADV_NORMA", 16)) {
    /*                               L      */
#ifdef POSIX_FADV_NORMAL
      *iv_return = POSIX_FADV_NORMAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "POSIX_FADV_RANDO", 16)) {
    /*                               M      */
#ifdef POSIX_FADV_RANDOM
      *iv_return = POSIX_FADV_RANDOM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "CLOCK_UPTIME_FAS", 16)) {
    /*                               T      */
#ifdef CLOCK_UPTIME_FAST
      *iv_return = CLOCK_UPTIME_FAST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'W':
    if (memEQ(name, "AT_SYMLINK_FOLLO", 16)) {
    /*                               W      */
#ifdef AT_SYMLINK_FOLLOW
      *iv_return = AT_SYMLINK_FOLLOW;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_19 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     AT_SYMLINK_NOFOLLOW CLOCK_MONOTONIC_RAW CLOCK_REALTIME_FAST
     POSIX_FADV_DONTNEED POSIX_FADV_WILLNEED */
  /* Offset 13 gives the best switch position.  */
  switch (name[13]) {
  case 'E':
    if (memEQ(name, "CLOCK_REALTIME_FAST", 19)) {
    /*                            ^            */
#ifdef CLOCK_REALTIME_FAST
      *iv_return = CLOCK_REALTIME_FAST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "AT_SYMLINK_NOFOLLOW", 19)) {
    /*                            ^            */
#ifdef AT_SYMLINK_NOFOLLOW
      *iv_return = AT_SYMLINK_NOFOLLOW;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "CLOCK_MONOTONIC_RAW", 19)) {
    /*                            ^            */
#ifdef CLOCK_MONOTONIC_RAW
      *iv_return = CLOCK_MONOTONIC_RAW;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "POSIX_FADV_WILLNEED", 19)) {
    /*                            ^            */
#ifdef POSIX_FADV_WILLNEED
      *iv_return = POSIX_FADV_WILLNEED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "POSIX_FADV_DONTNEED", 19)) {
    /*                            ^            */
#ifdef POSIX_FADV_DONTNEED
      *iv_return = POSIX_FADV_DONTNEED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_20 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CLOCK_MONOTONIC_FAST CLOCK_UPTIME_PRECISE _CS_GNU_LIBC_VERSION */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'L':
    if (memEQ(name, "_CS_GNU_LIBC_VERSION", 20)) {
    /*                       ^                  */
#ifdef _CS_GNU_LIBC_VERSION
      *iv_return = _CS_GNU_LIBC_VERSION;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "CLOCK_MONOTONIC_FAST", 20)) {
    /*                       ^                  */
#ifdef CLOCK_MONOTONIC_FAST
      *iv_return = CLOCK_MONOTONIC_FAST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "CLOCK_UPTIME_PRECISE", 20)) {
    /*                       ^                  */
#ifdef CLOCK_UPTIME_PRECISE
      *iv_return = CLOCK_UPTIME_PRECISE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant (pTHX_ const char *name, STRLEN len, IV *iv_return) {
  /* Initially switch on the length of the name.  */
  /* When generated this function returned values for the list of names given
     in this section of perl code.  Rather than manually editing these functions
     to add or remove constants, which would result in this comment and section
     of code becoming inaccurate, we recommend that you edit this section of
     code, and use it to regenerate a new set of constant functions which you
     then use to replace the originals.

     Regenerate these constant functions by feeding this entire source file to
     perl -x

#!/usr/bin/perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(AT_EACCESS AT_EMPTY_PATH AT_FDCWD AT_NO_AUTOMOUNT AT_REMOVEDIR
	       AT_SYMLINK_FOLLOW AT_SYMLINK_NOFOLLOW BOOT_TIME CLOCK_BOOTTIME
	       CLOCK_HIGHRES CLOCK_MONOTONIC CLOCK_MONOTONIC_COARSE
	       CLOCK_MONOTONIC_FAST CLOCK_MONOTONIC_PRECISE CLOCK_MONOTONIC_RAW
	       CLOCK_PROCESS_CPUTIME_ID CLOCK_REALTIME CLOCK_REALTIME_COARSE
	       CLOCK_REALTIME_FAST CLOCK_REALTIME_PRECISE CLOCK_SOFTTIME
	       CLOCK_THREAD_CPUTIME_ID CLOCK_UPTIME CLOCK_UPTIME_FAST
	       CLOCK_UPTIME_PRECISE DEAD_PROCESS FD_CLOEXEC FNM_CASEFOLD
	       FNM_FILE_NAME FNM_LEADING_DIR FNM_NOESCAPE FNM_NOMATCH
	       FNM_PATHNAME FNM_PERIOD FP_INFINITE FP_NAN FP_NORMAL
	       FP_SUBNORMAL FP_ZERO F_DUPFD F_DUPFD_CLOEXEC F_GETFD F_GETFL
	       F_GETLK F_GETOWN F_RDLCK F_SETFD F_SETFL F_SETLK F_SETLKW
	       F_SETOWN F_UNLCK F_WRLCK INIT_PROCESS ITIMER_PROF ITIMER_REAL
	       ITIMER_VIRTUAL LOGIN_PROCESS NEW_TIME OLD_TIME O_ACCMODE
	       O_APPEND O_CLOEXEC O_CREAT O_DIRECTORY O_DSYNC O_EXEC O_NOCTTY
	       O_NOFOLLOW O_NONBLOCK O_RDONLY O_RDWR O_RSYNC O_SEARCH O_SYNC
	       O_TMPFILE O_TRUNC O_TTY_INIT O_WRONLY POSIX_FADV_DONTNEED
	       POSIX_FADV_NOREUSE POSIX_FADV_NORMAL POSIX_FADV_RANDOM
	       POSIX_FADV_SEQUENTIAL POSIX_FADV_WILLNEED RTLD_GLOBAL RTLD_LAZY
	       RTLD_LOCAL RTLD_NOW RUN_LVL SEEK_CUR SEEK_END SEEK_SET
	       TIMER_ABSTIME USER_PROCESS UTIME_NOW UTIME_OMIT
	       _CS_GNU_LIBC_VERSION _CS_GNU_LIBPTHREAD_VERSION _CS_PATH));

print constant_types(), "\n"; # macro defs
foreach (C_constant ("POSIX::2008", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("POSIX::2008", $types);
__END__
   */

  switch (len) {
  case 6:
    return constant_6 (aTHX_ name, iv_return);
    break;
  case 7:
    return constant_7 (aTHX_ name, iv_return);
    break;
  case 8:
    return constant_8 (aTHX_ name, iv_return);
    break;
  case 9:
    return constant_9 (aTHX_ name, iv_return);
    break;
  case 10:
    return constant_10 (aTHX_ name, iv_return);
    break;
  case 11:
    return constant_11 (aTHX_ name, iv_return);
    break;
  case 12:
    return constant_12 (aTHX_ name, iv_return);
    break;
  case 13:
    return constant_13 (aTHX_ name, iv_return);
    break;
  case 14:
    return constant_14 (aTHX_ name, iv_return);
    break;
  case 15:
    return constant_15 (aTHX_ name, iv_return);
    break;
  case 17:
    return constant_17 (aTHX_ name, iv_return);
    break;
  case 18:
    if (memEQ(name, "POSIX_FADV_NOREUSE", 18)) {
#ifdef POSIX_FADV_NOREUSE
      *iv_return = POSIX_FADV_NOREUSE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 19:
    return constant_19 (aTHX_ name, iv_return);
    break;
  case 20:
    return constant_20 (aTHX_ name, iv_return);
    break;
  case 21:
    /* Names all of length 21.  */
    /* CLOCK_REALTIME_COARSE POSIX_FADV_SEQUENTIAL */
    /* Offset 16 gives the best switch position.  */
    switch (name[16]) {
    case 'N':
      if (memEQ(name, "POSIX_FADV_SEQUENTIAL", 21)) {
      /*                               ^           */
#ifdef POSIX_FADV_SEQUENTIAL
        *iv_return = POSIX_FADV_SEQUENTIAL;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'O':
      if (memEQ(name, "CLOCK_REALTIME_COARSE", 21)) {
      /*                               ^           */
#ifdef CLOCK_REALTIME_COARSE
        *iv_return = CLOCK_REALTIME_COARSE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 22:
    /* Names all of length 22.  */
    /* CLOCK_MONOTONIC_COARSE CLOCK_REALTIME_PRECISE */
    /* Offset 12 gives the best switch position.  */
    switch (name[12]) {
    case 'M':
      if (memEQ(name, "CLOCK_REALTIME_PRECISE", 22)) {
      /*                           ^                */
#ifdef CLOCK_REALTIME_PRECISE
        *iv_return = CLOCK_REALTIME_PRECISE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'N':
      if (memEQ(name, "CLOCK_MONOTONIC_COARSE", 22)) {
      /*                           ^                */
#ifdef CLOCK_MONOTONIC_COARSE
        *iv_return = CLOCK_MONOTONIC_COARSE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 23:
    /* Names all of length 23.  */
    /* CLOCK_MONOTONIC_PRECISE CLOCK_THREAD_CPUTIME_ID */
    /* Offset 22 gives the best switch position.  */
    switch (name[22]) {
    case 'D':
      if (memEQ(name, "CLOCK_THREAD_CPUTIME_I", 22)) {
      /*                                     D      */
#ifdef CLOCK_THREAD_CPUTIME_ID
        *iv_return = CLOCK_THREAD_CPUTIME_ID;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'E':
      if (memEQ(name, "CLOCK_MONOTONIC_PRECIS", 22)) {
      /*                                     E      */
#ifdef CLOCK_MONOTONIC_PRECISE
        *iv_return = CLOCK_MONOTONIC_PRECISE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 24:
    if (memEQ(name, "CLOCK_PROCESS_CPUTIME_ID", 24)) {
#ifdef CLOCK_PROCESS_CPUTIME_ID
      *iv_return = CLOCK_PROCESS_CPUTIME_ID;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 26:
    if (memEQ(name, "_CS_GNU_LIBPTHREAD_VERSION", 26)) {
#ifdef _CS_GNU_LIBPTHREAD_VERSION
      *iv_return = _CS_GNU_LIBPTHREAD_VERSION;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

