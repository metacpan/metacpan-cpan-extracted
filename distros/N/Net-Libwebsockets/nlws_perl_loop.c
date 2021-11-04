#include "nlws.h"
#include "nlws_perl_loop.h"
#include "xshelper/xshelper.h"

#define DEBUG 0

#if DEBUG
#define LOG_FUNC fprintf(stderr, "%s\n", __func__)
#else
#define LOG_FUNC
#endif

static int
init_pt_custom (struct lws_context *cx, void *_loop, int tsi) {
    LOG_FUNC;

    nlws_abstract_loop_t* myloop_p = lws_evlib_tsi_to_evlib_pt(cx, tsi);

    nlws_abstract_loop_t *sourceloop_p = _loop;

    PERL_CONTEXT_FROM_STRUCT(sourceloop_p);

    SV* methargs[] = {
        newSVuv( (UV) cx ),
        NULL,
    };

    xsh_call_object_method_void( aTHX_ sourceloop_p->perlobj, "set_lws_context", methargs );

    StructCopy(sourceloop_p, myloop_p, nlws_abstract_loop_t);

    myloop_p->lws_context = cx;

    SvREFCNT_inc(myloop_p->perlobj);

    return 0;
}

static int
custom_io_accept (struct lws *wsi) {
    LOG_FUNC;

    nlws_abstract_loop_t* myloop_p = lws_evlib_wsi_to_evlib_pt(wsi);

    PERL_CONTEXT_FROM_STRUCT(myloop_p);

    int fd = lws_get_socket_fd(wsi);

    SV* myloop_sv = myloop_p->perlobj;

    SV* args[] = { newSViv(fd), NULL };

    xsh_call_object_method_void(aTHX_ myloop_sv, "add_fd", args);

    return 0;
}

static void
custom_io (struct lws *wsi, unsigned int flags) {
    LOG_FUNC;

    nlws_abstract_loop_t* myloop_p = lws_evlib_wsi_to_evlib_pt(wsi);

    int fd = lws_get_socket_fd(wsi);

    if (-1 != fd) {
        PERL_CONTEXT_FROM_STRUCT(myloop_p);

        SV* myloop_sv = myloop_p->perlobj;

        char *method_name;

        if (flags & LWS_EV_START) {
            method_name = "add_to_fd";
        }
        else {
            method_name = "remove_from_fd";
        }

        SV* args[] = {
            newSViv(fd),
            newSVuv(flags),
            NULL,
        };

        xsh_call_object_method_void(aTHX_ myloop_sv, method_name, args );
    }
}

static int
custom_io_close (struct lws *wsi) {
    LOG_FUNC;

    nlws_abstract_loop_t* myloop_p = lws_evlib_wsi_to_evlib_pt(wsi);

    int fd = lws_get_socket_fd(wsi);

    if (-1 != fd) {
        PERL_CONTEXT_FROM_STRUCT(myloop_p);

        SV* myloop_sv = myloop_p->perlobj;

        SV* args[] = { newSViv(fd), NULL };

        xsh_call_object_method_void(aTHX_ myloop_sv, "remove_fd", args);
    }

    return 0;
}

# if 0
static void
custom_destroy_wsi (struct lws *wsi) {
    LOG_FUNC;

    nlws_abstract_loop_t* myloop_p = lws_evlib_wsi_to_evlib_pt(wsi);

    PERL_CONTEXT_FROM_STRUCT(myloop_p);
}

static void
custom_destroy_context1 (struct lws_context *context) {
    LOG_FUNC;
    fprintf(stderr, "lws_context = %p\n", context);
}

static void
custom_destroy_context2 (struct lws_context *context) {
    LOG_FUNC;
    fprintf(stderr, "lws_context = %p\n", context);
}
#endif

static void
custom_destroy_pt (struct lws_context *cx, int tsi) {
    LOG_FUNC;

    nlws_abstract_loop_t* myloop_p = lws_evlib_tsi_to_evlib_pt(cx, tsi);

    PERL_CONTEXT_FROM_STRUCT(myloop_p);

    SvREFCNT_dec(myloop_p->perlobj);
}

const struct lws_event_loop_ops event_loop_ops_custom = {
    .name                   = "net-lws-custom-loop",

    .init_pt                = init_pt_custom,
    .init_vhost_listen_wsi  = custom_io_accept,
    .sock_accept            = custom_io_accept,
    .io                     = custom_io,
    .wsi_logical_close      = custom_io_close,

# if 0
    .destroy_wsi            = custom_destroy_wsi,
    .destroy_context1       = custom_destroy_context1,
    .destroy_context2       = custom_destroy_context2,
#endif
    .destroy_pt       = custom_destroy_pt,

    .evlib_size_pt          = sizeof(nlws_abstract_loop_t),
};

const lws_plugin_evlib_t evlib_custom = {
    .hdr = {
        "custom perl loop",
        "net_lws_plugin",
        LWS_BUILD_HASH,
        LWS_PLUGIN_API_MAGIC,
    },

    .ops = &event_loop_ops_custom,
};
