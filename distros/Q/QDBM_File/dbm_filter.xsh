SV*
filter_fetch_key(QDBM_File db, SV* code)
CODE:
    RETVAL = &PL_sv_undef;
    DBM_setFilter(db->filter_fetch_key, code);

SV*
filter_store_key(QDBM_File db, SV* code)
CODE:
    RETVAL = &PL_sv_undef;
    DBM_setFilter(db->filter_store_key, code);

SV*
filter_fetch_value(QDBM_File db, SV* code)
CODE:
    RETVAL = &PL_sv_undef;
    DBM_setFilter(db->filter_fetch_value, code);

SV*
filter_store_value(QDBM_File db, SV* code)
CODE:
    RETVAL = &PL_sv_undef;
    DBM_setFilter(db->filter_store_value, code);
