#ifndef POEXS_H
#define POEXS_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define MODE_RD 0
#define MODE_WR 1
#define MODE_EX 2

#if defined(PERL_VERSION) && PERL_VERSION > 9
#define POE_SV_FORMAT "%-p"
#else
#define POE_SV_FORMAT "%_"
#endif

extern void
poe_initialize(void);

extern void
poe_enqueue_data_ready(SV *kernel, int mode, int *fds, int fd_count);

extern void
poe_data_ev_dispatch_due(SV *kernel);

extern void
poe_test_if_kernel_idle(SV *kernel);

extern int
poe_data_ses_count(SV *kernel);

extern double
poe_timeh(void);

extern const char *
poe_mode_names(int mode);

extern void
poe_trap(const char *fmt, ...);

#ifdef XS_LOOP_TRACE
#include <stdio.h>
#include <stdarg.h>

extern void poexs_trace_file(const char *fmt, ...);
#define POE_TRACE_FILE(foo) poexs_trace_file foo
extern int poexs_tracing_files(void);

extern void poexs_trace_event(const char *fmt, ...);
#define POE_TRACE_EVENT(foo) poexs_trace_event foo
extern int poexs_tracing_events(void);

extern void poexs_trace_call(const char *fmt, ...);
#define POE_TRACE_CALL(foo) poexs_trace_call foo
extern int poexs_tracing_calls(void);

extern void 
poexs_data_stat_add(SV *kernel, const char *name, double value);

#define POE_STAT_ADD(kernel, name, value) \
  poexs_data_stat_add(kernel, name, value);
#else
#define POE_TRACE_FILE(foo)
#define POE_TRACE_EVENT(foo)
#define POE_TRACE_CALL(foo)
#define POE_STAT_ADD(kernel, name, value)
#endif

#endif
