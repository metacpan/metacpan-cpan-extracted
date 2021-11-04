#include "nlws.h"
#include "nlws_logger.h"

#include <libwebsockets.h>

int nlws_get_global_lwsl_level() {
    int level = 0;

    for (int l=0; l<LLL_COUNT; l++) {
        int cur_level = 1 << l;

        if (lwsl_visible(cur_level)) {
            level |= cur_level;
        }
    }

    return level;
}

void nlws_logger_on_refcount_change (struct lws_log_cx *cx, int _new) {
    nlws_logger_opaque_t* opaque = cx->opaque;

    PERL_CONTEXT_FROM_STRUCT(opaque);
//fprintf(stderr, "%s: refcount: %d (%d)\n", PL_phase_names[PL_phase], cx->refcount, _new);

    while (_new > 0) {
        SvREFCNT_inc(opaque->perlobj);
        _new--;
    }

    while (_new < 0) {
        SvREFCNT_dec(opaque->perlobj);
        _new++;
    }
}

void nlws_logger_emit(struct lws_log_cx *cx, int level, const char *line, size_t len) {

    // Don’t send the trailing newline to the callback.
    if (line[len-1] == '\n') {
        len--;
    }

    nlws_logger_opaque_t* opaque = cx->opaque;

    PERL_CONTEXT_FROM_STRUCT(opaque);

    SV* args[] = {
        newSViv(level),
        newSVpvn(line, len),
        NULL,
    };

    xsh_call_sv_trap_void(opaque->callback, args, LOGGER_CLASS " callback error: ");
}
