#ifndef ST_ABI_H
#define ST_ABI_H

/* Shared C ABI between Template::Stencil (the provider) and consumers such as
 * Punk, whose view tier renders a template without a Perl frame between the
 * dispatcher and the engine. It is resolved at RUNTIME via
 * Template::Stencil::_abi_ptr - a DBI-style function-pointer table - so there
 * is no link-time symbol coupling and each dist builds and upgrades
 * independently. A consumer reaches the header through ExtUtils::Depends, or
 * vendors a copy pinned at ST_ABI_VERSION, and checks abi_version at boot; a
 * mismatch means "call the Perl-visible render method", never a crash.
 *
 * The table only ever grows at the end; ST_ABI_VERSION bumps on any append,
 * and a consumer requires abi_version >= the version it was written against,
 * treating a later table as a superset it uses a prefix of.
 *
 * Perl headers (EXTERN.h / perl.h / XSUB.h) must be included before this file
 * so SV, HV and pTHX are defined. */

#define ST_ABI_VERSION 1

typedef struct st_abi {
    int abi_version;                     /* == ST_ABI_VERSION */

    /* The opaque engine handle behind a blessed Template::Stencil object (what
     * Template::Stencil->new returns), building it on first use exactly as the
     * render method does. Returns NULL for anything that is not one rather
     * than croaking, so it is safe to probe with on a fall-back path. (The one
     * thing it will still croak on is an engine allocation failing.)
     *
     * The handle belongs to the object: it stays valid while that SV is alive
     * and the caller does not free it. Hold a reference to the OBJECT, and call
     * this on each render rather than caching the pointer - under ithreads a
     * cloned object drops its engine and rebuilds a fresh one lazily, so a
     * cached handle would outlive what it points at. The lookup is a walk of
     * the object's magic chain, which is why it is cheap enough to mean that. */
    void *(*engine_of)(pTHX_ SV *obj_sv);

    /* Render through an engine. `tmpl` is a template name or source string
     * (dispatched by the same rule as the render method), `data` the variables,
     * `opts` an optional hashref (wrapper => name | undef) or NULL.
     *
     * On success returns a new SV the CALLER OWNS - wire-ready UTF-8 bytes
     * unless the engine was built with chars => 1. On failure returns NULL and
     * sets *err to a mortal SV holding "name:line: message"; the caller decides
     * whether that is a croak_sv or a 500. Never croaks of its own accord.
     *
     * Do not assign the returned SV to a plain lexical and return that: perl
     * may steal the buffer. Store it where it is going (a response body slot,
     * an SV you already own) directly. */
    SV *(*render)(pTHX_ void *engine, SV *tmpl, HV *data, SV *opts, SV **err);
} st_abi;

#endif /* ST_ABI_H */
