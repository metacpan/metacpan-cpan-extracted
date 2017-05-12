/* vim: set expandtab sts=4: */
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <pthread.h>
#include <unistd.h>

typedef struct watchdog_s {
    int fd;
    int timeout;
} watchdog_t;

/* wait for file to be closed and then kill the current process */
void*
watchdog(void* param) {
    char buf[64];
    size_t n;
    sigset_t ss;
    struct timeval tv;
    watchdog_t *wdt = (watchdog_t*) param;
    int pid = getpid();

    sigfillset(&ss);
    pthread_sigmask(SIG_BLOCK, &ss, NULL);

    /* when file closed, send TERM to himself */
    for (;;) {
        n = read(wdt->fd, buf, 64);
        if (n <= 0) {
            kill(getpid(), SIGTERM);
            break;
        }
    }

    if (wdt->timeout) {
        /* if after timeout process is still running, just _exit(2) */
        tv.tv_sec = wdt->timeout;
        tv.tv_usec = 0;
        select(0, NULL, NULL, NULL, &tv);
        _exit(-1);
    }
}

MODULE = Parallel::Boss    PACKAGE = Parallel::Boss    PREFIX = boss_
PROTOTYPES: DISABLE

void
boss__start_watchdog(fd, timeout)
        int fd
        int timeout
    PREINIT:
        int s;
        watchdog_t *wdt;
        pthread_t pth;
        pthread_attr_t attr;
    CODE:
        Newx(wdt, 1, watchdog_t);
        wdt->fd = fd;
        wdt->timeout = timeout;
        s = pthread_attr_init(&attr);
        if (s != 0) {
            croak("Couldn't start watchdog, pthread_attr_init returned %d", s);
        }
        s = pthread_create(&pth, &attr, &watchdog, wdt);
        if (s != 0) {
            croak("Couldn't start watchdog, pthread_create returned %d", s);
        }
