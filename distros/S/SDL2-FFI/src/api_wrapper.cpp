#include <SDL_events.h>
#include <SDL_mixer.h>
#include <SDL_stdinc.h>

#include <SDL.h>
#include <SDL_thread.h>
#include <SDL_timer.h>

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#ifdef USE_ITHREADS
static PerlInterpreter *my_perl; /***    The Perl interpreter    ***/
#endif

/* Very cheap system to prevent accessing perl
context concurrently in multiple threads */
typedef void(SDLCALL *mix_func)(void *, Uint8 *, int);

SV *channel_finished_cb, *music_finished_cb;

#define CALLBACK_TYPES 6
// +0: timer callback
// +1: mixer callback (Mix_SetPostMix and Mix_HookMusic)
// +2: music finished callback
// +3: mixer channel finished callback
// +4: mixer effect callback
// +5: mixer effect done callback
SDL_mutex *mutex[CALLBACK_TYPES];
SDL_cond *cond[CALLBACK_TYPES];
Uint32 callbackEventType;

typedef struct TimerCallbackContainer
{
    Uint32 interval;
    SV *args;
    SV *callback;
} TimerCallbackContainer;
typedef struct CallbackContainer
{
    Uint32 interval;
    SV *args;
    SV *callback;
    SV *retval;
} CallbackContainer;
typedef struct EffectContainer
{
    Uint8 *chunk;
    int len;
    SV *callback;
    SV *args;
    int code;
} EffectContainer;

typedef struct Effect
{
    const Mix_Chunk *chunk;
    Mix_EffectFunc_t f;
    Mix_EffectDone_t d;
    SV *args;
    int len;
} Effect;

