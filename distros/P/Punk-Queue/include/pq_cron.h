#ifndef PQ_CRON_H
#define PQ_CRON_H

/* pq_cron.h - the cron expression parser and the next-occurrence walk.
 * Pure C over epoch seconds; no database, no Perl values in the hot parts.
 *
 * Five fields - minute hour dom month dow - compiled once into bitmasks.
 * Supported: `*`, ranges a-b, steps *\/n and a-b\/n, lists a,b,c,
 * case-insensitive three-letter month and day names, the @ aliases, and
 * `@every <n>(s|m|h|d)`. Deliberately excluded, and rejected BY NAME
 * rather than mis-parsed: L W # ? and second/year fields.
 *
 * The vixie dom/dow OR rule is implemented and separately flagged: when
 * BOTH day fields are restricted, a day matching either fires; when only
 * one is restricted, it alone gates. This is the single most common cron
 * bug and it gets its own test block.
 *
 * A spec that can never match ("0 0 30 2 *") is rejected at parse time -
 * the 5-year walk cap doubles as the detector - so the failure is a boot
 * croak naming the spec, not a cron that silently never fires. */

typedef struct pq_cron {
    U64 minute;              /* bits 0-59                                */
    U32 hour;                /* bits 0-23                                */
    U32 dom;                 /* bits 1-31                                */
    U16 mon;                 /* bits 1-12                                */
    U8  dow;                 /* bits 0-6, 0 = Sunday (7 folds to 0)      */
    U8  dom_restricted;      /* the vixie OR flags                       */
    U8  dow_restricted;
    IV  every;               /* @every interval seconds; 0 = field mode  */
} pq_cron;

#define PQ_CRON_ALL_MIN  ((U64)0xFFFFFFFFFFFFFFFULL)   /* 60 bits */
#define PQ_CRON_ALL_HOUR ((U32)0x00FFFFFF)             /* 24 bits */
#define PQ_CRON_ALL_DOM  ((U32)0xFFFFFFFE)             /* bits 1-31 */
#define PQ_CRON_ALL_MON  ((U16)0x1FFE)                 /* bits 1-12 */
#define PQ_CRON_ALL_DOW  ((U8)0x7F)                    /* bits 0-6 */

/* ---- field parsing --------------------------------------------------------- */

static const char *const PQ_CRON_MONTHS[] =
    { "jan","feb","mar","apr","may","jun",
      "jul","aug","sep","oct","nov","dec" };
static const char *const PQ_CRON_DAYS[] =
    { "sun","mon","tue","wed","thu","fri","sat" };

/* One name or number token out of a field chunk. Returns the numeric
 * value, or -1 with *errp set. */
static int pq_cron_atom(pTHX_ const char **pp, const char *end,
                        const char *const *names, int nnames,
                        int base, const char **errp) {
    const char *p = *pp;
    if (p < end && isALPHA((U8)*p)) {
        char buf[4];
        int i;
        if (end - p < 3) { *errp = p; return -1; }
        for (i = 0; i < 3; i++) buf[i] = (char)toLOWER((U8)p[i]);
        buf[3] = 0;
        for (i = 0; i < nnames; i++)
            if (strEQ(buf, names[i])) { *pp = p + 3; return i + base; }
        *errp = p;
        return -1;
    }
    if (p < end && isDIGIT((U8)*p)) {
        int v = 0;
        while (p < end && isDIGIT((U8)*p)) v = v * 10 + (*p++ - '0');
        *pp = p;
        return v;
    }
    *errp = p;
    return -1;
}

/* Parse one field into a mask. lo/hi is the legal range; names may be
 * NULL. Returns 0 on success, or the offending position via *errp. */
static int pq_cron_field(pTHX_ const char *s, const char *end,
                         int lo, int hi,
                         const char *const *names, int nnames,
                         U64 *mask, const char **errp) {
    U64 out = 0;
    const char *p = s;

    while (p < end) {
        int a, b, step = 1;

        if (*p == '*') {
            p++;
            a = lo; b = hi;
        }
        else {
            a = pq_cron_atom(aTHX_ &p, end, names, nnames, lo, errp);
            if (a < 0) return -1;
            if (p < end && *p == '-') {
                p++;
                b = pq_cron_atom(aTHX_ &p, end, names, nnames, lo, errp);
                if (b < 0) return -1;
            }
            else b = a;
        }
        if (p < end && *p == '/') {
            p++;
            step = pq_cron_atom(aTHX_ &p, end, NULL, 0, 0, errp);
            if (step <= 0) return -1;
            if (b == a) b = hi;   /* a/n means a-hi/n; star-slash-n arrives
                                   * here with a=lo, b=hi already        */
        }

        if (a < lo || a > hi || b > hi) { *errp = s; return -1; }

        if (a <= b) {
            int v;
            for (v = a; v <= b; v += step) out |= ((U64)1) << v;
        }
        else {
            /* a wrapped range (fri-mon): both arcs */
            int v;
            for (v = a; v <= hi; v += step) out |= ((U64)1) << v;
            for (v = lo; v <= b; v += step) out |= ((U64)1) << v;
        }

        if (p < end && *p == ',') { p++; continue; }
        break;
    }
    if (p != end) { *errp = p; return -1; }
    *mask = out;
    return 0;
}

