
#ifndef SEEKER_H
#define SEEKER_H

#include "Types.h"
#include "VectorTypes.h"
#include "Vector.h"
#include "IClock.h"
#include "Ticker.h"
#include "IProxy.h"
#include "ISeekerTarget.h"

class Seeker : public Ticker {

    public:
        Seeker(IClock *clock, ICompleter *completer, IProxy<int,2> *proxy, ISeekerTarget *target, Vector2f seeker_start_xy, float speed);
        ~Seeker();
        void start   (Uint32 now);
        void stop    ();
        void pause   (Uint32 now);
        void resume  (Uint32 now);
        void restart (Uint32 now);

    protected:
        void on_tick (Uint32 now);
    private:
        ISeekerTarget  *target;
        IProxy<int,2>  *proxy;
        float           speed;
        Vector2f        last_xy;
        Vector2f        orig_xy;
        Uint32          last_tick_time;
        Uint32          pause_start_time;
 
};

#endif
