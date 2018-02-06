#ifndef _GNU_SOURCE
    #define _GNU_SOURCE     /* for canonicalize_file_name */
#endif

#include <ctype.h>      /* is_digit */
#include <dirent.h>     /* opendir, readdir_r */
#include <fcntl.h>
#include <stdbool.h>    /* BOOL */
#include <stdio.h>      /* *scanf family */
#include <stdlib.h>     /* malloc family */
#include <string.h>     /* strchr */
#include <time.h>       /* time_t */
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/vfs.h>    /* statfs */
/* glibc only goodness */
#include <obstack.h>    /* glibc's handy obstacks */
/* ptheads */
#include <pthread.h>    /* pthead_once */

#define obstack_chunk_alloc     malloc
#define obstack_chunk_free      free

#include "os/Linux.h"

/* NOTE: Before this was actually milliseconds even though it said microseconds, now it is correct. */
#define JIFFIES_TO_MICROSECONDS(x) (((x)*1e6)/system_hertz)

/* some static values that won't change, */
static pthread_once_t   globals_init = PTHREAD_ONCE_INIT;

static long long            boot_time;
static unsigned             page_size;
static unsigned long long   system_memory;
static unsigned             system_hertz;

static bool     init_failed = false;


/* get_string()
 *
 * Access strings in read only section
 *
 * @param   elem    String we want to retrive (look at enum strings)
 * @return  Address of string
 */
inline static const char *get_string(int elem)
{
    return strings + strings_index[elem];
}

/* init_static_vars()
 *
 * Called by pthead_once to initlize global variables (system settings that don't change)
 */
static void init_static_vars()
{
    struct obstack      mem_pool;

    char                *file_text, *file_off;
    off_t               file_len;

    unsigned long long  total_memory;

    boot_time = -1;
    system_memory = -1;

    page_size = getpagesize();

    /* initilize our mem stack, tempoary memory */
    obstack_init(&mem_pool);

/* find hertz size, I'm hoping this is gotten from elf note AT_CLKTCK */
    system_hertz = sysconf(_SC_CLK_TCK);

/* find boot time */
    /* read /proc/stat in */
    if ((file_text = read_file("stat", NULL, &file_len, &mem_pool)) == NULL)
        goto fail;

    /* look for the line that starts with btime
     * NOTE: incrementing file_off after strchr is legal because file_text will
     *       be null terminated, so worst case after '\n' there will be '\0' and
     *       strncmp will fail or sscanf won't return 1
     *       Only increment on the first line */
    for (file_off = file_text; file_off; file_off = strchr(file_off, '\n')) {
        if (file_off != file_text)
            file_off++;

        if (strncmp(file_off, "btime", 5) == 0) {
            if (sscanf(file_off, "btime %lld", &boot_time) == 1)
                break;
        }
    }

    obstack_free(&mem_pool, file_text);

    /* did we scrape the number of pages successfuly? */
    if (boot_time == -1)
        goto fail;

/* find total number of system pages */
    /* read /proc/meminfo */
    if ((file_text = read_file("meminfo", NULL, &file_len, &mem_pool)) == NULL)
        goto fail;

    /* look for the line that starts with: MemTotal */
    for (file_off = file_text; file_off; file_off = strchr(file_off, '\n')) {
        if (file_off != file_text)
            file_off++;

        if (strncmp(file_off, "MemTotal:", 9) == 0) {
            if (sscanf(file_off, "MemTotal: %llu", &system_memory) == 1) {
                system_memory *= 1024; /* convert to bytes */
                break;
            }
        }
    }

    obstack_free(&mem_pool, file_text);

    /* did we scrape the number of pages successfuly? */
    if (total_memory == -1)
        goto fail;

/* intilize system hertz value */

/* cleanup */
    obstack_free(&mem_pool, NULL);
    return;

/* mark failure and cleanup allocated resources */
fail:
    obstack_free(&mem_pool, NULL);
    init_failed = true;
}