/* The whole expression. Croaks on anything unsupported, naming the token
 * - a mis-parsed cron that fires at the wrong time is far worse than a
 * loud rejection. */
static void pq_cron_parse(pTHX_ const char *expr, STRLEN len, pq_cron *c) {
    const char *p = expr, *end = expr + len;
    const char *fs[5], *fe[5];
    int i;

    memset(c, 0, sizeof *c);

    while (p < end && isSPACE((U8)*p)) p++;
    while (end > p && isSPACE((U8)end[-1])) end--;
    if (p >= end)
        croak("Punk::Queue: empty cron expression");

    /* the deliberate exclusions, rejected by name */
    {
        const char *q;
        for (q = p; q < end; q++) {
            if (*q == 'L' || *q == 'W' || *q == '#' || *q == '?')
                croak("Punk::Queue: cron token '%c' is not supported "
                      "(L, W, # and ? are excluded in this release)", *q);
        }
    }

    if (*p == '@') {
        static const struct { const char *name; const char *expr; }
        aliases[] = {
            { "@yearly",   "0 0 1 1 *" }, { "@annually", "0 0 1 1 *" },
            { "@monthly",  "0 0 1 * *" }, { "@weekly",   "0 0 * * 0" },
            { "@daily",    "0 0 * * *" }, { "@midnight", "0 0 * * *" },
            { "@hourly",   "0 * * * *" },
        };
        size_t n = (size_t)(end - p);
        unsigned int k;
        for (k = 0; k < sizeof aliases / sizeof *aliases; k++) {
            if (n == strlen(aliases[k].name)
                && memEQ(p, aliases[k].name, n)) {
                pq_cron_parse(aTHX_ aliases[k].expr,
                              strlen(aliases[k].expr), c);
                return;
            }
        }
        if (n > 7 && memEQ(p, "@every ", 7)) {
            const char *q = p + 7;
            IV v = 0;
            while (q < end && isDIGIT((U8)*q)) v = v * 10 + (*q++ - '0');
            if (v > 0 && q + 1 == end) {
                IV mult = *q == 's' ? 1 : *q == 'm' ? 60
                        : *q == 'h' ? 3600 : *q == 'd' ? 86400 : 0;
                if (mult) {
                    c->every = v * mult;
                    return;
                }
            }
            croak("Punk::Queue: @every wants '<n>(s|m|h|d)', not '%.*s'",
                  (int)(end - p), p);
        }
        croak("Punk::Queue: unknown cron alias '%.*s'", (int)(end - p), p);
    }

    /* split five whitespace-separated fields */
    for (i = 0; i < 5; i++) {
        while (p < end && isSPACE((U8)*p)) p++;
        if (p >= end)
            croak("Punk::Queue: cron expression has %d field(s), needs 5 "
                  "(minute hour day-of-month month day-of-week)", i);
        fs[i] = p;
        while (p < end && !isSPACE((U8)*p)) p++;
        fe[i] = p;
    }
    while (p < end && isSPACE((U8)*p)) p++;
    if (p < end)
        croak("Punk::Queue: cron expression has more than 5 fields - "
              "second and year fields are not supported");

    {
        const char *err = NULL;
        U64 m;
        if (pq_cron_field(aTHX_ fs[0], fe[0], 0, 59, NULL, 0, &m, &err))
            croak("Punk::Queue: bad cron minute field near '%.8s'", err);
        c->minute = m & PQ_CRON_ALL_MIN;
        if (pq_cron_field(aTHX_ fs[1], fe[1], 0, 23, NULL, 0, &m, &err))
            croak("Punk::Queue: bad cron hour field near '%.8s'", err);
        c->hour = (U32)m & PQ_CRON_ALL_HOUR;
        if (pq_cron_field(aTHX_ fs[2], fe[2], 1, 31, NULL, 0, &m, &err))
            croak("Punk::Queue: bad cron day-of-month field near '%.8s'",
                  err);
        c->dom = (U32)m & PQ_CRON_ALL_DOM;
        if (pq_cron_field(aTHX_ fs[3], fe[3], 1, 12,
                          PQ_CRON_MONTHS, 12, &m, &err))
            croak("Punk::Queue: bad cron month field near '%.8s'", err);
        c->mon = (U16)m & PQ_CRON_ALL_MON;
        if (pq_cron_field(aTHX_ fs[4], fe[4], 0, 7,
                          PQ_CRON_DAYS, 7, &m, &err))
            croak("Punk::Queue: bad cron day-of-week field near '%.8s'",
                  err);
        /* dow 7 is Sunday in half the world's crontabs: fold bit 7 into
         * bit 0 AFTER the mask is built. (Folding per-atom was the bug
         * that turned `*` - which expands to the range 0-7 - into
         * Sunday-only, quietly restricting every cron to one weekday.) */
        m |= (m >> 7) & 1;
        c->dow = (U8)m & PQ_CRON_ALL_DOW;
    }

    if (!c->minute || !c->hour || !c->dom || !c->mon || !c->dow)
        croak("Punk::Queue: a cron field matches nothing");

    c->dom_restricted = (c->dom != PQ_CRON_ALL_DOM);
    c->dow_restricted = (c->dow != PQ_CRON_ALL_DOW);
}

