
#include <stdlib.h>
#include "Ticker.h"

using namespace std;

Ticker::Ticker(IClock *clock, ICompleter *completer) :
               clock(clock),
               completer(completer),
               _is_active(false),
               _is_paused(false) {
}

Ticker::~Ticker() {
    if (_is_active) unregister_ticker();
    delete completer;
}

void Ticker::start(Uint32 now) {
    _is_active = true;
    register_ticker();
}

void Ticker::stop() {
    _is_active = false;
    unregister_ticker();
}

void Ticker::pause(Uint32 now) {
    _is_paused = true;
}

void Ticker::resume(Uint32 now) {
    _is_paused = false;
}

void Ticker::tick(Uint32 now) {
    if (_is_paused) return;
    on_tick(now);
}

bool Ticker::is_active() const {
    return _is_active;
}

bool Ticker::is_paused() const {
    return _is_paused;
}

void Ticker::register_ticker() {
    clock->register_ticker(this);
}

void Ticker::unregister_ticker() {
    clock->unregister_ticker(this);
}

void Ticker::on_complete(Uint32 now) {
    completer->animation_complete(now);
}

