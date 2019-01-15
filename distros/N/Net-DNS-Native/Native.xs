#ifdef __linux__
# define _GNU_SOURCE
#endif
#include <pthread.h>
#include <semaphore.h>
#include <stdint.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "bstree.h"

#pragma push_macro("free")
#pragma push_macro("malloc")
#undef free
#undef malloc
#include "queue.h" // will be used outside of the main thread
#pragma pop_macro("free")
#pragma pop_macro("malloc")

// write() is deprecated in favor of _write() - windows way
#if defined(WIN32) && !defined(UNDER_CE)
# include <io.h>
# define write _write
# define read _read
#endif

// unnamed semaphores are not implemented in this POSIX compatible UNIX system
#ifdef PERL_DARWIN
# include "mysemaphore.h"
# define sem_t my_sem_t
# define sem_init my_sem_init
# define sem_wait my_sem_wait
# define sem_post my_sem_post
# define sem_destroy my_sem_destroy
#endif

#ifdef __linux__
# include <link.h>
int _dl_phdr_cb(struct dl_phdr_info *info, size_t size, void *data) {
    int i;
    char *found = (char*)data;
    
    if (*found) {
        return *found;
    }
    
    for (i=0; i < info->dlpi_phnum; i++) {
        if (instr(info->dlpi_name, "libnss_files") != NULL) {
            *found = 1;
            break;
        }
    }
    
    return *found;
}
#endif

typedef struct DNS_result DNS_result;

typedef struct {
    pthread_mutex_t mutex;
    pthread_attr_t thread_attrs;
    pthread_t *threads_pool;
#ifndef WIN32
    sigset_t blocked_sig;
#endif
    sem_t semaphore;
    bstree* fd_map;
    queue* in_queue;
    int pool;
    char extra_thread;
    char notify_on_begin;
    int extra_threads_cnt;
    int busy_threads;
    queue* tout_queue;
    char forked;
    char need_pool_reinit;
    PerlInterpreter *perl;
} Net_DNS_Native;

typedef struct {
    Net_DNS_Native *self;
    char *host;
    char *service;
    struct addrinfo *hints;
    char extra;
    char pool;
    DNS_result *res;
} DNS_thread_arg;

struct DNS_result {
    int fd1;
    int error;
    struct addrinfo *hostinfo;
    int type;
    DNS_thread_arg *arg;
    char dequeued;
};

queue *DNS_instances = NULL;

void *DNS_getaddrinfo(void *v_arg) {
    DNS_thread_arg *arg = (DNS_thread_arg *)v_arg;
#ifndef WIN32
    if (!arg->pool)
        pthread_sigmask(SIG_BLOCK, &arg->self->blocked_sig, NULL);
#endif
    
    if (arg->self->notify_on_begin)
        write(arg->res->fd1, "1", 1);
    arg->res->error = getaddrinfo(arg->host, arg->service, arg->hints, &arg->res->hostinfo);
    
    pthread_mutex_lock(&arg->self->mutex);
    arg->res->arg = arg;
    if (arg->extra) arg->self->extra_threads_cnt--;
    write(arg->res->fd1, "2", 1);
    pthread_mutex_unlock(&arg->self->mutex);
    
    return NULL;
}

void *DNS_pool_worker(void *v_arg) {
    Net_DNS_Native *self = (Net_DNS_Native*)v_arg;
#ifndef WIN32
    pthread_sigmask(SIG_BLOCK, &self->blocked_sig, NULL);
#endif
    
    while (sem_wait(&self->semaphore) == 0) {
        pthread_mutex_lock(&self->mutex);
        void *arg = queue_shift(self->in_queue);
        if (arg != NULL) self->busy_threads++;
        pthread_mutex_unlock(&self->mutex);
        
        if (arg == NULL) {
            // this was request to quit thread
            break;
        }
        
        DNS_getaddrinfo(arg);
        
        pthread_mutex_lock(&self->mutex);
        self->busy_threads--;
        pthread_mutex_unlock(&self->mutex);
    }
    
    return NULL;
}

