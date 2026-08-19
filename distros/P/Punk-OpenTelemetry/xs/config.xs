MODULE = Punk::OpenTelemetry    PACKAGE = Punk::OpenTelemetry::Config

PROTOTYPES: DISABLE

# The OTEL_* environment surface, the precedence merge, and the one line the
# SDK prints at boot.

# from_env() -> a config hashref, read once.
SV *
from_env()
    CODE:
        RETVAL = newRV_noinc((SV *)otel_config_from_env(aTHX));
    OUTPUT:
        RETVAL

# resolve(@layers) -> a config hashref.
#
# Layers are merged LOWEST FIRST, so the caller writes them in the order they
# win: resolve($keyword, $file, $env). Undef layers are skipped, so a caller
# does not have to test each source before passing it.
SV *
resolve(...)
    CODE:
    {
        HV *out = newHV();
        int i;
        for (i = items - 1; i >= 0; i--) {
            HV *h = otel_hv_of(aTHX_ ST(i));
            if (h) otel_config_merge(aTHX_ out, h);
        }
        RETVAL = newRV_noinc((SV *)out);
    }
    OUTPUT:
        RETVAL

# diagnostic($config) -> the boot line. Never contains a header value.
SV *
diagnostic(config)
        SV *config
    CODE:
    {
        HV *h = otel_hv_of(aTHX_ config);
        if (!h) croak("Punk::OpenTelemetry::Config::diagnostic: need a hashref");
        RETVAL = newSVsv(otel_config_diagnostic(aTHX_ h));
    }
    OUTPUT:
        RETVAL

# disabled($config) -> whether the SDK is off. A separate entry point because
# it is asked before anything is built, and the answer must not depend on any
# of it having been built.
IV
disabled(config)
        SV *config
    CODE:
    {
        HV *h = otel_hv_of(aTHX_ config);
        SV *v = h ? otel_h(aTHX_ h, "disabled") : NULL;
        RETVAL = (v && SvTRUE(v)) ? 1 : 0;
    }
    OUTPUT:
        RETVAL
