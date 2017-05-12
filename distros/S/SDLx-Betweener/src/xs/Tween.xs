
#include "Types.h"
#include "Tween.h"
#include "SDL.h"

MODULE = SDLx::Betweener  PACKAGE = SDLx::Betweener::Tween

#define COMPUTE_NOW()            \
    Uint32 now = items == 2?     \
        (Uint32) SvIV(ST(1)):    \
        (Uint32) SDL_GetTicks(); \

void
Tween::start(...)
    CODE:
        COMPUTE_NOW()
        THIS->start(now);

void
Tween::stop()

void
Tween::pause(...)
    CODE:
        COMPUTE_NOW()
        THIS->pause(now);

void
Tween::resume(...)
    CODE:
        COMPUTE_NOW()
        THIS->resume(now);

bool
Tween::is_paused()

bool
Tween::is_active()

Uint32
Tween::get_cycle_start_time()

Uint32
Tween::get_total_pause_time()

Uint32
Tween::get_duration()

void
Tween::set_duration(new_duration, ...)
    Uint32 new_duration
    CODE:
        COMPUTE_NOW()
        THIS->set_duration(new_duration, now);

void
Tween::DESTROY()
    CODE:
        delete THIS;


