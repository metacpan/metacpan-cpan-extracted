#ifndef STENCIL_RENDER_H
#define STENCIL_RENDER_H

/* Render flags */
#define STENCIL_RF_STRICT       0x1u  /* croak on undef output values */
#define STENCIL_RF_NO_SORT_KEYS 0x2u  /* raw hash order in for k,v */
#define STENCIL_RF_NO_ESCAPE    0x8u  /* auto_escape => 0: print raw */
#define STENCIL_RF_CHARS        0x10u /* chars => 1: SvUTF8-flagged
                                         result instead of the default
                                         wire-ready UTF-8 bytes */
#define STENCIL_RF_PRETTY       0x20u /* pretty => 1: post-format the
                                         rendered HTML via Eshu
                                         (optional dependency) */

/* Execute a compiled program against a data hashref. On success
 * returns the buffer SV (caller owns / mortalises); on failure returns
 * NULL and sets *err to a mortal SV "name:line: message". `prog` is
 * non-const: the first successful render stores the profiled output
 * size for later pre-grow. */
SV *stencil_render_run(pTHX_ stencil_program *prog, HV *data,
                       uint32_t flags, const char *tname, SV **err);

/* Engine-aware entry: page unit plus optional wrapper unit whose
 * {% content %} runs the page. incs vectors come from the engine's
 * link step; eff_* are the include-graph-wide render-state sizes. */
struct stencil_cache_ent;
SV *stencil_render_core(pTHX_
    stencil_program *page_prog, struct stencil_cache_ent **page_incs,
    const char *page_name,
    stencil_program *wrap_prog, struct stencil_cache_ent **wrap_incs,
    const char *wrap_name,
    uint32_t eff_stack, uint32_t eff_frames, uint32_t eff_binds,
    HV *data, HV *filters, uint32_t flags, SV **err);

/* Steady-state observability counters (cumulative; tests snapshot and
 * diff). Incremented on the slow paths only. */
extern UV stencil_stat_buf_grows;
extern UV stencil_stat_scratch_allocs;

#endif /* STENCIL_RENDER_H */
