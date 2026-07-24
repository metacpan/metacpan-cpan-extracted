MODULE = TOML::XS     PACKAGE = TOML::XS::Timestamp

PROTOTYPES: DISABLE

SV*
to_string (SV* selfsv)
    CODE:
        toml_datum_t datum = _get_toml_timestamp_from_sv(aTHX_ selfsv);

        RETVAL = newSVpvs("");

        switch (datum.type) {
        case TOML_DATE:
        case TOML_DATETIME:
        case TOML_DATETIMETZ:
            sv_catpvf(
                RETVAL,
                "%02d-%02d-%02d",
                datum.u.ts.year, datum.u.ts.month, datum.u.ts.day
            );
            break;
        case TOML_TIME:
            break;
        default:
            assert(0);
        }

        switch (datum.type) {
        case TOML_DATETIME:
        case TOML_DATETIMETZ:
            sv_catpv(RETVAL, "T");
        default:
            // checked above
            break;
        }

        switch (datum.type) {
        case TOML_TIME:
        case TOML_DATETIME:
        case TOML_DATETIMETZ:
            sv_catpvf(
                RETVAL,
                "%02d:%02d:%02d",
                datum.u.ts.hour, datum.u.ts.minute, datum.u.ts.second
            );

            if (datum.u.ts.usec != 0) {

                // Strip trailing 0s:
                int32_t usec = datum.u.ts.usec;
                while ((usec % 10) == 0) {
                    usec /= 10;
                }

                sv_catpvf(RETVAL, ".%d", usec);
            }
        default:
            // checked above
            break;
        }

        if (datum.type == TOML_DATETIMETZ) {
            append_tz_to_sv(aTHX_ datum.u.ts.tz, RETVAL);
        } else {
            ASSUME(datum.u.ts.tz == 0);
        }

    OUTPUT:
        RETVAL

SV*
year (SV* selfsv)
    CODE:
        toml_datum_t datum = _get_toml_timestamp_from_sv(aTHX_ selfsv);

        RETVAL = &PL_sv_undef;

        switch (datum.type) {
        case TOML_DATE:
        case TOML_DATETIME:
        case TOML_DATETIMETZ:
            RETVAL = newSViv(datum.u.ts.year);
        case TOML_TIME:
            break;
        default:
            assert(0);
        }
    OUTPUT:
        RETVAL

SV*
month (SV* selfsv)
    CODE:
        toml_datum_t datum = _get_toml_timestamp_from_sv(aTHX_ selfsv);

        RETVAL = &PL_sv_undef;

        switch (datum.type) {
        case TOML_DATE:
        case TOML_DATETIME:
        case TOML_DATETIMETZ:
            RETVAL = newSViv(datum.u.ts.month);
        case TOML_TIME:
            break;
        default:
            assert(0);
        }
    OUTPUT:
        RETVAL

SV*
day (SV* selfsv)
    ALIAS:
        date = 1
    CODE:
        UNUSED(ix);

        toml_datum_t datum = _get_toml_timestamp_from_sv(aTHX_ selfsv);

        RETVAL = &PL_sv_undef;

        switch (datum.type) {
        case TOML_DATE:
        case TOML_DATETIME:
        case TOML_DATETIMETZ:
            RETVAL = newSViv(datum.u.ts.day);
        case TOML_TIME:
            break;
        default:
            assert(0);
        }
    OUTPUT:
        RETVAL

SV*
hour (SV* selfsv)
    ALIAS:
        hours = 1
    CODE:
        UNUSED(ix);

        toml_datum_t datum = _get_toml_timestamp_from_sv(aTHX_ selfsv);

        RETVAL = &PL_sv_undef;

        switch (datum.type) {
        case TOML_TIME:
        case TOML_DATETIME:
        case TOML_DATETIMETZ:
            RETVAL = newSViv(datum.u.ts.hour);
        case TOML_DATE:
            break;
        default:
            assert(0);
        }
    OUTPUT:
        RETVAL

SV*
minute (SV* selfsv)
    ALIAS:
        minutes = 1
    CODE:
        UNUSED(ix);

        toml_datum_t datum = _get_toml_timestamp_from_sv(aTHX_ selfsv);

        RETVAL = &PL_sv_undef;

        switch (datum.type) {
        case TOML_TIME:
        case TOML_DATETIME:
        case TOML_DATETIMETZ:
            RETVAL = newSViv(datum.u.ts.minute);
        case TOML_DATE:
            break;
        default:
            assert(0);
        }
    OUTPUT:
        RETVAL

SV*
second (SV* selfsv)
    ALIAS:
        seconds = 1
    CODE:
        UNUSED(ix);

        toml_datum_t datum = _get_toml_timestamp_from_sv(aTHX_ selfsv);

        RETVAL = &PL_sv_undef;

        switch (datum.type) {
        case TOML_TIME:
        case TOML_DATETIME:
        case TOML_DATETIMETZ:
            RETVAL = newSViv(datum.u.ts.second);
        case TOML_DATE:
            break;
        default:
            assert(0);
        }
    OUTPUT:
        RETVAL

SV*
millisecond (SV* selfsv)
    ALIAS:
        milliseconds = 1
    CODE:
        UNUSED(ix);

        toml_datum_t datum = _get_toml_timestamp_from_sv(aTHX_ selfsv);

        RETVAL = &PL_sv_undef;

        switch (datum.type) {
        case TOML_TIME:
        case TOML_DATETIME:
        case TOML_DATETIMETZ:
            RETVAL = newSViv(datum.u.ts.usec / 1000);
        case TOML_DATE:
            break;
        default:
            assert(0);
        }
    OUTPUT:
        RETVAL

SV*
microsecond (SV* selfsv)
    ALIAS:
        microseconds = 1
    CODE:
        UNUSED(ix);

        toml_datum_t datum = _get_toml_timestamp_from_sv(aTHX_ selfsv);

        RETVAL = &PL_sv_undef;

        switch (datum.type) {
        case TOML_TIME:
        case TOML_DATETIME:
        case TOML_DATETIMETZ:
            RETVAL = newSViv(datum.u.ts.usec);
        case TOML_DATE:
            break;
        default:
            assert(0);
        }
    OUTPUT:
        RETVAL

SV*
timezone (SV* selfsv)
    CODE:
        toml_datum_t datum = _get_toml_timestamp_from_sv(aTHX_ selfsv);

        RETVAL = &PL_sv_undef;

        switch (datum.type) {
        case TOML_DATETIMETZ:
            RETVAL = newSVpvs("");
            append_tz_to_sv(aTHX_ datum.u.ts.tz, RETVAL);
        case TOML_DATE:
        case TOML_TIME:
        case TOML_DATETIME:
            break;
        default:
            assert(0);
        }
    OUTPUT:
        RETVAL
