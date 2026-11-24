#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "pdl.h"
#include "pdlcore.h"

#include <duckdb.h>
#include <string.h>

static Core* PDL;
static SV*   CoreSV;

typedef struct {
    duckdb_database   db;
    duckdb_connection con;
} PdlDuckDBConn;

static PdlDuckDBConn* sv_to_conn(pTHX_ SV* sv) {
    if (!sv_isobject(sv) || !sv_derived_from(sv, "PDL::DuckDB::Connection")) {
        croak("Expected a PDL::DuckDB::Connection object");
    }
    IV ptr = SvIV(SvRV(sv));
    if (!ptr) {
        croak("PDL::DuckDB::Connection has already been closed");
    }
    return INT2PTR(PdlDuckDBConn*, ptr);
}

static int duckdb_type_to_pdl(duckdb_type dt) {
    switch (dt) {
        case DUCKDB_TYPE_BOOLEAN:  return PDL_B;
        case DUCKDB_TYPE_TINYINT:  return PDL_SB;
        case DUCKDB_TYPE_UTINYINT: return PDL_B;
        case DUCKDB_TYPE_SMALLINT: return PDL_S;
        case DUCKDB_TYPE_USMALLINT:return PDL_US;
        case DUCKDB_TYPE_INTEGER:  return PDL_L;
        case DUCKDB_TYPE_UINTEGER: return PDL_UL;
        case DUCKDB_TYPE_BIGINT:   return PDL_LL;
        case DUCKDB_TYPE_UBIGINT:  return PDL_ULL;
        case DUCKDB_TYPE_FLOAT:    return PDL_F;
        case DUCKDB_TYPE_DOUBLE:   return PDL_D;
        default:                   return -1;
    }
}

MODULE = PDL::DuckDB    PACKAGE = PDL::DuckDB

PROTOTYPES: DISABLE

BOOT:
{
    CoreSV = get_sv("PDL::SHARE", FALSE);
    if (!CoreSV) {
        croak("PDL::DuckDB requires PDL::Core to be loaded first");
    }
    PDL = INT2PTR(Core*, SvIV(CoreSV));
    if (PDL->Version != PDL_CORE_VERSION) {
        croak("PDL::DuckDB needs to be recompiled against the newly installed PDL");
    }
}

const char*
duckdb_version()
CODE:
    RETVAL = duckdb_library_version();
OUTPUT:
    RETVAL

MODULE = PDL::DuckDB    PACKAGE = PDL::DuckDB::Connection

SV*
_xs_open(const char* path)
CODE:
    PdlDuckDBConn* c;
    Newxz(c, 1, PdlDuckDBConn);

    const char* db_path = (path && path[0] != '\0' && strcmp(path, ":memory:") != 0) ? path : NULL;
    if (duckdb_open(db_path, &c->db) == DuckDBError) {
        Safefree(c);
        croak("PDL::DuckDB failed to open database");
    }
    if (duckdb_connect(c->db, &c->con) == DuckDBError) {
        duckdb_close(&c->db);
        Safefree(c);
        croak("PDL::DuckDB failed to connect to database");
    }

    SV* iv  = newSViv(PTR2IV(c));
    SV* ref = newRV_noinc(iv);
    sv_bless(ref, gv_stashpv("PDL::DuckDB::Connection", GV_ADD));
    RETVAL = ref;
OUTPUT:
    RETVAL

void
exec(SV* self, const char* sql)
CODE:
    PdlDuckDBConn* c = sv_to_conn(aTHX_ self);
    duckdb_result res;
    if (duckdb_query(c->con, sql, &res) == DuckDBError) {
        const char* err = duckdb_result_error(&res);
        char msg[512];
        snprintf(msg, sizeof(msg), "PDL::DuckDB query failed: %s", err ? err : "unknown error");
        duckdb_destroy_result(&res);
        croak("%s", msg);
    }
    duckdb_destroy_result(&res);

