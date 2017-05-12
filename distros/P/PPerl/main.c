/* pperl - run perl scripts persistently */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include <memory.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <fcntl.h>
#include <limits.h>
#include <signal.h>
#include <unistd.h>
#include "pperl.h"

#include "pass_fd.h" /* the stuff borrowed from stevens */

#define DEBUG 1

/* must never be less than 3 */
#define BUF_SIZE 4096


#ifdef ENOBUFS
#   define NO_BUFSPC(e) ((e) == ENOBUFS || (e) == ENOMEM)
#else
#   define NO_BUFSPC(e) ((e) == ENOMEM)
#endif

static void Usage( char *pName );
static void DecodeParm( char *pArg );
static int  DispatchCall( char *scriptname, int argc, char **argv );

char *pVersion = PPERL_VERSION;
char perl_options[1024];
extern char **environ;
pid_t connected_to;
int kill_script = 0;
int any_user = 0;
int prefork = 5;
int maxclients = 100;
int path_max;
int no_cleanup = 0;
FILE *log_fd = NULL;

#if DEBUG
#define Dx(x) (x)
#else
#define Dx(x)
#endif

static
void Debug( const char * format, ...)
{
    va_list args;
    
    if (!log_fd)
      return;
    
    va_start(args, format);
    vfprintf(log_fd, format, args);
    va_end(args);
    fflush(log_fd);
}


int main( int argc, char **argv )
{
    int i;
    char *pArg;
    int pperl_section = 0;
    int return_code = 0;

    if( argc < 2 )
        Usage( argv[0] );
    
#ifdef PATH_MAX
    path_max = PATH_MAX;
#else
    path_max = pathconf (path, _PC_PATH_MAX);
    if (path_max <= 0) {
        path_max = 4096;
    }
#endif

    pperl_section = 0;
    for ( i = 1; i < argc; i++ ) {
        pArg = argv[i];
        /* fprintf(stderr, "Parsing arg: %s\n", pArg); */
        if (*pArg != '-') break;
        if ( !strcmp(pArg, "-k") || !strcmp(pArg, "--kill") )
            kill_script = 1;
        else if (!strncmp(pArg, "--prefork", 9) ) {
            int newval;
            if (pArg[9] == '=') /* "--prefork=20" */
                pArg += 10;
            else                /* "--prefork" "20" */
                pArg = argv[++i];

            newval = atoi(pArg);
            if (newval > 0) prefork = newval;
        }
        else if (!strncmp(pArg, "--logfile", 7) ) {
            int newval;
            char *filename;
            if (pArg[7] == '=') /* --logfile=.... */
              pArg += 13;
            else
              pArg = argv[++i];
            
            filename = pArg;
            newval = atoi(pArg);
            if (newval == 0) {
              fprintf(stderr, "opening log_fd: %s\n", filename);
              log_fd = fopen(filename, "a");
              if (!log_fd) {
                perror("Cannot open logfile");
                exit(1);
              }
            }
            else {
              log_fd = fdopen(newval, "a");
              if (!log_fd) {
                perror("fd for --logfile error");
                exit(1);
              }
            }
        }
        else if (!strncmp(pArg, "--no-cleanup", 12) ) {
            no_cleanup = 1;
        }
        else if (!strncmp(pArg, "--maxclients", 12) ) {
            int newval;
            if (pArg[12] == '=') /* "--maxclients=20" */
                pArg += 13;
            else                /* "--maxclients" "20" */
                pArg = argv[++i];

            newval = atoi(pArg);
            if (newval > 0) maxclients = newval;
        }
        else if ( !strcmp(pArg, "-z") || !strcmp(pArg, "--anyuser") )
            any_user = 1;
        else if ( !strcmp(pArg, "-h") || !strcmp(pArg, "--help") )
            Usage( NULL );
        else if ( !strncmp(pArg, "--", 2) )
            ; /* do nothing - backward compatibility */
        else {
            DecodeParm( pArg );
        }
    }
    
    i++;
    return_code = DispatchCall( pArg, argc - i, (char**)(argv + i) );
    Dx(Debug("done, returning %d\n", return_code));
    if (log_fd) fclose(log_fd);
    return return_code;
}