void DNS_free_timedout(Net_DNS_Native *self, char force) {
    if (queue_size(self->tout_queue)) {
        queue_iterator *it = queue_iterator_new(self->tout_queue);
        int fd;
        DNS_result *res;
        
        while (!queue_iterator_end(it)) {
            fd = (intptr_t)queue_at(self->tout_queue, it);
            res = bstree_get(self->fd_map, fd);
            if (res == NULL) {
                goto FREE_TOUT;
            }
            
            if (force || res->arg) {
                bstree_del(self->fd_map, fd);
                if (!res->error && res->hostinfo)
                    freeaddrinfo(res->hostinfo);
                
                close(fd);
                close(res->fd1);
                if (res->arg) {
                    if (res->arg->hints)   free(res->arg->hints);
                    if (res->arg->host)    Safefree(res->arg->host);
                    if (res->arg->service) Safefree(res->arg->service);
                    free(res->arg);
                }
                free(res);
                
                FREE_TOUT:
                    queue_del(self->tout_queue, it);
                    continue;
            }
            
            queue_iterator_next(it);
        }
        
        queue_iterator_destroy(it);
    }
}

void DNS_lock_semaphore(sem_t *s) {
#ifdef PERL_DARWIN
    pthread_mutex_lock(&s->lock);
#endif
}

void DNS_unlock_semaphore(sem_t *s) {
#ifdef PERL_DARWIN
    pthread_mutex_unlock(&s->lock);
#endif
}

void DNS_before_fork_handler() {
    if (queue_size(DNS_instances) == 0) {
        return;
    }
    
    Net_DNS_Native *self;
    queue_iterator *it = queue_iterator_new(DNS_instances);
    while (!queue_iterator_end(it)) {
        self = queue_at(DNS_instances, it);
        pthread_mutex_lock(&self->mutex);
        if (self->pool) DNS_lock_semaphore(&self->semaphore);
        queue_iterator_next(it);
    }
    queue_iterator_destroy(it);
}

void DNS_after_fork_handler_parent() {
    if (queue_size(DNS_instances) == 0) {
        return;
    }
    
    Net_DNS_Native *self;
    queue_iterator *it = queue_iterator_new(DNS_instances);
    while (!queue_iterator_end(it)) {
        self = queue_at(DNS_instances, it);
        pthread_mutex_unlock(&self->mutex);
        if (self->pool) DNS_unlock_semaphore(&self->semaphore);
        queue_iterator_next(it);
    }
    queue_iterator_destroy(it);
}

void DNS_reinit_pool(Net_DNS_Native *self) {
    pthread_t tid;
    int i, rc;
    
    for (i=0; i<self->pool; i++) {
        rc = pthread_create(&tid, NULL, DNS_pool_worker, (void*)self);
        if (rc == 0) {
            self->threads_pool[i] = tid;
        }
        else {
            croak("Can't recreate thread #%d after fork: %s", i+1, strerror(rc));
        }
    }
}

void DNS_after_fork_handler_child() {
    if (queue_size(DNS_instances) == 0) {
        return;
    }
    
    Net_DNS_Native *self;
    queue_iterator *it = queue_iterator_new(DNS_instances);
    
    while (!queue_iterator_end(it)) {
        self = queue_at(DNS_instances, it);
        pthread_mutex_unlock(&self->mutex);
        if (self->pool) DNS_unlock_semaphore(&self->semaphore);
        
        // reinitialize stuff
        DNS_free_timedout(self, 1);
        
        self->extra_threads_cnt = 0;
        self->busy_threads = 0;
        self->perl = PERL_GET_THX;
        self->forked = 1;
        
        if (self->pool) {
#ifdef __NetBSD__
            // unfortunetly under NetBSD threads created here will misbehave
            self->need_pool_reinit = 1;
#else
            DNS_reinit_pool(self);
#endif
        }
        
        queue_iterator_next(it);
    }
    
    queue_iterator_destroy(it);
}

