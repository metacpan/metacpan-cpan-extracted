
#include <stdlib.h>
#include "Tween.h"
#include "easing.h"

Tween::Tween(IClock *clock, ICompleter *completer,
             ITweenForm *form, Uint32 duration, int ease_type,
             CycleControl *control) :
    Ticker(clock, completer),
    form(form),
    control(control),
    duration(duration),
    cycle_start_time(0),
    last_cycle_complete_time(0),
    pause_start_time(0),
    total_pause_time(0),
    ease_func(Get_Ease(ease_type)) {
}

Tween::~Tween() {
    delete form;
    delete control;
}

void Tween::start(Uint32 now) {
    Ticker::start(now);
    control->animation_started();

    cycle_start_time         = now;
    last_cycle_complete_time = 0;
    total_pause_time         = 0;
    form->start(control->is_reversed()? 1 :0);
}

void Tween::stop() {
    Ticker::stop();
    last_cycle_complete_time =
        cycle_start_time + duration + total_pause_time;
    total_pause_time = 0;
}

void Tween::pause(Uint32 now) {
    Ticker::pause(now);
    pause_start_time = now;
}

void Tween::resume(Uint32 now) {
    Ticker::resume(now);
    total_pause_time += now - pause_start_time;
    pause_start_time = 0;
}

Uint32 Tween::get_cycle_start_time() {
    return cycle_start_time;
}

Uint32 Tween::get_total_pause_time() {
    return total_pause_time;
}

Uint32 Tween::get_duration() {
    return duration;
}

void Tween::set_duration(Uint32 new_duration, Uint32 now) {
    float ratio      = 1.0 - (float) new_duration / (float) duration;
    double elapsed   = now - cycle_start_time - total_pause_time;
    duration         = new_duration;
    cycle_start_time = cycle_start_time + total_pause_time + elapsed * ratio;
    total_pause_time = 0;
}

void Tween::on_tick(Uint32 now) {
    // tick on some other tween in timeline could have stopped me
    if (!is_active()) { return; }

    bool   is_complete = 0;
    Uint32 elapsed     = now - cycle_start_time - total_pause_time;

    if (elapsed >= duration) {
        is_complete = 1;
        elapsed     = duration;
    }
    float t_normal = (float) elapsed / duration;
    float eased    = ease_func(t_normal);

    if (control->is_reversed()) eased = 1 - eased;
    form->tick(eased);

    // check is_active because tween tick could have stopped the tween
    if (!is_active() || !is_complete) { return; }

    control->cycle_complete();

    if (control->is_animation_complete()) {
        stop();
        on_complete(last_cycle_complete_time);
        return;
    }

    // begin repeat cycle
    cycle_start_time         += elapsed;
    last_cycle_complete_time  = 0;
}

