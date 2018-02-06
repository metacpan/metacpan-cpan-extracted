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
    int             uid;
    int             gid;
    /* values scraped from /proc/{$pid}/stat */
    pid_t               pid;
    char                comm[16];                   /* limit in kernel, likewise in procps */
    char                state_c;
    int                 ppid;
    int                 pgrp;
    int                 sid;
    int                 tracer;
    int                 tty;
    unsigned            flags;
    unsigned long       minflt, cminflt, majflt, cmajflt;
    unsigned long long  utime, stime;
    long long           cutime, cstime;
    long                priority;
    unsigned long long  start_time;
    unsigned long       vsize;
    long                rss;
    unsigned long       wchan;
    /* these are derived from above time values */
    unsigned long long  time, ctime;
    /* from above state_c but fixed up elsewhere */
    const char      *state;
    /* values scraped from /proc/{$pid}/status */
    int             euid, suid, fuid;
    int             egid, sgid, fgid;
    /* cwd, cmdline & exec files; values allocated at the end of obstacks */
    char            *cwd;
    char            *cmndline;
    char            *cmdline;
    int         cmdline_len;
    char            *environ;
    int         environ_len;
    char            *exec;
    /* other values */
    char            pctcpu[LENGTH_PCTCPU];  /* precent cpu, without '%' char */
    char            pctmem[sizeof("100.00")];   /* precent memory, without '%' char */
};


enum state
{
    SLEEP,
    WAIT,
    RUN,
    IDLE,
    DEFUNCT,
    STOP,
    UWAIT,
    DEAD,
    WAKEKILL,
    TRACINGSTOP,
    PARKED
};


/* strings, to make sure they get placed in read only memory,
 * ditto for pointers to them and so we avoid relocations */
static const char strings[] =
{
/* process state */
    "sleep\0"
    "wait\0"
    "run\0"
    "idle\0"
    "defunct\0"
    "stop\0"
    "uwait\0"
    "dead\0"
    "wakekill\0"
    "tracingstop\0"
/* error messages */
    "/proc unavailable\0"
    "intilization failed\0"
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
    "wchan\0"
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
    "tracer\0"
/* format string */
    "IIISIIIILLLLLJJJJIJPLLJJSIIIIIISSSSSAAI\0"
};

/* I generated this array with a perl script processing the above char array,
 * and then performed cross string optimization (by hand) for:
 *      pid,    time,   uid,    gid,    minflt,     majflt,
 */
static const size_t strings_index[] =
{
    /* process status strings */
    0,
    6,
    11,
    15,
    20,
    28,
    33,
    39,
    44,
    53,
    /* error messages */
    65,
    83,
    /* fields */
    103,
    107,
    111,
    115,
    121,
    126,
    131,
    136,
    143,
    149,
    156,
    164,
    171,
    179,
    185,
    191,
    198,
    205,
    214,
    220,
    225,
    229,
    235,
    240,
    246,
    252,
    257,
    262,
    267,
    272,
    277,
    282,
    289,
    296,
    305,
    310,
    314,
    322,
    330,
    /* default format string (pre lower casing) */
    337
};


enum string_name {
    /* NOTE: we start this enum at 10, so we can use still keep using the
     * state enum, and have those correspond to the static strings */
/* error messages */
    STR_ERR_PROC_STATFS = 10,
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
    STR_FIELD_WCHAN,
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
    STR_FIELD_ENIVORN,
    STR_FIELD_TRACER,
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
    F_WCHAN,
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
    F_TRACER
};



static const char* const field_names[] =
{
    strings + 103,
    strings + 107,
    strings + 111,
    strings + 115,
    strings + 121,
    strings + 126,
    strings + 131,
    strings + 136,
    strings + 143,
    strings + 149,
    strings + 156,
    strings + 164,
    strings + 171,
    strings + 179,
    strings + 185,
    strings + 191,
    strings + 198,
    strings + 205,
    strings + 214,
    strings + 220,
    strings + 225,
    strings + 229,
    strings + 235,
    strings + 240,
    strings + 246,
    strings + 252,
    strings + 257,
    strings + 262,
    strings + 267,
    strings + 272,
    strings + 277,
    strings + 282,
    strings + 289,
    strings + 296,
    strings + 305,
    strings + 310,
    strings + 314,
    strings + 322,
    strings + 330
};