/* OS_initlize()
 *
 * Called by XS parts whenever Proc::ProcessTable::new is called
 *
 * NOTE: There's a const char* -> char* conversion that's evil, but can't fix
 * this without breaking the Proc::ProcessTable XS API.
 */
char* OS_initialize()
{
    struct statfs sfs;

    /* did we already try to initilize before and fail, if pthrad_once only
     * let us flag a failure from the init function; behavor of longjmp is
     * undefined, so that avaue is out out of the question */
    if (init_failed)
        return (char *) get_string(STR_ERR_INIT);

    /* check if /proc is mounted, let this go before initlizing globals (below),
     * since the missing /proc message might me helpful */
    if(statfs("/proc", &sfs) == -1)
        return (char *) get_string(STR_ERR_PROC_STATFS);

    /* one time initlization of some values that won't change */
    pthread_once(&globals_init, init_static_vars);

    return NULL;
}



inline static void field_enable(char *format_str, enum field field)
{
    format_str[field] = tolower(format_str[field]);
}


inline static void field_enable_range(char *format_str, enum field field1,
    enum field field2)
{
    int i;
    for (i = field1; i <= field2; i++)
        format_str[i] = tolower(format_str[i]);
}

/* proc_pid_file()
 *
 * Build a path to the pid directory in proc '/proc/${pid}' with an optional
 * relative path at the end. Put the resultant path on top of the obstack.
 *
 * @return  Address of the create path string.
 */
inline static char *proc_pid_file(const char *pid, const char *file,
    struct obstack *mem_pool)
{
    /* path to dir */
    obstack_printf(mem_pool, "/proc/%s", pid);

    /* additional path (not just the dir) */
    if (file)
        obstack_printf(mem_pool, "/%s", file);

    obstack_1grow(mem_pool, '\0');

    return (char *) obstack_finish(mem_pool);
}


/* read_file()
 *
 * Reads the contents of a file using an obstack for memory. It can read files like
 * /proc/stat or /proc/${pid}/stat.
 *
 * @param   path        String representing the part following /proc (usualy this is
 *                      the process pid number)
 * @param   etxra_path  Path to the file to read in (relative to /proc/${path}/)
 * @param   len         Pointer to the value where the length will be saved
 *
 * @return  Pointer to a null terminate string allocated on the obstack, or
 *          NULL when it fails (doesn't clean up the obstack).
 */
static char *read_file(const char *path, const char *extra_path,
    off_t *len, struct obstack *mem_pool)
{
    int         fd, result = -1;
    char        *text, *file, *start;

    /* build the filename in our tempoary storage */
    file = proc_pid_file(path, extra_path, mem_pool);

    fd = open(file, O_RDONLY);

    /* free tmp memory we allocated for the file contents, this way we are not
     * poluting the obstack and the only thing left on it is the file */
    obstack_free(mem_pool, file);

    if (fd == -1)
        return NULL;

    /* read file into our buffer */
    for (*len = 0; result; *len += result) {
        obstack_blank(mem_pool, 1024);
        start = obstack_base(mem_pool) + *len;

        if ((result = read(fd, start, 1024)) == -1) {
            obstack_free(mem_pool, obstack_finish(mem_pool));
            close(fd);
            return NULL;
        }
    }

    start = obstack_base(mem_pool) + *len;
    *start = '\0';

    /* finalize our text buffer */
    text = obstack_finish(mem_pool);

    /* not bothering checking return value, because it's possible that the
     * process went away */
    close(fd);

    return text;
}

/* get_user_info()
 *
 * Find the user/group id of the process
 *
 * @param   pid         String representing the pid
 * @param   prs         Data structure where to put the scraped values
 * @param   mem_pool    Obstack to use for temory storage
 */
static void get_user_info(char *pid, char *format_str, struct procstat* prs,
    struct obstack *mem_pool)
{
    char        *path_pid;
    struct stat stat_pid;
    int         result;

    /* (temp) /proc/${pid} */
    path_pid = proc_pid_file(pid, NULL, mem_pool);