SV*
query_pdl(SV* self, const char* sql)
CODE:
    PdlDuckDBConn* c = sv_to_conn(aTHX_ self);
    duckdb_result res;
    if (duckdb_query(c->con, sql, &res) == DuckDBError) {
        const char* err = duckdb_result_error(&res);
        char msg[512];
        snprintf(msg, sizeof(msg), "PDL::DuckDB query failed: %s", err ? err : "unknown error");
        duckdb_destroy_result(&res);
        croak("%s", msg);
    }

    idx_t ncols   = duckdb_column_count(&res);
    idx_t nchunks = duckdb_result_chunk_count(res);

    /* Compute total row count across chunks */
    idx_t total_rows = 0;
    for (idx_t ci = 0; ci < nchunks; ++ci) {
        duckdb_data_chunk chunk = duckdb_result_get_chunk(res, ci);
        total_rows += duckdb_data_chunk_get_size(chunk);
        duckdb_destroy_data_chunk(&chunk);
    }

    HV* out_hv = newHV();

    for (idx_t col = 0; col < ncols; ++col) {
        const char* col_name = duckdb_column_name(&res, col);
        duckdb_type dt       = duckdb_column_type(&res, col);
        int pdl_dt           = duckdb_type_to_pdl(dt);

        if (pdl_dt >= 0) {
            pdl* p = PDL->pdlnew();
            p->datatype = pdl_dt;
            PDL_Indx dims[1] = { (PDL_Indx)total_rows };
            PDL->setdims(p, dims, 1);
            PDL->allocdata(p);

            size_t elem_size = PDL->howbig(pdl_dt);
            char* dst = (char*)p->data;
            idx_t offset = 0;

            for (idx_t ci = 0; ci < nchunks; ++ci) {
                duckdb_data_chunk chunk = duckdb_result_get_chunk(res, ci);
                idx_t nrows = duckdb_data_chunk_get_size(chunk);
                if (nrows > 0) {
                    duckdb_vector vec = duckdb_data_chunk_get_vector(chunk, col);
                    void* src = duckdb_vector_get_data(vec);
                    memcpy(dst + offset * elem_size, src, (size_t)nrows * elem_size);
                    offset += nrows;
                }
                duckdb_destroy_data_chunk(&chunk);
            }

            SV* pdl_sv = newSV(0);
            PDL->SetSV_PDL(pdl_sv, p);
            (void)hv_store(out_hv, col_name, (I32)strlen(col_name), pdl_sv, 0);
        } else {
            /* Non-numeric column (e.g. VARCHAR): return Perl arrayref of strings */
            AV* av = newAV();
            for (idx_t ci = 0; ci < nchunks; ++ci) {
                duckdb_data_chunk chunk = duckdb_result_get_chunk(res, ci);
                idx_t nrows = duckdb_data_chunk_get_size(chunk);
                duckdb_vector vec = duckdb_data_chunk_get_vector(chunk, col);
                duckdb_string_t* strs = (duckdb_string_t*)duckdb_vector_get_data(vec);
                for (idx_t r = 0; r < nrows; ++r) {
                    if (duckdb_string_is_inlined(strs[r])) {
                        av_push(av, newSVpvn(strs[r].value.inlined.inlined, strs[r].value.inlined.length));
                    } else {
                        av_push(av, newSVpvn(strs[r].value.pointer.ptr, strs[r].value.pointer.length));
                    }
                }
                duckdb_destroy_data_chunk(&chunk);
            }
            (void)hv_store(out_hv, col_name, (I32)strlen(col_name), newRV_noinc((SV*)av), 0);
        }
    }

    duckdb_destroy_result(&res);
    RETVAL = newRV_noinc((SV*)out_hv);
OUTPUT:
    RETVAL

void
DESTROY(SV* self)
CODE:
    if (SvROK(self)) {
        SV* iv = SvRV(self);
        IV ptr = SvIV(iv);
        if (ptr) {
            PdlDuckDBConn* c = INT2PTR(PdlDuckDBConn*, ptr);
            duckdb_disconnect(&c->con);
            duckdb_close(&c->db);
            Safefree(c);
            sv_setiv(iv, 0);
        }
    }
