
#ifndef TIMELINE_H
#define TIMELINE_H

#include <stdlib.h>
#include <set>
#include "Types.h"
#include "VectorTypes.h"
#include "CycleControl.h"
#include "IClock.h"
#include "IProxy.h"
#include "IPath.h"
#include "ICompleter.h"
#include "Tween.h"

class Timeline : public IClock {

    public:
        Timeline();
        virtual ~Timeline();
        void   register_ticker(ITicker *ticker);
        void unregister_ticker(ITicker *ticker);
        void tick(Uint32 now);

        Tween *build_int_tween(IProxy<int,1> *proxy, ICompleter *completer,
                               int duration, int from, int to, int ease_type,
                               CycleControl *control);

        Tween *build_float_tween(IProxy<float,1> *proxy, ICompleter *completer,
                                 int duration, float from, float to, int ease_type,
                                 CycleControl *control);

        Tween *build_path_tween(IProxy<int,2> *proxy, ICompleter *completer,
                                int duration, IPath *path, int ease_type,
                                CycleControl *control);

        Tween *build_rgba_tween(IProxy<int,4> *proxy, ICompleter *completer,
                                int duration, Vector4c from, Vector4c to,
                                int ease_type, CycleControl *control);

    private:
        std::set<ITicker*> tickers;
       

};

#endif
