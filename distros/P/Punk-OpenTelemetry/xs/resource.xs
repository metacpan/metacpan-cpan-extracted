MODULE = Punk::OpenTelemetry    PACKAGE = Punk::OpenTelemetry::Resource

PROTOTYPES: DISABLE

# instance_id(): a fresh UUID-shaped id, from the same entropy source the
# trace ids use. Never cached - see otel_resource.h for why rand() is not an
# option here.
SV *
instance_id()
    CODE:
        RETVAL = otel_res_instance_id(aTHX);
    OUTPUT:
        RETVAL

# detect(%overrides): the resource, as a hashref.
#
# Precedence, lowest first: the detected defaults, then
# OTEL_RESOURCE_ATTRIBUTES, then OTEL_SERVICE_NAME for the service name, then
# the explicit arguments - which win over everything, including the
# environment, because a caller that said so meant it.
SV *
detect(...)
    CODE:
    {
        HV *r = newHV();
        HV *over = (HV *)sv_2mortal((SV *)newHV());
        SV *service = NULL;
        SV *tmp;
        int i;

        if (items % 2)
            croak("Punk::OpenTelemetry::Resource::detect: "
                  "odd number of overrides");
        for (i = 0; i + 1 < items; i += 2) {
            STRLEN kl;
            const char *k = SvPV_const(ST(i), kl);
            if (kl == 12 && memEQ(k, "service_name", 12))
                service = ST(i + 1);            /* the one named override */
            else
                (void)hv_store(over, k, (I32)kl, newSVsv(ST(i + 1)), 0);
        }

        if (!(service && SvOK(service))) {
            SV **e = hv_fetchs(GvHV(PL_envgv), "OTEL_SERVICE_NAME", 0);
            service = (e && *e && SvOK(*e)) ? *e : NULL;
        }
        if (!(service && SvOK(service)))
            service = sv_2mortal(newSVpvs("unknown_service"));

        /* unknown_service is the spec's default and a genuinely bad place to
         * end up: it is the single most common reason a trace cannot be found
         * again, because every unnamed service in the fleet shares the name.
         * Say so once, at boot, where somebody can still act on it. */
        {
            STRLEN sl;
            const char *sp = SvPV_const(service, sl);
            if (sl == 15 && memEQ(sp, "unknown_service", 15)) {
                SV **d = hv_fetchs(GvHV(PL_envgv), "OTEL_SDK_DISABLED", 0);
                if (!(d && *d && SvTRUE(*d)))
                    warn("Punk::OpenTelemetry: no service.name configured - "
                         "telemetry will arrive as 'unknown_service' and be "
                         "indistinguishable from every other unnamed "
                         "service\n");
            }
        }

        (void)hv_stores(r, "service.name", newSVsv(service));
        (void)hv_stores(r, "service.instance.id", otel_res_instance_id(aTHX));
        (void)hv_stores(r, "telemetry.sdk.name", newSVpvs("punk-opentelemetry"));
        (void)hv_stores(r, "telemetry.sdk.language", newSVpvs("perl"));
        tmp = get_sv("Punk::OpenTelemetry::VERSION", 0);
        (void)hv_stores(r, "telemetry.sdk.version",
                        (tmp && SvOK(tmp)) ? newSVsv(tmp) : newSV(0));
        (void)hv_stores(r, "process.pid", newSViv((IV)PerlProc_getpid()));
        (void)hv_stores(r, "process.runtime.name", newSVpvs("perl"));
        /* sprintf('%vd', $^V), built from the same numbers $^V is */
        (void)hv_stores(r, "process.runtime.version",
            newSVpvf("%d.%d.%d", (int)PERL_REVISION, (int)PERL_VERSION,
                                 (int)PERL_SUBVERSION));
        tmp = otel_res_perl_sv(aTHX_ "\030", 1);          /* $^X */
        if (tmp) (void)hv_stores(r, "process.executable.name", newSVsv(tmp));

        tmp = otel_res_hostname(aTHX);
        if (tmp) (void)hv_stores(r, "host.name", newSVsv(tmp));
#ifdef ARCHNAME
        /* $Config{archname}, without loading Config: the macro IS what the
         * Config entry was generated from. */
        (void)hv_stores(r, "host.arch", newSVpvs(ARCHNAME));
#endif

        {
            SV **e = hv_fetchs(GvHV(PL_envgv), "OTEL_RESOURCE_ATTRIBUTES", 0);
            if (e && *e && SvOK(*e) && SvCUR(*e)) {
                STRLEN el;
                const char *ep = SvPV_const(*e, el);
                otel_res_parse_env_attrs(aTHX_ r, ep, el);
            }
        }

        {   /* explicit overrides win over everything, including the
             * environment. Applied last, so they always do. */
            HE *he;
            hv_iterinit(over);
            while ((he = hv_iternext(over))) {
                STRLEN kl;
                const char *k = HePV(he, kl);
                (void)hv_store(r, k, (I32)kl, newSVsv(HeVAL(he)), 0);
            }
        }

        RETVAL = newRV_noinc((SV *)r);
    }
    OUTPUT:
        RETVAL
