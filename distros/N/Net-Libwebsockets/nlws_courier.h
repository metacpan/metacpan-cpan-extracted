#ifndef NLWS_COURIER_H
#define NLWS_COURIER_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <unistd.h>
#include <stdbool.h>

#include <libwebsockets.h>

#include "nlws.h"

typedef struct {
    struct lws *wsi;

    unsigned on_text_count;
    SV** on_text;

    unsigned on_binary_count;
    SV** on_binary;

    struct lws_ring *ring;
    unsigned consume_pending_count;

    unsigned pauses;

    pid_t pid;

    bool            close_requested;
    uint16_t        close_status;
    unsigned char   close_reason[MAX_CLOSE_REASON_LENGTH];
    STRLEN          close_reason_length;
} courier_t;

courier_t* nlws_create_courier (pTHX_ struct lws *wsi);

void nlws_destroy_courier (pTHX_ courier_t* courier);

#endif
