
#ifndef CYCLECONTROL_H
#define CYCLECONTROL_H

class CycleControl {

    public:
        CycleControl(bool forever, int repeat, bool bounce, bool reverse);
        void animation_started();
        void cycle_complete();
        bool is_animation_complete();
        bool is_reversed();
        bool is_bouncing();
    private:
        bool forever;
        int  repeat;
        int  repeat_counter;
        bool bounce;
        bool reverse;
        bool _is_reversed;

};

#endif