    result = stat(path_pid, &stat_pid);

    obstack_free(mem_pool, path_pid);

    if (result == -1)
        return;

    prs->uid = stat_pid.st_uid;
    prs->gid = stat_pid.st_gid;

    field_enable(format_str, F_UID);
    field_enable(format_str, F_GID);
}

/* get_proc_stat()
 *
 * Reads a processes stat file in the proc filesystem '/proc/${pid}/stat' and
 * fills the procstat structure with the values.
 *
 * @param   pid         String representing the pid
 * @param   prs         Data structure where to put the scraped values
 * @param   mem_pool    Obstack to use for temory storage
 */
static bool get_proc_stat(char *pid, char *format_str, struct procstat* prs,
    struct obstack *mem_pool)
{
    char    *stat_text, *stat_cont, *paren;
    int     result;
    off_t   stat_len;
    long    dummy_l;
    int     dummy_i;

    bool    read_ok = true;

    if ((stat_text = read_file(pid, "stat", &stat_len, mem_pool)) == NULL)
        return false;

    /* replace the first ')' with a '\0', the contents look like this:
     *    pid (program_name) state ...
     * if we don't find ')' then it's incorrectly formated */
    if ((paren = strrchr(stat_text, ')')) == NULL) {
        read_ok = false;
        goto done;
    }

    *paren = '\0';

    /* scan in pid, and the command, in linux the command is a max of 15 chars
     * plus a terminating NULL byte; prs->comm will be NULL terminated since
     * that area of memory is all zerored out when prs is allocated */
    if (sscanf(stat_text, "%d (%15c", &prs->pid, prs->comm) != 2)
      /* we might get an empty command name, so check for it:
       * do the open and close parenteses lie next to each other?
       * proceed if yes, finish otherwise
       */
      if((strchr(stat_text,'(') + 1) != paren)
        goto done;

    /* address at which we pickup again, after the ')'
     * NOTE: we don't bother checking bounds since strchr didn't return NULL
     * thus the NULL terminator will be at least paren+1, which is ok */
    stat_cont = paren + 1;

    /* scape the remaining values */
    result = sscanf(stat_cont, " %c %d %d %d %d %d %u %lu %lu %lu %lu %llu"
        " %llu %llu %lld %ld %ld %ld %d %llu %lu %ld %ld %lu %lu %lu %lu %lu"
        " %lu %lu %lu %lu %lu",
        &prs->state_c,                  // %c
        &prs->ppid, &prs->pgrp,         // %d %d
        &prs->sid,                      // %d
        &prs->tty, &dummy_i,                                        /* tty, tty_pgid */
        &prs->flags,                    // %u
        &prs->minflt, &prs->cminflt, &prs->majflt, &prs->cmajflt, // %lu %lu %lu %lu
        &prs->utime, &prs->stime,
        &prs->cutime, &prs->cstime,
        &prs->priority,
        &dummy_l,                                                   /* nice */
        &dummy_l,                                                   /* num threads */
        &dummy_i,                                                   /* timeout obsolete */
        &prs->start_time,
        &prs->vsize, &prs->rss,
        &dummy_l,
        &dummy_l, &dummy_l,
        &dummy_l,
        &dummy_l, &dummy_l,
        &dummy_l, &dummy_l, &dummy_l, &dummy_l,
        &prs->wchan);

    /* 33 items in scanf's list... It's all or nothing baby */
    if (result != 33) {
        read_ok = false;
        goto done;
    }

    /* enable fields; F_STATE is not the range */
    field_enable_range(format_str, F_PID, F_WCHAN);

done:
    obstack_free(mem_pool, stat_text);
    return read_ok;
}


