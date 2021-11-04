#ifndef NLWS_FRAME_H
#define NLWS_FRAME_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <libwebsockets.h>

typedef struct {
    U8                      *pre_plus_payload;
    size_t                  len;
    enum lws_write_protocol flags;
} frame_t;

void nlws_destroy_frame (void *_frame);

#endif
