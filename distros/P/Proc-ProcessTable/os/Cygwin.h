#define LENGTH_PCTCPU 10  /* Maximum percent cpu sufficient to hold 100000.00 or up to 1000 cpus  */
/* Proc::ProcessTable functions */
void ppt_warn(const char*, ...);
void bless_into_proc(char* , char**, ...);

/* it also gets used by init_static_vars at the way top of the file,
 * I wanted init_static_vars to be at the way top close to the global vars */
static char *read_file(const char *path, const char *extra_path, off_t *len,
    struct obstack *mem_pool);

struct procstat
{
  /* user/group id of the user running it */
  int                   uid;
  int                   gid;
  /* values scraped from /proc/{$pid}/stat */
  pid_t                 pid;
  char                	comm[NAME_MAX];
  char                	state_c;
  int                 	ppid;
  int                 	pgrp;
  int                 	sid;
  int                 	tty;
  unsigned            	flags;
  unsigned long       	minflt, cminflt, majflt, cmajflt;
  unsigned long long  	utime, stime;
  long long           	cutime, cstime;
  long                	priority;
  unsigned long long  	start_time;
  unsigned long       	vsize;
  long                	rss;
  /* these are derived from above time values */
  unsigned long long    time, ctime;
  /* from above state_c but fixed up elsewhere */
  const char           *state;
  /* values scraped from /proc/{$pid}/status */
  int                   euid, suid, fuid;
  int                   egid, sgid, fgid;
  /* cwd, cmdline & exec files; values allocated at the end of obstacks */
  char                 *cwd;
  char                 *cmndline;
  char                 *cmdline;
  int                   cmdline_len;
  char                 *environ;
  int                   environ_len;
  char                 *exec;
  /* other values */
  char                  pctcpu[LENGTH_PCTCPU];    /* percent cpu, without '%' char */
  char                  pctmem[sizeof("100.00")]; /* percent memory, without '%' char */
  /* extra Windows stuff */
  char                 *winexename;
  int                   winpid;
};


enum state
{
    SLEEP,
    RUN,
    DEFUNCT,
    STOP,
    UWAIT,
};


/* strings, to make sure they get placed in read only memory,
 * ditto for pointers to them and so we avoid relocations */
static const char strings[] =
{
  /* process state */
  "sleep\0"
  "run\0"
  "defunct\0"
  "stop\0"
  "uwait\0"
  /* error messages */
  "/proc unavailable\0"
  "initialization failed\0"
  /* fields */
  "uid\0"
  "gid\0"
  "pid\0"
  "fname\0"
  "ppid\0"
  "pgrp\0"
  "sess\0"
  "ttynum\0"
  "flags\0"
  "minflt\0"
  "cminflt\0"
  "majflt\0"
  "cmajflt\0"
  "utime\0"
  "stime\0"
  "cutime\0"
  "cstime\0"
  "priority\0"
  "start\0"
  "size\0"
  "rss\0"
  "time\0"
  "ctime\0"
  "state\0"
  "euid\0"
  "suid\0"
  "fuid\0"
  "egid\0"
  "sgid\0"
  "fgid\0"
  "pctcpu\0"
  "pctmem\0"
  "cmndline\0"
  "exec\0"
  "cwd\0"
  "cmdline\0"
  "environ\0"
  "winexename\0"
  "winpid\0"
  /* format string */
  "IIISIIIILLLLLJJJJIJPLJJSIIIIIISSSSSAASI\0"
};

static const size_t strings_index[] =
{
  /* process status strings */
    0, /*  6 sleep */
    6, /*  4 run */
   10, /*  8 defunct */
   18, /*  5 stop */
   23, /*  6 uwait */
  /* error messages */
   29, /* 18 /proc unavailable */
   47, /* 22 initialization failed */
  /* fields */
   69, /*  4 uid */
   73, /*  4 gid */
   77, /*  4 pid */
   81, /*  6 fname */
   87, /*  5 ppid */
   92, /*  5 pgrp */
   97, /*  5 sess */
  102, /*  7 ttynum */
  109, /*  6 flags */
  115, /*  7 minflt */
  122, /*  8 cminflt */
  130, /*  7 majflt */
  137, /*  8 cmajflt */
  145, /*  6 utime */
  151, /*  6 stime */
  157, /*  7 cutime */
  164, /*  7 cstime */
  171, /*  9 priority */
  180, /*  6 start */
  186, /*  5 size */
  191, /*  4 rss */
  195, /*  5 time */
  200, /*  6 ctime */
  206, /*  6 state */
  212, /*  5 euid */
  217, /*  5 suid */
  222, /*  5 fuid */
  227, /*  5 egid */
  232, /*  5 sgid */
  237, /*  5 fgid */
  242, /*  7 pctcpu */
  249, /*  7 pctmem */
  256, /*  9 cmndline */
  265, /*  5 exec */
  270, /*  4 cwd */
  274, /*  8 cmdline */
  282, /*  8 environ */
  290, /* 11 winexename */
  301, /*  7 winpid */
  /* default format string (pre lower casing) */
  308
};


