#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "plack_handler_h2.h"

MODULE = Plack::Handler::H2        PACKAGE = Plack::Handler::H2

void
ph2_run_wrapper(self, app, options)
    SV* self
    SV* app
    SV* options
  CODE:
    ph2_run(self, app, options);

void
ph2_stream_write_data_wrapper(env, session, end_stream, data)
    SV* env
    SV* session
    SV* end_stream
    SV* data
  CODE:
    ph2_stream_write_data(env, session, end_stream, data);

void
ph2_stream_write_headers_wrapper(env, session, response)
    SV* env
    SV* session
    SV* response
  CODE:
    ph2_stream_write_headers(env, session, response);
