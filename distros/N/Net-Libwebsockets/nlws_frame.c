#include "nlws_frame.h"

void nlws_destroy_frame (void *_frame) {
    frame_t *frame_p = _frame;

    Safefree(frame_p->pre_plus_payload);
}