static void eval_link(char *pid, char *link_rel, enum field field, char **ptr,
    char *format_str, struct obstack *mem_pool)
{
    char *link_file, *link;

    /* path to the link file like. /proc/{pid}/{link_rel} */
    link_file = proc_pid_file(pid, link_rel, mem_pool);

    /* It's okay to use canonicalize_file_name instead of readlink on linux
     * for the cwd symlink, since on linux the links we care about will never
     * be relative links (cwd, exec)
     * Doing this because readlink works on static buffers */
    link = canonicalize_file_name(link_file);

    /* we no longer need need the path to the link file */
    obstack_free(mem_pool, link_file);

    if (link == NULL)
        return;

    /* copy the path onto our obstack, set the value (somewhere in pts)
     * and free the results of canonicalize_file_name */
    obstack_printf(mem_pool, "%s", link);
    obstack_1grow(mem_pool, '\0');

    *ptr = (char *) obstack_finish(mem_pool);
    free(link);

    /* enable whatever field we successfuly retrived */
    field_enable(format_str, field);
}


static void get_proc_cmndline(char *pid, char *format_str, struct procstat* prs,
    struct obstack *mem_pool)
{
    char    *cmndline_text, *cur;
    off_t   cmndline_off;

    if ((cmndline_text = read_file(pid, "cmdline", &cmndline_off, mem_pool)) == NULL)
        return;

    /* replace all '\0' with spaces (except for the last one */
    for (cur = cmndline_text; cur < cmndline_text + cmndline_off - 1; cur++) {
        if (*cur == '\0')
            *cur = ' ';
    }

    prs->cmndline = cmndline_text;
    field_enable(format_str, F_CMNDLINE);
}

static void get_proc_cmdline(char *pid, char *format_str, struct procstat* prs,
    struct obstack *mem_pool)
{
    char    *cmdline_text, *cur;
    off_t   cmdline_off;

    if ((cmdline_text = read_file(pid, "cmdline", &cmdline_off, mem_pool)) == NULL)
        return;

    prs->cmdline = cmdline_text;
    prs->cmdline_len = cmdline_off;
    field_enable(format_str, F_CMDLINE);
}

static void get_proc_environ(char *pid, char *format_str, struct procstat* prs,
    struct obstack *mem_pool)
{
    char    *environ_text, *cur;
    off_t   environ_off;

    if ((environ_text = read_file(pid, "environ", &environ_off, mem_pool)) == NULL)
        return;

    prs->environ = environ_text;
    prs->environ_len = environ_off;
    field_enable(format_str, F_ENVIRON);
}

static void get_proc_status(char *pid, char *format_str, struct procstat* prs,
    struct obstack *mem_pool)
{
    char    *status_text, *loc;
    off_t   status_len;
    int     dummy_i;

    if ((status_text = read_file(pid, "status", &status_len, mem_pool)) == NULL)
        return;

    loc = status_text;

    /*
     * get the euid, egid and so on out of /proc/$$/status
     * where the 2 lines in which we are interested in are:
     * [5] Uid:    500     500     500     500
     * [6] Gid:    500     500     500     500
     * added by scip
     */

     for(loc = status_text; loc; loc = strchr(loc, '\n')) {
        /* skip past the \n character */
        if (loc != status_text)
            loc++;

        if (strncmp(loc, "Uid:", 4) == 0) {
            sscanf(loc + 4, " %d %d %d %d", &dummy_i, &prs->euid, &prs->suid, &prs->fuid);
            field_enable_range(format_str, F_EUID, F_FUID);
        } else if (strncmp(loc, "Gid:", 4) == 0) {
            sscanf(loc + 4, " %d %d %d %d", &dummy_i, &prs->egid, &prs->sgid, &prs->fgid);
            field_enable_range(format_str, F_EGID, F_FGID);
        } else if (strncmp(loc, "TracerPid:", 10) == 0) {
            sscanf(loc + 10, " %d", &prs->tracer);
            field_enable(format_str, F_TRACER);
        }

        /* short circuit condition */
        if (islower(format_str[F_EUID]) && islower(format_str[F_EGID]) && islower(format_str[F_TRACER]))
            goto done;
    }

done:
    obstack_free(mem_pool, status_text);
}


/* fixup_stat_values()
 *
 * Correct, calculate, covert values to user expected values.
 *
 * @param   format_str  String containing field index types
 * @param   prs         Data structure to peform fixups on
 */