static void DecodeParm( char *pArg )
{
    if ( (strlen(perl_options) + strlen(pArg) + 1) > 1000 ) {
        fprintf(stderr, "param list too long. Sorry.");
        exit(1);
    }
    strcat(perl_options, pArg);
    strcat(perl_options, " ");
}

static void Usage( char *pName )
{
    printf( "pperl version %s\n", pVersion );

    if( pName == NULL )
    {
        printf( "Usage: pperl [options] filename\n" );
    }
    else
    {
        printf( "Usage: %.255s [options] filename\n", pName );
    }
    printf("perl options are passed to your perl executable (see the perlrun man page).\n"
           "pperl options control the persistent perl behaviour\n"
           "\n"
           "PPerl Options:\n"
           "  -k  or --kill      Kill the currently running pperl for that script\n"
           "  -h  or --help      This page\n"
	   "  --prefork          The number of child processes to prefork (default=5)\n"
	   "  --maxclients       The number of client connections each child\n"
	   "                       will process (default=100)\n"
           "  -z  or --anyuser   Allow any user (after the first) to access the socket\n"
           "                       WARNING: This has severe security implications. Use\n"
	   "                       at your own risk\n"
           "  --no-cleanup       Skip the cleanup stage at the end of running your script\n"
           "                       this may make your code run faster, but if you forget\n"
           "                       to close files then they will remain unflushed and unclosed\n"
    );
    exit( 1 );
}

static void *
my_malloc(size_t size)
{
    void *mem = malloc(size);
    if (mem == NULL) {
        perror("malloc failed");
        exit(-1);
    }
    return mem;
}

/* make socket name from scriptname, switching / for _ */
static char *
MakeSockName(char * scriptname )
{
    char * sockname;
    char * save;
    /* strict C compilers can't/won't do char foo[variant]; */
    char *fullpath = my_malloc(path_max);
    int i = 0;

    if (realpath(scriptname, fullpath) == NULL) {
        perror("pperl: resolving full pathname to script failed");
        exit(1);
    }
    Dx(Debug("realpath returned: %s\n", fullpath));
    /* Ugh. I am a terrible C programmer! */
    sockname = my_malloc(strlen(P_tmpdir) + strlen(fullpath) + 3);
    save = sockname;
    sprintf(sockname, "%s/", P_tmpdir);
    sockname += strlen(P_tmpdir) + 1;
    while (fullpath[i] != '\0') {
        if (fullpath[i] == '/') {
            *sockname = '_';
        }
        else if (fullpath[i] == '.') {
            *sockname = '_';
        }
        else {
            *sockname = fullpath[i];
        }
        sockname++; i++;
    }
    *sockname = '\0';
    free(fullpath);
    return save;
}


static void
sig_handler(int sig)
{
    kill(connected_to, sig);
    signal(sig, sig_handler);
    /* skreech_to_a_halt++; */
}