MODULE = Net::DNS::Native   PACKAGE = Net::DNS::Native

PROTOTYPES: DISABLE

SV*
new(char* class, ...)
    PREINIT:
        Net_DNS_Native *self;
    CODE:
        if (items % 2 == 0)
            croak("odd number of parameters");
        
        Newx(self, 1, Net_DNS_Native);
        
        int i, rc;
        self->pool = 0;
        self->notify_on_begin = 0;
        self->extra_thread = 0;
        self->extra_threads_cnt = 0;
        self->busy_threads = 0;
        self->forked = 0;
        self->need_pool_reinit = 0;
        self->perl = PERL_GET_THX;
#ifndef WIN32
        sigfillset(&self->blocked_sig);
#endif
        char *opt;
        
        for (i=1; i<items; i+=2) {
            opt = SvPV_nolen(ST(i));
            
            if (strEQ(opt, "pool")) {
                self->pool = SvIV(ST(i+1));
                if (self->pool < 0) self->pool = 0;
            }
            else if (strEQ(opt, "extra_thread")) {
                self->extra_thread = SvIV(ST(i+1));
            }
            else if (strEQ(opt, "notify_on_begin")) {
                self->notify_on_begin = SvIV(ST(i+1));
            }
            else {
                warn("unsupported option: %s", SvPV_nolen(ST(i)));
            }
        }
        
        char attr_ok = 0, mutex_ok = 0, sem_ok = 0;
        
        rc = pthread_attr_init(&self->thread_attrs);
        if (rc != 0) {
            warn("pthread_attr_init(): %s", strerror(rc));
            goto FAIL;
        }
        attr_ok = 1;
        rc = pthread_attr_setdetachstate(&self->thread_attrs, PTHREAD_CREATE_DETACHED);
        if (rc != 0) {
            warn("pthread_attr_setdetachstate(): %s", strerror(rc));
            goto FAIL;
        }
        rc = pthread_mutex_init(&self->mutex, NULL);
        if (rc != 0) {
            warn("pthread_mutex_init(): %s", strerror(rc));
            goto FAIL;
        }
        mutex_ok = 1;
        
        self->in_queue = NULL;
        self->threads_pool = NULL;
        
        if (DNS_instances == NULL) {
            DNS_instances = queue_new();
#ifndef WIN32
            rc = pthread_atfork(DNS_before_fork_handler, DNS_after_fork_handler_parent, DNS_after_fork_handler_child);
            if (rc != 0) {
                warn("Can't install fork handler: %s", strerror(rc));
                goto FAIL;
            }
#endif
        }
        
        if (self->pool) {
            if (sem_init(&self->semaphore, 0, 0) != 0) {
                warn("sem_init(): %s", strerror(errno));
                goto FAIL;
            }
            sem_ok = 1;
            
            self->threads_pool = malloc(self->pool*sizeof(pthread_t));
            pthread_t tid;
            int j = 0;
            
            for (i=0; i<self->pool; i++) {
                rc = pthread_create(&tid, NULL, DNS_pool_worker, (void*)self);
                if (rc == 0) {
                    self->threads_pool[j++] = tid;
                }
                else {
                    warn("Can't create thread #%d: %s", i+1, strerror(rc));
                }
            }
            
            if (j == 0) {
                goto FAIL;
            }
            
            self->pool = j;
            self->in_queue = queue_new();
        }
        
        self->fd_map = bstree_new();
        self->tout_queue = queue_new();
        RETVAL = newSV(0);
        sv_setref_pv(RETVAL, class, (void *)self);
        
        if (0) {
            FAIL:
                if (attr_ok) pthread_attr_destroy(&self->thread_attrs);
                if (mutex_ok) pthread_mutex_destroy(&self->mutex);
                if (sem_ok) sem_destroy(&self->semaphore);
                if (self->threads_pool) free(self->threads_pool);
                Safefree(self);
                RETVAL = &PL_sv_undef;
        }
        
        queue_push(DNS_instances, self);
    OUTPUT:
        RETVAL

