MODULE = TOML::XS     PACKAGE = TOML::XS::Document

PROTOTYPES: DISABLE

SV*
get (SV* docsv, ...)
    ALIAS:
        to_struct = 1
        parse = 2
    CODE:
        UNUSED(ix);
        toml_result_t* res = exs_structref_ptr(docsv);

        toml_datum_t datum = res->toptab;

        if (items > 1) {
            datum = _drill_into_table(aTHX_ datum, &ST(1), 0, items-1);
        }

        RETVAL = _toml_datum_to_sv(aTHX_ datum);
    OUTPUT:
        RETVAL

void
DESTROY (SV* docsv)
    CODE:
#if DETECT_LEAKS
        _warn_if_global_destruct_destroy(aTHX_ docsv);
#endif

        toml_result_t* res = exs_structref_ptr(docsv);
        toml_free(*res);