static int handle_socket(int sd, int argc, char **argv );
static int DispatchCall( char *scriptname, int argc, char **argv )
{
    register int i, sd, len;
    int error_number;
    ssize_t readlen;
    struct sockaddr_un saun;
    struct stat stat_buf;
    struct stat sock_stat;
    char *sock_name;
    char buf[BUF_SIZE];
    int respawn_script = 0;
	sd = 0;

    /* create socket name */
    Dx(Debug("pperl: %s\n", scriptname));
    sock_name = MakeSockName(scriptname);
    Dx(Debug("got socket: %s\n", sock_name));

    if (!stat(sock_name, &sock_stat) && !stat(scriptname, &stat_buf)) {
        if (stat_buf.st_mtime >= sock_stat.st_mtime) {
            respawn_script = 1;
            Dx(Debug("respawning slave - top level script changed\n"));
        } 
    }
    
    if (kill_script || respawn_script) {
        int pid_fd, sock_name_len;
        char *pid_file;
        pid_t pid = 0;
        
        respawn_script = 0; /* reset so we can use it later :-) */
	
        sock_name_len = strlen(sock_name);
        pid_file = my_malloc(sock_name_len + 5);
        strncpy(pid_file, sock_name, sock_name_len);
        pid_file[sock_name_len] = '.';
        pid_file[sock_name_len+1] = 'p';
        pid_file[sock_name_len+2] = 'i';
        pid_file[sock_name_len+3] = 'd';
        pid_file[sock_name_len+4] = '\0';
        
        Dx(Debug("opening pid_file: %s\n", pid_file));
        pid_fd = open(pid_file, O_RDONLY);
        if (pid_fd == -1) {
            Dx(Debug("Cannot open pid file (perhaps PPerl wasn't running for that script?)\n"));
            write(1, "No process killed - no pid file\n", 32);
            goto killed;
        }
        
        readlen = read(pid_fd, buf, BUF_SIZE);
        if (readlen == -1) {
            perror("pperl: nothing in pid file?");
            goto killed;
        }
        buf[readlen] = '\0';
        
        close(pid_fd);
        
        pid = atoi(buf);
        Dx(Debug("got pid %d (%s)\n", pid, buf));
        if (kill(pid, SIGINT) == -1) {
            if (errno == ESRCH) {
                perror("pperl kill");
                Dx(Debug("Process didn't exist. Unlinking %s and %s\n", pid_file, sock_name));
                unlink(pid_file);
                unlink(sock_name);
            }
            else {
                perror("pperl: could not kill process");
            }
        }
        
        free(pid_file);

    killed:
    
        if (kill_script) {
            free(sock_name); /* Hmm, should probably do this everywhere else we return too */
            return 0;
        }
        
        if (pid != 0) {
            /* cheesy - let the child go away proper */
            while (!kill(pid, 0)) {}
        }
    }
    
    for (i = 0; i < 10; i++) {
        sd = socket(PF_UNIX, SOCK_STREAM, PF_UNSPEC);
        if (sd != -1) {
            break;
        }
        else if (NO_BUFSPC(errno)) {
            sleep(1);
        }
        else {
            perror("pperl: Couldn't create socket");
            return 1;
        }
    }

    saun.sun_family = PF_UNIX;
    strcpy(saun.sun_path, sock_name);

    len = sizeof(saun.sun_family) + strlen(saun.sun_path) + 1;

    Dx(Debug("%d connecting\n", getpid()));

    if (stat((const char*)sock_name, &stat_buf)) {
        if (errno == ENOENT) {
            /* socket doesn't exist. good */
            Dx(Debug("socket doesn't exist yet (good)\n"));
        }
        else {
            perror("Socket stat error");
            exit(1);
        }
    }
    
    /* is there a race between stat() and connect() here? Or is it irrelevant? */
    
    if (connect(sd, (struct sockaddr *)&saun, len) < 0) {
        /* Consider spawning Perl here and try again */
        FILE *source;
        int tmp_fd;
        char temp_file[BUF_SIZE];
        char *lock_file;
        int sock_name_len;
        int lock_fd;
        int start_checked = 0;
        int wrote_footer = 0; /* we may encounter __END__ or __DATA__ */
        int line;
        int retry_connect = 0;
        int exit_code = 0;

        int pid, itmp, exitstatus;
        sigset_t mask, omask;

        Dx(Debug("Couldn't connect, spawning new server: %s\n", strerror(errno)));
        
        sock_name_len = strlen(sock_name);
        lock_file = my_malloc(sock_name_len + 6);
        strncpy(lock_file, sock_name, sock_name_len);
        lock_file[sock_name_len] = '.';
        lock_file[sock_name_len+1] = 'l';
        lock_file[sock_name_len+2] = 'o';
        lock_file[sock_name_len+3] = 'c';
        lock_file[sock_name_len+4] = 'k';
        lock_file[sock_name_len+5] = '\0';
        
        Dx(Debug("opening lock_file: %s\n", lock_file));
        lock_fd = open(lock_file, O_CREAT|O_WRONLY, S_IRUSR|S_IWUSR);
        if (lock_fd == -1) {
            perror("Cannot open lock file");
            exit_code = 1;
            goto cleanup;
        }
        while (flock(lock_fd, LOCK_EX|LOCK_NB) == -1) {
            Dx(Debug("flock failed - someone else is probably waiting to spawn - sleeping\n"));
            retry_connect = 1;
            sleep(1);
        }
        
        if (retry_connect) {
            if (connect(sd, (struct sockaddr *)&saun, len) >= 0) {
                goto cleanup; /* everything is now OK! */
            }
            /* otherwise we try ourselves to re-spawn */
        }
        
        /*
        if (unlink(sock_name) != 0 && errno != ENOENT) {
            perror("pperl: removal of old socket failed");
            exit_code = 1;
            goto cleanup;
        }
        */
        
        /* Create temp file with adjusted script... */
        if (!(source = fopen(scriptname, "r"))) {
            perror("pperl: Cannot open perl script");
            exit_code = 1;
            goto cleanup;
        }

        snprintf(temp_file, BUF_SIZE, "%s/%s", P_tmpdir, "pperlXXXXXX");
        tmp_fd = mkstemp(temp_file);
        if (tmp_fd == -1) {
            perror("pperl: Cannot create temporary file");
            exit_code = 1;
            goto cleanup;
        }
            
        write(tmp_fd, "### Temp File ###\n", 18);
        write(tmp_fd, perl_header, strlen(perl_header));

        /* rewrite the perl script with pperl.h.header contents wrapper
           and do some other fixups in the process */
        line = 0;
        while ( fgets( buf, BUF_SIZE, source ) ) {
            readlen = strlen(buf);
            Dx(Debug("read '%s' %d \n", buf, readlen));

            if (!start_checked) { /* first line */
                start_checked = 1;

                if (buf[0] == '#' && buf[1] == '!') { 
                    char *args;
                    /* solaris sometimes doesn't propogate all the
                     * shebang line  - so we do that here */
                    if ( (args = strstr(buf, " ")) ) {
                        strncat(perl_options, args, strlen(args) - 1);
                    }

                    write(tmp_fd, "\n#line 2 ", 9);
                    write(tmp_fd, scriptname, strlen(scriptname));
                    write(tmp_fd, "\n", 1);

                    line = 2;
                    continue;
                }
                else {
                    write(tmp_fd, "\n#line 1 ", 9);
                    write(tmp_fd, scriptname, strlen(scriptname));
                    write(tmp_fd, "\n", 1);
                }
            }
            if ((!strcmp(buf, "__END__\n") || 
                 !strcmp(buf, "__DATA__\n")) &&
                !wrote_footer) {
                char text_line[BUF_SIZE];
                wrote_footer = 1;
                write(tmp_fd, perl_footer, strlen(perl_footer));
                snprintf(text_line, BUF_SIZE, "package main;\n#line %d %s\n", line, scriptname);
                write(tmp_fd, text_line, strlen(text_line));
            }
            write(tmp_fd, buf, readlen);
            if (buf[readlen] == '\n') ++line;
        }
        
        if (fclose(source)) { 
            perror("pperl: Error reading perl script");
            exit_code = 1;
            goto cleanup;
        }

        if (!wrote_footer) 
            write(tmp_fd, perl_footer, strlen(perl_footer));

        Dx(Debug("wrote file %s\n", temp_file));

        close(tmp_fd);

        /*** Temp file creation done ***/

        snprintf(buf, BUF_SIZE, "%s %s %s %s %d %d %d %d %s", 
                 PERL_INTERP, perl_options, temp_file,
                 sock_name, prefork, maxclients, 
                 any_user, no_cleanup, scriptname);
        Dx(Debug("syscall: %s\n", buf));

        /* block SIGCHLD so noone else can wait() on the child before we do */
        sigemptyset(&mask);
        sigaddset(&mask, SIGCHLD);
        sigprocmask(SIG_BLOCK, &mask, &omask);

        if ((pid = system(buf)) != 0) {
            unlink(temp_file);
            if (stat((const char*)sock_name, &stat_buf) == 0) {
                /* socket exists - perhaps we should just try and connect to it? */
                /* possible cause is a race condition. So ignore this and just try
                   the connect() call again. */
                perror("pperl: perl script failed to start, but lets be gung-ho and try and connect again anyway!");
            }
            perror("pperl: perl script failed to start");
            exit_code = 1;
            goto cleanup;
        }
        else {
          Dx(Debug("waiting for perl to return...\n"));
          while ((itmp = waitpid(0, &exitstatus, 0)) == -1 && errno == EINTR)
              ;
          sigprocmask(SIG_SETMASK, &omask, NULL);
          Dx(Debug("returned.\n"));
    
          /* now remove the perl script */
          unlink(temp_file);
        }
        
        /* try and connect to the new socket */
        while ((i++ <= 30) && (connect(sd, (struct sockaddr *)&saun, len) < 0))
        {
            Dx(Debug("."));
            sleep(1);
        }
        if (i >= 30) {
            /* If we really *really* couldn't connect, try and delete the socket if it exists */
            if (unlink(sock_name) != 0 && errno != ENOENT) {
                perror("pperl: removal of old socket failed");
            }
            perror("pperl: persistent perl process failed to start after 30 seconds");
            exit_code = 1;
            goto cleanup;
        }
        
        Dx(Debug("Connected\n"));
        
    cleanup:
        flock(lock_fd, LOCK_UN);
        close(lock_fd);
        free(lock_file);
        if (exit_code > 0) {
            free(sock_name);
            exit(exit_code);
        }
    }
    
    free(sock_name);
    return handle_socket(sd, argc, argv);
}

