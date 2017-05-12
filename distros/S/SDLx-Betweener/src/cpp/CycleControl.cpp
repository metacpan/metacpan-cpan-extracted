
#include "CycleControl.h"

CycleControl::CycleControl(bool forever, int repeat, bool bounce, bool reverse) :
    forever(forever),
    repeat(repeat),
    repeat_counter(0),
    bounce(bounce),
    reverse(reverse),
    _is_reversed(0) {
}

void CycleControl::animation_started() {
    repeat_counter = repeat;
    _is_reversed   = reverse;
}

void CycleControl::cycle_complete() {
    if (!forever) repeat_counter--;
    if (bounce) _is_reversed = !_is_reversed;
}

bool CycleControl::is_animation_complete() {
    return !forever && repeat_counter <= 0;
}

bool CycleControl::is_reversed() {
   return _is_reversed; 
}

bool CycleControl::is_bouncing() {
    return bounce;
}