int
_getaddrinfo(Net_DNS_Native *self, char *host, SV* sv_service, SV* sv_hints, int type)
    INIT:
        int fd[2];
    CODE:
#ifdef __NetBSD__
        if (self->need_pool_reinit) {
            self->need_pool_reinit = 0;
            DNS_reinit_pool(self);
        }
#endif
        if (socketpair(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, PF_UNSPEC, fd) != 0)
            croak("socketpair(): %s", strerror(errno));
        
        char *service = SvOK(sv_service) ? SvPV_nolen(sv_service) : "";
        struct addrinfo *hints = NULL;
        
        if (SvOK(sv_hints)) {
            // defined
            if (!SvROK(sv_hints) || SvTYPE(SvRV(sv_hints)) != SVt_PVHV) {
                // not reference or not a hash inside reference
                croak("hints should be reference to hash");
            }
            
            hints = malloc(sizeof(struct addrinfo));
            hints->ai_flags = 0;
            hints->ai_family = AF_UNSPEC;
            hints->ai_socktype = 0;
            hints->ai_protocol = 0;
            hints->ai_addrlen = 0;
            hints->ai_addr = NULL;
            hints->ai_canonname = NULL;
            hints->ai_next = NULL;
            
            HV* hv_hints = (HV*)SvRV(sv_hints);
            
            SV **flags_ptr = hv_fetch(hv_hints, "flags", 5, 0);
            if (flags_ptr != NULL) {
                hints->ai_flags = SvIV(*flags_ptr);
            }
            
            SV **family_ptr = hv_fetch(hv_hints, "family", 6, 0);
            if (family_ptr != NULL) {
                hints->ai_family = SvIV(*family_ptr);
            }
            
            SV **socktype_ptr = hv_fetch(hv_hints, "socktype", 8, 0);
            if (socktype_ptr != NULL) {
                hints->ai_socktype = SvIV(*socktype_ptr);
            }
            
            SV **protocol_ptr = hv_fetch(hv_hints, "protocol", 8, 0);
            if (protocol_ptr != NULL) {
                hints->ai_protocol = SvIV(*protocol_ptr);
            }
        }
        
        DNS_result *res = malloc(sizeof(DNS_result));
        res->fd1 = fd[1];
        res->error = 0;
        res->hostinfo = NULL;
        res->type = type;
        res->arg = NULL;
        res->dequeued = 0;
        
        DNS_thread_arg *arg = malloc(sizeof(DNS_thread_arg));
        arg->self = self;
        arg->host = strlen(host) ? savepv(host) : NULL;
        arg->service = strlen(service) ? savepv(service) : NULL;
        arg->hints = hints;
        arg->extra = 0;
        arg->pool  = 0;
        arg->res = res;
        
        pthread_mutex_lock(&self->mutex);
        DNS_free_timedout(self, 0);
        bstree_put(self->fd_map, fd[0], res);
        if (self->pool) {
            if (self->busy_threads == self->pool && (self->extra_thread || queue_size(self->tout_queue) > self->extra_threads_cnt)) {
                arg->extra = 1;
                self->extra_threads_cnt++;
            }
            else {
                arg->pool = 1;
                queue_push(self->in_queue, arg);
                sem_post(&self->semaphore);
            }
        }
        pthread_mutex_unlock(&self->mutex);
        
        if (!self->pool || arg->extra) {
            pthread_t tid;
            int rc = pthread_create(&tid, &self->thread_attrs, DNS_getaddrinfo, (void *)arg);
            if (rc != 0) {
                if (arg->host)    Safefree(arg->host);
                if (arg->service) Safefree(arg->service);
                free(arg);
                free(res);
                if (hints) free(hints);
                pthread_mutex_lock(&self->mutex);
                bstree_del(self->fd_map, fd[0]);
                pthread_mutex_unlock(&self->mutex);
                close(fd[0]);
                close(fd[1]);
                croak("pthread_create(): %s", strerror(rc));
            }
        }
        
        RETVAL = fd[0];
    OUTPUT:
        RETVAL