/* ---- timezone-aware civil time ---------------------------------------------
 *
 * tz is 'UTC' (default), 'local' (POSIX mktime/localtime_r, honouring the
 * process TZ), or a fixed '+HHMM'/'-HHMM'. No timezone database: UTC and
 * fixed offsets use our own civil-date arithmetic; only 'local' touches
 * libc, because only 'local' has DST. */

typedef struct pq_civil {
    int year, mon, mday, hour, min, wday;   /* mon 1-12, wday 0=Sun */
} pq_civil;

enum { PQ_TZ_UTC, PQ_TZ_LOCAL, PQ_TZ_FIXED };

typedef struct pq_tz {
    int kind;
    IV  offset;              /* seconds east of UTC, PQ_TZ_FIXED only */
} pq_tz;

static void pq_tz_parse(pTHX_ const char *tz, STRLEN len, pq_tz *out) {
    out->kind = PQ_TZ_UTC;
    out->offset = 0;
    if (!tz || !len || (len == 3 && memEQ(tz, "UTC", 3))) return;
    if (len == 5 && memEQ(tz, "local", 5)) { out->kind = PQ_TZ_LOCAL; return; }
    if (len == 5 && (tz[0] == '+' || tz[0] == '-')
        && isDIGIT((U8)tz[1]) && isDIGIT((U8)tz[2])
        && isDIGIT((U8)tz[3]) && isDIGIT((U8)tz[4])) {
        IV hh = (tz[1] - '0') * 10 + (tz[2] - '0');
        IV mm = (tz[3] - '0') * 10 + (tz[4] - '0');
        if (hh <= 14 && mm <= 59) {
            out->kind = PQ_TZ_FIXED;
            out->offset = (hh * 3600 + mm * 60) * (tz[0] == '-' ? -1 : 1);
            return;
        }
    }
    croak("Punk::Queue: cron tz must be 'UTC', 'local' or '+HHMM', "
          "not '%.*s'", (int)len, tz);
}