//
extern "C" void Bundle_SDL_Wrap_BEGIN(const char *package, int argc, const char *argv[]) {
    // fprintf(stderr, "# Bundle_SDL_Wrap_BEGIN( %s, ... )", package);
    for (int i = 0; i < CALLBACK_TYPES; i++) {
        cond[i] = SDL_CreateCond();
        mutex[i] = SDL_CreateMutex();
    }
    callbackEventType = SDL_RegisterEvents(CALLBACK_TYPES);
#ifdef USE_ITHREADS
    my_perl = (PerlInterpreter *)PERL_GET_CONTEXT;
    SDL_Log("ITHREADS!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
#endif
}
extern "C" void Bundle_SDL_Wrap_END(const char *package) {
    // fprintf(stderr, "# Bundle_SDL_Wrap_END( %s )", package);
    for (int i = 0; i < CALLBACK_TYPES; i++) {
        SDL_DestroyMutex(mutex[i]);
        SDL_CondBroadcast(cond[i]); // Resolve any deadlocks
        SDL_DestroyCond(cond[i]);
    }
}
extern "C" void Bundle_SDL_Yield() {
    dTHX;
#ifdef USE_ITHREADS
    PERL_SET_CONTEXT(my_perl);
#endif
    SDL_Event event_in;
    SDL_PumpEvents();
    // example taken from https://wiki.libsdl.org/SDL_AddTimer to deal
    // with multithreading problems
    while (SDL_PeepEvents(&event_in, 1, SDL_GETEVENT, callbackEventType,
                          callbackEventType + CALLBACK_TYPES) == 1) {
        SDL_Log("event_in.type == %d and callbackEventType == %d [%d] at %s line %d.",
                event_in.type, callbackEventType, event_in.type - callbackEventType, __FILE__,
                __LINE__);
        if (event_in.type == callbackEventType) { // Simple SDL_AddTimer( ... ) callback
            TimerCallbackContainer *cb = ((TimerCallbackContainer *)event_in.user.data1);
            int interval = cb->interval;
            SV *args = (SV *)cb->args;
            {
                dSP;
                int count;
                ENTER;
                SAVETMPS;
                PUSHMARK(SP);
                {
                    XPUSHs((newSVuv(interval)));
                    XPUSHs((SvRV(args)));
                }
                PUTBACK;
                count = call_sv(cb->callback, G_SCALAR);
                SPAGAIN;
                if (count != 1) croak("Expected 1 value from timer callback, got %d\n", count);
                cb->interval = POPi;
                PUTBACK;
                FREETMPS;
                LEAVE;
            }
            int ret = SDL_CondSignal(cond[0]);
            if (ret < 0) SDL_Log("SDL_CondSignal(cond[0]) error: %s", SDL_GetError());
        }
        else if (event_in.type ==
                 callbackEventType + 1) { // +1: mixer callback (Mix_SetPostMix and Mix_HookMusic)

            EffectContainer *cb = ((EffectContainer *)event_in.user.data1);
            int len = cb->len;
            SV *args = (SV *)cb->args;
            {
                dSP;
                ENTER;
                SAVETMPS;
                AV *sva = newAV();
                for (int i = 0; i < len; i++)
                    av_push(sva, newSVuv(cb->chunk[i]));
                SV *ref = newRV_inc(newRV_inc((SV *)sva));
                PUSHMARK(SP);
                {
                    XPUSHs(sv_2mortal(SvRV(args)));
                    XPUSHs(sv_2mortal(ref));
                    XPUSHs(sv_2mortal(newSViv(len)));
                }
                PUTBACK;
                SDL_Log("idk at %s line %d.", __FILE__, __LINE__);

                call_sv(cb->callback, G_DISCARD);
                SDL_Log("idk at %s line %d.", __FILE__, __LINE__);

                SPAGAIN;
                {
                    Uint8 digit;
                    SV *deref = SvRV(SvRV(ref));
                    for (int i = 0; i < len; i++) {
                        SV *_i = *av_fetch((AV *)deref, i, 1);
                        if (SvNIOK(_i)) cb->chunk[i] = SvUV(_i);
                    }
                }
                PUTBACK;
                FREETMPS;
                LEAVE;
            }
            int ret = SDL_CondSignal(cond[/*event_in.type - callbackEventType*/ cb->code]);
            if (ret < 0)
                SDL_Log("SDL_CondSignal(cond[%d]) error: %s",
                        /*event_in.type - callbackEventType*/ cb->code, SDL_GetError());
        }
        else if (event_in.type == callbackEventType + 2) {
            SDL_Log("idk at %s line %d.", __FILE__, __LINE__);
            {
                dSP;
                ENTER;
                SAVETMPS;
                SDL_Log("idk at %s line %d.", __FILE__, __LINE__);

                SDL_Log("idk at %s line %d.", __FILE__, __LINE__);

                PUSHMARK(SP);
                PUTBACK;
                SDL_Log("idk at %s line %d.", __FILE__, __LINE__);

                call_sv(music_finished_cb, G_DISCARD);
                SDL_Log("idk at %s line %d.", __FILE__, __LINE__);

                SPAGAIN;
                SDL_Log("idk at %s line %d.", __FILE__, __LINE__);

                PUTBACK;
                FREETMPS;
                LEAVE;
                SDL_Log("idk at %s line %d.", __FILE__, __LINE__);
            }
        }

        else if (event_in.type == callbackEventType + 3) {
            {
                dSP;
                ENTER;
                SAVETMPS;
                SDL_Log("idk at %s line %d.", __FILE__, __LINE__);

                SDL_Log("idk at %s line %d.", __FILE__, __LINE__);

                PUSHMARK(SP);
                { mXPUSHi(newSViv((int)event_in.user.code)); }

                PUTBACK;
                SDL_Log("idk at %s line %d.", __FILE__, __LINE__);

                call_sv(channel_finished_cb, G_DISCARD);
                SDL_Log("idk at %s line %d.", __FILE__, __LINE__);

                SPAGAIN;
                SDL_Log("idk at %s line %d.", __FILE__, __LINE__);

                PUTBACK;
                FREETMPS;
                LEAVE;
                SDL_Log("idk at %s line %d.", __FILE__, __LINE__);
            }
            SDL_CondBroadcast(cond[4]);
        }
        else {
            SDL_Log("Unhandled callback! Type: %d", event_in.user.code);
        }
    }
    // SDL_Log("idk at %s line %d.", __FILE__, __LINE__);

    return;
}

Uint32 timer_callback(Uint32 interval, void *param) {
    dTHX;
#ifdef USE_ITHREADS
    PERL_SET_CONTEXT(my_perl);
#endif
    SDL_LockMutex(mutex[0]);
    SDL_Event event;
    TimerCallbackContainer *container = (TimerCallbackContainer *)param;
    container->interval = interval;
    event.type = callbackEventType;
    event.user.code = callbackEventType;
    event.user.data1 = container;
    SDL_PushEvent(&event);
    int ret = SDL_CondWait(cond[0], mutex[0]);
    if (ret == 0)
        interval = container->interval;
    else if (ret < 0)
        SDL_Log("Timer callback error: %s [Please report this as an issue]", SDL_GetError());
    SDL_UnlockMutex(mutex[0]);
    return interval;
}
extern "C" SDL_TimerID Bundle_SDL_AddTimer(int interval, SV *cb, SV *params) {
    dTHX;
#ifdef USE_ITHREADS
    PERL_SET_CONTEXT(my_perl);
#endif
    CallbackContainer *container = (CallbackContainer *)SDL_malloc(sizeof(CallbackContainer));
    if (!container) {
        SDL_OutOfMemory();
        return 0;
    }
    container->interval = interval;
    container->callback = SvREFCNT_inc(cb);
    container->args = newRV_inc(params);
    return SDL_AddTimer(interval, timer_callback, container);
}

void wrap_mix_func(void *udata, Uint8 *stream, int len) {
    SDL_Event event;
    EffectContainer *container = (EffectContainer *)udata;
    SDL_LockMutex(mutex[container->code]);
    container->len = len;
    container->chunk = stream;
    event.type = callbackEventType + 1;
    event.user.data1 = container;
    SDL_PushEvent(&event);
    //
    int ret = SDL_CondWait(cond[container->code], mutex[container->code]);
    if (ret == SDL_MUTEX_TIMEDOUT)
        SDL_Log("%s at %s line %d.", SDL_GetError(), __FILE__, __LINE__);
    else if (ret == 0)
        stream = container->chunk;
    // else if (ret < 0)
    //   SDL_Log("%s at %s line %d.", SDL_GetError(), __FILE__, __LINE__);
    SDL_UnlockMutex(mutex[container->code]);
    // SDL_Log("%s at %s line %d.", SDL_GetError(), __FILE__, __LINE__);
    return;
}
extern "C" void Bundle_Mix_SetPostMix(SV *cb, SV *params) {
    EffectContainer *container = (EffectContainer *)SDL_malloc(sizeof(EffectContainer));
    if (!container) {
        SDL_OutOfMemory();
        return;
    }
    if (cb == &PL_sv_undef) {
        SDL_Log("ACK!!!!!!!!!!!!!!!!!!!!! at %s line %d.", __FILE__, __LINE__);
        Mix_SetPostMix(NULL, NULL);
        return;
    }

    container->callback = SvREFCNT_inc(cb);
    container->args = newRV_inc(params);
    container->code = 1;
    Mix_SetPostMix(wrap_mix_func, container);
    // else
    //    Mix_SetPostMix(NULL, NULL);
}
extern "C" void Bundle_Mix_HookMusic(SV *cb, SV *params) {
    EffectContainer *container = (EffectContainer *)SDL_malloc(sizeof(EffectContainer));
    if (!container) {
        SDL_OutOfMemory();
        return;
    }
    if (cb == &PL_sv_undef) {
        SDL_Log("ACK!!!!!!!!!!!!!!!!!!!!! at %s line %d.", __FILE__, __LINE__);
        Mix_HookMusic(NULL, NULL);
        return;
    }
    SDL_Log("Okay! at %s line %d.", __FILE__, __LINE__);

    container->callback = cb;
    SDL_Log("Okay! at %s line %d.", __FILE__, __LINE__);

    container->args = newRV_inc(params);
    SDL_Log("Okay! at %s line %d.", __FILE__, __LINE__);

    container->code = 2;
    SDL_Log("Okay! at %s line %d.", __FILE__, __LINE__);

    Mix_HookMusic(wrap_mix_func, container);
    SDL_Log("Okay! at %s line %d.", __FILE__, __LINE__);

    // else
    //    Mix_HookMusic(NULL, NULL);
}

void music_finished_func() {
    SDL_Event event_out;
    event_out.type = callbackEventType + 2;
    SDL_PushEvent(&event_out);
    return;
}
extern "C" void Bundle_Mix_HookMusicFinished(SV *cb) {
    SDL_Log("idk at %s line %d.", __FILE__, __LINE__);
    if (cb == &PL_sv_undef) {
        SDL_Log("ACK!!!!!!!!!!!!!!!!!!!!! at %s line %d.", __FILE__, __LINE__);

        music_finished_cb = NULL;
        Mix_HookMusicFinished(NULL);
    }
    else {
        SDL_Log("Okay! at %s line %d.", __FILE__, __LINE__);

        music_finished_cb = SvREFCNT_inc(cb);
        Mix_HookMusicFinished(music_finished_func);
    }
}

void channel_finished_func(int channel) {
    SDL_Log("idk at %s line %d.", __FILE__, __LINE__);
    SDL_Event event_out;
    event_out.type = callbackEventType + 3;
    event_out.user.code = channel;
    SDL_PushEvent(&event_out);
    SDL_Log("idk at %s line %d.", __FILE__, __LINE__);
}
extern "C" void Bundle_Mix_ChannelFinished(SV *cb) {
    SDL_Log("idk at %s line %d.", __FILE__, __LINE__);
    if (cb == &PL_sv_undef) {
        SDL_Log("UNDEF!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! at %s line %d.", __FILE__, __LINE__);
        channel_finished_cb = NULL;
        Mix_ChannelFinished(NULL);
    }
    else {
        SDL_Log("YAY! at %s line %d.", __FILE__, __LINE__);

        channel_finished_cb = SvREFCNT_inc(cb);
        Mix_ChannelFinished(channel_finished_func);
    }
    SDL_Log("idk at %s line %d.", __FILE__, __LINE__);
}

void mix_effect_func(int chan, void *stream, int len, Effect *udata) {
    SDL_LockMutex(mutex[4]);

    SDL_Log("mix_effect_func | %d", chan);
    udata->chunk = (Mix_Chunk *)stream;
    udata->len = len;

    SDL_Event event_out;
    event_out.type = callbackEventType + 4;

    event_out.user.code = chan;
    event_out.user.data1 = udata;
    event_out.user.data2 = (void *)stream;
    SDL_Log("Before: %d", ((Uint8 *)stream)[0]);
    SDL_PushEvent(&event_out);

    int ret = SDL_CondWait(cond[4], mutex[4]); // XXX: There's a deadlock somewhere
    if (ret == 0)                              // SDL_memcpy(stream, _stream, len);
        ; // SDL_Log("After: %d | %d", ((Uint8 *)event_out.user.data2)[0], udata->chunk[0]);
    else if (ret < 0)
        SDL_Log("Error: %s", SDL_GetError());
    return;
}

void mix_effect_done_func(int chan, void *udata) {
    SDL_Log("mix_effect_done_func");
}
extern "C" int Bundle_Mix_RegisterEffect(int chan, Mix_EffectFunc_t f, Mix_EffectDone_t d,
                                         void *args) {
    Effect *real = (Effect *)SDL_malloc(sizeof(Effect));
    real->f = f;
    real->d = d;
    return Mix_RegisterEffect(
        chan, (Mix_EffectFunc_t)(f == (Mix_EffectFunc_t)NULL ? (void *)f : (void *)mix_effect_func),
        (Mix_EffectDone_t)(d == (Mix_EffectDone_t)NULL ? d : mix_effect_done_func), real);
}