static void fixup_stat_values(char *format_str, struct procstat* prs)
{
    /* set the state pointer to the right (const) string */
    switch (prs->state_c) {
        case 'S':
            prs->state = get_string(SLEEP);
            break;
        case 'W':
            prs->state = get_string(WAIT); /*Waking state.  Could be mapped to WAKING, but would break backward compatibility */
            break;
        case 'R':
            prs->state = get_string(RUN);
            break;
        case 'I':
            prs->state = get_string(IDLE);
            break;
        case 'Z':
            prs->state = get_string(DEFUNCT);
            break;
        case 'D':
            prs->state = get_string(UWAIT);
            break;
        case 'T':
            prs->state = get_string(STOP);
            break;
        case 'x':
            prs->state = get_string(DEAD);
            break;
        case 'X':
            prs->state = get_string(DEAD);
            break;
        case 'K':
            prs->state = get_string(WAKEKILL);
            break;
        case 't':
            prs->state = get_string(TRACINGSTOP);
            break;
        case 'P':
            prs->state = get_string(PARKED);
            break;
        /* unknown state, state is already set to NULL */
        default:
            ppt_warn("Ran into unknown state (hex char: %x)", (int) prs->state_c);
            goto skip_state_format;
    }

    field_enable(format_str, F_STATE);

skip_state_format:

    prs->start_time = (prs->start_time / system_hertz) + boot_time;

    /* fix time */

    prs->stime      = JIFFIES_TO_MICROSECONDS(prs->stime);
    prs->utime      = JIFFIES_TO_MICROSECONDS(prs->utime);
    prs->cstime     = JIFFIES_TO_MICROSECONDS(prs->cstime);
    prs->cutime     = JIFFIES_TO_MICROSECONDS(prs->cutime);

    /* derived time values */
    prs->time   = prs->utime    + prs->stime;
    prs->ctime  = prs->cutime   + prs->cstime;

    field_enable_range(format_str, F_TIME, F_CTIME);

    /* fix rss to be in bytes (returned from kernel in pages) */
    prs->rss    *= page_size;
}

/* calc_prec()
 *
 * calculate the two cpu/memory precentage values
 */
static void calc_prec(char *format_str, struct procstat *prs, struct obstack *mem_pool)
{
    int len;
    /* calculate pctcpu - NOTE: This assumes the cpu time is in microsecond units!
       multiplying by 1/1e6 puts all units back in seconds.  Then multiply by 100.0f to get a percentage.
    */

    float pctcpu = ( 100.0f * (prs->utime + prs->stime ) * 1/1e6 ) / (time(NULL) - prs->start_time);

    len = snprintf(prs->pctcpu, LENGTH_PCTCPU, "%6.2f", pctcpu);
    if( len >= LENGTH_PCTCPU ) {  ppt_warn("percent cpu truncated from %d, set LENGTH_PCTCPU to at least: %d)", len, len + 1); }


    field_enable(format_str, F_PCTCPU);

    /* calculate pctmem */
    if (system_memory > 0) {
        sprintf(prs->pctmem, "%3.2f", (float) prs->rss / system_memory * 100.f);
        field_enable(format_str, F_PCTMEM);
    }
}

/* is_pid()
 *
 *
 * @return  Boolean value.
 */
inline static bool is_pid(const char* str)
{
    for(; *str; str++) {
        if (!isdigit(*str))
            return false;
    }

    return true;
}

inline static bool pid_exists(const char *str, struct obstack *mem_pool)
{
    char    *pid_dir_path = NULL;
    int     result;

    obstack_printf(mem_pool, "/proc/%s", str);
    obstack_1grow(mem_pool, '\0');
    pid_dir_path = obstack_finish(mem_pool);

    /* directory exists? */
    result = (access(pid_dir_path, F_OK) != -1);

    obstack_free(mem_pool, pid_dir_path);

    return result;
}