void
_get_result(Net_DNS_Native *self, int fd)
    PPCODE:
        pthread_mutex_lock(&self->mutex);
        DNS_result *res = bstree_get(self->fd_map, fd);
        bstree_del(self->fd_map, fd);
        pthread_mutex_unlock(&self->mutex);
        
        if (res == NULL) croak("attempt to get result which doesn't exists");
        if (!res->arg) {
            pthread_mutex_lock(&self->mutex);
            bstree_put(self->fd_map, fd, res);
            pthread_mutex_unlock(&self->mutex);
            croak("attempt to get not ready result");
        }
        
        XPUSHs(sv_2mortal(newSViv(res->type)));
        SV *err = newSV(0);
        sv_setiv(err, (IV)res->error);
        sv_setpv(err, res->error ? gai_strerror(res->error) : "");
        SvIOK_on(err);
        XPUSHs(sv_2mortal(err));
        
        if (!res->error) {
            struct addrinfo *info;
            for (info = res->hostinfo; info != NULL; info = info->ai_next) {
                HV *hv_info = newHV();
                hv_store(hv_info, "family", 6, newSViv(info->ai_family), 0);
                hv_store(hv_info, "socktype", 8, newSViv(info->ai_socktype), 0);
                hv_store(hv_info, "protocol", 8, newSViv(info->ai_protocol), 0);
                hv_store(hv_info, "addr", 4, newSVpvn((char*)info->ai_addr, info->ai_addrlen), 0);
                hv_store(hv_info, "canonname", 9, info->ai_canonname ? newSVpv(info->ai_canonname, 0) : newSV(0), 0);
                XPUSHs(sv_2mortal(newRV_noinc((SV*)hv_info)));
            }
            
            if (res->hostinfo) freeaddrinfo(res->hostinfo);
        }
        
        close(fd);
        close(res->fd1);
        if (res->arg->hints)   free(res->arg->hints);
        if (res->arg->host)    Safefree(res->arg->host);
        if (res->arg->service) Safefree(res->arg->service);
        free(res->arg);
        free(res);

void
_timedout(Net_DNS_Native *self, int fd)
    PPCODE:
        char unknown = 0;
        
        pthread_mutex_lock(&self->mutex);
        if (bstree_get(self->fd_map, fd) == NULL) {
            unknown = 1;
        }
        else {
            queue_push(self->tout_queue, (void*)(intptr_t)fd);
        }
        pthread_mutex_unlock(&self->mutex);
        
        if (unknown)
            croak("attempt to set timeout on unknown source");

