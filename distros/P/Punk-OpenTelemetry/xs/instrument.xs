MODULE = Punk::OpenTelemetry    PACKAGE = Punk::OpenTelemetry::Instrument

PROTOTYPES: DISABLE

# Wire the SDK to the hooks the ecosystem grew for it: Punk's pk_abi request,
# response and query observers, Fetch's outbound observer, and DBIx::Loop's
# statement observer.
#
# Every registration is process-global and permanent, which is what those
# tables offer; install() is therefore idempotent and is meant to be called
# once, at boot, from the worker that will serve.

# install($tracer, %opt) -> a hashref of which points went live.
#
# Options: server, client, db (each 1 by default).
SV *
install(tracer, ...)
        SV *tracer
    CODE:
    {
        HV *out = newHV();
        int i;
        int want_server = 1, want_client = 1, want_db = 1;

        if (!(SvROK(tracer) && SvIOK(SvRV(tracer))))
            croak("Punk::OpenTelemetry::Instrument::install: "
                  "expected a Punk::OpenTelemetry::Tracer");
        for (i = 1; i + 1 < items; i += 2) {
            const char *k = SvPV_nolen(ST(i));
            int v = SvTRUE(ST(i + 1)) ? 1 : 0;
            if      (strEQ(k, "server")) want_server = v;
            else if (strEQ(k, "client")) want_client = v;
            else if (strEQ(k, "db"))     want_db = v;
        }
        OTEL_TRACER = INT2PTR(otel_tracer *, SvIV(SvRV(tracer)));
        OTEL_INSTR.server = want_server;
        OTEL_INSTR.client = want_client;
        OTEL_INSTR.db     = want_db;

        /* ---- Punk: server spans and the shipped DBI backend ------------- */
        {
            const pk_abi *A = otel_pk(aTHX);
            if (A && !OTEL_PK_INSTALLED) {
                int ok = A->on_request(aTHX_ otel_on_request, (void *)A)
                      && A->on_response(aTHX_ otel_on_response, (void *)A);
                if (ok) OTEL_PK_INSTALLED = 1;
                (void)hv_stores(out, "server", newSViv(ok ? 1 : 0));
                if (A->abi_version >= 2) {
                    int q = A->on_query(aTHX_ otel_on_query,
                                        otel_on_query_done, NULL);
                    (void)hv_stores(out, "db_punk", newSViv(q ? 1 : 0));
                }
            }
            else (void)hv_stores(out, "server",
                                 newSViv(OTEL_PK_INSTALLED ? 1 : 0));
        }

        /* ---- Fetch: client spans, and the traceparent that makes a trace
         * cross a process boundary at all ---------------------------------- */
        {
            const fetch_abi *F = otel_ft(aTHX);
            if (F && !OTEL_FT_INSTALLED) {
                int ok = F->on_request(aTHX_ otel_ft_start, otel_ft_done, NULL);
                if (ok) OTEL_FT_INSTALLED = 1;
                (void)hv_stores(out, "client", newSViv(ok ? 1 : 0));
            }
            else (void)hv_stores(out, "client",
                                 newSViv(OTEL_FT_INSTALLED ? 1 : 0));
        }

        RETVAL = newRV_noinc((SV *)out);
    }
    OUTPUT:
        RETVAL

# Turn a point on or off after installation. The registrations stay; the
# callbacks return immediately. An application drowning in database spans can
# silence those without losing its server spans.
void
configure(...)
    CODE:
    {
        int i;
        for (i = 0; i + 1 < items; i += 2) {
            const char *k = SvPV_nolen(ST(i));
            int v = SvTRUE(ST(i + 1)) ? 1 : 0;
            if      (strEQ(k, "server"))  OTEL_INSTR.server = v;
            else if (strEQ(k, "client"))  OTEL_INSTR.client = v;
            else if (strEQ(k, "db"))      OTEL_INSTR.db = v;
            else if (strEQ(k, "enabled")) OTEL_INSTR.enabled = v;
        }
    }

void
config()
    PPCODE:
        EXTEND(SP, 8);
        mPUSHp("server", 6);   mPUSHi(OTEL_INSTR.server);
        mPUSHp("client", 6);   mPUSHi(OTEL_INSTR.client);
        mPUSHp("db", 2);       mPUSHi(OTEL_INSTR.db);
        mPUSHp("enabled", 7);  mPUSHi(OTEL_INSTR.enabled);

# The recursion guard, reachable from Perl.
#
# The exporter sends spans over HTTP with Fetch, and Fetch is instrumented, so
# an export would otherwise produce a client span, which is queued, and
# exported... The first collector outage becomes an infinite loop of telemetry
# about failing to send telemetry. Everything the SDK does on its own behalf
# runs inside this.
void
suppress_begin()
    CODE:
        otel_suppress_begin();

void
suppress_end()
    CODE:
        otel_suppress_end();

IV
suppressed()
    CODE:
        RETVAL = OTEL_INSTR.suppress;
    OUTPUT:
        RETVAL

# ---- the semantic conventions, reachable for the tests ----------------------
# These are pure functions over strings and are where the cardinality rules
# live, so they are asserted directly rather than inferred from a span.

# The canonical method, or "_OTHER" for anything not in the known set. The
# method is client-controlled and otherwise unbounded, and it lands in a
# metric dimension in the metrics phase.
SV *
method(m)
        SV *m
    CODE:
    {
        STRLEN l;
        const char *s = SvPV_const(m, l);
        const char *c = otel_sc_method(s, l);
        RETVAL = newSVpv(c ? c : "_OTHER", 0);
    }
    OUTPUT:
        RETVAL

# The span status implied by an HTTP status, per span kind. A 4xx does NOT
# fail a SERVER span - the server worked and said no - but it DOES fail a
# CLIENT span, where it is a failure of the call this process made.
IV
server_status(code)
        IV code
    CODE:
        RETVAL = otel_sc_server_status(code);
    OUTPUT:
        RETVAL

IV
client_status(code)
        IV code
    CODE:
        RETVAL = otel_sc_client_status(code);
    OUTPUT:
        RETVAL

# db.operation.name: the leading keyword, uppercased and bounded.
SV *
db_operation(sql)
        SV *sql
    CODE:
    {
        STRLEN l;
        const char *s = SvPV_const(sql, l);
        char op[32];
        if (otel_sc_db_operation(s, l, op, sizeof op)) RETVAL = newSVpv(op, 0);
        else XSRETURN_UNDEF;
    }
    OUTPUT:
        RETVAL

SV *
schema_url()
    CODE:
        RETVAL = newSVpvs(OTEL_SCHEMA_URL);
    OUTPUT:
        RETVAL
