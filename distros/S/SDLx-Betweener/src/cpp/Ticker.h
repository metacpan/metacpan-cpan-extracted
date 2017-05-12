
#ifndef TICKER_H
#define TICKER_H

#include <stdlib.h>
#include "IClock.h"
#include "ITicker.h"
#include "ICompleter.h"
#include "Types.h"

class Ticker : public ITicker {

    public:
        Ticker(IClock *clock, ICompleter *completer);
        virtual ~Ticker();
        virtual void start    (Uint32 now);
        virtual void stop     ();
        virtual void pause    (Uint32 now);
        virtual void resume   (Uint32 now);
        virtual void tick     (Uint32 now);
                bool is_active() const;
                bool is_paused() const;
    protected:
        virtual void on_tick(Uint32 now) = 0;
        virtual void on_complete(Uint32 now);
    private:
        IClock     *clock;
        ICompleter *completer;
        bool        _is_active;
        bool        _is_paused;
        void        register_ticker();
        void        unregister_ticker();
       
};

#endif