enum string_name {
    /* NOTE: we start this enum at 10, so we can use still keep using the
     * state enum, and have those correspond to the static strings */
/* error messages */
    STR_ERR_PROC_STATFS = 5,
    STR_ERR_INIT,
/* fields */
    STR_FIELD_UID,
    STR_FIELD_GID,
    STR_FIELD_PID,
    STR_FIELD_FNAME,
    STR_FIELD_PPID,
    STR_FIELD_PGRP,
    STR_FIELD_SESS,
    STR_FIELD_TTYNUM,
    STR_FIELD_FLAGS,
    STR_FIELD_MINFLT,
    STR_FIELD_CMINFLT,
    STR_FIELD_MAJFLT,
    STR_FIELD_CMAJFLT,
    STR_FIELD_UTIME,
    STR_FIELD_STIME,
    STR_FIELD_CUTIME,
    STR_FIELD_CSTIME,
    STR_FIELD_PRIORITY,
    STR_FIELD_START,
    STR_FIELD_SIZE,
    STR_FIELD_RSS,
    STR_FIELD_TIME,
    STR_FIELD_CTIME,
    STR_FIELD_STATE,
    STR_FIELD_EUID,
    STR_FIELD_SUID,
    STR_FIELD_FUID,
    STR_FIELD_EGID,
    STR_FIELD_SGID,
    STR_FIELD_FGID,
    STR_FIELD_PCTCPU,
    STR_FIELD_PCTMEM,
    STR_FIELD_CMNDLINE,
    STR_FIELD_EXEC,
    STR_FIELD_CWD,
    STR_FIELD_CMDLINE,
    STR_FIELD_ENVIRON,
    STR_FIELD_WINEXENAME,
    STR_FIELD_WINPID,
/* format string */
    STR_DEFAULT_FORMAT
};


enum field
{
    F_UID,
    F_GID,
    F_PID,
    F_FNAME,
    F_PPID,
    F_PGRP,
    F_SESS,
    F_TTYNUM,
    F_FLAGS,
    F_MINFLT,
    F_CMINFLT,
    F_MAJFLT,
    F_CMAJFLT,
    F_UTIME,
    F_STIME,
    F_CUTIME,
    F_CSTIME,
    F_PRIORITY,
    F_START,
    F_SIZE,
    F_RSS,
    F_TIME,
    F_CTIME,
    F_STATE,
    F_EUID,
    F_SUID,
    F_FUID,
    F_EGID,
    F_SGID,
    F_FGID,
    F_PCTCPU,
    F_PCTMEM,
    F_CMNDLINE,
    F_EXEC,
    F_CWD,
    F_CMDLINE,
    F_ENVIRON,
    F_WINEXENAME,
    F_WINPID
};

static const char* const field_names[] =
{
    strings +   69, /*  4 uid */
    strings +   73, /*  4 gid */
    strings +   77, /*  4 pid */
    strings +   81, /*  6 fname */
    strings +   87, /*  5 ppid */
    strings +   92, /*  5 pgrp */
    strings +   97, /*  5 sess */
    strings +  102, /*  7 ttynum */
    strings +  109, /*  6 flags */
    strings +  115, /*  7 minflt */
    strings +  122, /*  8 cminflt */
    strings +  130, /*  7 majflt */
    strings +  137, /*  8 cmajflt */
    strings +  145, /*  6 utime */
    strings +  151, /*  6 stime */
    strings +  157, /*  7 cutime */
    strings +  164, /*  7 cstime */
    strings +  171, /*  9 priority */
    strings +  180, /*  6 start */
    strings +  186, /*  5 size */
    strings +  191, /*  4 rss */
    strings +  195, /*  5 time */
    strings +  200, /*  6 ctime */
    strings +  206, /*  6 state */
    strings +  212, /*  5 euid */
    strings +  217, /*  5 suid */
    strings +  222, /*  5 fuid */
    strings +  227, /*  5 egid */
    strings +  232, /*  5 sgid */
    strings +  237, /*  5 fgid */
    strings +  242, /*  7 pctcpu */
    strings +  249, /*  7 pctmem */
    strings +  256, /*  9 cmndline */
    strings +  265, /*  5 exec */
    strings +  270, /*  4 cwd */
    strings +  274, /*  8 cmdline */
    strings +  282, /*  8 environ */
    strings +  290, /* 11 winexename */
    strings +  301, /*  7 winpid */
};