void
DESTROY(Net_DNS_Native *self)
    CODE:
        if (PERL_GET_THX != self->perl) {
            // attempt to destroy from another perl thread
            return;
        }
        
        if (self->pool) {
            pthread_mutex_lock(&self->mutex);
            if (queue_size(self->in_queue) > 0) {
                // warnings are useless in global destruction
                if (!PL_dirty)
                    warn("destroying Net::DNS::Native object while queue for resolver has %d elements", queue_size(self->in_queue));
                
                queue_iterator *it = queue_iterator_new(self->in_queue);
                DNS_thread_arg *arg;
                
                while (!queue_iterator_end(it)) {
                    arg = queue_at(self->in_queue, it);
                    arg->res->dequeued = 1;
                    free(arg);
                    queue_iterator_next(it);
                }
                
                queue_iterator_destroy(it);
                queue_clear(self->in_queue);
            }
            pthread_mutex_unlock(&self->mutex);
            
            int i;
            for (i=0; i<self->pool; i++) {
                sem_post(&self->semaphore);
            }
            
            void *rv;
            
            for (i=0; i<self->pool; i++) {
#ifdef __NetBSD__
                // unfortunetly NetBSD can join only first thread after fork
                if (self->forked && i > 0) break;
#endif
                pthread_join(self->threads_pool[i], &rv);
            }
            
            queue_destroy(self->in_queue);
            free(self->threads_pool);
            sem_destroy(&self->semaphore);
        }
        
        pthread_mutex_lock(&self->mutex);
        DNS_free_timedout(self, 0);
        pthread_mutex_unlock(&self->mutex);
        
        if (bstree_size(self->fd_map) > 0) {
            if (!PL_dirty)
                warn("destroying Net::DNS::Native object with %d non-received results", bstree_size(self->fd_map));
            
            int *fds = bstree_keys(self->fd_map);
            int i, l, j;
            char buf[1];
            
            for (i=0, l=bstree_size(self->fd_map); i<l; i++) {
                DNS_result *res = bstree_get(self->fd_map, fds[i]);
                
                if (!res->dequeued) {
                    for (j=0; j<2; j++) {
                        read(fds[i], buf, 1);
                        // notify_on_begin may send 1
                        if (buf[0] == '2') break;
                    }
                    
                    if (!res->error && res->hostinfo) freeaddrinfo(res->hostinfo);
                    if (res->arg->hints)   free(res->arg->hints);
                    if (res->arg->host)    Safefree(res->arg->host);
                    if (res->arg->service) Safefree(res->arg->service);
                    free(res->arg);
                }
                
                close(res->fd1);
                close(fds[i]);
                free(res);
            }
            
            free(fds);
        }
        
        queue_iterator *it = queue_iterator_new(DNS_instances);
        while (!queue_iterator_end(it)) {
            if (queue_at(DNS_instances, it) == self) {
                queue_del(DNS_instances, it);
                break;
            }
            queue_iterator_next(it);
        }
        queue_iterator_destroy(it);
        
        pthread_attr_destroy(&self->thread_attrs);
        pthread_mutex_destroy(&self->mutex);
        bstree_destroy(self->fd_map);
        queue_destroy(self->tout_queue);
        Safefree(self);

void
pack_sockaddr_in6(int port, SV *sv_address)
    PPCODE:
        STRLEN len;
        char *address = SvPV(sv_address, len);
        if (len != 16)
            croak("address length is %lu should be 16", len);
        
        struct sockaddr_in6 *addr = malloc(sizeof(struct sockaddr_in6));
        memcpy(addr->sin6_addr.s6_addr, address, 16);
        addr->sin6_family = AF_INET6;
        addr->sin6_port = port;
        
        XPUSHs(sv_2mortal(newSVpvn((char*) addr, sizeof(struct sockaddr_in6))));

void
unpack_sockaddr_in6(SV *sv_addr)
    PPCODE:
        STRLEN len;
        char *addr = SvPV(sv_addr, len);
        if (len != sizeof(struct sockaddr_in6))
            croak("address length is %lu should be %lu", len, sizeof(struct sockaddr_in6));
        
        struct sockaddr_in6 *struct_addr = (struct sockaddr_in6*) addr;
        XPUSHs(sv_2mortal(newSViv(struct_addr->sin6_port)));
        XPUSHs(sv_2mortal(newSVpvn((char*)struct_addr->sin6_addr.s6_addr, 16)));

int
_is_non_safe_symbols_loaded()
    INIT:
        char found = 0;
    CODE:
#ifdef __linux__
        dl_iterate_phdr(_dl_phdr_cb, (void*)&found);
#endif
        RETVAL = found;
    OUTPUT:
        RETVAL
