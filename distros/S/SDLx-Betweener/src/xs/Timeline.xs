
#include "VectorTypes.h"
#include "CycleControl.h"
#include "Timeline.h"
#include "ICompleter.h"
#include "ISeekerTarget.h"
#include "Seeker.h"
#include "PerlDirectSeekerTarget.h"
#include "PerlCompleterFactory.h"
#include "PerlProxyFactory.h"
#include "PerlPathFactory.h"
#include "SDL.h"

MODULE = SDLx::Betweener         PACKAGE = SDLx::Betweener::Timeline

Timeline *
Timeline::new()

void
Timeline::tick(...)
    CODE:
        Uint32 now = items == 2?     \
            (Uint32) SvIV(ST(1)):    \
            (Uint32) SDL_GetTicks(); \
        THIS->tick(now);

Tween *
Timeline::_tween_int(proxy_type, proxy_args, duration, from, to, ease, forever, repeat, bounce, reverse, done)
    int    proxy_type
    SV    *proxy_args
    int    duration
    int    from
    int    to
    int    ease
    bool   forever
    int    repeat
    bool   bounce
    bool   reverse
    SV    *done
    CODE:
        IProxy<int,1> *proxy     = Build_Proxy<int,1>(proxy_type, proxy_args);
        ICompleter    *completer = Build_Completer(done);
        CycleControl  *control   = new CycleControl(forever, repeat, bounce, reverse);
        Tween         *tween     = THIS->build_int_tween(proxy, completer, duration, from, to, ease, control);
        char           CLASS[]   = "SDLx::Betweener::Tween";
        RETVAL                   = tween;
    OUTPUT:
        RETVAL

Tween *
Timeline::_tween_float(proxy_type, proxy_args, duration, from, to, ease, forever, repeat, bounce, reverse, done)
    int    proxy_type
    SV    *proxy_args
    int    duration
    float  from
    float  to
    int    ease
    bool   forever
    int    repeat
    bool   bounce
    bool   reverse
    SV    *done
    CODE:
        IProxy<float,1> *proxy     = Build_Proxy<float,1>(proxy_type, proxy_args);
        ICompleter      *completer = Build_Completer(done);
        CycleControl    *control   = new CycleControl(forever, repeat, bounce, reverse);
        Tween           *tween     = THIS->build_float_tween(proxy, completer, duration, from, to, ease, control);
        char             CLASS[]   = "SDLx::Betweener::Tween";
        RETVAL                     = tween;
    OUTPUT:
        RETVAL

Tween *
Timeline::_tween_path(proxy_type, proxy_args, duration, path_type, path_args, ease, forever, repeat, bounce, reverse, done)
    int    proxy_type
    SV    *proxy_args
    int    duration
    int    path_type
    SV    *path_args
    int    ease
    bool   forever
    int    repeat
    bool   bounce
    bool   reverse
    SV    *done
    CODE:
        IProxy<int,2> *proxy     = Build_Proxy<int,2>(proxy_type, proxy_args);
        ICompleter    *completer = Build_Completer(done);
        CycleControl  *control   = new CycleControl(forever, repeat, bounce, reverse);
        IPath         *path      = Build_Path(path_type, path_args);
        Tween         *tween     = THIS->build_path_tween(proxy, completer, duration, path, ease, control);
        char           CLASS[]   = "SDLx::Betweener::Tween";
        RETVAL                   = tween;
    OUTPUT:
        RETVAL

Tween *
Timeline::_tween_rgba(proxy_type, proxy_args, duration, from, to, ease, forever, repeat, bounce, reverse, done)
    int    proxy_type
    SV    *proxy_args
    int    duration
    Uint32 from
    Uint32 to
    int    ease
    bool   forever
    int    repeat
    bool   bounce
    bool   reverse
    SV    *done
    CODE:
        Vector4c from_v, to_v;
        from_v[3] = (from & 0x000000FF)      ;
        from_v[2] = (from & 0x0000FF00) >>  8;
        from_v[1] = (from & 0x00FF0000) >> 16;
        from_v[0] = (from & 0xFF000000) >> 24;
          to_v[3] = (to   & 0x000000FF)      ;
          to_v[2] = (to   & 0x0000FF00) >>  8;
          to_v[1] = (to   & 0x00FF0000) >> 16;
          to_v[0] = (to   & 0xFF000000) >> 24;

        IProxy<int,4> *proxy     = Build_Proxy<int,4>(proxy_type, proxy_args);
        ICompleter    *completer = Build_Completer(done);
        CycleControl  *control   = new CycleControl(forever, repeat, bounce, reverse);
        Tween         *tween     = THIS->build_rgba_tween(proxy, completer, duration, from_v, to_v, ease, control);
        char           CLASS[]   = "SDLx::Betweener::Tween";
        RETVAL                   = tween;
    OUTPUT:
        RETVAL

Seeker *
Timeline::_tween_seek(proxy_type, proxy_args, speed, start_xy_sv, target_sv, done)
    int    proxy_type
    SV    *proxy_args
    float  speed
    SV    *start_xy_sv
    SV    *target_sv
    SV    *done
    CODE:
        AV*      arr = (AV*) SvRV(start_xy_sv);
        SV**     e1  = av_fetch(arr, 0, 0);
        SV**     e2  = av_fetch(arr, 1, 0);
        Vector2f xy  = { {(float) SvIV(*e1), (float) SvIV(*e2)} };

        IProxy<int,2> *proxy     = Build_Proxy<int,2>(proxy_type, proxy_args);
        ICompleter    *completer = Build_Completer(done);
        ISeekerTarget *target    = new PerlDirectSeekerTarget(target_sv);
        Seeker        *seeker    = new Seeker(THIS, completer, proxy, target, xy, speed);
        char           CLASS[]   = "SDLx::Betweener::Seeker";
        RETVAL                   = seeker;
    OUTPUT:
        RETVAL

