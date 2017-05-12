
#include "Types.h"
#include "Seeker.h"
#include "SDL.h"

MODULE = SDLx::Betweener  PACKAGE = SDLx::Betweener::Seeker

#define COMPUTE_NOW()            \
    Uint32 now = items == 2?     \
        (Uint32) SvIV(ST(1)):    \
        (Uint32) SDL_GetTicks(); \

void
Seeker::start(...)
    CODE:
        COMPUTE_NOW()
        THIS->start(now);

void
Seeker::stop()

void
Seeker::restart(...)
    CODE:
        COMPUTE_NOW()
        THIS->restart(now);

void
Seeker::pause(...)
    CODE:
        COMPUTE_NOW()
        THIS->pause(now);

void
Seeker::resume(...)
    CODE:
        COMPUTE_NOW()
        THIS->resume(now);

bool
Seeker::is_paused()

bool
Seeker::is_active()

void
Seeker::DESTROY()
    CODE:
        delete THIS;


