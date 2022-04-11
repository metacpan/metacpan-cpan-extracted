#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "const-c.inc"

#include <pthread.h>
#include <unistd.h>
#include <td/telegram/td_json_client.h>

typedef struct {
    int id;
} client_t;

pthread_mutex_t log_mutex;
char * log_buffer;
int log_buffer_max_capacity;
int log_buffer_capacity;
int log_buffer_len;

static inline int min(int a, int b){ return a<b ? a : b; }
static inline int max(int a, int b){ return a>b ? a : b; }

void td_log_message_callback(int verbosity_level, const char *message){
    if( pthread_mutex_lock(&log_mutex) ){
        perror("WARNING: telegram log_mutex lock failed");
        fprintf(stderr, "  with telegram log verbosity=%d, msg=%s\n", verbosity_level, message);
        return;
    }

    verbosity_level = min(127, max(-128, verbosity_level));

    STRLEN message_len = strlen(message);
    if( log_buffer_capacity - log_buffer_len < sizeof(int8_t) + message_len + 1 ){
        char * new_log_buffer;
        int new_log_buffer_capacity;
        if( log_buffer_max_capacity - log_buffer_len < sizeof(int8_t) + message_len + 1 )
            new_log_buffer = NULL;
        else{
            new_log_buffer_capacity = log_buffer_capacity;
            do
                new_log_buffer_capacity *= 2;
            while( new_log_buffer_capacity - log_buffer_len < sizeof(int8_t) + message_len + 1 );
            new_log_buffer_capacity = min(new_log_buffer_capacity, log_buffer_max_capacity);
            new_log_buffer = realloc(log_buffer, sizeof(*log_buffer)*new_log_buffer_capacity);
        }
        if( !new_log_buffer ){
            pthread_mutex_unlock(&log_mutex);
            fprintf(stderr, "telegram log buffer is full.\n  with telegram log verbosity=%d, msg=%s\n", verbosity_level, message);
            return;
        }
        log_buffer_capacity = new_log_buffer_capacity;
        log_buffer = new_log_buffer;
    }
    *(int8_t*)&log_buffer[log_buffer_len] = (int8_t) verbosity_level;
    memcpy(log_buffer+log_buffer_len+sizeof(int8_t), message, message_len+1);
    log_buffer_len += sizeof(int8_t) + message_len + 1;

    pthread_mutex_unlock(&log_mutex);
}

MODULE = Telegram::JsonAPI		PACKAGE = Telegram::JsonAPI		

INCLUDE: const-xs.inc

void
td_create_client_id()
    PPCODE:
        dSP;
        dXSTARG;
        XPUSHi(td_create_client_id());

void
td_send(int client_id, const char * request)
    PPCODE:
        td_send(client_id, request);

void
td_receive(double timeout)
    PPCODE:
        dSP;
        dXSTARG;
        const char * msg = td_receive(timeout);
        if( msg )
            XPUSHp(msg, strlen(msg));
        else
            XPUSHs(&PL_sv_undef);

void
td_execute(const char * request)
    PPCODE:
        dSP;
        dXSTARG;
        const char * msg = td_execute(request);
        if( msg )
            XPUSHp(msg, strlen(msg));
        else
            XPUSHs(&PL_sv_undef);

void
td_start_log(int max_verbosity_level=1024, int max_buffer_capacity=1048576)
    PPCODE:
        if( pthread_mutex_lock(&log_mutex) )
            perror("WARNING: telegram log_mutex lock failed at `td_start_log`");
        else{
            log_buffer_max_capacity = max_buffer_capacity;
            if( !log_buffer ){
                log_buffer_capacity = min(1024, log_buffer_max_capacity);
                log_buffer_len = 0;
                log_buffer = malloc(log_buffer_capacity);
                if( !log_buffer ){
                    log_buffer_capacity = 0;
                    croak("td_start_log: Failed to allocate memory for log");
                }
            }
            pthread_mutex_unlock(&log_mutex);
            td_set_log_message_callback(max_verbosity_level, td_log_message_callback);
        }

void
td_stop_log()
    PPCODE:
        td_set_log_message_callback(0, NULL);
        if( pthread_mutex_lock(&log_mutex) )
            perror("WARNING: telegram log_mutex lock failed at `td_stop_log`");
        else{
            if( log_buffer ){
                free(log_buffer);
                log_buffer = NULL;
                log_buffer_capacity = log_buffer_len = 0;
            }
            pthread_mutex_unlock(&log_mutex);
        }

void
td_poll_log(SV * callback_SV)
    PPCODE:
        if( !(SvROK(callback_SV) && SvTYPE(SvRV(callback_SV))==SVt_PVCV) )
            croak("td_poll_log: callback should be a sub");

        if( pthread_mutex_lock(&log_mutex) )
            perror("WARNING: telegram log_mutex lock failed at `td_poll_log_message`");
        else{
            dSP;

            if( log_buffer_len ){
                char *log_buffer_polled = log_buffer;
                int log_buffer_polled_len = log_buffer_len;
                int log_buffer_polled_capacity = log_buffer_capacity;

                log_buffer_capacity = min(1024, log_buffer_max_capacity);
                log_buffer_len = 0;
                log_buffer = malloc(sizeof(*log_buffer) * log_buffer_capacity);
                if( !log_buffer ){
                    warn("td_poll_log: failed to allocate new log buffer");
                    log_buffer_capacity = 0;
                }

                pthread_mutex_unlock(&log_mutex);

                char *p = log_buffer_polled;
                char *p_end = p + log_buffer_polled_len;
                while( p<p_end && SvOK(callback_SV) ){
                    ENTER;
                    SAVETMPS;

                    PUSHMARK(SP);
                    EXTEND(SP, 2);

                    int verbosity_level = (int) *(int8_t*)p;
                    char * message = p + sizeof(int8_t);
                    STRLEN message_len = strlen(message);

                    p += sizeof(int8_t) + message_len + 1;

                    mPUSHi(verbosity_level);
                    mPUSHp(message, strlen(message));

                    PUTBACK;

                    call_sv(callback_SV, G_DISCARD|G_VOID);

                    FREETMPS;
                    LEAVE;

                    SPAGAIN;
                }

                free(log_buffer_polled);
            }
            else
                pthread_mutex_unlock(&log_mutex);
        }

BOOT:
    pthread_mutex_init(&log_mutex, NULL);

    log_buffer_capacity = 0;
    log_buffer = NULL;
    log_buffer_len = 0;