void OS_get_table()
{
    /* dir walker storage */
    DIR             *dir;
    struct dirent   *dir_ent, *dir_result;

    /* all our storage is going to be here */
    struct obstack  mem_pool;

    /* container for scaped process values */
    struct procstat *prs;

    /* string containing our local copy of format_str, elements will be
     * lower cased if we are able to figure them out */
    char            *format_str;

    /* initlize a small memory pool for this function */
    obstack_init(&mem_pool);

    /* put the dirent on the obstack, since it's rather large */
    dir_ent = obstack_alloc(&mem_pool, sizeof(struct dirent));

    if ((dir = opendir("/proc")) == NULL)
        return;

    /* Iterate through all the process entries (numeric) under /proc */
    while(readdir_r(dir, dir_ent, &dir_result) == 0 && dir_result) {

        /* Only look at this file if it's a proc id; that is, all numbers */
        if(!is_pid(dir_result->d_name))
            continue;

        /* allocate container for storing process values */
        prs = obstack_alloc(&mem_pool, sizeof(struct procstat));
        bzero(prs, sizeof(struct procstat));

        /* intilize the format string */
        obstack_printf(&mem_pool, "%s", get_string(STR_DEFAULT_FORMAT));
        obstack_1grow(&mem_pool, '\0');
        format_str = (char *) obstack_finish(&mem_pool);

        /* get process' uid/guid */
        get_user_info(dir_result->d_name, format_str, prs, &mem_pool);

        /* scrape /proc/${pid}/stat */
        if (get_proc_stat(dir_result->d_name, format_str, prs, &mem_pool) == false) {
            /* did the pid directory go away mid flight? */
            if (pid_exists(dir_result->d_name, &mem_pool) == false)
                continue;
        }

        /* correct values (times) found in /proc/${pid}/stat */
        fixup_stat_values(format_str, prs);

    /* get process' cmndline */
    get_proc_cmndline(dir_result->d_name, format_str, prs, &mem_pool);

    /* get process' cmdline */
    get_proc_cmdline(dir_result->d_name, format_str, prs, &mem_pool);

    /* get process' environ */
    get_proc_environ(dir_result->d_name, format_str, prs, &mem_pool);

        /* get process' cwd & exec values from the symblink */
        eval_link(dir_result->d_name, "cwd", F_CWD, &prs->cwd, format_str,
            &mem_pool);
        eval_link(dir_result->d_name, "exe", F_EXEC, &prs->exec, format_str,
            &mem_pool);

        /* scapre from /proc/{$pid}/status */
        get_proc_status(dir_result->d_name, format_str, prs, &mem_pool);

        /* calculate precent cpu & mem values */
        calc_prec(format_str, prs, &mem_pool);

        /* Go ahead and bless into a perl object */
        /* Linux.h defines const char* const* Fiels, but we cast it away, as bless_into_proc only understands char** */
        bless_into_proc(format_str, (char**) field_names,
            prs->uid,
            prs->gid,
            prs->pid,
            prs->comm,
            prs->ppid,
            prs->pgrp,
            prs->sid,
            prs->tty,
            prs->flags,
            prs->minflt,
            prs->cminflt,
            prs->majflt,
            prs->cmajflt,
            prs->utime,
            prs->stime,
            prs->cutime,
            prs->cstime,
            prs->priority,
            prs->start_time,
            prs->vsize,
            prs->rss,
            prs->wchan,
        prs->time,
        prs->ctime,
            prs->state,
            prs->euid,
            prs->suid,
            prs->fuid,
            prs->egid,
            prs->sgid,
            prs->fgid,
            prs->pctcpu,
            prs->pctmem,
            prs->cmndline,
            prs->exec,
            prs->cwd,
            prs->cmdline,
            prs->cmdline_len,
            prs->environ,
            prs->environ_len,
            prs->tracer
        );

        /* we want a new prs, for the next itteration */
        obstack_free(&mem_pool, prs);
    }

    closedir(dir);

    /* free all our tempoary memory */
    obstack_free(&mem_pool, NULL);
}