/* days-from-civil (Howard Hinnant's algorithm), and back */
static IV pq_days_from_civil(int y, int m, int d) {
    IV era, yoe, doy, doe;
    y -= m <= 2;
    era = (y >= 0 ? y : y - 399) / 400;
    yoe = y - era * 400;
    doy = (153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + d - 1;
    doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    return era * 146097 + doe - 719468;
}

static void pq_civil_from_days(IV z, int *y, int *m, int *d) {
    IV era, doe, yoe, doy, mp;
    z += 719468;
    era = (z >= 0 ? z : z - 146096) / 146097;
    doe = z - era * 146097;
    yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    mp  = (5 * doy + 2) / 153;
    *d  = (int)(doy - (153 * mp + 2) / 5 + 1);
    *m  = (int)(mp + (mp < 10 ? 3 : -9));
    *y  = (int)(yoe + era * 400 + (*m <= 2));
}

/* epoch -> civil in tz */
static void pq_civil_of(pTHX_ double epoch, const pq_tz *tz, pq_civil *cv) {
    if (tz->kind == PQ_TZ_LOCAL) {
        time_t t = (time_t)epoch;
        struct tm tmv;
        (void)localtime_r(&t, &tmv);
        cv->year = tmv.tm_year + 1900;
        cv->mon  = tmv.tm_mon + 1;
        cv->mday = tmv.tm_mday;
        cv->hour = tmv.tm_hour;
        cv->min  = tmv.tm_min;
        cv->wday = tmv.tm_wday;
        return;
    }
    {
        IV t = (IV)epoch + tz->offset;
        IV days = t / 86400, secs = t % 86400;
        if (secs < 0) { secs += 86400; days--; }
        pq_civil_from_days(days, &cv->year, &cv->mon, &cv->mday);
        cv->hour = (int)(secs / 3600);
        cv->min  = (int)((secs % 3600) / 60);
        cv->wday = (int)(((days % 7) + 11) % 7);   /* epoch day 0 = Thu */
    }
}

/* civil midnight-of -> epoch, non-local frames only */
static double pq_epoch_of_civil(const pq_tz *tz, int y, int m, int d,
                                int hh, int mi) {
    IV days = pq_days_from_civil(y, m, d);
    return (double)(days * 86400 + hh * 3600 + mi * 60) - (double)tz->offset;
}

/* does this civil day satisfy the day fields, vixie OR included */
static int pq_cron_day_ok(const pq_cron *c, const pq_civil *cv) {
    int dom_hit = (c->dom >> cv->mday) & 1;
    int dow_hit = (c->dow >> cv->wday) & 1;
    if (c->dom_restricted && c->dow_restricted) return dom_hit || dow_hit;
    if (c->dom_restricted) return dom_hit;
    if (c->dow_restricted) return dow_hit;
    return 1;
}

#define PQ_CRON_HORIZON (5.0 * 366.0 * 86400.0)

/* The next occurrence strictly after `from`, or -1 when none exists
 * within five years (which the parser uses to reject unmatchable specs).
 *
 * The walk is structured - skip non-matching months by month, days by
 * day, hours by hour - so the worst case is thousands of steps, not the
 * millions a minute-by-minute scan would take.
 *
 * DST, for tz 'local': the walk is over epoch seconds, which never
 * produce a wall time inside the spring-forward gap, so an occurrence in
 * the skipped hour simply does not fire. In the fall-back doubled hour
 * the same wall minute exists at two epochs; a candidate whose wall
 * minute equals `from`'s is skipped, so a pinned time fires once while
 * a sweeping every-minute spec keeps firing every real minute - both the behaviours the
 * plan promises. */
static double pq_cron_next(pTHX_ const pq_cron *c, double from,
                           const pq_tz *tz) {
    double t;
    pq_civil fromcv;
    double limit = from + PQ_CRON_HORIZON;

    if (c->every > 0)
        return from + (double)c->every;

    pq_civil_of(aTHX_ from, tz, &fromcv);

    /* first whole minute strictly after from */
    t = (double)((IV)(from / 60) * 60 + 60);

    while (t <= limit) {
        pq_civil cv;
        pq_civil_of(aTHX_ t, tz, &cv);

        if (!((c->mon >> cv.mon) & 1)) {
            /* first minute of the next month */
            int y = cv.year, m = cv.mon + 1;
            if (m > 12) { m = 1; y++; }
            if (tz->kind == PQ_TZ_LOCAL) {
                struct tm tmv;
                memset(&tmv, 0, sizeof tmv);
                tmv.tm_year = y - 1900; tmv.tm_mon = m - 1; tmv.tm_mday = 1;
                tmv.tm_isdst = -1;
                t = (double)mktime(&tmv);
            }
            else t = pq_epoch_of_civil(tz, y, m, 1, 0, 0);
            continue;
        }
        if (!pq_cron_day_ok(c, &cv)) {
            if (tz->kind == PQ_TZ_LOCAL) {
                struct tm tmv;
                memset(&tmv, 0, sizeof tmv);
                tmv.tm_year = cv.year - 1900; tmv.tm_mon = cv.mon - 1;
                tmv.tm_mday = cv.mday + 1; tmv.tm_isdst = -1;
                t = (double)mktime(&tmv);
            }
            else t = pq_epoch_of_civil(tz, cv.year, cv.mon, cv.mday, 0, 0)
                   + 86400.0;
            continue;
        }
        if (!((c->hour >> cv.hour) & 1)) {
            t += (double)((59 - cv.min) * 60 + 60);
            continue;
        }
        if (!((c->minute >> cv.min) & 1)) {
            t += 60.0;
            continue;
        }

        /* the fall-back dedupe: same wall minute as `from` fires once */
        if (tz->kind == PQ_TZ_LOCAL
            && cv.year == fromcv.year && cv.mon == fromcv.mon
            && cv.mday == fromcv.mday && cv.hour == fromcv.hour
            && cv.min == fromcv.min) {
            t += 60.0;
            continue;
        }
        return t;
    }
    return -1.0;
}

/* Parse + verify: the boot-time entry. Croaks on syntax AND on a spec
 * that can never fire. */
static void pq_cron_compile(pTHX_ const char *expr, STRLEN elen,
                            const char *tz, STRLEN tlen,
                            pq_cron *c, pq_tz *z) {
    pq_cron_parse(aTHX_ expr, elen, c);
    pq_tz_parse(aTHX_ tz, tlen, z);
    if (c->every == 0) {
        double n = pq_cron_next(aTHX_ c, (double)time(NULL), z);
        if (n < 0)
            croak("Punk::Queue: cron '%.*s' can never fire "
                  "(no occurrence within five years)", (int)elen, expr);
    }
}

#endif /* PQ_CRON_H */