static 
int 
handle_socket(int sd, int argc, char **argv) {
    long max_fd;
    char **env;
    int i;
    char buf[BUF_SIZE];

    Dx(Debug("connected over %d\n", sd));

    read(sd, buf, 10);
    buf[10] = '\0';
    connected_to = atoi(buf);
    Dx(Debug("chatting to %d, hooking signals\n", connected_to));

    /* bad magic number, there only seem to be 30 signals on a linux
     * box -- richardc*/
    for (i = 1; i < 32; i++) 
        signal(i, sig_handler);


    Dx(Debug("sending fds\n"));
    if ((max_fd = sysconf(_SC_OPEN_MAX)) < 0) {
        perror("pperl: dunno how many fds to check");
        exit(1);
    }

    for (i = 0; i < max_fd; i++) {
        if (fcntl(i, F_GETFL, -1) >= 0 && i != sd) {
            int ret;
            write(sd, &i, sizeof(int));
            ret = send_fd(sd, i);
            Dx(Debug("send_fd %d %d\n", i, ret));
        }
    }
    i = -1;
    write(sd, &i, sizeof(int));
    Dx(Debug("fds sent\n"));

    write(sd, "[PID]", 6);
    snprintf(buf, BUF_SIZE, "%d", getpid());
    write(sd, buf, strlen(buf) + 1);

    
    /* print to socket... */
    write(sd, "[ENV]", 6);
    for (i= 0, env = environ; *env; i++, env++); 
    snprintf(buf, BUF_SIZE, "%d", i);
    write(sd, buf, strlen(buf) + 1);
    
    while ( *environ != NULL ) {
        size_t len = strlen(*environ) + 1;
        /* Dx(Debug("sending environ: %s\n", *environ)); */
        write(sd, *environ, len);
        environ++;
    }

    write(sd, "[CWD]", 6);
    if (getcwd(buf, BUF_SIZE) == NULL) {
        perror("pperl: getcwd");
        exit (1);
    }
    write(sd, buf, strlen(buf) + 1);

    Dx(Debug("sending %d args\n", argc));
    write(sd, "[ARGV]", 7);
    snprintf(buf, BUF_SIZE, "%d", argc);
    write(sd, buf, strlen(buf) + 1);
    for (i = 0; i < argc; i++) {
        size_t len = strlen(argv[i]) + 1;
        Dx(Debug("sending argv[%d]: '%s'\n", i, argv[i]));
        write(sd, argv[i], len);
    }

    write(sd, "[DONE]", 7);

    Dx(Debug("waiting for OK message from %d\n", sd));
    if (read(sd, buf, 3) != 3) {
        perror("pperl: failed to read 3 bytes for an OK message");
        exit(1);
    }
    if (strncmp(buf, "OK\n", 3)) {
        i = read(sd, buf, BUF_SIZE - 1);
        buf[i] = '\0';
        fprintf(stderr, "pperl: expected 'OK\\n', got: '%s'\n", buf);
        exit(1);
    }
    Dx(Debug("got it\n"));

    Dx(Debug("reading return code\n"));
    i = read(sd, buf, BUF_SIZE - 1);
    if (i == -1) {
      perror("Nothing read back from socket!");
    }
    buf[i] = '\0';
    Dx(Debug("socket read '%s'\n", buf));

    for (i = 0; i < max_fd; i++) {
        close(i);
    }
    
    exit (atoi(buf));
}



/* 
Local Variables:
mode: C
c-basic-offset: 4
tab-width: 4
indent-tabs-mode: nil
End:
*/
